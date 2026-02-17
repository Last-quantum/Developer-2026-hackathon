import 'package:hive/hive.dart';

import 'study_week.dart';

part 'study_plan.g.dart';

@HiveType(typeId: 2)
class StudyPlan extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String jobTarget;

  @HiveField(2)
  List<String> aiQuestions;

  @HiveField(3)
  Map<String, String> userAnswers;

  @HiveField(4)
  List<StudyWeek> weeks;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  StudyPlan({
    required this.id,
    required this.jobTarget,
    required this.aiQuestions,
    required this.userAnswers,
    required this.weeks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudyPlan.create({
    required String jobTarget,
    required List<String> aiQuestions,
    required Map<String, String> userAnswers,
    required List<StudyWeek> weeks,
  }) {
    final now = DateTime.now();
    return StudyPlan(
      id: '${now.millisecondsSinceEpoch}',
      jobTarget: jobTarget,
      aiQuestions: aiQuestions,
      userAnswers: userAnswers,
      weeks: weeks,
      createdAt: now,
      updatedAt: now,
    );
  }
}
