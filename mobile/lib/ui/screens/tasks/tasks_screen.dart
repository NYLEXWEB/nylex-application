import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/tasks_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'task_form_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TasksProvider>(context, listen: false).fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TasksProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Task",
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const TaskFormDialog(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["All", "Todo", "In Progress", "Completed", "Blocked"].map((s) {
                  final isSelected = provider.selectedStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: isSelected,
                      onSelected: (_) => provider.fetchTasks(status: s),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading && provider.tasks.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.tasks.isEmpty) {
                  return ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchTasks(),
                  );
                }

                if (provider.tasks.isEmpty) {
                  return EmptyView(
                    title: "No Tasks Found",
                    subtitle: "Organize project milestones and actionable tasks.",
                    icon: Icons.task_alt,
                    buttonText: "Create Task",
                    onAction: () => showDialog(
                      context: context,
                      builder: (_) => const TaskFormDialog(),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchTasks(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = provider.tasks[index];
                      final isCompleted = task.status == "Completed";

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: isCompleted,
                                onChanged: (_) {
                                  if (isCompleted) {
                                    provider.reopenTask(task.id);
                                  } else {
                                    provider.completeTask(task.id);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              decoration: isCompleted ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                        ),
                                        StatusChip(status: task.status),
                                      ],
                                    ),
                                    if (task.projectName != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Project: ${task.projectName!}",
                                        style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                    if (task.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        task.description!,
                                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (task.dueDate != null) ...[
                                          const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Due: ${Formatters.formatDate(task.dueDate)}",
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        if (task.assignedToName != null) ...[
                                          const Icon(Icons.person_outline, size: 12, color: AppColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.assignedToName!,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
