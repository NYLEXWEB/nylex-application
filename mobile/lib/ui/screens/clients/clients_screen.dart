import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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

class _ClientsScreenState extends State<ClientsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ClientsProvider>(context, listen: false).fetchClients();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsProvider = Provider.of<ClientsProvider>(context);

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
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search by business, name or phone...",
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              clientsProvider.fetchClients(search: "");
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onSubmitted: (val) => clientsProvider.fetchClients(search: val),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["All", "Active", "Completed", "Inactive"].map((status) {
                      final isSelected = clientsProvider.selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (_) => clientsProvider.fetchClients(status: status),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content Body
          Expanded(
            child: Builder(
              builder: (context) {
                if (clientsProvider.isLoading && clientsProvider.clients.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (clientsProvider.errorMessage != null && clientsProvider.clients.isEmpty) {
                  return ErrorView(
                    message: clientsProvider.errorMessage!,
                    onRetry: () => clientsProvider.fetchClients(),
                  );
                }

                if (clientsProvider.clients.isEmpty) {
                  return EmptyView(
                    title: "No Clients Found",
                    subtitle: "Add your first client to start managing projects and invoices.",
                    icon: Icons.business_outlined,
                    buttonText: "Add Client",
                    onAction: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => clientsProvider.fetchClients(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: clientsProvider.clients.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final client = clientsProvider.clients[index];
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
                                if (client.assignedToName != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 14, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Assigned: ${client.assignedToName}",
                                        style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
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
