import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class ShopModel {
  final String shopId;
  final String shopName;
  final String route;
  final String contactNumber;
  final double currentBalance;
  final String lastRemark;
  final DateTime? lastVisited;
  final String ownerName;
  final String address;
  final String city;
  final int stopOrder;

  const ShopModel({
    required this.shopId,
    required this.shopName,
    required this.route,
    required this.contactNumber,
    required this.currentBalance,
    this.lastRemark = '',
    this.lastVisited,
    this.ownerName = '',
    this.address = '',
    this.city = '',
    this.stopOrder = 1,
  });

  bool get isCleared => currentBalance <= 0;
  bool get isHighOverdue => currentBalance >= 5000;
  bool get isModerateBalance => currentBalance > 0 && currentBalance < 5000;

  Color get balanceBadgeColor {
    if (isCleared) return AppColors.success;
    if (isHighOverdue) return AppColors.danger;
    return AppColors.warning;
  }

  String get balanceBadgeText {
    if (isCleared) return 'Cleared';
    if (isHighOverdue) return 'High Due';
    return 'Pending';
  }

  Uri get googleMapsUri {
    final query = Uri.encodeComponent('$shopName, ${address.isNotEmpty ? address : city}, Kerala');
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
  }

  ShopModel copyWith({
    String? shopId,
    String? shopName,
    String? route,
    String? contactNumber,
    double? currentBalance,
    String? lastRemark,
    DateTime? lastVisited,
    String? ownerName,
    String? address,
    String? city,
    int? stopOrder,
  }) {
    return ShopModel(
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      route: route ?? this.route,
      contactNumber: contactNumber ?? this.contactNumber,
      currentBalance: currentBalance ?? this.currentBalance,
      lastRemark: lastRemark ?? this.lastRemark,
      lastVisited: lastVisited ?? this.lastVisited,
      ownerName: ownerName ?? this.ownerName,
      address: address ?? this.address,
      city: city ?? this.city,
      stopOrder: stopOrder ?? this.stopOrder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'route': route,
      'contactNumber': contactNumber,
      'currentBalance': currentBalance,
      'lastRemark': lastRemark,
      'lastVisited': lastVisited != null ? Timestamp.fromDate(lastVisited!) : null,
      'ownerName': ownerName,
      'address': address,
      'city': city,
      'stopOrder': stopOrder,
    };
  }

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? visited;
    final lastVisitedRaw = map['lastVisited'];
    if (lastVisitedRaw is Timestamp) {
      visited = lastVisitedRaw.toDate();
    } else if (lastVisitedRaw is String) {
      visited = DateTime.tryParse(lastVisitedRaw);
    }

    return ShopModel(
      shopId: map['shopId'] as String? ?? id,
      shopName: map['shopName'] as String? ?? 'Unnamed Store',
      route: map['route'] as String? ?? 'Unassigned Route',
      contactNumber: map['contactNumber'] as String? ?? '',
      currentBalance: (map['currentBalance'] as num?)?.toDouble() ?? 0.0,
      lastRemark: map['lastRemark'] as String? ?? '',
      lastVisited: visited,
      ownerName: map['ownerName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      stopOrder: (map['stopOrder'] as num?)?.toInt() ?? 1,
    );
  }

  factory ShopModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return ShopModel.fromMap(data, doc.id);
  }
}
