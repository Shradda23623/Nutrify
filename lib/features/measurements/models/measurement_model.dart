class MeasurementEntry {
  final String id;
  final DateTime date;
  final double? waist;  // cm
  final double? hips;   // cm
  final double? chest;  // cm
  final double? arms;   // cm (bicep)
  final double? thighs; // cm
  final String? note;

  MeasurementEntry({
    required this.id,
    required this.date,
    this.waist,
    this.hips,
    this.chest,
    this.arms,
    this.thighs,
    this.note,
  });

  factory MeasurementEntry.create({
    double? waist,
    double? hips,
    double? chest,
    double? arms,
    double? thighs,
    String? note,
  }) {
    final now = DateTime.now();
    return MeasurementEntry(
      id: now.millisecondsSinceEpoch.toString(),
      date: now,
      waist: waist,
      hips: hips,
      chest: chest,
      arms: arms,
      thighs: thighs,
      note: note,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toIso8601String(),
        'waist': waist,
        'hips': hips,
        'chest': chest,
        'arms': arms,
        'thighs': thighs,
        'note': note,
      };

  factory MeasurementEntry.fromMap(Map<String, dynamic> map) =>
      MeasurementEntry(
        id: map['id'] as String? ??
            (map['date'] as String? ?? DateTime.now().toIso8601String()),
        date: DateTime.parse(map['date'] as String),
        waist: (map['waist'] as num?)?.toDouble(),
        hips: (map['hips'] as num?)?.toDouble(),
        chest: (map['chest'] as num?)?.toDouble(),
        arms: (map['arms'] as num?)?.toDouble(),
        thighs: (map['thighs'] as num?)?.toDouble(),
        note: map['note'] as String?,
      );

  MeasurementEntry copyWith({
    String? id,
    DateTime? date,
    double? waist,
    double? hips,
    double? chest,
    double? arms,
    double? thighs,
    String? note,
    bool clearWaist = false,
    bool clearHips = false,
    bool clearChest = false,
    bool clearArms = false,
    bool clearThighs = false,
    bool clearNote = false,
  }) =>
      MeasurementEntry(
        id: id ?? this.id,
        date: date ?? this.date,
        waist: clearWaist ? null : (waist ?? this.waist),
        hips: clearHips ? null : (hips ?? this.hips),
        chest: clearChest ? null : (chest ?? this.chest),
        arms: clearArms ? null : (arms ?? this.arms),
        thighs: clearThighs ? null : (thighs ?? this.thighs),
        note: clearNote ? null : (note ?? this.note),
      );
}
