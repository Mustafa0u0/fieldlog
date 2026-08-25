import 'package:flutter/material.dart';

import '../models/inspection.dart';
import '../theme.dart';

class InspectionTile extends StatelessWidget {
  const InspectionTile({required this.inspection, super.key});

  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final colour = conditionColour(context, inspection.condition.name);
    final text = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // The dot is supporting evidence, never the only signal — the
                // condition is written out beside it.
                Container(
                  width: 10,
                  height: 10,
                  decoration:
                      BoxDecoration(color: colour, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    inspection.site,
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  _clock(inspection.recordedAt),
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              inspection.condition.label,
              style: text.bodyMedium
                  ?.copyWith(color: colour, fontWeight: FontWeight.w600),
            ),
            if (inspection.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(inspection.note, style: text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  static String _clock(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
}
