import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/shop_model.dart';
import '../../../models/collection_model.dart';
import '../../../providers/firestore_providers.dart';
import '../../../services/pdf_report_service.dart';

class CollectPaymentSheet extends ConsumerStatefulWidget {
  final ShopModel shop;

  const CollectPaymentSheet({super.key, required this.shop});

  @override
  ConsumerState<CollectPaymentSheet> createState() => _CollectPaymentSheetState();
}

class _CollectPaymentSheetState extends ConsumerState<CollectPaymentSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedPaymentMode = AppConstants.paymentModeCash;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _setPresetAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
    setState(() {});
  }

  void _addPresetAmount(double amount) {
    final current = double.tryParse(_amountController.text) ?? 0.0;
    _amountController.text = (current + amount).toStringAsFixed(0);
    setState(() {});
  }

  double get _currentEnteredAmount {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  double get _calculatedBalanceAfter {
    return (widget.shop.currentBalance - _currentEnteredAmount).clamp(0.0, double.infinity);
  }

  Future<void> _submitPayment() async {
    final amount = _currentEnteredAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid payment amount greater than ₹0'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);

      final collection = await firestoreService.recordPayment(
        shopId: widget.shop.shopId,
        shopName: widget.shop.shopName,
        amountPaid: amount,
        paymentMode: _selectedPaymentMode,
        note: _noteController.text.trim(),
      );

      // Trigger immediate notification
      await notificationService.showPaymentSuccessNotification(
        shopName: widget.shop.shopName,
        amount: amount,
        paymentMode: _selectedPaymentMode,
      );

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessReceiptDialog(collection);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording collection: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessReceiptDialog(CollectionModel collection) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 54,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Recorded!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.shop.shopName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Collected Amount:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        CurrencyFormatter.format(collection.amountPaid),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Mode:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Row(
                        children: [
                          Icon(collection.paymentModeIcon, size: 14, color: collection.paymentModeColor),
                          const SizedBox(width: 4),
                          Text(
                            collection.paymentMode,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: collection.paymentModeColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Due:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      Text(
                        CurrencyFormatter.format(collection.balanceAfter),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              PdfReportService.sharePaymentReceipt(
                collection: collection,
                shop: widget.shop,
              );
            },
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Share Receipt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 42),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Shop Name & Balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Record Payment Collection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.shop.shopName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Current Due',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.danger),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.shop.currentBalance),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Amount Input Field
            const Text(
              'Collected Amount (₹) *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.currency_rupee, size: 24, color: AppColors.primary),
                hintText: '0',
                suffixIcon: _amountController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _amountController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),

            // Quick Preset Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('+₹500'),
                    backgroundColor: AppColors.surfaceVariant,
                    onPressed: () => _addPresetAmount(500),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('+₹1,000'),
                    backgroundColor: AppColors.surfaceVariant,
                    onPressed: () => _addPresetAmount(1000),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('+₹2,000'),
                    backgroundColor: AppColors.surfaceVariant,
                    onPressed: () => _addPresetAmount(2000),
                  ),
                  const SizedBox(width: 8),
                  if (widget.shop.currentBalance > 0)
                    ActionChip(
                      label: Text('Full (${CurrencyFormatter.format(widget.shop.currentBalance)})'),
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      onPressed: () => _setPresetAmount(widget.shop.currentBalance),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Mode Single-Choice Chips
            const Text(
              'Payment Mode *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: AppConstants.paymentModes.map((mode) {
                final isSelected = _selectedPaymentMode == mode;
                IconData icon;
                Color activeColor;
                switch (mode) {
                  case AppConstants.paymentModeCash:
                    icon = Icons.payments_rounded;
                    activeColor = AppColors.cashColor;
                    break;
                  case AppConstants.paymentModeGPay:
                    icon = Icons.phone_android_rounded;
                    activeColor = AppColors.gpayColor;
                    break;
                  default:
                    icon = Icons.account_balance_rounded;
                    activeColor = AppColors.bankColor;
                }

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedPaymentMode = mode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor.withOpacity(0.12) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? activeColor : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(icon, size: 20, color: isSelected ? activeColor : AppColors.textSecondary),
                            const SizedBox(height: 4),
                            Text(
                              mode,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected ? activeColor : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Remarks / Reference
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Remark / Transaction Ref (Optional)',
                hintText: 'e.g. UPI Ref / Cheque No / Paid to agent',
                prefixIcon: Icon(Icons.description_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            // Running Balance Preview Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance After Collection:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                  Text(
                    CurrencyFormatter.format(_calculatedBalanceAfter),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _calculatedBalanceAfter == 0 ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Confirm ₹${_currentEnteredAmount.toStringAsFixed(0)} Collection'),
            ),
          ],
        ),
      ),
    );
  }
}
