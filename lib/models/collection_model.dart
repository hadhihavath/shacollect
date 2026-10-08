import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class CollectionModel {
  final String transactionId;
  final String shopId;
  final String shopName;
  final double amountPaid;
  final String paymentMode; // "Cash" | "GPay" | "Company Account"
  final DateTime timestamp;
  final double balanceAfter;
  final String note;

  const CollectionModel({
    required this.transactionId,
    required this.shopId,
    required this.shopName,
    required this.amountPaid,
    required this.paymentMode,
    required this.timestamp,
    required this.balanceAfter,
    this.note = '',
  });

  Color get paymentModeColor {
    switch (paymentMode) {
      case AppConstants.paymentModeCash:
        return AppColors.cashColor;
      case AppConstants.paymentModeGPay:
        return AppColors.gpayColor;
      case AppConstants.paymentModeCompanyAccount:
        return AppColors.bankColor;
      default:
        return AppColors.primary;
    }
  }

  IconData get paymentModeIcon {
    switch (paymentMode) {
      case AppConstants.paymentModeCash:
        return Icons.payments_outlined;
      case AppConstants.paymentModeGPay:
        return Icons.phone_android_outlined;
      case AppConstants.paymentModeCompanyAccount:
        return Icons.account_balance_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  CollectionModel copyWith({
    String? transactionId,
    String? shopId,
    String? shopName,
    double? amountPaid,
    String? paymentMode,
    DateTime? timestamp,
    double? balanceAfter,
    String? note,
  }) {
    return CollectionModel(
      transactionId: transactionId ?? this.transactionId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentMode: paymentMode ?? this.paymentMode,
      timestamp: timestamp ?? this.timestamp,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'shopId': shopId,
      'shopName': shopName,
      'amountPaid': amountPaid,
      'paymentMode': paymentMode,
      'timestamp': Timestamp.fromDate(timestamp),
      'balanceAfter': balanceAfter,
      'note': note,
    };
  }

  factory CollectionModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime time = DateTime.now();
    final timeRaw = map['timestamp'];
    if (timeRaw is Timestamp) {
      time = timeRaw.toDate();
    } else if (timeRaw is String) {
      time = DateTime.tryParse(timeRaw) ?? DateTime.now();
    }

    return CollectionModel(
      transactionId: map['transactionId'] as String? ?? id,
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['paymentMode'] as String? ?? AppConstants.paymentModeCash,
      timestamp: time,
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] as String? ?? '',
    );
  }

  factory CollectionModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return CollectionModel.fromMap(data, doc.id);
  }
}
