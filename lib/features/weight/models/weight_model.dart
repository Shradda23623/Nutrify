class WeightEntry {
  final double kg;
  final DateTime date;
  final String? note;

  WeightEntry({required this.kg, required this.date, this.note});

  Map<String, dynamic> toMap() => {
        'kg': kg,
        'date': date.toIso8601String(),
        'note': note ?? '',
      };

  factory WeightEntry.fromMap(Map<String, dynamic> map) => WeightEntry(
        kg: (map['kg'] ?? 0).toDouble(),
        date: DateTime.parse(map['date']),
        note: map['note'] as String?,
      );
}
