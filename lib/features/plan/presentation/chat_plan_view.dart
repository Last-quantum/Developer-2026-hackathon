import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/app_state.dart';

class ChatPlanView extends StatelessWidget {
  const ChatPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('核心框架：${appState.jobDescription}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: appState.studyWeeks.length,
            itemBuilder: (context, index) {
              final week = appState.studyWeeks[index];
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
                    final dayIdx = entry.key;
                    final day = entry.value;
                    return ListTile(
                      title: Text(day.title),
                      subtitle: Text(
                          '时长: ${day.duration} | 视频: ${day.videoLink.isEmpty ? "暂无" : "确认后可见"}'),
                      trailing: IconButton(
                        icon: Icon(
                          day.isAddedToCalendar
                              ? Icons.check_circle
                              : Icons.add_alarm,
                          color: day.isAddedToCalendar
                              ? Colors.green
                              : Colors.blue,
                        ),
                        onPressed: () =>
                            appState.generateDayDetail(index, dayIdx),
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
