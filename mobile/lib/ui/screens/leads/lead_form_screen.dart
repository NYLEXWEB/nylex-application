import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/lead_model.dart';
import '../../../providers/leads_provider.dart';

class LeadFormScreen extends StatefulWidget {
  final LeadModel? lead;

  const LeadFormScreen({Key? key, this.lead}) : super(key: key);

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _serviceController;
  late TextEditingController _budgetController;
  late TextEditingController _notesController;

  String _leadSource = "Instagram";
  String _priority = "Medium";
  String _status = "New";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.lead;
    _nameController = TextEditingController(text: l?.name ?? "");
    _businessNameController = TextEditingController(text: l?.businessName ?? "");
    _phoneController = TextEditingController(text: l?.phone ?? "");
    _whatsappController = TextEditingController(text: l?.whatsapp ?? "");
    _emailController = TextEditingController(text: l?.email ?? "");
    _locationController = TextEditingController(text: l?.location ?? "");
    _serviceController = TextEditingController(text: l?.serviceRequired ?? "");
    _budgetController = TextEditingController(text: l != null && l.expectedBudget > 0 ? l.expectedBudget.toString() : "");
    _notesController = TextEditingController(text: l?.notes ?? "");

    if (l != null) {
      _leadSource = l.leadSource;
      _priority = l.priority;
      _status = l.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _serviceController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      "name": _nameController.text.trim(),
      "businessName": _businessNameController.text.trim().isEmpty ? null : _businessNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "whatsapp": _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      "email": _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      "location": _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      "serviceRequired": _serviceController.text.trim().isEmpty ? null : _serviceController.text.trim(),
      "expectedBudget": double.tryParse(_budgetController.text.trim()) ?? 0.0,
      "leadSource": _leadSource,
      "priority": _priority,
      "status": _status,
      "notes": _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    final provider = Provider.of<LeadsProvider>(context, listen: false);
    try {
      if (widget.lead != null) {
        await provider.updateLead(widget.lead!.id, payload);
      } else {
        await provider.createLead(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.lead != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Lead" : "Add Lead"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Lead / Contact Name *"),
              validator: (v) => Validators.required(v, "Lead name is required"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: "Business Name (Optional)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Phone Number *"),
              validator: (v) => Validators.phone(v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _whatsappController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "WhatsApp Number"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email Address"),
              validator: (v) => Validators.email(v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: "Location (City, State)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _serviceController,
              decoration: const InputDecoration(labelText: "Service Required (e.g. Website, SEO, Redesign)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Expected Budget (₹)"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _leadSource,
              decoration: const InputDecoration(labelText: "Lead Source"),
              items: ["Instagram", "WhatsApp", "Facebook", "Website", "Referral", "Direct", "Existing Client", "Other"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _leadSource = val!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _priority,
                    decoration: const InputDecoration(labelText: "Priority"),
                    items: ["Low", "Medium", "High", "Urgent"]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (val) => setState(() => _priority = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: "Status"),
                    items: ["New", "Contacted", "Follow-up", "Proposal", "Negotiation", "Won", "Lost"]
                        .map((st) => DropdownMenuItem(value: st, child: Text(st)))
                        .toList(),
                    onChanged: (val) => setState(() => _status = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Notes / Context"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? "Update Lead" : "Save Lead"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
