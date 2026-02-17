import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main_shell/presentation/main_app_page.dart';
import '../../plan/application/app_state.dart';

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
    final appState = context.watch<MyAppState>();

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
              onPressed:
                  appState.jobDescription.isEmpty || appState.isLoadingQuestions
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
              ...appState.aiQuestions.map(
                (q) => Padding(
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
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: appState.userAnswers.values.any((a) => a.isEmpty)
                    ? null
                    : () async {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) =>
                              const Center(child: CircularProgressIndicator()),
                        );
                        await appState.generateFullFramework();
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainAppPage(),
                            ),
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
