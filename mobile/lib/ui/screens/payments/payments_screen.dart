import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/finance_provider.dart';
import '../../widgets/empty_view.dart';
import '../../widgets/error_view.dart';
import 'add_payment_dialog.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchPayments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Payments Received"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Record Payment",
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const AddPaymentDialog(),
            ),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoading && provider.payments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null && provider.payments.isEmpty) {
            return ErrorView(
              message: provider.errorMessage!,
              onRetry: () => provider.fetchPayments(),
            );
          }

          if (provider.payments.isEmpty) {
            return EmptyView(
              title: "No Payments Logged",
              subtitle: "All cash, UPI and bank transfers will appear here.",
              icon: Icons.payments_outlined,
              buttonText: "Record Payment",
              onAction: () => showDialog(
                context: context,
                builder: (_) => const AddPaymentDialog(),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchPayments(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: provider.payments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final pay = provider.payments[index];

                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.successLight,
                      child: Icon(Icons.arrow_downward, color: AppColors.success, size: 20),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Formatters.formatCurrency(pay.amount, showDecimals: true),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            pay.paymentType,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("${pay.businessName ?? pay.clientName} • ${pay.paymentMethod}"),
                        if (pay.referenceNumber != null)
                          Text("Ref: ${pay.referenceNumber}", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text(
                          "${Formatters.formatDate(pay.paymentDate)} • Recv by: ${pay.receivedByName ?? 'NYLEX'}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
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
