import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/client_model.dart';
import '../../../providers/clients_provider.dart';
import '../../widgets/status_chip.dart';
import 'client_form_screen.dart';

class ClientDetailScreen extends StatefulWidget {
  final ClientModel client;

  const ClientDetailScreen({Key? key, required this.client}) : super(key: key);

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _timeline = [];
  bool _isLoadingTimeline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTimeline();
  }

  void _loadTimeline() async {
    setState(() => _isLoadingTimeline = true);
    final provider = Provider.of<ClientsProvider>(context, listen: false);
    final events = await provider.fetchClientTimeline(widget.client.id);
    if (mounted) {
      setState(() {
        _timeline = events;
        _isLoadingTimeline = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmArchive() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Archive Client"),
        content: Text("Are you sure you want to archive '${widget.client.businessName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ClientsProvider>(context, listen: false).archiveClient(widget.client.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Archive"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;

    return Scaffold(
      appBar: AppBar(
        title: Text(client.businessName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: AppColors.danger),
            onPressed: _confirmArchive,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Activity Timeline"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Overview Tab
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
                              client.businessName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          StatusChip(status: client.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow(Icons.person, "Contact Person", client.clientName),
                      _infoRow(Icons.phone, "Phone", client.phone),
                      if (client.whatsapp != null) _infoRow(Icons.chat, "WhatsApp", client.whatsapp!),
                      if (client.email != null) _infoRow(Icons.email, "Email", client.email!),
                      if (client.location != null) _infoRow(Icons.location_on, "Location", client.location!),
                      if (client.website != null) _infoRow(Icons.language, "Website", client.website!),
                      if (client.instagram != null) _infoRow(Icons.camera_alt, "Instagram", client.instagram!),
                      _infoRow(Icons.source, "Lead Source", client.leadSource ?? "Direct"),
                      if (client.assignedToName != null)
                        _infoRow(Icons.assignment_ind, "Assigned To", client.assignedToName!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Domain Information Section
              if (client.domainInfo != null) ...[
                const Text("Domain Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _infoRow(Icons.domain, "Domain", "${client.domainInfo!.domainName ?? 'N/A'}${client.domainInfo!.domainExtension ?? ''}"),
                        _infoRow(Icons.dns, "Registrar", client.domainInfo!.registrar ?? "N/A"),
                        _infoRow(Icons.alternate_email, "Purchase Email", client.domainInfo!.purchaseEmail ?? "N/A"),
                        _infoRow(Icons.calendar_today, "Purchase Date", client.domainInfo!.purchaseDate ?? "N/A"),
                        _infoRow(Icons.event_repeat, "Expiry Date", client.domainInfo!.expiryDate ?? "N/A"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes Section
              if (client.notes != null && client.notes!.isNotEmpty) ...[
                const Text("Client Notes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(client.notes!, style: const TextStyle(height: 1.4)),
                  ),
                ),
              ],
            ],
          ),

          // Timeline Tab (Section 12: Combined Client Timeline)
          _isLoadingTimeline
              ? const Center(child: CircularProgressIndicator())
              : _timeline.isEmpty
                  ? const Center(child: Text("No activities recorded on client timeline yet."))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _timeline.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final event = _timeline[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.background,
                              child: const Icon(Icons.history, color: AppColors.accent, size: 20),
                            ),
                            title: Text(event['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(event['description'] ?? ''),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.formatDateTime(event['date']),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
