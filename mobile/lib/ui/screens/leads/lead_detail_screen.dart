import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/lead_model.dart';
import '../../../providers/leads_provider.dart';
import '../../widgets/status_chip.dart';
import 'lead_form_screen.dart';
import 'convert_lead_sheet.dart';
import '../followups/followup_form_dialog.dart';

class LeadDetailScreen extends StatelessWidget {
  final LeadModel lead;

  const LeadDetailScreen({Key? key, required this.lead}) : super(key: key);

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Change Lead Status"),
        children: [
          "New",
          "Contacted",
          "Follow-up",
          "Proposal",
          "Negotiation",
          "Won",
          "Lost"
        ].map((s) => SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(ctx);
                await Provider.of<LeadsProvider>(context, listen: false).changeLeadStatus(lead.id, s);
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            )).toList(),
      ),
    );
  }

  void _confirmArchive(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Archive Lead"),
        content: Text("Are you sure you want to archive lead '${lead.name}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<LeadsProvider>(context, listen: false).archiveLead(lead.id);
              Navigator.pop(context);
            },
            child: const Text("Archive"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(lead.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LeadFormScreen(lead: lead)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: AppColors.danger),
            onPressed: () => _confirmArchive(context),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => FollowupFormDialog(leadId: lead.id, leadName: lead.name),
                  ),
                  icon: const Icon(Icons.add_alarm, size: 18),
                  label: const Text("Follow-up"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => ConvertLeadSheet(lead: lead),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  icon: const Icon(Icons.verified, size: 18),
                  label: const Text("Convert to Client"),
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
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
                          lead.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showStatusDialog(context),
                        borderRadius: BorderRadius.circular(6),
                        child: Row(
                          children: [
                            StatusChip(status: lead.status),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (lead.businessName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lead.businessName!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const Divider(height: 24),
                  _infoRow(Icons.phone, "Phone", lead.phone),
                  if (lead.whatsapp != null) _infoRow(Icons.chat, "WhatsApp", lead.whatsapp!),
                  if (lead.email != null) _infoRow(Icons.email, "Email", lead.email!),
                  if (lead.location != null) _infoRow(Icons.location_on, "Location", lead.location!),
                  if (lead.serviceRequired != null) _infoRow(Icons.design_services, "Service", lead.serviceRequired!),
                  _infoRow(Icons.currency_rupee, "Expected Budget", Formatters.formatCurrency(lead.expectedBudget)),
                  _infoRow(Icons.source, "Lead Source", lead.leadSource),
                  _infoRow(Icons.flag, "Priority", lead.priority),
                  if (lead.assignedToName != null) _infoRow(Icons.person, "Assigned To", lead.assignedToName!),
                  if (lead.nextFollowUp != null) _infoRow(Icons.schedule, "Next Follow-up", lead.nextFollowUp!),
                  _infoRow(Icons.calendar_today, "Created Date", Formatters.formatDate(lead.createdAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes Card
          if (lead.notes != null && lead.notes!.isNotEmpty) ...[
            const Text("Lead Activity & Notes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(lead.notes!, style: const TextStyle(height: 1.4)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
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
