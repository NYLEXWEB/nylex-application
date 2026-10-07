import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/client_model.dart';
import '../../../providers/clients_provider.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientModel? client;

  const ClientFormScreen({Key? key, this.client}) : super(key: key);

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _clientNameController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _notesController;

  // Domain fields
  late TextEditingController _domainNameController;
  late TextEditingController _registrarController;
  late TextEditingController _domainEmailController;
  late TextEditingController _domainPurchaseDateController;
  late TextEditingController _domainExpiryDateController;

  String _status = "Active";
  String _leadSource = "Direct";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _businessNameController = TextEditingController(text: c?.businessName ?? "");
    _clientNameController = TextEditingController(text: c?.clientName ?? "");
    _phoneController = TextEditingController(text: c?.phone ?? "");
    _whatsappController = TextEditingController(text: c?.whatsapp ?? "");
    _emailController = TextEditingController(text: c?.email ?? "");
    _locationController = TextEditingController(text: c?.location ?? "");
    _websiteController = TextEditingController(text: c?.website ?? "");
    _instagramController = TextEditingController(text: c?.instagram ?? "");
    _notesController = TextEditingController(text: c?.notes ?? "");

    _domainNameController = TextEditingController(text: c?.domainInfo?.domainName ?? "");
    _registrarController = TextEditingController(text: c?.domainInfo?.registrar ?? "");
    _domainEmailController = TextEditingController(text: c?.domainInfo?.purchaseEmail ?? "");
    _domainPurchaseDateController = TextEditingController(text: c?.domainInfo?.purchaseDate ?? "");
    _domainExpiryDateController = TextEditingController(text: c?.domainInfo?.expiryDate ?? "");

    if (c != null) {
      _status = c.status;
      _leadSource = c.leadSource ?? "Direct";
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _clientNameController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _notesController.dispose();
    _domainNameController.dispose();
    _registrarController.dispose();
    _domainEmailController.dispose();
    _domainPurchaseDateController.dispose();
    _domainExpiryDateController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final payload = {
      "businessName": _businessNameController.text.trim(),
      "clientName": _clientNameController.text.trim(),
      "phone": _phoneController.text.trim(),
      "whatsapp": _whatsappController.text.trim().isEmpty ? null : _whatsappController.text.trim(),
      "email": _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      "location": _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      "website": _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      "instagram": _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
      "leadSource": _leadSource,
      "status": _status,
      "notes": _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      "domainInfo": _domainNameController.text.trim().isEmpty
          ? null
          : {
              "domainName": _domainNameController.text.trim(),
              "registrar": _registrarController.text.trim(),
              "purchaseEmail": _domainEmailController.text.trim(),
              "purchaseDate": _domainPurchaseDateController.text.trim(),
              "expiryDate": _domainExpiryDateController.text.trim(),
            }
    };

    final provider = Provider.of<ClientsProvider>(context, listen: false);
    try {
      if (widget.client != null) {
        await provider.updateClient(widget.client!.id, payload);
      } else {
        await provider.createClient(payload);
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
    final isEdit = widget.client != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Client" : "Add Client"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Business Details
            const Text("Basic Information", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: "Business Name *"),
              validator: (v) => Validators.required(v, "Business name is required"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _clientNameController,
              decoration: const InputDecoration(labelText: "Contact Person Name *"),
              validator: (v) => Validators.required(v, "Contact name is required"),
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
              decoration: const InputDecoration(labelText: "Location / Address"),
            ),
            const SizedBox(height: 16),

            // Online Presence
            const Text("Online Presence", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: "Website URL"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(labelText: "Instagram Profile / Handle"),
            ),
            const SizedBox(height: 16),

            // Status & Lead Source
            const Text("Classification", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: "Client Status"),
              items: ["Active", "Completed", "Inactive"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _leadSource,
              decoration: const InputDecoration(labelText: "Lead Source"),
              items: ["Direct", "Instagram", "WhatsApp", "Facebook", "Website", "Referral", "Existing Client", "Other"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _leadSource = val!),
            ),
            const SizedBox(height: 16),

            // Domain Information (Section 32)
            const Text("Domain Information (Optional)", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _domainNameController,
              decoration: const InputDecoration(labelText: "Domain Name (e.g. example.com)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _registrarController,
              decoration: const InputDecoration(labelText: "Registrar (e.g. Hostinger, GoDaddy)"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _domainEmailController,
              decoration: const InputDecoration(labelText: "Purchase / Account Email"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _domainPurchaseDateController,
                    decoration: const InputDecoration(labelText: "Purchase Date (YYYY-MM-DD)"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _domainExpiryDateController,
                    decoration: const InputDecoration(labelText: "Expiry Date (YYYY-MM-DD)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Internal Notes"),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? "Update Client" : "Save Client"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
