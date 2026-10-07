import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/finance_provider.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'quotation_form_screen.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({Key? key}) : super(key: key);

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchQuotations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quotations"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Create Quotation",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.quotations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.quotations.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchQuotations(),
            );
          }

          if (provider.quotations.isEmpty) {
            return EmptyView(
              title: "No Quotations Generated",
              subtitle: "Send formal price estimates and proposals to prospects.",
              icon: Icons.request_quote_outlined,
              buttonText: "Create Quotation",
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuotationFormScreen()),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchQuotations(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.quotations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final q = provider.quotations[index];

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
                              q.quotationNumber,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            StatusChip(status: q.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.businessName ?? q.clientName ?? "Client",
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        if (q.projectName != null) ...[
                          const SizedBox(height: 2),
                          Text("Project: ${q.projectName}", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Estimated Total", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(
                                  Formatters.formatCurrency(q.total, showDecimals: true),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.accent),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.accent),
                                  tooltip: "PDF Generated",
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("PDF available at backend: ${ApiConstants.quotationPdf(q.id)}")),
                                    );
                                  },
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
