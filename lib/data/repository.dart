import 'dart:async';
import 'dart:io';

import 'package:outbox_queue/outbox_queue.dart';
import 'package:path_provider/path_provider.dart';

import '../models/inspection.dart';
import 'api.dart';

/// Holds the inspections and the queue that gets them to the server.
///
/// The app never waits on the network to record something. An inspection is
/// written to the outbox and the screen updates immediately; the queue deals
/// with delivery on its own schedule. That ordering is the entire design — an
/// inspector standing in a field has already done the work, and software that
/// refuses to accept it because of a bar of signal is software that gets
/// worked around with a paper pad.
class InspectionRepository {
  InspectionRepository({required Outbox outbox, required InspectionApi api})
      : _outbox = outbox,
        _api = api {
    _outbox.register('inspection', _send);
  }

  final Outbox _outbox;
  final InspectionApi _api;

  final List<Inspection> _recorded = [];
  final _changes = StreamController<void>.broadcast();

  /// Everything recorded on this device, newest first.
  List<Inspection> get recorded => List.unmodifiable(_recorded.reversed);

  Stream<void> get changes => _changes.stream;
  Stream<OutboxStats> get queue => _outbox.stats;

  static Future<InspectionRepository> open({InspectionApi? api}) async {
    final directory = await getApplicationSupportDirectory();
    return InspectionRepository(
      outbox:
          Outbox(store: FileOutboxStore(Directory('${directory.path}/outbox'))),
      api: api ?? InspectionApi(),
    );
  }

  Future<void> record(Inspection inspection) async {
    _recorded.add(inspection);
    _changes.add(null);

    await _outbox.enqueue(
      type: 'inspection',
      payload: inspection.toJson(),
      // One lane per site. Two inspections of the same site must reach the
      // server in the order they were made — the second describes what changed
      // since the first. Different sites have nothing to say to each other, so
      // a site that cannot be reached does not hold up the rest of the round.
      lane: inspection.site,
    );
  }

  Future<void> sync() => _outbox.drain();

  Future<OutboxStats> stats() => _outbox.snapshot();

  Future<OutboxVerdict> _send(OutboxOperation operation) async {
    final inspection = Inspection.fromJson(operation.payload);

    switch (await _api.send(inspection)) {
      case SendResult.accepted:
        return OutboxVerdict.done;
      case SendResult.unreachable:
        return OutboxVerdict.retry;
      case SendResult.rejected:
        // Retrying would block this site's lane until the attempts run out and
        // achieve nothing. Park it instead so it can be looked at.
        return OutboxVerdict.drop;
    }
  }

  Future<void> dispose() async {
    await _changes.close();
    await _outbox.dispose();
  }
}
