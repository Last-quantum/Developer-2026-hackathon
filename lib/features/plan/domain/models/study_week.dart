import 'study_day.dart';

class StudyWeek {
  final int weekNumber;
  final String title;
  final String content;
  List<StudyDay> days = [];

  StudyWeek({
    required this.weekNumber,
    required this.title,
    required this.content,
  });
}
