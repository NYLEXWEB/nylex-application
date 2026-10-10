import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/notifications_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../leads/leads_screen.dart';
import '../clients/clients_screen.dart';
import '../projects/projects_screen.dart';
import '../tasks/tasks_screen.dart';
import '../followups/followups_screen.dart';
import '../quotations/quotations_screen.dart';
import '../invoices/invoices_screen.dart';
import '../payments/payments_screen.dart';
import '../revenue/revenue_screen.dart';
import '../chat/chat_screen.dart';
import '../notifications/notifications_screen.dart';
import '../search/global_search_screen.dart';
import '../audit/audit_screen.dart';
import '../../widgets/server_settings_dialog.dart';
import '../../../core/constants/api_constants.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({Key? key}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _primaryScreens = [
    const DashboardScreen(),
    const LeadsScreen(),
    const ClientsScreen(),
    const MoreMenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<ChatProvider>(context, listen: false).initWebSocket(user.id);
        Provider.of<NotificationsProvider>(context, listen: false).fetchNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = Provider.of<NotificationsProvider>(context).unreadCount;
    final unreadChat = Provider.of<ChatProvider>(context).unreadCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _primaryScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppColors.accent.withOpacity(0.15),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
            label: "Home",
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.accent),
            label: "Leads",
          ),
          const NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business, color: AppColors.accent),
            label: "Clients",
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadNotifs > 0 || unreadChat > 0,
              label: Text("${unreadNotifs + unreadChat}"),
              child: const Icon(Icons.grid_view_outlined),
            ),
            selectedIcon: const Icon(Icons.grid_view, color: AppColors.accent),
            label: "More",
          ),
        ],
      ),
    );
  }
}

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final unreadNotifs = Provider.of<NotificationsProvider>(context).unreadCount;
    final unreadChat = Provider.of<ChatProvider>(context).unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("NYLEX Workspace"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Card
          Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? "U",
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? "User",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          "${user?.email ?? ''} • ${user?.role ?? 'PARTNER'}",
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Menu Grid
          const Text("Operations & Delivery", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _menuTile(context, Icons.folder_special_outlined, "Projects", "Client website contracts & milestones", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectsScreen()));
          }),
          _menuTile(context, Icons.check_circle_outline, "Tasks", "Milestones & assigned action items", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TasksScreen()));
          }),
          _menuTile(context, Icons.phone_callback_outlined, "Follow-ups", "Prospect meetings and reminders", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowupsScreen()));
          }),
          const SizedBox(height: 16),

          const Text("Finance & Billing", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _menuTile(context, Icons.request_quote_outlined, "Quotations", "Price proposals & estimates", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const QuotationsScreen()));
          }),
          _menuTile(context, Icons.receipt_long_outlined, "Invoices", "Official client bills & PDF generation", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoicesScreen()));
          }),
          _menuTile(context, Icons.payments_outlined, "Payments", "Advance, partial and balance payments", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsScreen()));
          }),
          _menuTile(context, Icons.account_balance_wallet_outlined, "Revenue Metrics", "Real cash collection & monthly analysis", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen()));
          }),
          const SizedBox(height: 16),

          const Text("Communication & Tools", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _menuTile(
            context,
            Icons.chat_bubble_outline,
            "Internal Partner Chat",
            "Real-time text chat between owners",
            () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
            },
            badgeCount: unreadChat,
          ),
          _menuTile(
            context,
            Icons.notifications_none_outlined,
            "Notifications",
            "Reminders, deadlines, payments",
            () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
            },
            badgeCount: unreadNotifs,
          ),
          _menuTile(context, Icons.search, "Global Search", "Search clients, leads, projects & invoices", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSearchScreen()));
          }),
          _menuTile(context, Icons.history, "Audit Trail", "Immutable system activity history", () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditScreen()));
          }),
          _menuTile(context, Icons.dns_outlined, "Server & API Settings", "Configure backend URL (${ApiConstants.baseUrl})", () {
            showServerSettingsDialog(context);
          }),
          const SizedBox(height: 20),

          // Server settings quick action
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () => showServerSettingsDialog(context),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: const Text("Configure Backend Server URL"),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _menuTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (badgeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  "$badgeCount",
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      ),
    );
  }
}
