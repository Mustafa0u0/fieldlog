import 'package:flutter/material.dart';
import 'package:outbox_queue/outbox_queue.dart';

/// Tells the inspector what the app is still holding.
///
/// The distinction between "waiting to send" and "retrying shortly" is the
/// whole reason this exists. A single "not synced" count invites people to
/// stand in a field pulling to refresh; saying that a retry is already
/// scheduled tells them they can walk away.
class QueueBanner extends StatelessWidget {
  const QueueBanner({required this.stats, required this.onSync, super.key});

  final OutboxStats stats;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (stats.total == 0 && stats.deadLettered == 0) {
      return _Bar(
        background: scheme.primaryContainer,
        foreground: scheme.onPrimaryContainer,
        icon: Icons.cloud_done_outlined,
        message: 'Everything is on the server',
      );
    }

    final parts = <String>[
      if (stats.pending > 0) '${stats.pending} to send',
      if (stats.waiting > 0) '${stats.waiting} retrying shortly',
      if (stats.deadLettered > 0) '${stats.deadLettered} need attention',
    ];

    return _Bar(
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
      icon: Icons.cloud_upload_outlined,
      message: parts.join(' · '),
      action: stats.pending > 0
          ? TextButton(onPressed: onSync, child: const Text('Send now'))
          : null,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.background,
    required this.foreground,
    required this.icon,
    required this.message,
    this.action,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w500),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
