import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../plan/application/app_state.dart';
import '../../plan/domain/models/study_day.dart';

class CalendarView extends StatelessWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final List<StudyDay> scheduledDays = [];
    for (final w in appState.studyWeeks) {
      scheduledDays.addAll(w.days.where((d) => d.isAddedToCalendar));
    }

    return scheduledDays.isEmpty
        ? const Center(child: Text('暂无日程，请在计划页将任务添加到日程'))
        : ListView.builder(
            itemCount: scheduledDays.length,
            itemBuilder: (context, index) {
              final day = scheduledDays[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(day.title),
                  subtitle: Text('时长: ${day.duration}'),
                  trailing:
                      const Icon(Icons.play_circle_fill, color: Colors.red),
                  onTap: () {
                    if (day.videoLink.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('推荐视频: ${day.videoLink}')),
                      );
                    }
                  },
                ),
              );
            },
          );
  }
}
