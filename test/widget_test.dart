// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:career_app/main.dart';
import 'package:career_app/features/plan/domain/models/study_day.dart';
import 'package:career_app/features/plan/domain/models/study_week.dart';
import 'package:career_app/features/plan/domain/models/study_plan.dart';
import 'package:career_app/features/plan/application/local_storage_service.dart';

void main() {
  testWidgets('Input page renders core fields', (WidgetTester tester) async {
    // 使用临时目录初始化 Hive（避免和真实数据冲突）
    final tempDir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(StudyDayAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StudyWeekAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(StudyPlanAdapter());
    }

    final storage = LocalStorageService();
    await storage.initBoxesOnly();

    await tester.pumpWidget(MyApp(storage: storage));

    expect(find.text('职业学习计划生成器'), findsOneWidget);
    expect(find.text('你想开启什么职业路径？'), findsOneWidget);
    expect(find.text('生成 AI 针对性问题'), findsOneWidget);

    // 清理
    await Hive.close();
    tempDir.deleteSync(recursive: true);
  });
}
