import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../models/quotation_model.dart';
import '../../../providers/finance_provider.dart';
import '../../../providers/clients_provider.dart';
import '../../../providers/projects_provider.dart';

class InvoiceFormScreen extends StatefulWidget {
  const InvoiceFormScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClientId;
  String? _selectedProjectId;
  late TextEditingController _dateController;
  late TextEditingController _dueDateController;
  late TextEditingController _discountController;
  late TextEditingController _taxRateController;
  late TextEditingController _notesController;

  final List<LineItemModel> _items = [
    LineItemModel(description: "Phase 1: Project Kickoff & Frontend Delivery", quantity: 1, rate: 25000, amount: 25000),
  ];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateController = TextEditingController(text: now.toString().substring(0, 10));
    _dueDateController = TextEditingController(text: now.add(const Duration(days: 15)).toString().substring(0, 10));
    _discountController = TextEditingController(text: "0");
    _taxRateController = TextEditingController(text: "18");
    _notesController = TextEditingController(text: "Bank Details:\nNYLEX Solutions • HDFC Bank • IFSC: HDFC0001234 • Acc: 50100987654321");

    final clients = Provider.of<ClientsProvider>(context, listen: false).clients;
    if (clients.isNotEmpty) _selectedClientId = clients.first.id;
  }

  @override
  void dispose() {
    _dateController.dispose();
    _dueDateController.dispose();
    _discountController.dispose();
    _taxRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(LineItemModel(description: "Additional Deliverables / Integration", quantity: 1, rate: 5000, amount: 5000));
    });
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
      "invoiceDate": _dateController.text.trim(),
      "dueDate": _dueDateController.text.trim(),
      "discount": double.tryParse(_discountController.text.trim()) ?? 0.0,
      "taxRate": double.tryParse(_taxRateController.text.trim()) ?? 0.0,
      "notes": _notesController.text.trim(),
      "items": _items.map((i) => i.toJson()).toList(),
    };

    try {
      await Provider.of<FinanceProvider>(context, listen: false).createInvoice(payload);
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
    final projects = Provider.of<ProjectsProvider>(context).projects;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invoice"),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedClientId,
              decoration: const InputDecoration(labelText: "Client *"),
              items: clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.businessName))).toList(),
              onChanged: (val) => setState(() => _selectedClientId = val),
              validator: (v) => v == null ? "Select client" : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              decoration: const InputDecoration(labelText: "Project (Optional)"),
              items: [
                const DropdownMenuItem(value: null, child: Text("None / Direct Retainer")),
                ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.projectName))),
              ],
              onChanged: (val) => setState(() => _selectedProjectId = val),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dateController,
                    decoration: const InputDecoration(labelText: "Invoice Date"),
                    validator: (v) => Validators.required(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _dueDateController,
                    decoration: const InputDecoration(labelText: "Due Date"),
                    validator: (v) => Validators.required(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Line Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Billed Line Items", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text("Add Item"),
                ),
              ],
            ),
            ..._items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: item.description,
                        decoration: const InputDecoration(labelText: "Item Description"),
                        onChanged: (v) {
                          _items[idx] = LineItemModel(
                            description: v,
                            quantity: item.quantity,
                            rate: item.rate,
                            amount: item.quantity * item.rate,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Qty"),
                              onChanged: (v) {
                                final q = double.tryParse(v) ?? 1.0;
                                _items[idx] = LineItemModel(
                                  description: _items[idx].description,
                                  quantity: q,
                                  rate: _items[idx].rate,
                                  amount: q * _items[idx].rate,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              initialValue: item.rate.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Rate (₹)"),
                              onChanged: (v) {
                                final r = double.tryParse(v) ?? 0.0;
                                _items[idx] = LineItemModel(
                                  description: _items[idx].description,
                                  quantity: _items[idx].quantity,
                                  rate: r,
                                  amount: _items[idx].quantity * r,
                                );
                              },
                            ),
                          ),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                              onPressed: () => setState(() => _items.removeAt(idx)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Discount (₹)"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _taxRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Tax Rate (%)"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Payment Instructions / Bank Details"),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Generate Official Invoice"),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
