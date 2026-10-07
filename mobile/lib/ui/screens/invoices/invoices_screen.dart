import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/finance_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'invoice_form_screen.dart';
import '../payments/add_payment_dialog.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchInvoices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create Invoice",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.invoices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.invoices.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchInvoices(),
            );
          }

          if (provider.invoices.isEmpty) {
            return EmptyView(
              title: "No Invoices Generated",
              subtitle: "Issue bills and track advance and balance payments.",
              icon: Icons.receipt_long_outlined,
              buttonText: "Create Invoice",
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InvoiceFormScreen()),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchInvoices(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.invoices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final inv = provider.invoices[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.invoiceNumber,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            StatusChip(status: inv.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          inv.businessName ?? inv.clientName ?? "Client",
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        if (inv.projectName != null) ...[
                          const SizedBox(height: 2),
                          Text("Project: ${inv.projectName}", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Total: ${Formatters.formatCurrency(inv.total, showDecimals: true)}",
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(
                                  "Balance: ${Formatters.formatCurrency(inv.balanceAmount, showDecimals: true)}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: inv.balanceAmount > 0 ? AppColors.danger : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
                                  tooltip: "PDF Document",
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("PDF available: ${ApiConstants.invoicePdf(inv.id)}")),
                                    );
                                  },
                                ),
                                if (inv.balanceAmount > 0)
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      backgroundColor: AppColors.success,
                                    ),
                                    onPressed: () => showDialog(
                                      context: context,
                                      builder: (_) => AddPaymentDialog(
                                        invoiceId: inv.id,
                                        clientId: inv.clientId,
                                        projectId: inv.projectId,
                                        suggestedAmount: inv.balanceAmount,
                                      ),
                                    ),
                                    child: const Text("Pay", style: TextStyle(fontSize: 12)),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
