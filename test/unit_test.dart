import 'package:flutter_test/flutter_test.dart';
import 'package:sha_collects/core/utils/currency_formatter.dart';
import 'package:sha_collects/core/utils/date_formatter.dart';
import 'package:sha_collects/models/shop_model.dart';
import 'package:sha_collects/core/constants/app_constants.dart';
import 'package:sha_collects/services/firestore_service.dart';
import 'package:sha_collects/services/seed_data_service.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('formats standard INR amounts correctly', () {
      expect(CurrencyFormatter.format(5000), '₹5,000');
      expect(CurrencyFormatter.format(12500), '₹12,500');
      expect(CurrencyFormatter.format(0), '₹0');
    });

    test('formats compact amounts correctly', () {
      expect(CurrencyFormatter.formatCompact(150000), '₹1.5L');
      expect(CurrencyFormatter.formatCompact(25000), '₹25k');
    });

    test('formats PDF INR amounts correctly without unsupported unicode glyphs', () {
      expect(CurrencyFormatter.formatPdf(5000), 'Rs. 5,000');
      expect(CurrencyFormatter.formatPdf(12500), 'Rs. 12,500');
      expect(CurrencyFormatter.formatPdf(0), 'Rs. 0');
    });
  });

  group('DateFormatter Tests', () {
    test('formats relative visit times properly', () {
      expect(DateFormatter.relativeVisitTime(null), 'Not visited yet');
      final justNow = DateTime.now().subtract(const Duration(seconds: 30));
      expect(DateFormatter.relativeVisitTime(justNow), 'Just now');
      final pastDays = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.relativeVisitTime(pastDays), '3 days ago');
    });
  });

  group('ShopModel & Collection Logic Tests', () {
    test('balance status classifications work correctly', () {
      const clearedShop = ShopModel(
        shopId: 's1',
        shopName: 'Test Shop 1',
        route: 'North Route',
        contactNumber: '123',
        currentBalance: 0.0,
      );
      expect(clearedShop.isCleared, isTrue);
      expect(clearedShop.isHighOverdue, isFalse);
      expect(clearedShop.balanceBadgeText, 'Cleared');

      const highOverdueShop = ShopModel(
        shopId: 's2',
        shopName: 'Test Shop 2',
        route: 'North Route',
        contactNumber: '123',
        currentBalance: 8500.0,
      );
      expect(highOverdueShop.isHighOverdue, isTrue);
      expect(highOverdueShop.isCleared, isFalse);
      expect(highOverdueShop.balanceBadgeText, 'High Due');
    });

    test('FirestoreService records payment and updates balance accurately', () async {
      final service = FirestoreService();
      service.enableLocalFallback(true);

      const testShop = ShopModel(
        shopId: 'shop-test-1',
        shopName: 'Alpha Supermarket',
        route: 'Route A',
        contactNumber: '9999999999',
        currentBalance: 5000.0,
      );
      await service.addShop(testShop);

      // Record ₹2,000 Cash payment
      final collection = await service.recordPayment(
        shopId: testShop.shopId,
        shopName: testShop.shopName,
        amountPaid: 2000.0,
        paymentMode: 'Cash',
        note: 'Partial cash settlement',
      );

      expect(collection.amountPaid, 2000.0);
      expect(collection.balanceAfter, 3000.0);

      // Check shop balance after payment
      final updatedShop = await service.streamShop('shop-test-1').first;
      expect(updatedShop, isNotNull);
      expect(updatedShop!.currentBalance, 3000.0);
      expect(updatedShop.lastRemark, contains('Paid ₹2000 via Cash'));
    });

    test('Follow-up scheduling and resolution works correctly', () async {
      final service = FirestoreService();
      service.enableLocalFallback(true);

      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final followUp = await service.scheduleFollowUp(
        shopId: 'shop-test-1',
        shopName: 'Alpha Supermarket',
        promiseDate: tomorrow,
        timeSlot: 'Morning (9 AM - 12 PM)',
        note: 'Promise to pay balance',
      );

      expect(followUp.isResolved, isFalse);

      await service.resolveFollowUp(followUp.followUpId);

      final list = await service.streamFollowUps(unresolvedOnly: false).first;
      final resolved = list.firstWhere((f) => f.followUpId == followUp.followUpId);
      expect(resolved.isResolved, isTrue);
    });

    test('markShopVisitedNoCollection updates lastVisited without affecting balance', () async {
      final service = FirestoreService();
      service.enableLocalFallback(true);

      const testShop = ShopModel(
        shopId: 'shop-test-visited',
        shopName: 'Beta Kidswear',
        route: AppConstants.routeMonMalappuram,
        contactNumber: '8888888888',
        currentBalance: 7500.0,
      );
      await service.addShop(testShop);

      await service.markShopVisitedNoCollection(
        shopId: testShop.shopId,
        reason: 'Owner Not Available',
      );

      final updatedShop = await service.streamShop('shop-test-visited').first;
      expect(updatedShop, isNotNull);
      expect(updatedShop!.currentBalance, 7500.0); // Balance untouched
      expect(updatedShop.lastRemark, contains('Visited (No Collection): Owner Not Available'));
      expect(updatedShop.lastVisited, isNotNull);
    });

    test('SeedDataService provides complete default dataset', () {
      final shops = SeedDataService.getSampleShops();
      final collections = SeedDataService.getSampleCollections();
      final followUps = SeedDataService.getSampleFollowUps();

      expect(shops.length, greaterThanOrEqualTo(8));
      expect(collections.length, greaterThanOrEqualTo(4));
      expect(followUps.length, greaterThanOrEqualTo(3));
    });
  });
}
