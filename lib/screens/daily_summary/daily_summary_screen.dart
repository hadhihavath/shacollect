import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/firestore_providers.dart';
import '../../services/pdf_report_service.dart';

class DailySummaryScreen extends ConsumerStatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  ConsumerState<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends ConsumerState<DailySummaryScreen> {
  Future<void> _pickDate() async {
    final currentDate = ref.read(selectedSummaryDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      ref.read(selectedSummaryDateProvider.notifier).state = picked;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedSummaryDateProvider);
    final stats = ref.watch(dailySummaryStatsProvider);
    final collectionsAsync = ref.watch(collectionsForDateProvider);
    final collections = collectionsAsync.value ?? [];

    final isToday = DateFormatter.isToday(selectedDate);

    // Calculate mode percentages
    final total = stats.totalAmount > 0 ? stats.totalAmount : 1.0;
    final cashPct = (stats.cashTotal / total).clamp(0.0, 1.0);
    final gpayPct = (stats.gpayTotal / total).clamp(0.0, 1.0);
    final bankPct = (stats.bankTotal / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Closing (EOD)'),
        actions: [
          // Date Selector
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 16),
            label: Text(
              isToday ? 'Today' : DateFormat('dd MMM').format(selectedDate),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Card: Total Collection Amount
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isToday ? "TODAY'S RECOVERED TOTAL" : "COLLECTED ON ${DateFormat('dd MMM yyyy').format(selectedDate).toUpperCase()}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${stats.transactionCount} Collections',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyFormatter.format(stats.totalAmount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 14),

                  // Mini Stats in Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _headerMiniStat('Shops Visited', '${stats.shopsVisitedCount}'),
                      _headerMiniStat('Route Outstanding', CurrencyFormatter.formatCompact(stats.totalRouteOutstanding)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Share & Export Actions Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: collections.isEmpty
                        ? null
                        : () {
                            PdfReportService.generateAndShareEODReport(
                              date: selectedDate,
                              totalAmount: stats.totalAmount,
                              shopsVisited: stats.shopsVisitedCount,
                              cashTotal: stats.cashTotal,
                              gpayTotal: stats.gpayTotal,
                              bankTotal: stats.bankTotal,
                              collections: collections,
                            );
                          },
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: collections.isEmpty
                        ? null
                        : () {
                            PdfReportService.shareEODTextSummary(
                              date: selectedDate,
                              totalAmount: stats.totalAmount,
                              shopsVisited: stats.shopsVisitedCount,
                              cashTotal: stats.cashTotal,
                              gpayTotal: stats.gpayTotal,
                              bankTotal: stats.bankTotal,
                              collections: collections,
                            );
                          },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Summary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Breakdown by Mode Section
            const Text(
              'Collection Breakdown by Mode',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _modeBreakdownRow(
                    title: 'Cash in Hand',
                    amount: stats.cashTotal,
                    percentage: cashPct,
                    color: AppColors.cashColor,
                    icon: Icons.payments_rounded,
                  ),
                  const Divider(height: 20),
                  _modeBreakdownRow(
                    title: 'Google Pay (GPay)',
                    amount: stats.gpayTotal,
                    percentage: gpayPct,
                    color: AppColors.gpayColor,
                    icon: Icons.phone_android_rounded,
                  ),
                  const Divider(height: 20),
                  _modeBreakdownRow(
                    title: 'Company Bank Account',
                    amount: stats.bankTotal,
                    percentage: bankPct,
                    color: AppColors.bankColor,
                    icon: Icons.account_balance_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Today's Collections Log
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recovered Transactions (${collections.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (collections.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 10),
                    const Text(
                      'No collections logged for this date.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Payments collected on routes will appear here automatically with real-time updates.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: collections.length,
                itemBuilder: (context, index) {
                  final item = collections[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.paymentModeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(item.paymentModeIcon, size: 20, color: item.paymentModeColor),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.shopName,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      item.paymentMode,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: item.paymentModeColor),
                                    ),
                                    const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                    Text(
                                      DateFormat('hh:mm a').format(item.timestamp),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.format(item.amountPaid),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                            Text(
                              'Bal: ${CurrencyFormatter.format(item.balanceAfter)}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _modeBreakdownRow({
    required String title,
    required double amount,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  CurrencyFormatter.format(amount),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${(percentage * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.surfaceVariant,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
