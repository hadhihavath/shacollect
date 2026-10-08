import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/shop_model.dart';
import '../../providers/firestore_providers.dart';
import '../shop_details/shop_details_screen.dart';
import '../shop_details/widgets/collect_payment_sheet.dart';
import '../shop_details/widgets/mark_visited_sheet.dart';
import '../route_planner/route_map_screen.dart';
import 'widgets/collection_stat_header.dart';
import 'widgets/shop_card.dart';
import 'widgets/add_shop_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _filterOnlyHighDue = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCollectSheet(BuildContext context, ShopModel shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CollectPaymentSheet(shop: shop),
    );
  }

  void _openMarkVisitedSheet(BuildContext context, ShopModel shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MarkVisitedSheet(shop: shop),
    );
  }

  void _openShopDetails(BuildContext context, String shopId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ShopDetailsScreen(shopId: shopId),
      ),
    );
  }

  void _openAddShopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AddShopDialog(),
    );
  }

  Future<void> _triggerCloudSync() async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Text('Syncing with Firebase Cloud Firestore...'),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await ref.read(firestoreServiceProvider).syncNow();
    if (mounted) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? '☁️ Firebase Synced: ${result.shopsCount} stores online'
                : '📡 ${result.message}',
          ),
          backgroundColor: result.success ? AppColors.success : AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = ref.watch(selectedRouteFilterProvider);
    final shopsAsync = ref.watch(shopsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            const SliverToBoxAdapter(
              child: CollectionStatHeader(),
            ),
          ];
        },
        body: Column(
          children: [
            // Search Bar & Filter Options
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search shop, owner, route, or phone...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      ref.read(searchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sync with Firebase Database
                      IconButton(
                        tooltip: 'Sync with Firebase Database',
                        icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _triggerCloudSync,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Horizontal Route Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...AppConstants.defaultRoutes.map((route) {
                          final isSelected = selectedRoute == route;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(route),
                              selected: isSelected,
                              showCheckmark: false,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 12,
                              ),
                              backgroundColor: AppColors.surfaceVariant,
                              onSelected: (_) {
                                ref.read(selectedRouteFilterProvider.notifier).state = route;
                              },
                            ),
                          );
                        }),
                        // Quick filter: High Overdue toggle
                        FilterChip(
                          avatar: Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: _filterOnlyHighDue ? Colors.white : AppColors.danger,
                          ),
                          label: const Text('High Due (> ₹5k)'),
                          selected: _filterOnlyHighDue,
                          showCheckmark: false,
                          selectedColor: AppColors.danger,
                          labelStyle: TextStyle(
                            color: _filterOnlyHighDue ? Colors.white : AppColors.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.danger.withOpacity(0.08),
                          onSelected: (val) {
                            setState(() => _filterOnlyHighDue = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quick Action Banner for Trip Map Navigation
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const RouteMapScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.secondary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'View Map Roadmap & Turn-by-Turn GPS for "$selectedRoute"',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Shops List View
            Expanded(
              child: shopsAsync.when(
                data: (shops) {
                  var filteredShops = shops;
                  if (_filterOnlyHighDue) {
                    filteredShops = filteredShops.where((s) => s.isHighOverdue).toList();
                  }

                  if (filteredShops.isEmpty) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Shops Found on Route',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No stores registered for this route yet.\nTap "+ Add Store" to register a customer shop and start logging collections.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _openAddShopDialog(context),
                              icon: const Icon(Icons.add_business_rounded, size: 18),
                              label: const Text('Add Store to Route'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: filteredShops.length,
                    itemBuilder: (context, index) {
                      final shop = filteredShops[index];
                      return ShopCard(
                        shop: shop,
                        onTap: () => _openShopDetails(context, shop.shopId),
                        onQuickCollect: () => _openCollectSheet(context, shop),
                        onMarkVisited: () => _openMarkVisitedSheet(context, shop),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.warning),
                      const SizedBox(height: 12),
                      const Text(
                        'Unable to load stores list',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$error',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(shopsStreamProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry Connection'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text('Add Shop', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const AddShopDialog(),
          );
        },
      ),
    );
  }
}
