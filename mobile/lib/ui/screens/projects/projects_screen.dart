import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/projects_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'project_detail_screen.dart';
import 'project_form_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectsProvider>(context, listen: false).fetchProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Projects"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Project",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
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
                children: [
                  "All",
                  "Planning",
                  "In Progress",
                  "Review",
                  "Completed",
                  "Delivered",
                  "On Hold"
                ].map((s) {
                  final isSelected = provider.selectedStatus == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: isSelected,
                      onSelected: (_) => provider.fetchProjects(status: s),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading && provider.projects.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.projects.isEmpty) {
                  return ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchProjects(),
                  );
                }

                if (provider.projects.isEmpty) {
                  return EmptyView(
                    title: "No Projects Found",
                    subtitle: "Manage client development, SEO, and maintenance contracts.",
                    icon: Icons.folder_special_outlined,
                    buttonText: "Create Project",
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProjectFormScreen()),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchProjects(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.projects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final project = provider.projects[index];
                      final contractValue = project.finalAmount > 0 ? project.finalAmount : project.quotedAmount;

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProjectDetailScreen(project: project)),
                          ),
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
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                    ),
                                    StatusChip(status: project.status),
                                  ],
                                ),
                                if (project.businessName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    project.businessName!,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Value: ${Formatters.formatCurrency(contractValue)}",
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                                    ),
                                    if (project.deadline != null)
                                      Text(
                                        "Due: ${Formatters.formatDate(project.deadline)}",
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                  ],
                                ),
                                if (project.assignedUserNames.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Assigned: ${project.assignedUserNames.join(', ')}",
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ]
                              ],
                            ),
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
