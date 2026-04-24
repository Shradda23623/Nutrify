class ReminderModel {
  final String id;
  final String title;
  final String time; // Store as HH:mm
  bool isActive;

  ReminderModel({
    required this.id,
    required this.title,
    required this.time,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'isActive': isActive,
      };

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
        id: json['id'],
        title: json['title'],
        time: json['time'],
        isActive: json['isActive'],
      );
}
