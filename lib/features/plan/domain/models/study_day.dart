import 'package:hive/hive.dart';

part 'study_day.g.dart';

@HiveType(typeId: 0)
class StudyDay extends HiveObject {
  @HiveField(0)
  final int dayNumber;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String duration;

  @HiveField(3)
  final String videoLink;

  @HiveField(4)
  String detailedContent = '';

  @HiveField(5)
  bool isAddedToCalendar = false;

  StudyDay({
    required this.dayNumber,
    required this.title,
    required this.duration,
    required this.videoLink,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'title': title,
        'duration': duration,
        'videoLink': videoLink,
        'detailedContent': detailedContent,
        'isAddedToCalendar': isAddedToCalendar,
      };

  factory StudyDay.fromJson(Map<String, dynamic> json) {
    final day = StudyDay(
      dayNumber: json['dayNumber'] as int,
      title: json['title'] as String,
      duration: json['duration'] as String,
      videoLink: json['videoLink'] as String,
    );
    day.detailedContent = json['detailedContent'] as String? ?? '';
    day.isAddedToCalendar = json['isAddedToCalendar'] as bool? ?? false;
    return day;
  }
}
