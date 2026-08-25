import 'dart:async';

import 'package:flutter/material.dart';
import 'package:outbox_queue/outbox_queue.dart';

import '../data/repository.dart';
import '../models/inspection.dart';
import '../widgets/inspection_tile.dart';
import '../widgets/queue_banner.dart';
import 'new_inspection_screen.dart';

/// Today's round.
class RoundScreen extends StatefulWidget {
  const RoundScreen({required this.repository, super.key});

  final InspectionRepository repository;

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> {
  OutboxStats _stats =
      const OutboxStats(pending: 0, waiting: 0, deadLettered: 0);
  StreamSubscription<void>? _changes;
  StreamSubscription<OutboxStats>? _queue;
  Timer? _retry;

  @override
  void initState() {
    super.initState();

    _changes = widget.repository.changes.listen((_) => setState(() {}));
    _queue = widget.repository.queue
        .listen((stats) => setState(() => _stats = stats));
    unawaited(_refreshStats());

    // A quiet retry loop rather than watching connectivity. The platform will
    // happily report a connection to a router with no route beyond it, so the
    // only honest test of whether the server is reachable is trying to reach
    // it. The queue's own backoff stops this from becoming a hammer.
    _retry = Timer.periodic(const Duration(seconds: 20), (_) => _sync());
  }

  @override
  void dispose() {
    _retry?.cancel();
    unawaited(_changes?.cancel());
    unawaited(_queue?.cancel());
    super.dispose();
  }

  Future<void> _refreshStats() async {
    final stats = await widget.repository.stats();
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _sync() async {
    await widget.repository.sync();
    await _refreshStats();
  }

  Future<void> _add() async {
    final inspection = await Navigator.of(context).push<Inspection>(
      MaterialPageRoute(builder: (_) => const NewInspectionScreen()),
    );
    if (inspection == null) return;

    await widget.repository.record(inspection);
    await _refreshStats();
    unawaited(_sync());
  }

  @override
  Widget build(BuildContext context) {
    final recorded = widget.repository.recorded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            onPressed: _sync,
            icon: const Icon(Icons.sync),
            tooltip: 'Try sending now',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Inspection'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: QueueBanner(stats: _stats, onSync: _sync),
            ),
            Expanded(
              child: recorded.isEmpty
                  ? const _Empty()
                  : RefreshIndicator(
                      onRefresh: _sync,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                        itemCount: recorded.length,
                        itemBuilder: (_, index) =>
                            InspectionTile(inspection: recorded[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist_outlined, size: 48, color: scheme.outline),
            const SizedBox(height: 16),
            Text('Nothing recorded yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Record an inspection and it is saved on this phone straight away, '
              'whether or not there is any signal.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
