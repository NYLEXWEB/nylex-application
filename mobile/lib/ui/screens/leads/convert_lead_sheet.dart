import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/lead_model.dart';
import '../../../providers/leads_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/projects_provider.dart';

class ConvertLeadSheet extends StatefulWidget {
  final LeadModel lead;

  const ConvertLeadSheet({Key? key, required this.lead}) : super(key: key);

  @override
  State<ConvertLeadSheet> createState() => _ConvertLeadSheetState();
}

class _ConvertLeadSheetState extends State<ConvertLeadSheet> {
  bool _createProject = true;
  late TextEditingController _projectNameController;
  late TextEditingController _projectTypeController;
  late TextEditingController _quotedAmountController;
  late TextEditingController _deadLineController;
  bool _isConverting = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    final defaultName = "${l.businessName ?? l.name} - ${l.serviceRequired ?? 'Web Development'}";
    _projectNameController = TextEditingController(text: defaultName);
    _projectTypeController = TextEditingController(text: l.serviceRequired ?? "Website");
    _quotedAmountController = TextEditingController(text: l.expectedBudget > 0 ? l.expectedBudget.toString() : "25000");
    _deadLineController = TextEditingController();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectTypeController.dispose();
    _quotedAmountController.dispose();
    _deadLineController.dispose();
    super.dispose();
  }

  void _convert() async {
    setState(() => _isConverting = true);
    final payload = {
      "createProject": _createProject,
      "projectName": _projectNameController.text.trim(),
      "projectType": _projectTypeController.text.trim(),
      "quotedAmount": double.tryParse(_quotedAmountController.text.trim()) ?? 0.0,
      "deadline": _deadLineController.text.trim().isEmpty ? null : _deadLineController.text.trim(),
    };

    try {
      final leadsProvider = Provider.of<LeadsProvider>(context, listen: false);
      await leadsProvider.convertLeadToClient(widget.lead.id, payload);

      // Refresh clients and projects in the background
      Provider.of<ClientsProvider>(context, listen: false).fetchClients();
      Provider.of<ProjectsProvider>(context, listen: false).fetchProjects();

      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context); // Return to lead list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lead successfully converted to Client & Project!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isConverting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.verified, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Convert Lead to Client", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      Text("Seamlessly transfer contact details into active client", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.background,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Client Name: ${widget.lead.businessName ?? widget.lead.name}", style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text("Phone: ${widget.lead.phone} • Email: ${widget.lead.email ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Automatically create client project", style: TextStyle(fontWeight: FontWeight.w600)),
              value: _createProject,
              onChanged: (val) => setState(() => _createProject = val ?? true),
            ),
            if (_createProject) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _projectNameController,
                decoration: const InputDecoration(labelText: "Project Name"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _projectTypeController,
                decoration: const InputDecoration(labelText: "Project Type (e.g. Website, SEO)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quotedAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quoted Contract Value (₹)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deadLineController,
                decoration: const InputDecoration(labelText: "Target Deadline (YYYY-MM-DD)"),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isConverting ? null : _convert,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isConverting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Center(child: Text("Confirm & Convert Now", style: TextStyle(fontSize: 16))),
            ),
          ],
        ),
      ),
    );
  }
}
