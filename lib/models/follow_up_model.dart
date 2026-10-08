import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpModel {
  final String followUpId;
  final String shopId;
  final String shopName;
  final DateTime promiseDate;
  final String timeSlot;
  final String note;
  final bool isResolved;
  final DateTime createdAt;

  const FollowUpModel({
    required this.followUpId,
    required this.shopId,
    required this.shopName,
    required this.promiseDate,
    required this.timeSlot,
    required this.note,
    this.isResolved = false,
    required this.createdAt,
  });

  bool get isOverdue {
    if (isResolved) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(promiseDate.year, promiseDate.month, promiseDate.day);
    return target.isBefore(today);
  }

  bool get isDueToday {
    if (isResolved) return false;
    final now = DateTime.now();
    return promiseDate.year == now.year &&
        promiseDate.month == now.month &&
        promiseDate.day == now.day;
  }

  FollowUpModel copyWith({
    String? followUpId,
    String? shopId,
    String? shopName,
    DateTime? promiseDate,
    String? timeSlot,
    String? note,
    bool? isResolved,
    DateTime? createdAt,
  }) {
    return FollowUpModel(
      followUpId: followUpId ?? this.followUpId,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      promiseDate: promiseDate ?? this.promiseDate,
      timeSlot: timeSlot ?? this.timeSlot,
      note: note ?? this.note,
      isResolved: isResolved ?? this.isResolved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'followUpId': followUpId,
      'shopId': shopId,
      'shopName': shopName,
      'promiseDate': Timestamp.fromDate(promiseDate),
      'timeSlot': timeSlot,
      'note': note,
      'isResolved': isResolved,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory FollowUpModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime pDate = DateTime.now();
    final pDateRaw = map['promiseDate'];
    if (pDateRaw is Timestamp) {
      pDate = pDateRaw.toDate();
    } else if (pDateRaw is String) {
      pDate = DateTime.tryParse(pDateRaw) ?? DateTime.now();
    }

    DateTime cDate = DateTime.now();
    final cDateRaw = map['createdAt'];
    if (cDateRaw is Timestamp) {
      cDate = cDateRaw.toDate();
    } else if (cDateRaw is String) {
      cDate = DateTime.tryParse(cDateRaw) ?? DateTime.now();
    }

    return FollowUpModel(
      followUpId: map['followUpId'] as String? ?? id,
      shopId: map['shopId'] as String? ?? '',
      shopName: map['shopName'] as String? ?? '',
      promiseDate: pDate,
      timeSlot: map['timeSlot'] as String? ?? 'Anytime During Route',
      note: map['note'] as String? ?? '',
      isResolved: map['isResolved'] as bool? ?? false,
      createdAt: cDate,
    );
  }

  factory FollowUpModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return FollowUpModel.fromMap(data, doc.id);
  }
}
