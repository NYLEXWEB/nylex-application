import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/project_model.dart';
import '../../../models/client_model.dart';
import '../../../providers/projects_provider.dart';
import '../../../providers/clients_provider.dart';

class ProjectFormScreen extends StatefulWidget {
  final ProjectModel? project;

  const ProjectFormScreen({Key? key, this.project}) : super(key: key);

  @override
  State<ProjectFormScreen> createState() => _ProjectFormScreenState();
}

class _ProjectFormScreenState extends State<ProjectFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quotedAmountController;
  late TextEditingController _finalAmountController;
  late TextEditingController _startDateController;
  late TextEditingController _deadlineController;

  // Domain fields
  late TextEditingController _domainNameController;
  late TextEditingController _registrarController;
  late TextEditingController _domainEmailController;
  late TextEditingController _domainExpiryController;

  String? _selectedClientId;
  String _projectType = "Website";
  String _status = "Planning";
  String _priority = "Medium";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameController = TextEditingController(text: p?.projectName ?? "");
    _descriptionController = TextEditingController(text: p?.description ?? "");
    _quotedAmountController = TextEditingController(text: p != null ? p.quotedAmount.toString() : "");
    _finalAmountController = TextEditingController(text: p != null ? p.finalAmount.toString() : "");
    _startDateController = TextEditingController(text: p?.startDate ?? "");
    _deadlineController = TextEditingController(text: p?.deadline ?? "");

    _domainNameController = TextEditingController(text: p?.domainInfo?.domainName ?? "");
    _registrarController = TextEditingController(text: p?.domainInfo?.registrar ?? "");
    _domainEmailController = TextEditingController(text: p?.domainInfo?.purchaseEmail ?? "");
    _domainExpiryController = TextEditingController(text: p?.domainInfo?.expiryDate ?? "");

    if (p != null) {
      _selectedClientId = p.clientId;
      _projectType = p.projectType;
      _status = p.status;
      _priority = p.priority;
    } else {
      // Preselect first client if available
      final clients = Provider.of<ClientsProvider>(context, listen: false).clients;
      if (clients.isNotEmpty) _selectedClientId = clients.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quotedAmountController.dispose();
    _finalAmountController.dispose();
    _startDateController.dispose();
    _deadlineController.dispose();
    _domainNameController.dispose();
    _registrarController.dispose();
    _domainEmailController.dispose();
    _domainExpiryController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a client")));
      return;
    }

    setState(() => _isSaving = true);
    final quotedAmt = double.tryParse(_quotedAmountController.text.trim()) ?? 0.0;
    final finalAmt = double.tryParse(_finalAmountController.text.trim()) ?? quotedAmt;

    final payload = {
      "projectName": _nameController.text.trim(),
      "clientId": _selectedClientId,
      "projectType": _projectType,
      "description": _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      "quotedAmount": quotedAmt,
      "finalAmount": finalAmt,
      "startDate": _startDateController.text.trim().isEmpty ? null : _startDateController.text.trim(),
      "deadline": _deadlineController.text.trim().isEmpty ? null : _deadlineController.text.trim(),
      "status": _status,
      "priority": _priority,
      "domainInfo": _domainNameController.text.trim().isEmpty
          ? null
          : {
              "domainName": _domainNameController.text.trim(),
              "registrar": _registrarController.text.trim(),
              "purchaseEmail": _domainEmailController.text.trim(),
              "expiryDate": _domainExpiryController.text.trim(),
            }
    };

    final provider = Provider.of<ProjectsProvider>(context, listen: false);
    try {
      if (widget.project != null) {
        await provider.updateProject(widget.project!.id, payload);
      } else {
        await provider.createProject(payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = Provider.of<ClientsProvider>(context).clients;
    final isEdit = widget.project != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Project" : "Create Project"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Project Name *"),
              validator: (v) => Validators.required(v, "Project name is required"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedClientId,
              decoration: const InputDecoration(labelText: "Client *"),
              items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.businessName))).toList(),
              onChanged: isEdit ? null : (val) => setState(() => _selectedClientId = val),
              validator: (v) => v == null ? "Client is required" : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _projectType,
              decoration: const InputDecoration(labelText: "Project Type"),
              items: ["Website", "Web App", "E-Commerce", "SEO", "Maintenance", "Branding", "Other"]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _projectType = val!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quotedAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quoted Amount (₹)"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _finalAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Final Amount (₹)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(labelText: "Start Date (YYYY-MM-DD)"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _deadlineController,
                    decoration: const InputDecoration(labelText: "Deadline (YYYY-MM-DD)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: "Status"),
                    items: ["Planning", "In Progress", "Review", "Completed", "Delivered", "On Hold", "Cancelled"]
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => _status = val!),
                  ),
                ),
                const SizedBox(width: 8),
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
              ],
            ),
            const SizedBox(height: 16),

            // Domain Information (Section 32)
            const Text("Domain & Registrar Info (Optional)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _domainNameController,
              decoration: const InputDecoration(labelText: "Domain Name (e.g. clientdomain.com)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registrarController,
              decoration: const InputDecoration(labelText: "Domain Registrar"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _domainEmailController,
                    decoration: const InputDecoration(labelText: "Purchase Email"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _domainExpiryController,
                    decoration: const InputDecoration(labelText: "Expiry Date (YYYY-MM-DD)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Project Scope & Description"),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? "Update Project" : "Create Project"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
