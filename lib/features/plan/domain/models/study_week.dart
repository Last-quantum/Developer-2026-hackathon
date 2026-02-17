import 'package:hive/hive.dart';

import 'study_day.dart';

part 'study_week.g.dart';

@HiveType(typeId: 1)
class StudyWeek extends HiveObject {
  @HiveField(0)
  final int weekNumber;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String content;

  @HiveField(3)
  List<StudyDay> days = [];

  StudyWeek({
    required this.weekNumber,
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toJson() => {
        'weekNumber': weekNumber,
        'title': title,
        'content': content,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory StudyWeek.fromJson(Map<String, dynamic> json) {
    final week = StudyWeek(
      weekNumber: json['weekNumber'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
    );
    final daysJson = json['days'] as List<dynamic>?;
    if (daysJson != null) {
      week.days = daysJson
          .map((d) => StudyDay.fromJson(d as Map<String, dynamic>))
          .toList();
    }
    return week;
  }
}
