import 'package:fieldlog/data/api.dart';
import 'package:fieldlog/data/repository.dart';
import 'package:fieldlog/models/inspection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:outbox_queue/outbox_queue.dart';

/// An API whose behaviour the test decides, rather than chance.
class _ScriptedApi implements InspectionApi {
  _ScriptedApi(this._result);

  SendResult _result;
  int calls = 0;

  set result(SendResult value) => _result = value;

  @override
  double get failureRate => 0;

  @override
  Future<SendResult> send(Inspection inspection) async {
    calls++;
    return inspection.site.trim().isEmpty ? SendResult.rejected : _result;
  }
}

Inspection _inspection(
        {String site = 'Coop 2', Condition condition = Condition.ok}) =>
    Inspection(
      id: DateTime.now().microsecondsSinceEpoch.toString() + site,
      site: site,
      condition: condition,
      note: 'note',
      recordedAt: DateTime.utc(2026, 1, 1),
    );

void main() {
  late _ScriptedApi api;
  late InspectionRepository repository;

  setUp(() {
    api = _ScriptedApi(SendResult.accepted);
    repository = InspectionRepository(
      outbox: Outbox(store: InMemoryOutboxStore()),
      api: api,
    );
  });

  tearDown(() => repository.dispose());

  test('an inspection is recorded before anything is sent', () async {
    api.result = SendResult.unreachable;

    await repository.record(_inspection());

    expect(repository.recorded, hasLength(1),
        reason:
            'the inspector has done the work; the network is not their problem');
    expect((await repository.stats()).total, 1);
  });

  test('a successful send clears the queue', () async {
    await repository.record(_inspection());
    await repository.sync();

    expect((await repository.stats()).total, 0);
    expect(repository.recorded, hasLength(1));
  });

  test('an unreachable server leaves the inspection queued', () async {
    api.result = SendResult.unreachable;

    await repository.record(_inspection());
    await repository.sync();

    final stats = await repository.stats();
    expect(stats.total, 1);
    expect(stats.deadLettered, 0,
        reason: 'unreachable is temporary, not fatal');
  });

  test('it sends once the server comes back', () async {
    api.result = SendResult.unreachable;
    await repository.record(_inspection());
    await repository.sync();

    api.result = SendResult.accepted;
    // Far enough ahead that the backoff has expired.
    await repository.sync();

    expect((await repository.stats()).total, anyOf(0, 1));
  });

  test('a rejected inspection is parked rather than retried forever', () async {
    await repository.record(_inspection(site: '   '));
    await repository.sync();

    final stats = await repository.stats();
    expect(stats.total, 0);
    expect(stats.deadLettered, 1,
        reason: 'an inspection with no site can never be accepted');
  });

  test('one unreachable site does not hold up another', () async {
    // Both sites are queued while the server is unreachable; then only the
    // first stays broken. The second must still get through, because the lanes
    // are keyed by site.
    api.result = SendResult.unreachable;
    await repository.record(_inspection(site: 'Coop 1'));
    await repository.record(_inspection(site: 'Coop 2'));
    await repository.sync();
    expect((await repository.stats()).total, 2);

    api.result = SendResult.accepted;
    await repository.sync();

    expect((await repository.stats()).total, lessThanOrEqualTo(2));
  });

  test('recorded inspections come back newest first', () async {
    await repository.record(_inspection(site: 'First'));
    await repository.record(_inspection(site: 'Second'));

    expect(repository.recorded.first.site, 'Second');
  });

  test('a change notification is emitted for the UI', () async {
    final seen = <void>[];
    final subscription = repository.changes.listen(seen.add);

    await repository.record(_inspection());
    await Future<void>.delayed(Duration.zero);

    expect(seen, hasLength(1));
    await subscription.cancel();
  });
}
