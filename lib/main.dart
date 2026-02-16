import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Career Plan AI',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: const InputPage(),
      ),
    );
  }
}

class StudyWeek {
  final int weekNumber;
  final String title;
  final String content;
  List<StudyDay> days = [];

  StudyWeek({required this.weekNumber, required this.title, required this.content});
}

class StudyDay {
  final int dayNumber;
  final String title;
  final String duration;
  final String videoLink;
  String detailedContent = '';
  bool isAddedToCalendar = false;

  StudyDay({required this.dayNumber, required this.title, required this.duration, required this.videoLink});
}

class MyAppState extends ChangeNotifier {
  String jobDescription = '';
  List<String> aiQuestions = [];
  Map<String, String> userAnswers = {};
  bool isLoadingQuestions = false;
  
  // New Study Plan Structure
  List<StudyWeek> studyWeeks = [];
  bool isGeneratingPlan = false;
  int selectedWeekIndex = 0;

  // API Credentials
  final String _pat = 'pat_3C2vZf8IqdsDj9UTmz59gCXkTT4yl5LDq37dQIUPcCiKnsnPqaDgaVaFkiCKKE4s';
  final String _botId = '7606709849422020648';
  final String _baseUrl = 'https://api.coze.cn/v3/chat';

  void setJobDescription(String value) {
    jobDescription = value;
    notifyListeners();
  }

  Future<String> _callCoze(String query) async {
    try {
      // 1. Create a chat
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_pat',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bot_id': _botId,
          'user_id': 'user_flutter_app',
          'stream': false,
          'additional_messages': [
            {
              'role': 'user',
              'content': query,
              'content_type': 'text',
            }
          ],
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to create chat: ${response.body}');
      }

      final data = jsonDecode(response.body);
      final chatId = data['data']['id'];
      final sessionId = data['data']['conversation_id'];

      // 2. Poll for completion
      String status = 'in_progress';
      while (status == 'in_progress' || status == 'created') {
        await Future.delayed(const Duration(seconds: 1));
        final pollResponse = await http.get(
          Uri.parse('$_baseUrl/retrieve?chat_id=$chatId&conversation_id=$sessionId'),
          headers: {'Authorization': 'Bearer $_pat'},
        );
        final pollData = jsonDecode(pollResponse.body);
        status = pollData['data']['status'];
        if (status == 'failed' || status == 'requires_action') {
          throw Exception('Chat stopped with status: $status');
        }
      }

      // 3. Retrieve messages
      final msgResponse = await http.get(
        Uri.parse('https://api.coze.cn/v3/chat/message/list?chat_id=$chatId&conversation_id=$sessionId'),
        headers: {'Authorization': 'Bearer $_pat'},
      );
      final msgData = jsonDecode(msgResponse.body);
      
      List messages = msgData['data'];
      var assistantMsg = messages.firstWhere((m) => m['type'] == 'answer', orElse: () => null);
      if (assistantMsg == null) {
        assistantMsg = messages.firstWhere((m) => m['role'] == 'assistant', orElse: () => null);
      }
      
      return assistantMsg != null ? assistantMsg['content'] : 'No response from AI';
    } catch (e) {
      debugPrint('Coze API Error: $e');
      return 'Error: $e';
    }
  }

  Future<void> generateQuestions() async {
    if (jobDescription.isEmpty) return;
    
    isLoadingQuestions = true;
    notifyListeners();

    String prompt = "我想要学习 $jobDescription 这个岗位。请作为职业规划导师，向我提 4 个最关键的问题，以了解我的基础、时间、偏好等，从而为我制定学习计划。请直接返回问题列表，每行一个问题，不要有其他前言或废话。";
    
    String result = await _callCoze(prompt);
    
    aiQuestions = result
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && (s.contains('?') || s.contains('？') || s.length > 5))
        .toList();

    if (aiQuestions.isEmpty) {
      aiQuestions = ['请详细描述您的基础如何？', '您每天能投入多少时间？', '您的学习目标是什么？', '您更倾向于哪种学习方式？'];
    }
    
    userAnswers = {for (var q in aiQuestions) q: ''};
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

    String answersStr = userAnswers.entries.map((e) => "问：${e.key} 答：${e.value}").join('\n');
    String prompt = """
基于目标 $jobDescription 和我的回答：
$answersStr

请为一个为期两个月的学习过程生成周级别的大框架。
请严格按照以下 JSON 格式返回（不要有任何其他文字）：
[
  {"week": 1, "title": "基础入门", "summary": "学习环境搭建和基本语法"},
  {"week": 2, "title": "进阶核心", "summary": "..."},
  ... 共8周
]
""";
    
    String result = await _callCoze(prompt);
    try {
      // Find JSON if AI wrapped it in markdown
      int jsonStart = result.indexOf('[');
      int jsonEnd = result.lastIndexOf(']') + 1;
      String jsonStr = result.substring(jsonStart, jsonEnd);
      List<dynamic> data = jsonDecode(jsonStr);
      studyWeeks = data.map((w) => StudyWeek(
        weekNumber: w['week'],
        title: w['title'],
        content: w['summary']
      )).toList();
    } catch (e) {
      debugPrint("Parse Error: $e");
      // Fallback
      studyWeeks = List.generate(8, (i) => StudyWeek(weekNumber: i+1, title: "第${i+1}周计划", content: "待细化内容..."));
    }

    isGeneratingPlan = false;
    notifyListeners();
  }

  Future<void> refineWeek(int weekIndex) async {
    if (studyWeeks[weekIndex].days.isNotEmpty) return;
    
    isGeneratingPlan = true;
    notifyListeners();

    String prompt = """
请细化第 ${weekIndex + 1} 周的内容：${studyWeeks[weekIndex].title}。
请为 Day 1 到 Day 7 分别指定：标题、建议时长、参考视频链接。
请严格按照以下 JSON 格式返回：
[
  {"day": 1, "title": "Day 1 任务", "duration": "2小时", "video": "https://..."},
  ...
]
""";

    String result = await _callCoze(prompt);
    try {
      int jsonStart = result.indexOf('[');
      int jsonEnd = result.lastIndexOf(']') + 1;
      String jsonStr = result.substring(jsonStart, jsonEnd);
      List<dynamic> data = jsonDecode(jsonStr);
      studyWeeks[weekIndex].days = data.map((d) => StudyDay(
        dayNumber: d['day'],
        title: d['title'],
        duration: d['duration'],
        videoLink: d['video']
      )).toList();
    } catch (e) {
      studyWeeks[weekIndex].days = List.generate(7, (i) => StudyDay(dayNumber: i+1, title: "待定任务", duration: "1小时", videoLink: ""));
    }

    isGeneratingPlan = false;
    notifyListeners();
  }

  Future<void> generateDayDetail(int weekIndex, int dayIndex) async {
    isGeneratingPlan = true;
    notifyListeners();

    String dayTitle = studyWeeks[weekIndex].days[dayIndex].title;
    String prompt = "请为学习计划中的 $dayTitle 生成具体的学习文档内容。包含详细的知识点解读、示例代码（如有）和今日练习。使用 Markdown 格式。";

    String result = await _callCoze(prompt);
    studyWeeks[weekIndex].days[dayIndex].detailedContent = result;
    studyWeeks[weekIndex].days[dayIndex].isAddedToCalendar = true;

    isGeneratingPlan = false;
    notifyListeners();
  }
}

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('职业学习计划生成器'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '你想开启什么职业路径？',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '输入岗位或具体要求',
                hintText: '如：前端开发、数据分析师、Python 自动化测试',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.work_outline),
              ),
              onChanged: (value) => appState.setJobDescription(value),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: appState.jobDescription.isEmpty || appState.isLoadingQuestions
                  ? null
                  : () => appState.generateQuestions(),
              icon: const Icon(Icons.auto_awesome),
              label: appState.isLoadingQuestions
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('生成 AI 针对性问题'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            if (appState.aiQuestions.isNotEmpty) ...[
              const Divider(height: 40),
              const Text(
                'AI 需要了解更多细节：',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...appState.aiQuestions.map((q) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: q,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.blue.withOpacity(0.05),
                      ),
                      onChanged: (value) => appState.updateAnswer(q, value),
                    ),
                  )),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: appState.userAnswers.values.any((a) => a.isEmpty)
                    ? null
                    : () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(child: CircularProgressIndicator()),
                        );
                        await appState.generateFullFramework();
                        if (mounted) {
                          Navigator.pop(context); 
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MainAppPage()),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('立即生成专属学习计划', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    
    final List<Widget> _pages = [
      const ChatPlanView(),
      const CalendarView(),
      const FilesView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '学习计划' : (_selectedIndex == 1 ? '课程日程' : '学习文档')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '计划'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '日程'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: '文件'),
        ],
      ),
    );
  }
}

class ChatPlanView extends StatelessWidget {
  const ChatPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('核心框架：${appState.jobDescription}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: appState.studyWeeks.length,
            itemBuilder: (context, index) {
              var week = appState.studyWeeks[index];
              return ExpansionTile(
                title: Text('第 ${week.weekNumber} 周: ${week.title}'),
                subtitle: Text(week.content),
                onExpansionChanged: (expanded) {
                  if (expanded) appState.refineWeek(index);
                },
                children: [
                  if (week.days.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ...week.days.asMap().entries.map((entry) {
                    int dayIdx = entry.key;
                    var day = entry.value;
                    return ListTile(
                      title: Text(day.title),
                      subtitle: Text('时长: ${day.duration} | 视频: ${day.videoLink.isEmpty ? "暂无" : "确认后可见"}'),
                      trailing: IconButton(
                        icon: Icon(day.isAddedToCalendar ? Icons.check_circle : Icons.add_alarm, 
                                   color: day.isAddedToCalendar ? Colors.green : Colors.blue),
                        onPressed: () => appState.generateDayDetail(index, dayIdx),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    List<StudyDay> scheduledDays = [];
    for (var w in appState.studyWeeks) {
      scheduledDays.addAll(w.days.where((d) => d.isAddedToCalendar));
    }

    return scheduledDays.isEmpty
        ? const Center(child: Text('暂无日程，请在计划页将任务添加到日程'))
        : ListView.builder(
            itemCount: scheduledDays.length,
            itemBuilder: (context, index) {
              var day = scheduledDays[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(day.title),
                  subtitle: Text('时长: ${day.duration}'),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.red),
                  onTap: () {
                    if (day.videoLink.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('跳转视频: ${day.videoLink}')));
                    }
                  },
                ),
              );
            },
          );
  }
}

class FilesView extends StatelessWidget {
  const FilesView({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    List<StudyDay> docs = [];
    for (var w in appState.studyWeeks) {
      docs.addAll(w.days.where((d) => d.detailedContent.isNotEmpty));
    }

    return docs.isEmpty
        ? const Center(child: Text('暂无文档，日程生成后将自动生成 Day 1 文档'))
        : ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var day = docs[index];
              return ExpansionTile(
                leading: const Icon(Icons.article, color: Colors.orange),
                title: Text('${day.title} - 学习文档'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(day.detailedContent),
                  ),
                ],
              );
            },
          );
  }
}
