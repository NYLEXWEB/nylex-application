import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/client_model.dart';
import '../../../providers/clients_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'client_detail_screen.dart';
import 'client_form_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientsProvider>(context, listen: false).fetchClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _confirmDeleteClient(BuildContext context, ClientModel client) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Client"),
        content: Text("Are you sure you want to delete client '${client.businessName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ClientsProvider>(context, listen: false).deleteClient(client.id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context);
    final allClients = clientsProvider.clients;

    // Filter by search query
    final filteredClients = allClients.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.businessName.toLowerCase().contains(q) ||
          c.clientName.toLowerCase().contains(q) ||
          c.phone.contains(q);
    }).toList();

    final activeClients = filteredClients.where((c) => c.status != "Completed").toList();
    final completedClients = filteredClients.where((c) => c.status == "Completed").toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Clients"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Client",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientFormScreen()),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "Active (${activeClients.length})"),
            Tab(text: "Completed (${completedClients.length})"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by business, contact or phone...",
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),

          // Content TabBarView
          Expanded(
            child: Builder(
              builder: (context) {
                if (clientsProvider.isLoading && allClients.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (clientsProvider.errorMessage != null && allClients.isEmpty) {
                  return ErrorView(
                    message: clientsProvider.errorMessage!,
                    onRetry: () => clientsProvider.fetchClients(),
                  );
                }

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildClientList(context, activeClients, isCompletedSection: false),
                    _buildClientList(context, completedClients, isCompletedSection: true),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientList(BuildContext context, List<ClientModel> list, {required bool isCompletedSection}) {
    if (list.isEmpty) {
      return EmptyView(
        title: isCompletedSection ? "No Completed Clients" : "No Active Clients",
        subtitle: isCompletedSection
            ? "Completed projects will appear here with domain & hosting details."
            : "Convert leads or add new clients to begin projects.",
        icon: isCompletedSection ? Icons.task_alt : Icons.business_outlined,
        buttonText: isCompletedSection ? null : "Add Client",
        onAction: isCompletedSection
            ? null
            : () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Provider.of<ClientsProvider>(context, listen: false).fetchClients(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final client = list[index];
          return Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientDetailScreen(client: client)),
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
                            client.businessName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        StatusChip(status: client.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Contact: ${client.clientName} • ${client.phone}",
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    if (client.domainInfo?.domainName != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.language, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            "Domain: ${client.domainInfo!.domainName}",
                            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (client.assignedToName != null)
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                "Assigned: ${client.assignedToName}",
                                style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                              ),
                            ],
                          )
                        else
                          const SizedBox.shrink(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                          tooltip: "Delete Client",
                          onPressed: () => _confirmDeleteClient(context, client),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
