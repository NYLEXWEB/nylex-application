import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/error_view.dart';
import '../leads/lead_form_screen.dart';
import '../clients/client_form_screen.dart';
import '../projects/project_form_screen.dart';
import '../tasks/task_form_dialog.dart';
import '../quotations/quotation_form_screen.dart';
import '../invoices/invoice_form_screen.dart';
import '../payments/add_payment_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboard();
    });
  }

  void _showQuickActionsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "Quick Actions",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _actionChip(Icons.person_add_outlined, "Add Lead", () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LeadFormScreen()));
                  }),
                  _actionChip(Icons.business_outlined, "Add Client", () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientFormScreen()));
                  }),
                  _actionChip(Icons.folder_open_outlined, "Add Project", () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectFormScreen()));
                  }),
                  _actionChip(Icons.check_circle_outline, "Add Task", () {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => const TaskFormDialog());
                  }),
                  _actionChip(Icons.request_quote_outlined, "Create Quotation", () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const QuotationFormScreen()));
                  }),
                  _actionChip(Icons.receipt_outlined, "Create Invoice", () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));
                  }),
                  _actionChip(Icons.payments_outlined, "Record Payment", () {
                    Navigator.pop(ctx);
                    showDialog(context: context, builder: (_) => const AddPaymentDialog());
                  }),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.accent),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      onPressed: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = Provider.of<DashboardProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (dashProvider.isLoading && dashProvider.dashboard == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashProvider.errorMessage != null && dashProvider.dashboard == null) {
      return Scaffold(
        body: ErrorView(
          message: dashProvider.errorMessage!,
          onRetry: () => dashProvider.fetchDashboard(),
        ),
      );
    }

    final data = dashProvider.dashboard;
    final summary = data?.summary;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("NYLEX Dashboard"),
            if (user != null)
              Text(
                "Welcome, ${user.name} (${user.role})",
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => dashProvider.fetchDashboard(),
            tooltip: "Refresh Data",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showQuickActionsSheet,
        tooltip: "Quick Action",
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => dashProvider.fetchDashboard(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Row 1: Summary Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                StatCard(
                  title: "Total Leads",
                  value: "${summary?.totalLeads ?? 0}",
                  icon: Icons.people_outline,
                  iconColor: AppColors.accent,
                ),
                StatCard(
                  title: "Active Clients",
                  value: "${summary?.activeClients ?? 0}",
                  icon: Icons.business,
                  iconColor: AppColors.success,
                ),
                StatCard(
                  title: "Active Projects",
                  value: "${summary?.activeProjects ?? 0}",
                  icon: Icons.folder_special_outlined,
                  iconColor: AppColors.purple,
                ),
                StatCard(
                  title: "Pending Follow-ups",
                  value: "${summary?.pendingFollowUps ?? 0}",
                  icon: Icons.phone_callback_outlined,
                  iconColor: AppColors.warning,
                ),
                StatCard(
                  title: "Total Revenue",
                  value: Formatters.formatCurrency(summary?.totalRevenue ?? 0),
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.success,
                ),
                StatCard(
                  title: "Pending Payments",
                  value: Formatters.formatCurrency(summary?.pendingPayments ?? 0),
                  icon: Icons.pending_actions_outlined,
                  iconColor: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Today's Follow-ups Section
            _sectionHeader("Today's Follow-ups", Icons.schedule),
            const SizedBox(height: 8),
            if (data?.todayFollowUps.isEmpty ?? true)
              _emptyCard("No follow-ups scheduled for today.")
            else
              ...data!.todayFollowUps.map((f) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.warningLight,
                        child: const Icon(Icons.phone, color: AppColors.warning, size: 18),
                      ),
                      title: Text(f['leadName'] ?? f['clientName'] ?? 'Contact', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text("${f['method']} at ${f['scheduledTime']} • ${f['notes'] ?? 'Scheduled'}"),
                      trailing: StatusChip(status: f['status'] ?? 'Pending'),
                    ),
                  )),
            const SizedBox(height: 20),

            // Tasks Due Today Section
            _sectionHeader("Tasks Due Today", Icons.check_circle_outline),
            const SizedBox(height: 8),
            if (data?.tasksDueToday.isEmpty ?? true)
              _emptyCard("No tasks due today.")
            else
              ...data!.tasksDueToday.map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.accentLight.withOpacity(0.2),
                        child: const Icon(Icons.task_alt, color: AppColors.accent, size: 18),
                      ),
                      title: Text(t['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text("Project: ${t['projectName'] ?? 'Nylex'}"),
                      trailing: StatusChip(status: t['status'] ?? 'Todo'),
                    ),
                  )),
            const SizedBox(height: 20),

            // Recent Project Updates Section
            _sectionHeader("Recent Project Updates", Icons.sync),
            const SizedBox(height: 8),
            if (data?.recentProjectUpdates.isEmpty ?? true)
              _emptyCard("No recent project updates.")
            else
              ...data!.recentProjectUpdates.map((u) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(u['projectName'] ?? 'Project', style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text(u['userName'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.accent)),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(u['updateText'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  )),
            const SizedBox(height: 20),

            // Recent Payments Section
            _sectionHeader("Recent Payments", Icons.payments_outlined),
            const SizedBox(height: 8),
            if (data?.recentPayments.isEmpty ?? true)
              _emptyCard("No payments recorded yet.")
            else
              ...data!.recentPayments.map((p) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.successLight,
                        child: Icon(Icons.arrow_downward, color: AppColors.success, size: 18),
                      ),
                      title: Text(Formatters.formatCurrency(p['amount']), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text("${p['businessName']} • ${p['paymentMethod']}"),
                      trailing: Text(Formatters.formatDate(p['paymentDate']), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  )),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      ),
    );
  }
}
