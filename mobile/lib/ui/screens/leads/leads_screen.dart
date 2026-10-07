import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/leads_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'lead_detail_screen.dart';
import 'lead_form_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({Key? key}) : super(key: key);

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LeadsProvider>(context, listen: false).fetchLeads();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = Provider.of<LeadsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leads"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Lead",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeadFormScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search leads by name, business, phone...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              leadsProvider.fetchLeads(search: "");
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onSubmitted: (val) => leadsProvider.fetchLeads(search: val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      "All",
                      "New",
                      "Contacted",
                      "Follow-up",
                      "Proposal",
                      "Negotiation",
                      "Won",
                      "Lost"
                    ].map((status) {
                      final isSelected = leadsProvider.selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) => leadsProvider.fetchLeads(status: status),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Leads List
          Expanded(
            child: Builder(
              builder: (context) {
                if (leadsProvider.isLoading && leadsProvider.leads.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (leadsProvider.errorMessage != null && leadsProvider.leads.isEmpty) {
                  return ErrorView(
                    message: leadsProvider.errorMessage!,
                    onRetry: () => leadsProvider.fetchLeads(),
                  );
                }

                if (leadsProvider.leads.isEmpty) {
                  return EmptyView(
                    title: "No Leads Found",
                    subtitle: "Track potential clients from Instagram, WhatsApp, or direct referrals.",
                    icon: Icons.person_add_outlined,
                    buttonText: "Add Lead",
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LeadFormScreen()),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => leadsProvider.fetchLeads(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: leadsProvider.leads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final lead = leadsProvider.leads[index];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
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
                                        lead.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    StatusChip(status: lead.status),
                                  ],
                                ),
                                if (lead.businessName != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    lead.businessName!,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      lead.phone,
                                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                    ),
                                    if (lead.expectedBudget > 0) ...[
                                      const Text(" • ", style: TextStyle(color: AppColors.textMuted)),
                                      Text(
                                        "Budget: ${Formatters.formatCurrency(lead.expectedBudget)}",
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.accent),
                                      ),
                                    ]
                                  ],
                                ),
                                if (lead.nextFollowUp != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 14, color: AppColors.warning),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Next Follow-up: ${lead.nextFollowUp}",
                                        style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
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
