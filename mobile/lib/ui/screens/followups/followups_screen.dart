import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/followups_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'followup_form_dialog.dart';

class FollowupsScreen extends StatefulWidget {
  const FollowupsScreen({Key? key}) : super(key: key);

  @override
  State<FollowupsScreen> createState() => _FollowupsScreenState();
}

class _FollowupsScreenState extends State<FollowupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FollowupsProvider>(context, listen: false).fetchFollowups();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FollowupsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Follow-ups"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Schedule Follow-up",
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const FollowupFormDialog(),
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
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("All Follow-ups"),
                  selected: !provider.filterToday,
                  onSelected: (_) => provider.fetchFollowups(todayOnly: false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text("Today Only"),
                  selected: provider.filterToday,
                  onSelected: (_) => provider.fetchFollowups(todayOnly: true),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Builder(
              builder: (context) {
                if (provider.isLoading && provider.followups.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.followups.isEmpty) {
                  return ErrorView(
                    message: provider.errorMessage!,
                    onRetry: () => provider.fetchFollowups(),
                  );
                }

                if (provider.followups.isEmpty) {
                  return EmptyView(
                    title: "No Follow-ups",
                    subtitle: "All prospect calls and meetings are up to date.",
                    icon: Icons.phone_callback_outlined,
                    buttonText: "Schedule Follow-up",
                    onAction: () => showDialog(
                      context: context,
                      builder: (_) => const FollowupFormDialog(),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchFollowups(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.followups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = provider.followups[index];
                      final isPending = item.status == "Pending";

                      return Card(
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
                                      item.leadName ?? item.clientName ?? "Contact",
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                  ),
                                  StatusChip(status: item.status),
                                ],
                              ),
                              if (item.leadBusiness != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.leadBusiness!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${Formatters.formatDate(item.scheduledDate)} at ${item.scheduledTime} (${item.method})",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              if (item.notes != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.notes!,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () => provider.completeFollowup(item.id),
                                    icon: const Icon(Icons.check, size: 16, color: AppColors.success),
                                    label: const Text("Mark Completed"),
                                  ),
                                ),
                              ]
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
