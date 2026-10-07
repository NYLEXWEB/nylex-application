import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/finance_provider.dart';
import '../../widgets/stat_card.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({Key? key}) : super(key: key);

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  String _selectedPeriod = "all";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceProvider>(context, listen: false).fetchRevenue(period: _selectedPeriod);
    });
  }

  void _onPeriodChanged(String period) {
    setState(() => _selectedPeriod = period);
    Provider.of<FinanceProvider>(context, listen: false).fetchRevenue(period: period);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final data = finance.revenueData;

    final total = (data['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final collected = (data['collectedRevenue'] as num?)?.toDouble() ?? 0.0;
    final pending = (data['pendingRevenue'] as num?)?.toDouble() ?? 0.0;
    final byClient = (data['revenueByClient'] as Map<String, dynamic>?) ?? {};
    final byMonth = (data['revenueByMonth'] as Map<String, dynamic>?) ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text("Revenue & Financials"),
      ),
      body: RefreshIndicator(
        onRefresh: () => finance.fetchRevenue(period: _selectedPeriod),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Period Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _periodChip("all", "All Time"),
                  _periodChip("today", "Today"),
                  _periodChip("week", "This Week"),
                  _periodChip("month", "This Month"),
                  _periodChip("year", "This Year"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Top Stat Cards
            StatCard(
              title: "Collected Revenue (Real Cash Flow)",
              value: Formatters.formatCurrency(collected, showDecimals: true),
              icon: Icons.account_balance_wallet,
              iconColor: AppColors.success,
              bgColor: AppColors.successLight.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: "Total Invoiced",
                    value: Formatters.formatCurrency(total, showDecimals: true),
                    icon: Icons.receipt_long,
                    iconColor: AppColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: "Pending Dues",
                    value: Formatters.formatCurrency(pending, showDecimals: true),
                    icon: Icons.pending_actions,
                    iconColor: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Revenue By Client
            const Text("Revenue by Client", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (byClient.isEmpty)
              _emptyCard("No client collections recorded yet.")
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: byClient.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                            Text(
                              Formatters.formatCurrency(entry.value, showDecimals: true),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Revenue By Month
            const Text("Revenue by Month", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (byMonth.isEmpty)
              _emptyCard("No monthly collections logged yet.")
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: byMonth.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(
                              Formatters.formatCurrency(entry.value, showDecimals: true),
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accent),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String key, String label) {
    final isSelected = _selectedPeriod == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _onPeriodChanged(key),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
      ),
    );
  }
}
