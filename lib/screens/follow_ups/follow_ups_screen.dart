import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/follow_up_model.dart';
import '../../providers/firestore_providers.dart';
import '../shop_details/shop_details_screen.dart';

class FollowUpsScreen extends ConsumerStatefulWidget {
  const FollowUpsScreen({super.key});

  @override
  ConsumerState<FollowUpsScreen> createState() => _FollowUpsScreenState();
}

class _FollowUpsScreenState extends ConsumerState<FollowUpsScreen> {
  int _selectedFilterIndex = 0; // 0: Pending, 1: Today/Overdue, 2: Resolved

  @override
  Widget build(BuildContext context) {
    final followUpsAsync = ref.watch(followUpsStreamProvider);
    final followUps = followUpsAsync.value ?? [];

    List<FollowUpModel> filteredList = [];
    if (_selectedFilterIndex == 0) {
      filteredList = followUps.where((f) => !f.isResolved).toList();
    } else if (_selectedFilterIndex == 1) {
      filteredList = followUps.where((f) => !f.isResolved && (f.isDueToday || f.isOverdue)).toList();
    } else {
      filteredList = followUps.where((f) => f.isResolved).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Promised Follow-ups'),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip(index: 0, title: 'All Pending'),
                const SizedBox(width: 8),
                _filterChip(index: 1, title: 'Today / Overdue', highlight: true),
                const SizedBox(width: 8),
                _filterChip(index: 2, title: 'Resolved'),
              ],
            ),
          ),

          // Follow-ups List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No follow-ups in this view',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _followUpCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required int index, required String title, bool highlight = false}) {
    final isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (highlight ? AppColors.danger.withOpacity(0.12) : AppColors.primary)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? (highlight ? AppColors.danger : AppColors.primary)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (highlight ? AppColors.danger : Colors.white)
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _followUpCard(FollowUpModel item) {
    Color statusColor = AppColors.primary;
    String statusLabel = 'Upcoming';

    if (item.isResolved) {
      statusColor = AppColors.success;
      statusLabel = 'Resolved';
    } else if (item.isOverdue) {
      statusColor = AppColors.danger;
      statusLabel = 'Overdue';
    } else if (item.isDueToday) {
      statusColor = AppColors.warning;
      statusLabel = 'Due Today';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (item.isOverdue || item.isDueToday) ? statusColor.withOpacity(0.4) : AppColors.border,
          width: 1.2,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.shopName,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.event_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  '${DateFormat('dd MMM yyyy').format(item.promiseDate)} • ${item.timeSlot}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.note,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!item.isResolved)
                  TextButton.icon(
                    onPressed: () async {
                      final firestoreService = ref.read(firestoreServiceProvider);
                      await firestoreService.resolveFollowUp(item.followUpId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Follow-up marked as resolved')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Mark Done', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => ShopDetailsScreen(shopId: item.shopId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.storefront_rounded, size: 14),
                  label: const Text('Open Shop', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
