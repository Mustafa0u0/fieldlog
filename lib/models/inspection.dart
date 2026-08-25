/// One visit to one site.
///
/// Deliberately small and flat. An inspection is filled in on a phone, often
/// with one hand, often in the rain — every field here had to justify the time
/// it costs to enter.
class Inspection {
  const Inspection({
    required this.id,
    required this.site,
    required this.condition,
    required this.note,
    required this.recordedAt,
  });

  final String id;
  final String site;
  final Condition condition;
  final String note;
  final DateTime recordedAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'site': site,
        'condition': condition.name,
        'note': note,
        'recordedAt': recordedAt.toIso8601String(),
      };

  static Inspection fromJson(Map<String, Object?> json) => Inspection(
        id: json['id']! as String,
        site: json['site']! as String,
        condition: Condition.values.byName(json['condition']! as String),
        note: (json['note'] as String?) ?? '',
        recordedAt: DateTime.parse(json['recordedAt']! as String),
      );
}

/// Three states, not five.
///
/// A scale with more points invites the inspector to split hairs at the till
/// of a wet field. What the office actually acts on is "is anything wrong, and
/// is it urgent" — so that is what gets recorded.
enum Condition {
  ok('Fine', 'Nothing needs doing'),
  attention('Needs attention', 'Should be looked at this week'),
  urgent('Urgent', 'Someone should go now');

  const Condition(this.label, this.meaning);

  final String label;
  final String meaning;
}
