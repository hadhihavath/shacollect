import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/shop_model.dart';
import '../models/collection_model.dart';
import '../models/follow_up_model.dart';
import '../models/user_model.dart';

enum CloudSyncStatus {
  synced,
  syncing,
  offline,
  error,
}

class SyncResult {
  final bool success;
  final String message;
  final int shopsCount;
  final int collectionsCount;
  final bool isPermissionDenied;

  const SyncResult({
    required this.success,
    required this.message,
    required this.shopsCount,
    required this.collectionsCount,
    this.isPermissionDenied = false,
  });
}

class FirestoreService {
  final FirebaseFirestore? _firestore;
  final String userId;
  final Uuid _uuid = const Uuid();
  bool _useLocalFallback = false;

  // Local memory storage (cache / offline fallback)
  final List<ShopModel> _localShops = [];
  final List<CollectionModel> _localCollections = [];
  final List<FollowUpModel> _localFollowUps = [];
  
  final _changeNotifier = StreamController<void>.broadcast();
  final _syncStatusController = StreamController<CloudSyncStatus>.broadcast();
  CloudSyncStatus _currentSyncStatus = CloudSyncStatus.synced;
  DateTime? _lastSyncTime;

  static FirebaseFirestore? _tryGetFirestoreInstance() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore instance not available (offline/test mode): $e');
      return null;
    }
  }

  FirestoreService({
    FirebaseFirestore? firestore,
    String? userId,
  })  : _firestore = firestore ?? _tryGetFirestoreInstance(),
        userId = userId ?? 'agent_sha_001' {
    if (_firestore == null) {
      _useLocalFallback = true;
    } else {
      _initialize();
    }
  }

  void _initialize() {
    if (_firestore == null) return;
    try {
      // Offline persistence is enabled in main.dart
      debugPrint('FirestoreService initialized for account user: $userId');
    } catch (e) {
      debugPrint('Firestore settings note: $e');
    }
  }

  CloudSyncStatus get currentSyncStatus => _currentSyncStatus;
  DateTime? get lastSyncTime => _lastSyncTime;

  Stream<CloudSyncStatus> get syncStatusStream async* {
    yield _currentSyncStatus;
    yield* _syncStatusController.stream;
  }

  void _setSyncStatus(CloudSyncStatus status) {
    _currentSyncStatus = status;
    if (status == CloudSyncStatus.synced) {
      _lastSyncTime = DateTime.now();
    }
    _syncStatusController.add(status);
  }

  void enableLocalFallback(bool enable) {
    _useLocalFallback = enable;
    _changeNotifier.add(null);
  }

  bool get isUsingLocalFallback => _useLocalFallback || _firestore == null;

  void _notifyLocalChange() {
    _changeNotifier.add(null);
  }

  Stream<T> _createLocalStream<T>(T Function() currentSupplier) async* {
    yield currentSupplier();
    yield* _changeNotifier.stream.map((_) => currentSupplier());
  }

  // ===================== PER-ACCOUNT FIRESTORE PATHS =====================

  DocumentReference<Map<String, dynamic>>? get _userDocRef =>
      _firestore?.collection('users').doc(userId);

  CollectionReference<Map<String, dynamic>>? get _shopsRef =>
      _firestore?.collection('users').doc(userId).collection(AppConstants.shopsCollection);

  CollectionReference<Map<String, dynamic>>? get _collectionsRef =>
      _firestore?.collection('users').doc(userId).collection(AppConstants.collectionsCollection);

  CollectionReference<Map<String, dynamic>>? get _followUpsRef =>
      _firestore?.collection('users').doc(userId).collection(AppConstants.followUpsCollection);

  // ===================== ACCOUNT INITIALIZATION & SYNC =====================

  /// Ensures user account profile exists in Firestore and seeds default route data if empty
  Future<void> ensureUserAccountInitialized({
    UserModel? user,
    List<ShopModel>? defaultShops,
    List<CollectionModel>? defaultCollections,
    List<FollowUpModel>? defaultFollowUps,
  }) async {
    if (_firestore == null) return;

    try {
      _setSyncStatus(CloudSyncStatus.syncing);

      // 1. Sync User profile to Firestore under users/{userId}
      if (_userDocRef != null) {
        await _userDocRef!.set({
          'uid': userId,
          'displayName': user?.displayName ?? 'Hadi Sha',
          'email': user?.email ?? 'hadi@tinyfab.in',
          'role': user?.role ?? 'Tiny Fab Collection & Sales Executive',
          'lastActive': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 2. Check if this account already has shops in Cloud Firestore
      if (_shopsRef != null) {
        final existing = await _shopsRef!.limit(1).get();
        if (existing.docs.isEmpty) {
          debugPrint('Account $userId has no shops in Firestore. Seeding default Route shops online...');
          if (defaultShops != null && defaultShops.isNotEmpty) {
            await syncInitialDataToCloud(
              defaultShops,
              defaultCollections ?? [],
              defaultFollowUps ?? [],
            );
          }
        } else {
          debugPrint('Account $userId already has stores in Cloud Firestore.');
          _setSyncStatus(CloudSyncStatus.synced);
        }
      }
    } catch (e) {
      debugPrint('ensureUserAccountInitialized note (safe offline cache): $e');
      _setSyncStatus(CloudSyncStatus.offline);
    }
  }

  /// Bulk uploads and synchronizes initial route dataset to Firebase Cloud Firestore for this account
  Future<void> syncInitialDataToCloud(
    List<ShopModel> shops,
    List<CollectionModel> collections,
    List<FollowUpModel> followUps,
  ) async {
    // Populate local cache first so UI is responsive
    loadInitialSeedData(shops, collections, followUps);

    if (_firestore == null || _shopsRef == null) return;

    try {
      _setSyncStatus(CloudSyncStatus.syncing);
      final batch = _firestore.batch();

      for (final shop in shops) {
        final docRef = _shopsRef!.doc(shop.shopId);
        batch.set(docRef, shop.toMap(), SetOptions(merge: true));
      }

      if (_collectionsRef != null) {
        for (final coll in collections) {
          final docRef = _collectionsRef!.doc(coll.transactionId);
          batch.set(docRef, coll.toMap(), SetOptions(merge: true));
        }
      }

      if (_followUpsRef != null) {
        for (final followUp in followUps) {
          final docRef = _followUpsRef!.doc(followUp.followUpId);
          batch.set(docRef, followUp.toMap(), SetOptions(merge: true));
        }
      }

      await batch.commit();
      debugPrint('Successfully synced initial dataset to Cloud Firestore for account: $userId');
      _setSyncStatus(CloudSyncStatus.synced);
    } catch (e) {
      debugPrint('Error syncing initial dataset to Firestore (queued in local cache): $e');
      _setSyncStatus(CloudSyncStatus.offline);
    }
  }

  /// Explicit sync with Cloud Firestore
  Future<SyncResult> syncNow() async {
    if (_firestore == null) {
      return SyncResult(
        success: false,
        message: 'Firestore is operating in offline local mode.',
        shopsCount: _localShops.length,
        collectionsCount: _localCollections.length,
      );
    }

    try {
      _setSyncStatus(CloudSyncStatus.syncing);

      try {
        await _firestore.enableNetwork();
      } catch (_) {}

      // Push any local shops to remote Firestore
      if (_shopsRef != null && _localShops.isNotEmpty) {
        final batch = _firestore.batch();
        for (final s in _localShops) {
          batch.set(_shopsRef!.doc(s.shopId), s.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
      }

      // Query current count from server
      final shopSnaps = await _shopsRef?.get(const GetOptions(source: Source.serverAndCache));
      final collSnaps = await _collectionsRef?.get(const GetOptions(source: Source.serverAndCache));

      final shopCount = shopSnaps?.docs.length ?? _localShops.length;
      final collCount = collSnaps?.docs.length ?? _localCollections.length;

      // Update user doc lastSynced
      await _userDocRef?.set({
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _setSyncStatus(CloudSyncStatus.synced);

      return SyncResult(
        success: true,
        message: 'Account data synchronized with Firebase Cloud Firestore.',
        shopsCount: shopCount,
        collectionsCount: collCount,
      );
    } catch (e) {
      debugPrint('syncNow error: $e');
      _setSyncStatus(CloudSyncStatus.offline);
      final isPerm = e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED');
      return SyncResult(
        success: false,
        isPermissionDenied: isPerm,
        message: isPerm
            ? 'Firebase Cloud Rules need to be updated in the Firebase Console to allow read/write.'
            : 'Offline mode active: Local modifications saved and will sync when connected ($e).',
        shopsCount: _localShops.length,
        collectionsCount: _localCollections.length,
      );
    }
  }

  // ===================== SHOPS =====================

  Stream<List<ShopModel>> streamShops({String? routeFilter, String? searchQuery}) {
    if (_useLocalFallback || _firestore == null || _shopsRef == null) {
      return _createLocalStream(() => _filterShops(_localShops, routeFilter, searchQuery));
    }

    try {
      Query<Map<String, dynamic>> query = _shopsRef!;
      if (routeFilter != null && routeFilter != 'All Routes' && routeFilter.isNotEmpty) {
        query = query.where('route', isEqualTo: routeFilter);
      }

      return query.snapshots().map((snapshot) {
        final shops = snapshot.docs.map((doc) => ShopModel.fromFirestore(doc)).toList();

        // Update local memory cache so offline operations have latest documents
        for (final s in shops) {
          final idx = _localShops.indexWhere((l) => l.shopId == s.shopId);
          if (idx != -1) {
            _localShops[idx] = s;
          } else {
            _localShops.add(s);
          }
        }

        shops.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));

        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final queryLower = searchQuery.toLowerCase().trim();
          return shops.where((s) =>
            s.shopName.toLowerCase().contains(queryLower) ||
            s.ownerName.toLowerCase().contains(queryLower) ||
            s.contactNumber.contains(queryLower) ||
            s.route.toLowerCase().contains(queryLower)
          ).toList();
        }

        _setSyncStatus(snapshot.metadata.hasPendingWrites ? CloudSyncStatus.syncing : CloudSyncStatus.synced);
        return shops;
      }).handleError((error) {
        debugPrint('Firestore streamShops error, using cached shops: $error');
        _setSyncStatus(CloudSyncStatus.offline);
        return _filterShops(_localShops, routeFilter, searchQuery);
      });
    } catch (e) {
      debugPrint('streamShops exception: $e');
      _setSyncStatus(CloudSyncStatus.offline);
      return _createLocalStream(() => _filterShops(_localShops, routeFilter, searchQuery));
    }
  }

  List<ShopModel> _filterShops(List<ShopModel> shops, String? routeFilter, String? searchQuery) {
    var result = List<ShopModel>.from(shops);
    if (routeFilter != null && routeFilter != 'All Routes' && routeFilter.isNotEmpty) {
      result = result.where((s) => s.route == routeFilter).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((s) =>
        s.shopName.toLowerCase().contains(q) ||
        s.ownerName.toLowerCase().contains(q) ||
        s.contactNumber.contains(q) ||
        s.route.toLowerCase().contains(q)
      ).toList();
    }
    result.sort((a, b) => b.currentBalance.compareTo(a.currentBalance));
    return result;
  }

  Stream<ShopModel?> streamShop(String shopId) {
    if (_useLocalFallback || _firestore == null || _shopsRef == null) {
      return _createLocalStream(() {
        final matches = _localShops.where((s) => s.shopId == shopId);
        return matches.isNotEmpty ? matches.first : null;
      });
    }

    try {
      return _shopsRef!.doc(shopId).snapshots().map((doc) {
        if (!doc.exists) return null;
        final shop = ShopModel.fromFirestore(doc);
        final idx = _localShops.indexWhere((s) => s.shopId == shopId);
        if (idx != -1) {
          _localShops[idx] = shop;
        } else {
          _localShops.add(shop);
        }
        return shop;
      }).handleError((error) {
        debugPrint('streamShop error: $error');
        final matches = _localShops.where((s) => s.shopId == shopId);
        return matches.isNotEmpty ? matches.first : null;
      });
    } catch (e) {
      return _createLocalStream(() {
        final matches = _localShops.where((s) => s.shopId == shopId);
        return matches.isNotEmpty ? matches.first : null;
      });
    }
  }

  Future<void> addShop(ShopModel shop) async {
    final docId = shop.shopId.isEmpty ? _uuid.v4() : shop.shopId;
    final newShop = shop.copyWith(shopId: docId);

    _localShops.removeWhere((s) => s.shopId == docId);
    _localShops.add(newShop);
    _notifyLocalChange();

    if (_firestore != null && _shopsRef != null) {
      try {
        _setSyncStatus(CloudSyncStatus.syncing);
        await _shopsRef!.doc(docId).set(newShop.toMap());
        _setSyncStatus(CloudSyncStatus.synced);
      } catch (e) {
        debugPrint('Error saving shop to Firestore (persisted locally): $e');
        _setSyncStatus(CloudSyncStatus.offline);
      }
    }
  }

  Future<void> updateShop(ShopModel shop) async {
    final index = _localShops.indexWhere((s) => s.shopId == shop.shopId);
    if (index != -1) {
      _localShops[index] = shop;
      _notifyLocalChange();
    }

    if (_firestore != null && _shopsRef != null) {
      try {
        _setSyncStatus(CloudSyncStatus.syncing);
        await _shopsRef!.doc(shop.shopId).update(shop.toMap());
        _setSyncStatus(CloudSyncStatus.synced);
      } catch (e) {
        debugPrint('Error updating shop in Firestore: $e');
        _setSyncStatus(CloudSyncStatus.offline);
      }
    }
  }

  // ===================== PAYMENTS / COLLECTIONS =====================

  Future<CollectionModel> recordPayment({
    required String shopId,
    required String shopName,
    required double amountPaid,
    required String paymentMode,
    String note = '',
  }) async {
    final transactionId = _uuid.v4();
    final now = DateTime.now();

    double previousBalance = 0.0;
    ShopModel? currentShop;

    final localIndex = _localShops.indexWhere((s) => s.shopId == shopId);
    if (localIndex != -1) {
      currentShop = _localShops[localIndex];
      previousBalance = currentShop.currentBalance;
    } else if (_firestore != null && _shopsRef != null) {
      try {
        final doc = await _shopsRef!.doc(shopId).get();
        if (doc.exists) {
          currentShop = ShopModel.fromFirestore(doc);
          previousBalance = currentShop.currentBalance;
        }
      } catch (_) {}
    }

    final newBalance = (previousBalance - amountPaid).clamp(0.0, double.infinity);
    final remarkText = 'Paid ₹${amountPaid.toStringAsFixed(0)} via $paymentMode';

    final collectionRecord = CollectionModel(
      transactionId: transactionId,
      shopId: shopId,
      shopName: shopName,
      amountPaid: amountPaid,
      paymentMode: paymentMode,
      timestamp: now,
      balanceAfter: newBalance,
      note: note,
    );

    // Update local memory
    _localCollections.insert(0, collectionRecord);
    if (currentShop != null) {
      final updatedShop = currentShop.copyWith(
        currentBalance: newBalance,
        lastRemark: remarkText,
        lastVisited: now,
      );
      if (localIndex != -1) {
        _localShops[localIndex] = updatedShop;
      } else {
        _localShops.add(updatedShop);
      }
    }
    _notifyLocalChange();

    if (_firestore != null && _shopsRef != null && _collectionsRef != null) {
      try {
        _setSyncStatus(CloudSyncStatus.syncing);
        final batch = _firestore.batch();
        final shopDocRef = _shopsRef!.doc(shopId);
        final collDocRef = _collectionsRef!.doc(transactionId);

        batch.update(shopDocRef, {
          'currentBalance': newBalance,
          'lastRemark': remarkText,
          'lastVisited': Timestamp.fromDate(now),
        });

        batch.set(collDocRef, collectionRecord.toMap());

        await batch.commit();
        _setSyncStatus(CloudSyncStatus.synced);
        debugPrint('Recorded payment of ₹$amountPaid for $shopName in Firestore under user: $userId');
      } catch (e) {
        debugPrint('Firestore recordPayment write error (cached locally): $e');
        _setSyncStatus(CloudSyncStatus.offline);
      }
    }

    return collectionRecord;
  }

  Stream<List<CollectionModel>> streamCollections({DateTime? date}) {
    if (_useLocalFallback || _firestore == null || _collectionsRef == null) {
      return _createLocalStream(() {
        if (date == null) return List<CollectionModel>.from(_localCollections);
        return _localCollections.where((c) =>
          c.timestamp.year == date.year &&
          c.timestamp.month == date.month &&
          c.timestamp.day == date.day
        ).toList();
      });
    }

    try {
      Query<Map<String, dynamic>> query = _collectionsRef!.orderBy('timestamp', descending: true);

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => CollectionModel.fromFirestore(doc)).toList();

        // Update local cache
        for (final c in list) {
          final idx = _localCollections.indexWhere((l) => l.transactionId == c.transactionId);
          if (idx != -1) {
            _localCollections[idx] = c;
          } else {
            _localCollections.add(c);
          }
        }

        if (date == null) return list;
        return list.where((c) =>
          c.timestamp.year == date.year &&
          c.timestamp.month == date.month &&
          c.timestamp.day == date.day
        ).toList();
      }).handleError((error) {
        debugPrint('streamCollections error, using local cache: $error');
        if (date == null) return _localCollections;
        return _localCollections.where((c) =>
          c.timestamp.year == date.year &&
          c.timestamp.month == date.month &&
          c.timestamp.day == date.day
        ).toList();
      });
    } catch (e) {
      debugPrint('streamCollections exception: $e');
      return _createLocalStream(() => _localCollections);
    }
  }

  Stream<List<CollectionModel>> streamShopCollections(String shopId) {
    if (_useLocalFallback || _firestore == null || _collectionsRef == null) {
      return _createLocalStream(() {
        final filtered = _localCollections.where((c) => c.shopId == shopId).toList();
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return filtered;
      });
    }

    try {
      return _collectionsRef!
          .where('shopId', isEqualTo: shopId)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) => CollectionModel.fromFirestore(doc)).toList();
        list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return list;
      }).handleError((error) {
        debugPrint('streamShopCollections error: $error');
        final filtered = _localCollections.where((c) => c.shopId == shopId).toList();
        filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return filtered;
      });
    } catch (e) {
      final filtered = _localCollections.where((c) => c.shopId == shopId).toList();
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Stream.value(filtered);
    }
  }

  // ===================== FOLLOW-UPS =====================

  Future<FollowUpModel> scheduleFollowUp({
    required String shopId,
    required String shopName,
    required DateTime promiseDate,
    required String timeSlot,
    required String note,
  }) async {
    final followUpId = _uuid.v4();
    final now = DateTime.now();

    final followUp = FollowUpModel(
      followUpId: followUpId,
      shopId: shopId,
      shopName: shopName,
      promiseDate: promiseDate,
      timeSlot: timeSlot,
      note: note,
      isResolved: false,
      createdAt: now,
    );

    _localFollowUps.insert(0, followUp);
    
    final shopIndex = _localShops.indexWhere((s) => s.shopId == shopId);
    if (shopIndex != -1) {
      final remark = 'Follow-up: Promised on ${promiseDate.day}/${promiseDate.month} ($timeSlot)';
      _localShops[shopIndex] = _localShops[shopIndex].copyWith(
        lastRemark: remark,
        lastVisited: now,
      );
    }
    _notifyLocalChange();

    if (_firestore != null && _followUpsRef != null && _shopsRef != null) {
      try {
        _setSyncStatus(CloudSyncStatus.syncing);
        final batch = _firestore.batch();
        batch.set(_followUpsRef!.doc(followUpId), followUp.toMap());
        batch.update(_shopsRef!.doc(shopId), {
          'lastRemark': 'Follow-up: Promised on ${promiseDate.day}/${promiseDate.month} ($timeSlot)',
          'lastVisited': Timestamp.fromDate(now),
        });
        await batch.commit();
        _setSyncStatus(CloudSyncStatus.synced);
        debugPrint('Scheduled follow-up for $shopName in Firestore');
      } catch (e) {
        debugPrint('Firestore scheduleFollowUp error: $e');
        _setSyncStatus(CloudSyncStatus.offline);
      }
    }

    return followUp;
  }

  Future<void> markShopVisitedNoCollection({
    required String shopId,
    required String reason,
    DateTime? nextFollowUpDate,
    String? followUpTimeSlot,
  }) async {
    final now = DateTime.now();
    final remark = 'Visited (No Collection): $reason';

    // 1. Update local shop state
    final index = _localShops.indexWhere((s) => s.shopId == shopId);
    ShopModel? shop;
    if (index != -1) {
      shop = _localShops[index];
      _localShops[index] = shop.copyWith(
        lastVisited: now,
        lastRemark: remark,
      );
    }

    // 2. Schedule follow-up if date is set
    FollowUpModel? followUp;
    if (nextFollowUpDate != null) {
      final followUpId = _uuid.v4();
      followUp = FollowUpModel(
        followUpId: followUpId,
        shopId: shopId,
        shopName: shop?.shopName ?? 'Store',
        promiseDate: nextFollowUpDate,
        timeSlot: followUpTimeSlot ?? 'Morning (9 AM - 12 PM)',
        note: reason,
        createdAt: now,
      );
      _localFollowUps.insert(0, followUp);
    }
    _notifyLocalChange();

    // 3. Sync with Firestore
    if (_firestore != null && _shopsRef != null) {
      try {
        _setSyncStatus(CloudSyncStatus.syncing);
        final batch = _firestore.batch();
        batch.update(_shopsRef!.doc(shopId), {
          'lastVisited': Timestamp.fromDate(now),
          'lastRemark': remark,
        });
        if (followUp != null && _followUpsRef != null) {
          batch.set(_followUpsRef!.doc(followUp.followUpId), followUp.toMap());
        }
        await batch.commit();
        _setSyncStatus(CloudSyncStatus.synced);
        debugPrint('Marked shop $shopId as visited (no collection) in Firestore');
      } catch (e) {
        debugPrint('Firestore markShopVisited error: $e');
        _setSyncStatus(CloudSyncStatus.offline);
      }
    }
  }

  Stream<List<FollowUpModel>> streamFollowUps({bool unresolvedOnly = false}) {
    if (_useLocalFallback || _firestore == null || _followUpsRef == null) {
      return _createLocalStream(() {
        var items = List<FollowUpModel>.from(_localFollowUps);
        if (unresolvedOnly) {
          items = items.where((f) => !f.isResolved).toList();
        }
        items.sort((a, b) => a.promiseDate.compareTo(b.promiseDate));
        return items;
      });
    }

    try {
      Query<Map<String, dynamic>> query = _followUpsRef!;
      if (unresolvedOnly) {
        query = query.where('isResolved', isEqualTo: false);
      }

      return query.snapshots().map((snapshot) {
        final list = snapshot.docs.map((doc) => FollowUpModel.fromFirestore(doc)).toList();

        for (final f in list) {
          final idx = _localFollowUps.indexWhere((l) => l.followUpId == f.followUpId);
          if (idx != -1) {
            _localFollowUps[idx] = f;
          } else {
            _localFollowUps.add(f);
          }
        }

        list.sort((a, b) => a.promiseDate.compareTo(b.promiseDate));
        return list;
      }).handleError((error) {
        debugPrint('streamFollowUps error: $error');
        var items = List<FollowUpModel>.from(_localFollowUps);
        if (unresolvedOnly) {
          items = items.where((f) => !f.isResolved).toList();
        }
        items.sort((a, b) => a.promiseDate.compareTo(b.promiseDate));
        return items;
      });
    } catch (e) {
      debugPrint('streamFollowUps exception: $e');
      return _createLocalStream(() => _localFollowUps);
    }
  }

  Future<void> resolveFollowUp(String followUpId) async {
    final index = _localFollowUps.indexWhere((f) => f.followUpId == followUpId);
    if (index != -1) {
      _localFollowUps[index] = _localFollowUps[index].copyWith(isResolved: true);
      _notifyLocalChange();
    }

    if (_firestore != null && _followUpsRef != null) {
      try {
        _setSyncStatus(CloudSyncStatus.syncing);
        await _followUpsRef!.doc(followUpId).update({'isResolved': true});
        _setSyncStatus(CloudSyncStatus.synced);
      } catch (e) {
        debugPrint('Error resolving follow-up in Firestore: $e');
        _setSyncStatus(CloudSyncStatus.offline);
      }
    }
  }

  // ===================== SEEDING / DEMO DATA =====================

  void loadInitialSeedData(
    List<ShopModel> shops,
    List<CollectionModel> collections,
    List<FollowUpModel> followUps,
  ) {
    _localShops.clear();
    _localShops.addAll(shops);
    _localCollections.clear();
    _localCollections.addAll(collections);
    _localFollowUps.clear();
    _localFollowUps.addAll(followUps);
    _notifyLocalChange();
  }
}
