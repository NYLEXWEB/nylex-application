import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/project_model.dart';
import '../../../models/daily_update_model.dart';
import '../../../models/task_model.dart';
import '../../../providers/projects_provider.dart';
import '../../../providers/tasks_provider.dart';
import '../../widgets/status_chip.dart';
import 'daily_update_dialog.dart';
import '../tasks/task_form_dialog.dart';
import 'project_form_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DailyUpdateModel> _dailyUpdates = [];
  List<dynamic> _activityFeed = [];
  bool _isLoadingTabs = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProjectData();
  }

  void _loadProjectData() async {
    setState(() => _isLoadingTabs = true);
    final projectsProvider = Provider.of<ProjectsProvider>(context, listen: false);
    final tasksProvider = Provider.of<TasksProvider>(context, listen: false);

    await tasksProvider.fetchTasks(projectId: widget.project.id);
    final updates = await projectsProvider.fetchDailyUpdates(widget.project.id);
    final feed = await projectsProvider.fetchActivityFeed(widget.project.id);

    if (mounted) {
      setState(() {
        _dailyUpdates = updates;
        _activityFeed = feed;
        _isLoadingTabs = false;
      });
    }
  }

  void _markDelivered() {
    final dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Deliver Project"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Mark this project as delivered and set official delivery handover date:",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Delivery Date (YYYY-MM-DD)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: "Handover Notes"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ProjectsProvider>(context, listen: false).deliverProject(
                widget.project.id,
                {"deliveryDate": dateController.text.trim(), "notes": notesController.text.trim()},
              );
              Navigator.pop(context);
            },
            child: const Text("Confirm Delivery"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final tasksProvider = Provider.of<TasksProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.projectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProjectFormScreen(project: project)),
            ),
          ),
          if (project.status != "Delivered")
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
              tooltip: "Mark Delivered",
              onPressed: _markDelivered,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Daily Updates"),
            Tab(text: "Tasks"),
            Tab(text: "Activity Feed"),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) => DailyUpdateDialog(projectId: project.id),
                );
                if (result == true) _loadProjectData();
              },
              icon: const Icon(Icons.post_add),
              label: const Text("Post Update"),
            )
          : _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (_) => TaskFormDialog(projectId: project.id),
                    );
                    _loadProjectData();
                  },
                  icon: const Icon(Icons.add_task),
                  label: const Text("Add Task"),
                )
              : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Overview Tab
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              project.projectName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          StatusChip(status: project.status),
                        ],
                      ),
                      if (project.businessName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Client: ${project.businessName}",
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                      const Divider(height: 24),
                      _infoRow("Type", project.projectType),
                      _infoRow("Contract Value", Formatters.formatCurrency(project.finalAmount > 0 ? project.finalAmount : project.quotedAmount)),
                      _infoRow("Total Paid", Formatters.formatCurrency(project.totalPaid)),
                      _infoRow("Balance Due", Formatters.formatCurrency(project.balanceDue)),
                      _infoRow("Priority", project.priority),
                      if (project.startDate != null) _infoRow("Start Date", Formatters.formatDate(project.startDate)),
                      if (project.deadline != null) _infoRow("Deadline", Formatters.formatDate(project.deadline)),
                      if (project.assignedUserNames.isNotEmpty)
                        _infoRow("Assigned Users", project.assignedUserNames.join(", ")),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Domain Information Section
              if (project.domainInfo != null) ...[
                const Text("Domain Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow("Domain", "${project.domainInfo!.domainName ?? 'N/A'}${project.domainInfo!.domainExtension ?? ''}"),
                        _infoRow("Registrar", project.domainInfo!.registrar ?? "N/A"),
                        _infoRow("Purchase Email", project.domainInfo!.purchaseEmail ?? "N/A"),
                        _infoRow("Expiry Date", project.domainInfo!.expiryDate ?? "N/A"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Delivery Information Section (Section 33)
              if (project.deliveryInfo != null) ...[
                const Text("Delivery Handover", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow("Delivery Date", Formatters.formatDate(project.deliveryInfo!.deliveryDate)),
                        _infoRow("Payment Status", project.deliveryInfo!.finalPaymentStatus ?? "N/A"),
                        if (project.deliveryInfo!.supportStartDate != null)
                          _infoRow("Support Start", Formatters.formatDate(project.deliveryInfo!.supportStartDate)),
                        if (project.deliveryInfo!.notes != null)
                          _infoRow("Handover Notes", project.deliveryInfo!.notes!),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          // 2. Daily Updates Tab (Section 20)
          _isLoadingTabs
              ? const Center(child: CircularProgressIndicator())
              : _dailyUpdates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.sync, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text("No daily updates posted yet.", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (_) => DailyUpdateDialog(projectId: project.id),
                              );
                              if (result == true) _loadProjectData();
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Post First Update"),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _dailyUpdates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final u = _dailyUpdates[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(u.userName ?? "Partner", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                    Text(Formatters.formatDate(u.date), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                                const Divider(height: 16),
                                Text(u.updateText, style: const TextStyle(fontSize: 14, height: 1.4)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

          // 3. Tasks Tab (Section 19)
          _isLoadingTabs
              ? const Center(child: CircularProgressIndicator())
              : tasksProvider.tasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.task_alt, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text("No tasks in this project yet.", style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (_) => TaskFormDialog(projectId: project.id),
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text("Add Task"),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasksProvider.tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final task = tasksProvider.tasks[index];
                        final isCompleted = task.status == "Completed";

                        return Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: isCompleted,
                              onChanged: (_) {
                                if (isCompleted) {
                                  tasksProvider.reopenTask(task.id);
                                } else {
                                  tasksProvider.completeTask(task.id);
                                }
                              },
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text("Assigned: ${task.assignedToName ?? 'Team'} • Due: ${Formatters.formatDate(task.dueDate)}"),
                            trailing: StatusChip(status: task.status),
                          ),
                        );
                      },
                    ),

          // 4. Activity Feed Tab (Section 21)
          _isLoadingTabs
              ? const Center(child: CircularProgressIndicator())
              : _activityFeed.isEmpty
                  ? const Center(child: Text("No activity recorded yet."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _activityFeed.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final act = _activityFeed[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.background,
                              child: const Icon(Icons.flash_on, color: AppColors.accent, size: 18),
                            ),
                            title: Text(act['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text("${act['author'] ?? ''} • ${act['description'] ?? ''}"),
                            trailing: Text(Formatters.formatDate(act['timestamp']), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
