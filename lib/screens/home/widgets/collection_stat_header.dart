import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/firestore_providers.dart';

class CollectionStatHeader extends ConsumerWidget {
  const CollectionStatHeader({super.key});

  Future<void> _handleManualSync(BuildContext context, WidgetRef ref) async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Syncing account data with Firebase Cloud Firestore...'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.primary,
      ),
    );

    final result = await ref.read(firestoreServiceProvider).syncNow();
    scaffold.hideCurrentSnackBar();
    scaffold.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '☁️ Firebase Cloud Database Synced (${result.shopsCount} stores online)'
              : '📡 ${result.message}',
        ),
        backgroundColor: result.success ? AppColors.success : AppColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authStateProvider).valueOrNull;
    final syncStatus = ref.read(cloudSyncStatusProvider).valueOrNull ?? CloudSyncStatus.synced;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              child: Text(
                user?.displayName.isNotEmpty == true
                    ? user!.displayName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'Field Agent',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        syncStatus == CloudSyncStatus.synced
                            ? Icons.cloud_done_rounded
                            : (syncStatus == CloudSyncStatus.syncing
                                ? Icons.sync_rounded
                                : Icons.cloud_off_rounded),
                        size: 18,
                        color: syncStatus == CloudSyncStatus.synced ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        syncStatus == CloudSyncStatus.synced
                            ? 'Firebase Database: Synced Online'
                            : (syncStatus == CloudSyncStatus.syncing
                                ? 'Firebase Database: Syncing...'
                                : 'Offline Cache Active'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Role: ${user?.role ?? "Tiny Fab Field Executive"}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'All route stores, collections, and follow-ups are securely backed up in the cloud.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _handleManualSync(context, ref);
              },
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Sync with Cloud Database Now'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authServiceProvider).signOut();
            },
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayCollections = ref.watch(todayCollectionsProvider).valueOrNull ?? [];
    final shops = ref.watch(shopsStreamProvider).valueOrNull ?? [];
    final user = ref.watch(authStateProvider).valueOrNull;
    final syncStatus = ref.watch(cloudSyncStatusProvider).valueOrNull ?? CloudSyncStatus.synced;

    double totalToday = 0.0;
    final Set<String> visitedShops = {};
    final now = DateTime.now();

    for (final c in todayCollections) {
      totalToday += c.amountPaid;
      visitedShops.add(c.shopId);
    }

    for (final s in shops) {
      if (s.lastVisited != null &&
          s.lastVisited!.year == now.year &&
          s.lastVisited!.month == now.month &&
          s.lastVisited!.day == now.day) {
        visitedShops.add(s.shopId);
      }
    }

    final visitedCount = visitedShops.length;
    final totalShopsCount = shops.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: App Name & Agent Profile & Sync Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TINY FAB • SHA COLLECTS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            user != null
                                ? '${user.displayName} (Collection & Sales)'
                                : 'Tiny Fab Kids Clothing Brand',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                  // User Avatar & Sync Badge
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _handleManualSync(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                syncStatus == CloudSyncStatus.synced
                                    ? Icons.cloud_done_rounded
                                    : (syncStatus == CloudSyncStatus.syncing
                                        ? Icons.sync_rounded
                                        : Icons.cloud_queue_rounded),
                                color: syncStatus == CloudSyncStatus.synced
                                    ? const Color(0xFF69F0AE)
                                    : Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                syncStatus == CloudSyncStatus.synced
                                    ? 'Cloud Synced'
                                    : (syncStatus == CloudSyncStatus.syncing
                                        ? 'Syncing...'
                                        : 'Offline Cache'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Avatar / Logout Action
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _showProfileDialog(context, ref),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Text(
                            user?.displayName.isNotEmpty == true
                                ? user!.displayName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Total Collection Display
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "TODAY'S RECOVERED CASH",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(totalToday),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  // Mini Progress Indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Route Progress',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$visitedCount / $totalShopsCount Visited',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
