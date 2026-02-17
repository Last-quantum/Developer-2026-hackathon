import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../domain/models/study_day.dart';
import '../domain/models/study_week.dart';

class MyAppState extends ChangeNotifier {
  String jobDescription = '';
  List<String> aiQuestions = [];
  Map<String, String> userAnswers = {};
  bool isLoadingQuestions = false;

  List<StudyWeek> studyWeeks = [];
  bool isGeneratingPlan = false;
  int selectedWeekIndex = 0;

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:3000');

  void setJobDescription(String value) {
    jobDescription = value;
    notifyListeners();
  }

  Future<String> _callCoze(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/api/coze-chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'userId': 'user_flutter_app',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Backend proxy call failed: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final content = data['content'];
      return content is String && content.isNotEmpty
          ? content
          : 'No response from AI';
    } catch (e) {
      debugPrint('Coze API Error: $e');
      return 'Error: $e';
    }
  }

  Future<void> generateQuestions() async {
    if (jobDescription.isEmpty) return;

    isLoadingQuestions = true;
    notifyListeners();

    const promptPrefix = '我想要学习 ';
    final prompt =
        '$promptPrefix$jobDescription 这个岗位。请作为职业规划导师，向我提 4 个最关键的问题，以了解我的基础、时间、偏好等，从而为我制定学习计划。请直接返回问题列表，每行一个问题，不要有其他前言或废话。';

    final result = await _callCoze(prompt);

    aiQuestions = result
        .split('\n')
        .map((s) => s.trim())
        .where((s) =>
            s.isNotEmpty &&
            (s.contains('?') || s.contains('？') || s.length > 5))
        .toList();

    if (aiQuestions.isEmpty) {
      aiQuestions = [
        '请详细描述您的基础如何？',
        '您每天能投入多少时间？',
        '您的学习目标是什么？',
        '您更倾向于哪种学习方式？',
      ];
    }

    userAnswers = {for (final q in aiQuestions) q: ''};
    isLoadingQuestions = false;
    notifyListeners();
  }

  void updateAnswer(String question, String answer) {
    userAnswers[question] = answer;
    notifyListeners();
  }

  Future<void> generateFullFramework() async {
    isGeneratingPlan = true;
    notifyListeners();

    final answersStr =
        userAnswers.entries.map((e) => '问：${e.key} 答：${e.value}').join('\n');
    final prompt = '''
基于目标 $jobDescription 和我的回答：
$answersStr

请为一个为期两个月的学习过程生成周级别的大框架。
请严格按照以下 JSON 格式返回（不要有任何其他文字）：
[
  {"week": 1, "title": "基础入门", "summary": "学习环境搭建和基本语法"},
  {"week": 2, "title": "进阶核心", "summary": "..."},
  ... 共8周
]
''';

    final result = await _callCoze(prompt);
    try {
      final jsonStart = result.indexOf('[');
      final jsonEnd = result.lastIndexOf(']') + 1;
      final jsonStr = result.substring(jsonStart, jsonEnd);
      final List<dynamic> data = jsonDecode(jsonStr);
      studyWeeks = data
          .map(
            (w) => StudyWeek(
              weekNumber: w['week'],
              title: w['title'],
              content: w['summary'],
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Parse Error: $e');
      studyWeeks = List.generate(
        8,
        (i) => StudyWeek(
          weekNumber: i + 1,
          title: '第${i + 1}周计划',
          content: '待细化内容...',
        ),
      );
    }

    isGeneratingPlan = false;
    notifyListeners();
  }

  Future<void> refineWeek(int weekIndex) async {
    if (studyWeeks[weekIndex].days.isNotEmpty) return;

    isGeneratingPlan = true;
    notifyListeners();

    final prompt = '''
请细化第 ${weekIndex + 1} 周的内容：${studyWeeks[weekIndex].title}。
请为 Day 1 到 Day 7 分别指定：标题、建议时长、推荐视频标题（直接给出适合在B站或其他平台搜索的视频标题）。
请严格按照以下 JSON 格式返回：
[
  {"day": 1, "title": "Day 1 任务", "duration": "2小时", "video": "推荐的视频标题"},
  ...
]
''';

    final result = await _callCoze(prompt);
    try {
      final jsonStart = result.indexOf('[');
      final jsonEnd = result.lastIndexOf(']') + 1;
      final jsonStr = result.substring(jsonStart, jsonEnd);
      final List<dynamic> data = jsonDecode(jsonStr);
      studyWeeks[weekIndex].days = data
          .map(
            (d) => StudyDay(
              dayNumber: d['day'],
              title: d['title'],
              duration: d['duration'],
              videoLink: d['video'],
            ),
          )
          .toList();
    } catch (e) {
      studyWeeks[weekIndex].days = List.generate(
        7,
        (i) => StudyDay(
          dayNumber: i + 1,
          title: '待定任务',
          duration: '1小时',
          videoLink: '',
        ),
      );
    }

    isGeneratingPlan = false;
    notifyListeners();
  }

  Future<void> generateDayDetail(int weekIndex, int dayIndex) async {
    isGeneratingPlan = true;
    notifyListeners();

    final dayTitle = studyWeeks[weekIndex].days[dayIndex].title;
    final prompt =
        '请为学习计划中的 $dayTitle 生成具体的学习文档内容。包含详细的知识点解读、示例代码（如有）和今日练习。使用 Markdown 格式。';

    final result = await _callCoze(prompt);
    studyWeeks[weekIndex].days[dayIndex].detailedContent = result;
    studyWeeks[weekIndex].days[dayIndex].isAddedToCalendar = true;

    isGeneratingPlan = false;
    notifyListeners();
  }
}
