import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/shop_model.dart';
import '../../models/collection_model.dart';
import '../../providers/firestore_providers.dart';
import '../../services/pdf_report_service.dart';

class ShopLedgerScreen extends ConsumerStatefulWidget {
  final String? initialShopId;

  const ShopLedgerScreen({super.key, this.initialShopId});

  @override
  ConsumerState<ShopLedgerScreen> createState() => _ShopLedgerScreenState();
}

class _ShopLedgerScreenState extends ConsumerState<ShopLedgerScreen> {
  String? _selectedShopId;

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.initialShopId;
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(shopsStreamProvider);
    final shops = shopsAsync.value ?? [];

    // Default select first shop if none selected
    if (_selectedShopId == null && shops.isNotEmpty) {
      _selectedShopId = shops.first.shopId;
    }

    ShopModel? currentShop;
    if (_selectedShopId != null && shops.isNotEmpty) {
      final matches = shops.where((s) => s.shopId == _selectedShopId);
      if (matches.isNotEmpty) {
        currentShop = matches.first;
      }
    }

    final collectionsAsync = _selectedShopId != null
        ? ref.watch(shopCollectionsProvider(_selectedShopId!))
        : const AsyncValue<List<CollectionModel>>.data(<CollectionModel>[]);
    final collections = collectionsAsync.value ?? [];

    final totalCollected = collections.fold<double>(0.0, (acc, item) => acc + item.amountPaid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Statement & Ledger'),
        actions: [
          if (currentShop != null)
            IconButton(
              tooltip: 'Export Statement PDF',
              icon: const Icon(Icons.picture_as_pdf_rounded),
              onPressed: () {
                PdfReportService.generateAndShareShopLedger(
                  shop: currentShop!,
                  collections: collections,
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Shop Selector Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Customer Shop',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    color: AppColors.surfaceVariant.withOpacity(0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedShopId,
                      hint: const Text('Choose a shop...'),
                      items: shops.map((s) {
                        return DropdownMenuItem(
                          value: s.shopId,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  s.shopName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(s.currentBalance),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: s.balanceBadgeColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedShopId = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ledger Content
          Expanded(
            child: currentShop == null
                ? const Center(child: Text('Please select a shop to view statement'))
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Balance Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentShop.shopName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Route: ${currentShop.route}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: currentShop.balanceBadgeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      currentShop.balanceBadgeText,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: currentShop.balanceBadgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Current Balance Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.format(currentShop.currentBalance),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: currentShop.balanceBadgeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Total Paid Logged', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 2),
                                      Text(
                                        CurrencyFormatter.format(totalCollected),
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Ledger Timeline
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Chronological Payment Ledger (${collections.length})',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (collections.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Center(
                              child: Text(
                                'No payment entries on record yet for this account.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
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
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: item.paymentModeColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(item.paymentModeIcon, size: 18, color: item.paymentModeColor),
                                            ),
                                            const SizedBox(width: 10),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.paymentMode,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: item.paymentModeColor,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormatter.formatDateTime(item.timestamp),
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '+${CurrencyFormatter.format(item.amountPaid)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.success,
                                              ),
                                            ),
                                            Text(
                                              'Balance: ${CurrencyFormatter.format(item.balanceAfter)}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (item.note.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceVariant,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Note: ${item.note}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
