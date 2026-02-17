import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/app_state.dart';

class ChatPlanView extends StatelessWidget {
  const ChatPlanView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OBJECTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appState.jobDescription,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              itemCount: appState.studyWeeks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final week = appState.studyWeeks[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      title: Text(
                        'Week ${week.weekNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          week.title,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF6B7280)),
                        ),
                      ),
                      textColor: const Color(0xFF111827),
                      iconColor: const Color(0xFF9CA3AF),
                      childrenPadding: EdgeInsets.zero,
                      onExpansionChanged: (expanded) {
                        if (expanded) appState.refineWeek(index);
                      },
                      children: [
                        if (week.days.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ...week.days.asMap().entries.map((entry) {
                          final dayIdx = entry.key;
                          final day = entry.value;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                    color: Colors.grey.withOpacity(0.05)),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 4),
                              title: Text(
                                day.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[400]),
                                    const SizedBox(width: 4),
                                    Text(
                                      day.duration,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500]),
                                    ),
                                    const SizedBox(width: 12),
                                    if (day.videoLink.isNotEmpty) ...[
                                      Icon(Icons.play_circle_outline,
                                          size: 14,
                                          color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Video',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280)),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  day.isAddedToCalendar
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  color: day.isAddedToCalendar
                                      ? const Color(0xFF10B981) // Emerald green
                                      : const Color(0xFFE5E7EB), // Light grey
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () =>
                                    appState.generateDayDetail(index, dayIdx),
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
