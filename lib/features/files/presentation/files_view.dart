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
        ? const Center(
            child: Text(
              'No documents generated yet.\nComplete tasks in Plan to generate.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final day = docs[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF), // Light blue tint
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Color(0xFF3B82F6), // Professional blue
                        size: 20,
                      ),
                    ),
                    title: Text(
                      day.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Color(0xFF111827),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF9CA3AF),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Text(
                          day.detailedContent,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
