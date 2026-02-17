import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../plan/application/app_state.dart';

class SavedPlansView extends StatelessWidget {
  const SavedPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    final savedPlans = appState.savedPlans;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Career Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create New Plan',
            onPressed: () {
              // Start a new plan clearing current state
              // checks verify this triggers LandingPage to show InputPage
              appState.startNewPlan();
              Navigator.of(context).pop(); // Close the saved plans page
            },
          ),
        ],
      ),
      body: savedPlans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.history_edu, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text(
                    'No saved plans yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () {
                       appState.startNewPlan();
                       Navigator.of(context).pop();
                     },
                     icon: const Icon(Icons.add),
                     label: const Text('Create New Plan'),
                   ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: savedPlans.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final plan = savedPlans[index];
                final date = plan.createdAt;
                final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                
                // Highlight the currently active plan
                final isCurrent = plan.id == appState.currentPlanId;

                return Card(
                  elevation: isCurrent ? 2 : 0,
                  color: isCurrent ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1) : null,
                  shape: isCurrent 
                    ? RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                      )
                    : null,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      plan.jobTarget,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Created: $dateStr',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${plan.weeks.length} Weeks Plan',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent)
                           const Chip(label: Text('Current', style: TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Plan?'),
                                content: Text('Are you sure you want to delete "${plan.jobTarget}"?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              appState.deletePlan(plan.id);
                            }
                          },
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      appState.loadPlan(plan);
                      Navigator.of(context).pop(); // Go back to main view
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          appState.startNewPlan();
          Navigator.of(context).pop();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Plan'),
      ),
    );
  }
}
