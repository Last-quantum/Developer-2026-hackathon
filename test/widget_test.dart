// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:career_app/main.dart';

void main() {
  testWidgets('Input page renders core fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('职业学习计划生成器'), findsOneWidget);
    expect(find.text('你想开启什么职业路径？'), findsOneWidget);
    expect(find.text('生成 AI 针对性问题'), findsOneWidget);
  });
}
