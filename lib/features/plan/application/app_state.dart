import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/language_detector.dart';
import '../domain/models/study_day.dart';
import '../domain/models/study_plan.dart';
import '../domain/models/study_week.dart';
import 'local_storage_service.dart';

class MyAppState extends ChangeNotifier {
  final LocalStorageService _storage;

  String jobDescription = '';
  List<String> aiQuestions = [];
  Map<String, String> userAnswers = {};
  bool isLoadingQuestions = false;

  List<StudyWeek> studyWeeks = [];
  bool isGeneratingPlan = false;
  int selectedWeekIndex = 0;

  /// 当前正在编辑的计划 id（null 表示尚未保存过）
  String? _currentPlanId;
  String? get currentPlanId => _currentPlanId;

  /// 历史计划列表（用于"我的计划"页面等）
  List<StudyPlan> get savedPlans => _storage.getAllPlans();

  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://localhost:3000');

  MyAppState(this._storage) {
    _tryRestoreLastPlan();
  }

  /// 尝试恢复上次打开的计划
  void _tryRestoreLastPlan() {
    final lastPlan = _storage.getLastOpenPlan();
    if (lastPlan != null) {
      debugPrint(
          '🔄 Restoring plan: id=${lastPlan.id}, job=${lastPlan.jobTarget}, weeks=${lastPlan.weeks.length}');
      _currentPlanId = lastPlan.id;
      jobDescription = lastPlan.jobTarget;
      aiQuestions = List<String>.from(lastPlan.aiQuestions);
      userAnswers = Map<String, String>.from(lastPlan.userAnswers);
      studyWeeks = lastPlan.weeks;
      notifyListeners();
    } else {
      debugPrint('🔄 No saved plan found to restore');
    }
  }

  /// 将当前状态保存到本地
  Future<void> _saveCurrent() async {
    if (studyWeeks.isEmpty) return; // 还没生成计划，不存

    final plan = StudyPlan(
      id: _currentPlanId ?? '${DateTime.now().millisecondsSinceEpoch}',
      jobTarget: jobDescription,
      aiQuestions: List<String>.from(aiQuestions),
      userAnswers: Map<String, String>.from(userAnswers),
      weeks: studyWeeks,
      createdAt: _currentPlanId != null
          ? (_storage.getPlan(_currentPlanId!)?.createdAt ?? DateTime.now())
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _currentPlanId = plan.id;
    await _storage.savePlan(plan);
    debugPrint(
        '💾 Plan saved! id=${plan.id}, weeks=${plan.weeks.length}, job=${plan.jobTarget}');
  }

  /// 开始一个新计划（清空当前状态）
  void startNewPlan() {
    _currentPlanId = null;
    jobDescription = '';
    aiQuestions = [];
    userAnswers = {};
    studyWeeks = [];
    selectedWeekIndex = 0;
    notifyListeners();
  }

  /// 加载一个已保存的计划
  void loadPlan(StudyPlan plan) {
    _currentPlanId = plan.id;
    jobDescription = plan.jobTarget;
    aiQuestions = List<String>.from(plan.aiQuestions);
    userAnswers = Map<String, String>.from(plan.userAnswers);
    studyWeeks = plan.weeks;
    selectedWeekIndex = 0;
    _storage.setLastOpenPlanId(plan.id);
    notifyListeners();
  }

  /// 删除一个已保存的计划
  Future<void> deletePlan(String id) async {
    await _storage.deletePlan(id);
    if (_currentPlanId == id) {
      startNewPlan();
    }
    notifyListeners();
  }

  void setJobDescription(String value) {
    jobDescription = value;
    notifyListeners();
  }

  Future<String> _callCoze(String query) async {
    const int maxRetries = 2; // Try up to 3 times total
    const Duration retryDelay = Duration(seconds: 2);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await http
            .post(
              Uri.parse('$_apiBaseUrl/api/coze-chat'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'query': query,
                'userId': 'user_flutter_app',
              }),
            )
            .timeout(const Duration(seconds: 120));

        if (response.statusCode != 200) {
          throw Exception('Backend proxy call failed: ${response.body}');
        }

        final data = jsonDecode(response.body);
        final content = data['content'];
        return content is String && content.isNotEmpty
            ? content
            : 'No response from AI';
      } on TimeoutException {
        debugPrint('Coze API Timeout (Attempt ${attempt + 1})');
        if (attempt == maxRetries) return 'Error: 请求超时，请检查网络后重试';
      } on http.ClientException catch (e) {
        debugPrint('Coze API Connection Error (Attempt ${attempt + 1}): $e');
        if (attempt == maxRetries) return 'Error: 网络连接中断，请检查网络';
      } catch (e) {
        // SocketException is often wrapped in ClientException or thrown directly
        if (e.toString().contains('SocketException') ||
            e.toString().contains('Connection closed')) {
          debugPrint('Coze API Socket Error (Attempt ${attempt + 1}): $e');
          if (attempt == maxRetries) return 'Error: 网络连接异常，请重试';
        } else {
          debugPrint('Coze API Error: $e');
          return 'Error: $e';
        }
      }

      // Wait before retrying
      if (attempt < maxRetries) {
        await Future.delayed(retryDelay * (attempt + 1)); // Exponential backoff
      }
    }
    return 'Error: 多次请求失败，请稍后重试';
  }

  Future<void> generateQuestions() async {
    if (jobDescription.isEmpty) return;

    isLoadingQuestions = true;
    notifyListeners();

    // 检测输入语言
    final language = LanguageDetector.detectLanguage(jobDescription);

    // 根据语言选择提示词
    final prompt = language == 'zh'
        ? '''我想要学习 $jobDescription 这个岗位。请作为职业规划导师，向我提 4 个最关键的问题，以了解我的基础、时间、偏好等，从而为我制定学习计划。请直接返回问题列表，每行一个问题，不要有其他前言或废话。'''
        : '''I want to learn the role of $jobDescription. As a career planning mentor, please ask me 4 critical questions to understand my foundation, available time, preferences, etc., so that I can create a learning plan for me. Please return only the list of questions, one per line, without any preamble or unnecessary words.''';

    final result = await _callCoze(prompt);

    aiQuestions = result
        .split('\n')
        .map((s) => s.trim())
        .where((s) =>
            s.isNotEmpty &&
            (s.contains('?') || s.contains('？') || s.length > 5))
        .toList();

    if (aiQuestions.isEmpty) {
      aiQuestions = language == 'zh'
          ? [
              '请详细描述您的基础如何？',
              '您每天能投入多少时间？',
              '您的学习目标是什么？',
              '您更倾向于哪种学习方式？',
            ]
          : [
              'What is your current foundation in this field?',
              'How much time can you dedicate daily?',
              'What is your primary learning goal?',
              'What is your preferred learning style?',
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

    // 检测输入语言
    final language = LanguageDetector.detectLanguage(jobDescription);

    final answersStr = language == 'zh'
        ? userAnswers.entries.map((e) => '问：${e.key} 答：${e.value}').join('\n')
        : userAnswers.entries
            .map((e) => 'Q: ${e.key} A: ${e.value}')
            .join('\n');

    final prompt = language == 'zh'
        ? '''
基于目标 $jobDescription 和我的回答：
$answersStr

请为一个为期两个月的学习过程生成周级别的大框架。
请严格按照以下 JSON 格式返回（不要有任何其他文字）：
[
  {"week": 1, "title": "基础入门", "summary": "学习环境搭建和基本语法"},
  {"week": 2, "title": "进阶核心", "summary": "..."},
  ... 共8周
]
'''
        : '''
Based on the goal of $jobDescription and my answers:
$answersStr

Please generate a week-level framework for an 8-week learning process.
Return strictly in the following JSON format (no other text):
[
  {"week": 1, "title": "Foundation Setup", "summary": "Environment setup and basic syntax"},
  {"week": 2, "title": "Core Concepts", "summary": "..."},
  ... 8 weeks total
]
''';

    final result = await _callCoze(prompt);
    if (result.startsWith('Error:')) {
      isGeneratingPlan = false;
      notifyListeners();
      throw Exception(result);
    }
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
          title: language == 'zh' ? '第${i + 1}周计划' : 'Week ${i + 1}',
          content: language == 'zh' ? '待细化内容...' : 'To be detailed...',
        ),
      );
    }

    isGeneratingPlan = false;
    notifyListeners();
    await _saveCurrent();

    // 后台预加载所有周的每日详情（fire-and-forget，不阻塞 UI）
    _prefetchAllWeeks();
  }

  /// 后台顺序预加载所有周的每日详情
  Future<void> _prefetchAllWeeks() async {
    for (int i = 0; i < studyWeeks.length; i++) {
      if (studyWeeks[i].days.isNotEmpty) continue;
      await _loadWeekDetails(i);
    }
  }

  Future<void> refineWeek(int weekIndex) async {
    if (studyWeeks[weekIndex].days.isNotEmpty) return;
    await _loadWeekDetails(weekIndex);
  }

  /// 加载指定周的每日详情（不影响全局 isGeneratingPlan 状态）
  Future<void> _loadWeekDetails(int weekIndex) async {
    if (studyWeeks[weekIndex].days.isNotEmpty) return;

    // 检测当前语言
    final language = LanguageDetector.detectLanguage(jobDescription);

    final prompt = language == 'zh'
        ? '''
请细化第 ${weekIndex + 1} 周的内容：${studyWeeks[weekIndex].title}。
请为 Day 1 到 Day 7 分别指定：标题、建议时长、推荐视频标题。

【重要】视频推荐要求：
1. 视频来源仅限：B站(bilibili)或YouTube
2. 必须是播放量高、质量高、口碑好的优质教学视频
3. 直接给出适合搜索的视频标题（例如："Python零基础入门教程 - 小甲鱼"）
4. 优先推荐经典的、被广泛认可的系列教程

请严格按照以下 JSON 格式返回：
[
  {"day": 1, "title": "Day 1 任务", "duration": "2小时", "video": "推荐的优质视频标题"},
  ...
]
'''
        : '''
Please refine the content for Week ${weekIndex + 1}: ${studyWeeks[weekIndex].title}.
Specify for Day 1 to Day 7: title, recommended duration, recommended video title.

【Important】Video recommendation requirements:
1. Video sources only: Bilibili or YouTube
2. Must be high-volume, high-quality, well-reviewed teaching videos
3. Provide video titles suitable for searching
4. Prioritize classic, widely recognized tutorial series

Return strictly in JSON format:
[
  {"day": 1, "title": "Day 1 Task", "duration": "2 hours", "video": "Recommended video title"},
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
          title: language == 'zh' ? '待定任务' : 'Pending Task',
          duration: language == 'zh' ? '1小时' : '1 hour',
          videoLink: '',
        ),
      );
    }

    notifyListeners();
    await _saveCurrent();
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
    await _saveCurrent();
  }
}
