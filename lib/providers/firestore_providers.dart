import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../models/shop_model.dart';
import '../models/collection_model.dart';
import '../models/follow_up_model.dart';
import '../core/constants/app_constants.dart';

import '../providers/auth_provider.dart';

export '../services/firestore_service.dart' show CloudSyncStatus, SyncResult;

// Services
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final uid = user?.uid ?? 'agent_sha_001';
  return FirestoreService(userId: uid);
});

final cloudSyncStatusProvider = StreamProvider<CloudSyncStatus>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.syncStatusStream;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// UI State Filters
final selectedRouteFilterProvider = StateProvider<String>((ref) => AppConstants.getTodayDefaultRoute());
final searchQueryProvider = StateProvider<String>((ref) => '');

// Shops Stream
final shopsStreamProvider = StreamProvider<List<ShopModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final routeFilter = ref.watch(selectedRouteFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider);

  return firestoreService.streamShops(
    routeFilter: routeFilter,
    searchQuery: searchQuery,
  );
});

// Single Shop Stream Provider
final shopDetailsProvider = StreamProvider.family<ShopModel?, String>((ref, shopId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamShop(shopId);
});

// Selected Date for Daily Summary / EOD
final selectedSummaryDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// Collections Stream for a selected date
final collectionsForDateProvider = StreamProvider<List<CollectionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final date = ref.watch(selectedSummaryDateProvider);
  return firestoreService.streamCollections(date: date);
});

// Today's Collections Stream (for top persistent header)
final todayCollectionsProvider = StreamProvider<List<CollectionModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamCollections(date: DateTime.now());
});

// Single Shop Collections Stream (for Ledger)
final shopCollectionsProvider = StreamProvider.family<List<CollectionModel>, String>((ref, shopId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamShopCollections(shopId);
});

// Follow Ups Stream
final followUpsStreamProvider = StreamProvider<List<FollowUpModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.streamFollowUps(unresolvedOnly: false);
});

// Today's Aggregate Collection Metrics Class
class DailySummaryStats {
  final double totalAmount;
  final int shopsVisitedCount;
  final int transactionCount;
  final double cashTotal;
  final double gpayTotal;
  final double bankTotal;
  final double totalRouteOutstanding;

  const DailySummaryStats({
    required this.totalAmount,
    required this.shopsVisitedCount,
    required this.transactionCount,
    required this.cashTotal,
    required this.gpayTotal,
    required this.bankTotal,
    required this.totalRouteOutstanding,
  });

  factory DailySummaryStats.empty() {
    return const DailySummaryStats(
      totalAmount: 0.0,
      shopsVisitedCount: 0,
      transactionCount: 0,
      cashTotal: 0.0,
      gpayTotal: 0.0,
      bankTotal: 0.0,
      totalRouteOutstanding: 0.0,
    );
  }
}

// Provider computing Daily Summary Stats for Selected Date
final dailySummaryStatsProvider = Provider<DailySummaryStats>((ref) {
  final collectionsAsync = ref.watch(collectionsForDateProvider);
  final shopsAsync = ref.watch(shopsStreamProvider);

  final collections = collectionsAsync.value ?? [];
  final shops = shopsAsync.value ?? [];

  double totalAmount = 0.0;
  double cashTotal = 0.0;
  double gpayTotal = 0.0;
  double bankTotal = 0.0;
  final Set<String> visitedShopIds = {};

  for (final c in collections) {
    totalAmount += c.amountPaid;
    visitedShopIds.add(c.shopId);

    if (c.paymentMode == AppConstants.paymentModeCash) {
      cashTotal += c.amountPaid;
    } else if (c.paymentMode == AppConstants.paymentModeGPay) {
      gpayTotal += c.amountPaid;
    } else if (c.paymentMode == AppConstants.paymentModeCompanyAccount) {
      bankTotal += c.amountPaid;
    }
  }

  double totalOutstanding = 0.0;
  for (final s in shops) {
    totalOutstanding += s.currentBalance;
  }

  return DailySummaryStats(
    totalAmount: totalAmount,
    shopsVisitedCount: visitedShopIds.length,
    transactionCount: collections.length,
    cashTotal: cashTotal,
    gpayTotal: gpayTotal,
    bankTotal: bankTotal,
    totalRouteOutstanding: totalOutstanding,
  );
});
