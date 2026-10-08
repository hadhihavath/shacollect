import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/shop_model.dart';
import '../../providers/firestore_providers.dart';
import '../home/widgets/add_shop_dialog.dart';
import '../shop_details/widgets/collect_payment_sheet.dart';
import '../shop_details/widgets/mark_visited_sheet.dart';
import '../shop_details/shop_details_screen.dart';

class RouteMapScreen extends ConsumerStatefulWidget {
  const RouteMapScreen({super.key});

  @override
  ConsumerState<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends ConsumerState<RouteMapScreen> {
  late String _selectedRoute;

  @override
  void initState() {
    super.initState();
    _selectedRoute = AppConstants.getTodayDefaultRoute();
  }

  Future<void> _launchMaps(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Google Maps: $e')),
        );
      }
    }
  }

  void _openFullRouteNavigation(List<ShopModel> shops) {
    if (shops.isEmpty) return;
    // Launch Google Maps with first destination or search query
    final firstShop = shops.first;
    _launchMaps(firstShop.googleMapsUri);
  }

  @override
  Widget build(BuildContext context) {
    final allShopsAsync = ref.watch(shopsStreamProvider);
    final allShops = allShopsAsync.valueOrNull ?? [];

    // Filter shops assigned to selected route
    final routeShops = allShops
        .where((s) => _selectedRoute == AppConstants.routeAll || s.route == _selectedRoute)
        .toList();

    // Sort by stopOrder
    routeShops.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));

    final totalRouteDue = routeShops.fold<double>(0.0, (acc, s) => acc + s.currentBalance);
    final dayName = AppConstants.getDayNameForRoute(_selectedRoute);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Travel Map & Stops',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              'Tiny Fab Kids Clothing • $dayName',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add Store to this Route',
            icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const AddShopDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Route Selector Dropdown & Day Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Day Selector Horizontal Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.defaultRoutes.map((r) {
                      final isSelected = _selectedRoute == r;
                      String label = r;
                      if (r.contains(' - ')) {
                        label = r.split(' - ')[0]; // e.g. "Monday", "Tuesday"
                      } else if (r.contains(':')) {
                        label = r.split(':')[0];
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 11,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedRoute = r);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Active Route Summary Bar
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedRoute,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${routeShops.length} Retail Kidswear Stores on Path',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Route Due', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          Text(
                            CurrencyFormatter.format(totalRouteDue),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Route Roadmap & Stores List
          Expanded(
            child: routeShops.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 54, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No Stores Added to this Route Yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap the button below to add your first kids clothing retailer on this travel path.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const AddShopDialog(),
                              );
                            },
                            icon: const Icon(Icons.add_business_rounded, size: 18),
                            label: const Text('Add Store to Route'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    children: [
                      // Starting Node: Office / Hub
                      _buildOriginCard(),

                      // Sequential Store Stops
                      ...List.generate(routeShops.length, (index) {
                        final shop = routeShops[index];
                        final isLast = index == routeShops.length - 1;
                        return _buildStopTimelineItem(
                          stopIndex: index + 1,
                          shop: shop,
                          isLast: isLast,
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: routeShops.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => _openFullRouteNavigation(routeShops),
                icon: const Icon(Icons.navigation_rounded, size: 20),
                label: Text('Start GPS Navigation (Stop 1: ${routeShops.first.shopName})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOriginCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'START POINT: Tiny Fab Hub / Office',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Depart from HQ with kidswear garment samples & invoices',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '0.0 km',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        // Connecting road line
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: 3,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildStopTimelineItem({
    required int stopIndex,
    required ShopModel shop,
    required bool isLast,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: shop.isHighOverdue ? AppColors.danger.withOpacity(0.4) : AppColors.border,
              width: shop.isHighOverdue ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stop Number & Store Name & Due Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stop Number Circle
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: shop.balanceBadgeColor,
                      foregroundColor: Colors.white,
                      child: Text(
                        '$stopIndex',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.shopName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  shop.address.isNotEmpty ? shop.address : shop.city,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Balance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: shop.balanceBadgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        CurrencyFormatter.format(shop.currentBalance),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: shop.balanceBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),

                if (shop.lastRemark.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Remark: ${shop.lastRemark}',
                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Action Buttons for this stop
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Open in Google Maps
                    OutlinedButton.icon(
                      onPressed: () => _launchMaps(shop.googleMapsUri),
                      icon: const Icon(Icons.directions_rounded, size: 16),
                      label: const Text('Maps', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        side: const BorderSide(color: AppColors.secondary),
                        foregroundColor: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Mark Visited (No Cash)
                    OutlinedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => MarkVisitedSheet(shop: shop),
                        );
                      },
                      icon: const Icon(Icons.event_available_rounded, size: 14),
                      label: const Text('Visited', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                        side: const BorderSide(color: AppColors.border),
                        foregroundColor: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Collect Cash / Entry
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => CollectPaymentSheet(shop: shop),
                        );
                      },
                      icon: const Icon(Icons.currency_rupee, size: 14),
                      label: const Text('Collect', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Details
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => ShopDetailsScreen(shopId: shop.shopId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Road connector if not last
        if (!isLast)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
      ],
    );
  }
}
