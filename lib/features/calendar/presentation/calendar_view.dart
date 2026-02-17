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
        ? const Center(
            child: Text(
              'No items scheduled yet.\nGo to Plan to add items.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF), height: 1.5),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            itemCount: scheduledDays.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final day = scheduledDays[index];
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.timer_outlined,
                                  size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                day.duration,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (day.videoLink.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Recommended Video: ${day.videoLink}'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF1F2937),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_filled_rounded),
                        color: const Color(0xFF111827),
                        iconSize: 32,
                      ),
                  ],
                ),
              );
            },
          );
  }
}
