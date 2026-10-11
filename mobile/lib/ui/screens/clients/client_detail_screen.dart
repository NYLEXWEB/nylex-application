import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late ClientModel _client;
  List<dynamic> _timeline = [];
  bool _isLoadingTimeline = false;
  bool _hideDomainPassword = true;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _tabController = TabController(length: 2, vsync: this);
    _loadTimeline();
  }

  void _loadTimeline() async {
    setState(() => _isLoadingTimeline = true);
    final provider = Provider.of<ClientsProvider>(context, listen: false);
    final events = await provider.fetchClientTimeline(_client.id);
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

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Client"),
        content: Text("Are you sure you want to permanently delete '${_client.businessName}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<ClientsProvider>(context, listen: false).deleteClient(_client.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Client '${_client.businessName}' deleted")),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    if (_client.status.toLowerCase() == newStatus.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Client status is already $newStatus")),
      );
      return;
    }

    if (newStatus == "Completed") {
      _showCompletedDomainDialog();
      return;
    }

    try {
      final updated = await Provider.of<ClientsProvider>(context, listen: false)
          .updateClientStatus(_client.id, newStatus);
      if (updated != null && mounted) {
        setState(() => _client = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Status changed to $newStatus")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e"), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showCompletedDomainDialog() {
    final domainCtrl = TextEditingController(text: _client.domainInfo?.domainName ?? "");
    final registrarCtrl = TextEditingController(text: _client.domainInfo?.registrar ?? "");
    final emailCtrl = TextEditingController(text: _client.domainInfo?.purchaseEmail ?? "");
    final passwordCtrl = TextEditingController(text: _client.domainInfo?.purchaseEmailPassword ?? "");
    final dateCtrl = TextEditingController(
      text: _client.domainInfo?.purchaseDate ?? Formatters.formatDate(DateTime.now().toIso8601String()),
    );
    bool obscureDialogPassword = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt, color: AppColors.accent, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Mark Completed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Enter Domain & Account Details", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: domainCtrl,
                    decoration: const InputDecoration(
                      labelText: "Domain Name *",
                      hintText: "example.com",
                      prefixIcon: Icon(Icons.language, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: registrarCtrl,
                    decoration: const InputDecoration(
                      labelText: "Registrar *",
                      hintText: "GoDaddy, Hostinger, Namecheap...",
                      prefixIcon: Icon(Icons.dns, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: "Purchase Email",
                      hintText: "admin@example.com",
                      prefixIcon: Icon(Icons.alternate_email, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscureDialogPassword,
                    decoration: InputDecoration(
                      labelText: "Purchase Email Password",
                      hintText: "••••••••",
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureDialogPassword ? Icons.visibility_off : Icons.visibility,
                          size: 20,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureDialogPassword = !obscureDialogPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          dateCtrl.text = Formatters.formatDate(picked.toIso8601String());
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: "Purchase Date",
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: () async {
                final domainName = domainCtrl.text.trim();
                final registrar = registrarCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final password = passwordCtrl.text.trim();
                final date = dateCtrl.text.trim();

                final domainData = {
                  'domainName': domainName.isNotEmpty ? domainName : null,
                  'registrar': registrar.isNotEmpty ? registrar : null,
                  'purchaseEmail': email.isNotEmpty ? email : null,
                  'purchaseEmailPassword': password.isNotEmpty ? password : null,
                  'purchaseDate': date.isNotEmpty ? date : null,
                };

                final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);

                try {
                  final updated = await clientsProvider
                      .updateClientStatus(_client.id, 'Completed', domainInfo: domainData);
                  if (updated != null && mounted) {
                    setState(() => _client = updated);
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text("Client marked as Completed with Domain details")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text("Error updating client: $e"), backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              child: const Text("Save & Complete"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_client.businessName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final clientsProvider = Provider.of<ClientsProvider>(context, listen: false);
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ClientFormScreen(client: _client)),
              );
              if (res == true && mounted) {
                try {
                  final updated = clientsProvider.clients.firstWhere((c) => c.id == _client.id);
                  setState(() => _client = updated);
                } catch (_) {}
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: _confirmDelete,
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
              // Client Header Card
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
                              _client.businessName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                          ),
                          StatusChip(status: _client.status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow(Icons.person, "Contact Person", _client.clientName),
                      _infoRow(Icons.phone, "Phone", _client.phone),
                      if (_client.whatsapp != null && _client.whatsapp!.isNotEmpty)
                        _infoRow(Icons.chat, "WhatsApp", _client.whatsapp!),
                      if (_client.email != null && _client.email!.isNotEmpty)
                        _infoRow(Icons.email, "Email", _client.email!),
                      if (_client.location != null && _client.location!.isNotEmpty)
                        _infoRow(Icons.location_on, "Location", _client.location!),
                      if (_client.website != null && _client.website!.isNotEmpty)
                        _infoRow(Icons.language, "Website", _client.website!),
                      if (_client.instagram != null && _client.instagram!.isNotEmpty)
                        _infoRow(Icons.camera_alt, "Instagram", _client.instagram!),
                      _infoRow(Icons.source, "Lead Source", _client.leadSource ?? "Direct"),
                      if (_client.assignedToName != null)
                        _infoRow(Icons.assignment_ind, "Assigned To", _client.assignedToName!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Status Buttons Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Quick Status Change",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _statusButton(
                              label: "Active",
                              statusValue: "Active",
                              icon: Icons.play_arrow_rounded,
                              activeColor: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statusButton(
                              label: "Completed",
                              statusValue: "Completed",
                              icon: Icons.task_alt,
                              activeColor: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _statusButton(
                              label: "Inactive",
                              statusValue: "Inactive",
                              icon: Icons.pause_circle_outline,
                              activeColor: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Domain Information Section
              if (_client.domainInfo != null &&
                  (_client.domainInfo!.domainName != null || _client.domainInfo!.registrar != null)) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Domain & Account Details", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.accent),
                      tooltip: "Edit Domain Details",
                      onPressed: _showCompletedDomainDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_client.domainInfo!.domainName != null)
                          _infoRow(Icons.domain, "Domain", "${_client.domainInfo!.domainName}${_client.domainInfo!.domainExtension ?? ''}"),
                        if (_client.domainInfo!.registrar != null)
                          _infoRow(Icons.dns, "Registrar", _client.domainInfo!.registrar!),
                        if (_client.domainInfo!.purchaseEmail != null)
                          _infoRow(Icons.alternate_email, "Purchase Email", _client.domainInfo!.purchaseEmail!),
                        if (_client.domainInfo!.purchaseEmailPassword != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                const SizedBox(
                                  width: 110,
                                  child: Text("Email Password", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                ),
                                Expanded(
                                  child: Text(
                                    _hideDomainPassword ? "••••••••••••" : _client.domainInfo!.purchaseEmailPassword!,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _hideDomainPassword ? Icons.visibility_off : Icons.visibility,
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() => _hideDomainPassword = !_hideDomainPassword);
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18, color: AppColors.accent),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: "Copy password",
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _client.domainInfo!.purchaseEmailPassword!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Password copied to clipboard")),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_client.domainInfo!.purchaseDate != null)
                          _infoRow(Icons.calendar_today, "Purchase Date", _client.domainInfo!.purchaseDate!),
                        if (_client.domainInfo!.expiryDate != null)
                          _infoRow(Icons.event_repeat, "Expiry Date", _client.domainInfo!.expiryDate!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Notes Section
              if (_client.notes != null && _client.notes!.isNotEmpty) ...[
                const Text("Client Notes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_client.notes!, style: const TextStyle(height: 1.4)),
                  ),
                ),
              ],
            ],
          ),

          // Timeline Tab
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

  Widget _statusButton({
    required String label,
    required String statusValue,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _client.status.toLowerCase() == statusValue.toLowerCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _updateStatus(statusValue),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.18) : AppColors.background,
            border: Border.all(
              color: isSelected ? activeColor : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: isSelected ? activeColor : AppColors.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
