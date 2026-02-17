import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../plan/application/app_state.dart';
import '../../plan/domain/models/study_day.dart';

class FilesView extends StatelessWidget {
  const FilesView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final List<StudyDay> docs = [];
    for (final w in appState.studyWeeks) {
      docs.addAll(w.days.where((d) => d.detailedContent.isNotEmpty));
    }

    return docs.isEmpty
        ? const Center(child: Text('暂无文档，日程生成后将自动生成 Day 1 文档'))
        : ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final day = docs[index];
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
