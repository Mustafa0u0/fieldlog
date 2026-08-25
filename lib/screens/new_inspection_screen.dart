import 'package:flutter/material.dart';

import '../models/inspection.dart';
import '../theme.dart';

/// Recording an inspection.
///
/// One screen, three decisions, no scrolling on a normal phone. The condition
/// is chosen from three large targets rather than a dropdown, because the
/// whole interaction happens standing up with one hand.
class NewInspectionScreen extends StatefulWidget {
  const NewInspectionScreen({super.key});

  @override
  State<NewInspectionScreen> createState() => _NewInspectionScreenState();
}

class _NewInspectionScreenState extends State<NewInspectionScreen> {
  final _site = TextEditingController();
  final _note = TextEditingController();
  Condition _condition = Condition.ok;

  @override
  void dispose() {
    _site.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _site.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('New inspection')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            TextField(
              controller: _site,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Site',
                hintText: 'Coop 2, North shed',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Text('Condition', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final condition in Condition.values)
              _ConditionOption(
                condition: condition,
                selected: _condition == condition,
                onTap: () => setState(() => _condition = condition),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _note,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'What you saw, in your own words',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: ready ? _save : null,
              child: const Text('Record'),
            ),
            const SizedBox(height: 10),
            Text(
              'Recorded straight away. It reaches the server when there is signal.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    Navigator.of(context).pop(
      Inspection(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        site: _site.text.trim(),
        condition: _condition,
        note: _note.text.trim(),
        recordedAt: DateTime.now(),
      ),
    );
  }
}

class _ConditionOption extends StatelessWidget {
  const _ConditionOption({
    required this.condition,
    required this.selected,
    required this.onTap,
  });

  final Condition condition;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colour = conditionColour(context, condition.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: selected
                ? colour.withValues(alpha: 0.10)
                : scheme.surfaceContainerLow,
            border: Border.all(
              color: selected ? colour : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? colour : scheme.outline,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: selected ? colour : scheme.onSurface,
                      ),
                    ),
                    // The meaning is spelled out. "Urgent" means different
                    // things to different people, and an inspector guessing is
                    // how a scale stops being comparable between rounds.
                    Text(
                      condition.meaning,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
