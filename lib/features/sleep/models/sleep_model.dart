class SleepEntry {
  final DateTime bedtime;
  final DateTime wakeTime;
  final int quality; // 1-5
  final String notes;

  SleepEntry({
    required this.bedtime,
    required this.wakeTime,
    required this.quality,
    this.notes = '',
  });

  int get durationMinutes {
    final diff = wakeTime.difference(bedtime);
    return diff.inMinutes < 0 ? diff.inMinutes + 1440 : diff.inMinutes;
  }

  double get durationHours => durationMinutes / 60.0;

  Map<String, dynamic> toMap() => {
        'bedtime': bedtime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'quality': quality,
        'notes': notes,
      };

  factory SleepEntry.fromMap(Map<String, dynamic> map) => SleepEntry(
        bedtime: DateTime.parse(map['bedtime'] as String),
        wakeTime: DateTime.parse(map['wakeTime'] as String),
        quality: map['quality'] as int,
        notes: map['notes'] as String? ?? '',
      );
}
