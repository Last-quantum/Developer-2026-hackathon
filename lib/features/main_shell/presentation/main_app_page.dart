import 'package:flutter/material.dart';

import '../../calendar/presentation/calendar_view.dart';
import '../../files/presentation/files_view.dart';
import '../../plan/presentation/chat_plan_view.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [
      ChatPlanView(),
      CalendarView(),
      FilesView(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? '学习计划'
            : (_selectedIndex == 1 ? '课程日程' : '学习文档')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: '计划'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: '日程'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined), label: '文件'),
        ],
      ),
    );
  }
}
