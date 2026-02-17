import 'package:flutter/material.dart';

import '../../calendar/presentation/calendar_view.dart';
import '../../files/presentation/files_view.dart';
import '../../plan/presentation/chat_plan_view.dart';
import '../../plan/presentation/saved_plans_view.dart';

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
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'Strategy'
              : (_selectedIndex == 1 ? 'Schedule' : 'Library'),
          style: const TextStyle(
              fontWeight: FontWeight.w600, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withOpacity(0.1),
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedPlansView()),
              );
            },
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Saved Plans',
          )
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: const Color(0xFF111827),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedLabelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: -0.2),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Plan'),
            BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today_rounded),
                label: 'Schedule'),
            BottomNavigationBarItem(
                icon: Icon(Icons.folder_open_outlined),
                activeIcon: Icon(Icons.folder_rounded),
                label: 'Files'),
          ],
        ),
      ),
    );
  }
}
