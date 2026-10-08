import '../models/shop_model.dart';
import '../models/collection_model.dart';
import '../models/follow_up_model.dart';
import '../core/constants/app_constants.dart';

class SeedDataService {
  static List<ShopModel> getSampleShops() {
    final now = DateTime.now();

    return [
      // ==================== MONDAY - MALAPPURAM ====================
      ShopModel(
        shopId: 'shop-mlp-001',
        shopName: 'Tiny Toes Kids Wear',
        ownerName: 'Rashid Manjeri',
        route: AppConstants.routeMonMalappuram,
        contactNumber: '+91 98450 11223',
        currentBalance: 12500.0,
        lastRemark: 'Tiny Fab Summer Kidswear stock delivered. Promised 50% recovery today.',
        lastVisited: now.subtract(const Duration(days: 7)),
        address: 'Near Old Bus Stand, Kottakkal',
        city: 'Kottakkal',
        stopOrder: 1,
      ),
      ShopModel(
        shopId: 'shop-mlp-002',
        shopName: 'Junior Kingdom Childrens Boutique',
        ownerName: 'Ibrahim Kutty',
        route: AppConstants.routeMonMalappuram,
        contactNumber: '+91 98765 43210',
        currentBalance: 3200.0,
        lastRemark: 'Paid ₹2,800 via GPay last cycle. Baby frocks & shirts in high demand.',
        lastVisited: now.subtract(const Duration(hours: 3)),
        address: 'Gulf Bazaar Road, Tirur',
        city: 'Tirur',
        stopOrder: 2,
      ),
      ShopModel(
        shopId: 'shop-mlp-003',
        shopName: 'Little Angels Fashions',
        ownerName: 'Musthafa Kamal',
        route: AppConstants.routeMonMalappuram,
        contactNumber: '+91 94471 22334',
        currentBalance: 8400.0,
        lastRemark: 'Check clearing on Tuesday. Requires additional Tiny Fab newborn sets.',
        lastVisited: now.subtract(const Duration(days: 4)),
        address: 'Pandikkad Road Junction, Manjeri',
        city: 'Manjeri',
        stopOrder: 3,
      ),

      // ==================== TUESDAY - MALAPPURAM ====================
      ShopModel(
        shopId: 'shop-mlp-004',
        shopName: 'Baby Land Kids Showroom',
        ownerName: 'Sujith Kumar',
        route: AppConstants.routeTueMalappuram,
        contactNumber: '+91 99223 34455',
        currentBalance: 14200.0,
        lastRemark: 'Large festive kidswear order balance. Owner requested collection after 3 PM.',
        lastVisited: now.subtract(const Duration(days: 6)),
        address: 'Calicut Road, Perinthalmanna',
        city: 'Perinthalmanna',
        stopOrder: 1,
      ),
      ShopModel(
        shopId: 'shop-mlp-005',
        shopName: 'Chotta Bheem Baby World',
        ownerName: 'Nizar Nilambur',
        route: AppConstants.routeTueMalappuram,
        contactNumber: '+91 97455 66778',
        currentBalance: 0.0,
        lastRemark: 'Account fully settled! Excellent regular Tiny Fab customer.',
        lastVisited: now.subtract(const Duration(days: 1)),
        address: 'Chandakkunnu, Nilambur',
        city: 'Nilambur',
        stopOrder: 2,
      ),
      ShopModel(
        shopId: 'shop-mlp-006',
        shopName: 'Honey Bee Kidswear & Garments',
        ownerName: 'Basheer Kondotty',
        route: AppConstants.routeTueMalappuram,
        contactNumber: '+91 98950 88990',
        currentBalance: 4800.0,
        lastRemark: 'Will clear balance during airport bypass route run.',
        lastVisited: now.subtract(const Duration(days: 5)),
        address: 'Main Market, Kondotty',
        city: 'Kondotty',
        stopOrder: 3,
      ),

      // ==================== WEDNESDAY: KANNUR ====================
      ShopModel(
        shopId: 'shop-knr-001',
        shopName: 'Panda Kidswear & Toys',
        ownerName: 'Sunil Thalassery',
        route: AppConstants.routeWedKannur,
        contactNumber: '+91 94460 77112',
        currentBalance: 9600.0,
        lastRemark: 'Tiny Fab girls party wear sold out. Promised transfer to Company Account.',
        lastVisited: now.subtract(const Duration(days: 2)),
        address: 'Logans Road, Thalassery',
        city: 'Thalassery',
        stopOrder: 1,
      ),
      ShopModel(
        shopId: 'shop-knr-002',
        shopName: 'Smart Kidz Boutique',
        ownerName: 'Vinod Nair',
        route: AppConstants.routeWedKannur,
        contactNumber: '+91 98472 33445',
        currentBalance: 16800.0,
        lastRemark: 'High balance pending for 2 weeks. Collect ₹10,000 Cheque.',
        lastVisited: now.subtract(const Duration(days: 3)),
        address: 'Fort Road, Kannur City',
        city: 'Kannur',
        stopOrder: 2,
      ),

      // ==================== THURSDAY: KANNUR ====================
      ShopModel(
        shopId: 'shop-knr-003',
        shopName: 'First Cry & Kids Plaza',
        ownerName: 'Santhosh Payyanur',
        route: AppConstants.routeThuKannur,
        contactNumber: '+91 94951 88223',
        currentBalance: 5200.0,
        lastRemark: 'Regular weekly payment route for Tiny Fab cotton essentials.',
        lastVisited: now.subtract(const Duration(days: 4)),
        address: 'Perumba, Payyanur',
        city: 'Payyanur',
        stopOrder: 1,
      ),
      ShopModel(
        shopId: 'shop-knr-004',
        shopName: 'Little Star Textiles & Kidswear',
        ownerName: 'Hamza Mattannur',
        route: AppConstants.routeThuKannur,
        contactNumber: '+91 97440 99112',
        currentBalance: 7300.0,
        lastRemark: 'Visit during airport road return leg.',
        lastVisited: now.subtract(const Duration(days: 6)),
        address: 'Near Bus Stand, Mattannur',
        city: 'Mattannur',
        stopOrder: 2,
      ),

      // ==================== FRIDAY: KOZHIKODE ====================
      ShopModel(
        shopId: 'shop-clt-001',
        shopName: 'Tiny Fab Brand Retailer - Calicut',
        ownerName: 'Farhan SM',
        route: AppConstants.routeFriKozhikode,
        contactNumber: '+91 98460 55667',
        currentBalance: 18500.0,
        lastRemark: 'Key distributor counter on SM Street. Promised ₹12,000 cash collection.',
        lastVisited: now.subtract(const Duration(hours: 5)),
        address: 'Sweet Meat (SM) Street, Kozhikode',
        city: 'Kozhikode',
        stopOrder: 1,
      ),
      ShopModel(
        shopId: 'shop-clt-002',
        shopName: 'Apple Kids Collection',
        ownerName: 'Manaf Calicut',
        route: AppConstants.routeFriKozhikode,
        contactNumber: '+91 99951 44332',
        currentBalance: 4100.0,
        lastRemark: 'Paid ₹3,500 Cash on last Friday. Balance remaining.',
        lastVisited: now.subtract(const Duration(hours: 2)),
        address: 'Mavoor Road Junction, Kozhikode',
        city: 'Kozhikode',
        stopOrder: 2,
      ),

      // ==================== SATURDAY: KOZHIKODE ====================
      ShopModel(
        shopId: 'shop-clt-003',
        shopName: 'Minions Baby & Kids Wear',
        ownerName: 'Raju Vadakara',
        route: AppConstants.routeSatKozhikode,
        contactNumber: '+91 98470 66554',
        currentBalance: 6500.0,
        lastRemark: 'Saturday afternoon recovery. Ready with GPay.',
        lastVisited: now.subtract(const Duration(days: 5)),
        address: 'Old Bus Stand, Vadakara',
        city: 'Vadakara',
        stopOrder: 1,
      ),
      ShopModel(
        shopId: 'shop-clt-004',
        shopName: 'Little Wonders Kidswear',
        ownerName: 'Ashraf Koyilandy',
        route: AppConstants.routeSatKozhikode,
        contactNumber: '+91 94475 11998',
        currentBalance: 2900.0,
        lastRemark: 'Prompt payer. Place new catalogue order for Tiny Fab winter wear.',
        lastVisited: now.subtract(const Duration(days: 6)),
        address: 'Main Road, Koyilandy',
        city: 'Koyilandy',
        stopOrder: 2,
      ),
    ];
  }

  static List<CollectionModel> getSampleCollections() {
    final now = DateTime.now();

    return [
      CollectionModel(
        transactionId: 'tx-tf-101',
        shopId: 'shop-clt-001',
        shopName: 'Tiny Fab Brand Retailer - Calicut',
        amountPaid: 6500.0,
        paymentMode: AppConstants.paymentModeCash,
        timestamp: DateTime(now.year, now.month, now.day, 10, 30),
        balanceAfter: 18500.0,
        note: 'Cash received on SM Street counter.',
      ),
      CollectionModel(
        transactionId: 'tx-tf-102',
        shopId: 'shop-clt-002',
        shopName: 'Apple Kids Collection',
        amountPaid: 3500.0,
        paymentMode: AppConstants.paymentModeGPay,
        timestamp: DateTime(now.year, now.month, now.day, 11, 45),
        balanceAfter: 4100.0,
        note: 'GPay Ref #GP392819 for Tiny Fab batch #204.',
      ),
      CollectionModel(
        transactionId: 'tx-tf-103',
        shopId: 'shop-mlp-002',
        shopName: 'Junior Kingdom Childrens Boutique',
        amountPaid: 2800.0,
        paymentMode: AppConstants.paymentModeGPay,
        timestamp: DateTime(now.year, now.month, now.day, 13, 15),
        balanceAfter: 3200.0,
        note: 'UPI payment cleared.',
      ),
      CollectionModel(
        transactionId: 'tx-tf-104',
        shopId: 'shop-knr-001',
        shopName: 'Panda Kidswear & Toys',
        amountPaid: 5000.0,
        paymentMode: AppConstants.paymentModeCompanyAccount,
        timestamp: DateTime(now.year, now.month, now.day, 15, 10),
        balanceAfter: 9600.0,
        note: 'Bank transfer to Tiny Fab company account.',
      ),
    ];
  }

  static List<FollowUpModel> getSampleFollowUps() {
    final now = DateTime.now();

    return [
      FollowUpModel(
        followUpId: 'fu-tf-201',
        shopId: 'shop-mlp-001',
        shopName: 'Tiny Toes Kids Wear',
        promiseDate: now.add(const Duration(days: 1)),
        timeSlot: 'Morning (9 AM - 12 PM)',
        note: 'Will clear ₹6,000 when morning kidswear sales cash accumulates.',
        isResolved: false,
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      FollowUpModel(
        followUpId: 'fu-tf-202',
        shopId: 'shop-knr-002',
        shopName: 'Smart Kidz Boutique',
        promiseDate: now,
        timeSlot: 'Afternoon (12 PM - 4 PM)',
        note: 'Proprietor promised ₹10,000 cheque during Fort Road visit.',
        isResolved: false,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      FollowUpModel(
        followUpId: 'fu-tf-203',
        shopId: 'shop-clt-003',
        shopName: 'Minions Baby & Kids Wear',
        promiseDate: now.add(const Duration(days: 2)),
        timeSlot: 'Evening (4 PM - 8 PM)',
        note: 'Will settle balance on Saturday route in Vadakara.',
        isResolved: false,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
