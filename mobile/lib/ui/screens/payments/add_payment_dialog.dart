import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/projects_provider.dart';

class AddPaymentDialog extends StatefulWidget {
  final String? invoiceId;
  final String? clientId;
  final String? projectId;
  final double? suggestedAmount;

  const AddPaymentDialog({
    Key? key,
    this.invoiceId,
    this.clientId,
    this.projectId,
    this.suggestedAmount,
  }) : super(key: key);

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClientId;
  String? _selectedProjectId;
  String? _selectedInvoiceId;
  late TextEditingController _amountController;
  late TextEditingController _dateController;
  late TextEditingController _refController;
  late TextEditingController _notesController;

  String _paymentMethod = "UPI";
  String _paymentType = "Advance";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedClientId = widget.clientId;
    _selectedProjectId = widget.projectId;
    _selectedInvoiceId = widget.invoiceId;

    _amountController = TextEditingController(
      text: widget.suggestedAmount != null && widget.suggestedAmount! > 0 ? widget.suggestedAmount!.toString() : "",
    );
    _dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
    _refController = TextEditingController();
    _notesController = TextEditingController();

    if (_selectedClientId == null) {
      final clients = Provider.of<ClientsProvider>(context, listen: false).clients;
      if (clients.isNotEmpty) _selectedClientId = clients.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select a client")));
      return;
    }

    setState(() => _isSaving = true);
    final payload = {
      "clientId": _selectedClientId,
      "projectId": _selectedProjectId,
      "invoiceId": _selectedInvoiceId,
      "amount": double.tryParse(_amountController.text.trim()) ?? 0.0,
      "paymentDate": _dateController.text.trim(),
      "paymentMethod": _paymentMethod,
      "paymentType": _paymentType,
      "referenceNumber": _refController.text.trim().isEmpty ? null : _refController.text.trim(),
      "notes": _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    try {
      await Provider.of<FinanceProvider>(context, listen: false).recordPayment(payload);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = Provider.of<ClientsProvider>(context).clients;
    final invoices = Provider.of<FinanceProvider>(context).invoices;

    return AlertDialog(
      title: const Text("Record Payment"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedClientId,
                decoration: const InputDecoration(labelText: "Client *"),
                items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.businessName))).toList(),
                onChanged: (val) => setState(() => _selectedClientId = val),
                validator: (v) => v == null ? "Select client" : null,
              ),
              const SizedBox(height: 12),
              if (invoices.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedInvoiceId,
                  decoration: const InputDecoration(labelText: "Link Invoice (Optional)"),
                  items: [
                    const DropdownMenuItem(value: null, child: Text("No invoice link")),
                    ...invoices.map((inv) => DropdownMenuItem(value: inv.id, child: Text("${inv.invoiceNumber} (Bal: ₹${inv.balanceAmount})"))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedInvoiceId = val;
                      if (val != null) {
                        final found = invoices.firstWhere((i) => i.id == val);
                        if (found.balanceAmount > 0) {
                          _amountController.text = found.balanceAmount.toString();
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Payment Amount (₹) *"),
                validator: (v) => Validators.positiveNumber(v, "Amount"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(labelText: "Payment Date (YYYY-MM-DD) *"),
                validator: (v) => Validators.required(v),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: const InputDecoration(labelText: "Method"),
                      items: ["UPI", "Bank Transfer", "Cash", "Razorpay", "Other"]
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (val) => setState(() => _paymentMethod = val!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _paymentType,
                      decoration: const InputDecoration(labelText: "Type"),
                      items: ["Advance", "Partial", "Balance", "Full"]
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _paymentType = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _refController,
                decoration: const InputDecoration(labelText: "Transaction / UTR / Reference No."),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Payment Notes"),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Log Payment"),
        ),
      ],
    );
  }
}
