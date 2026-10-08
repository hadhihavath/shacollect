import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/shop_model.dart';
import '../../../providers/firestore_providers.dart';

class MarkVisitedSheet extends ConsumerStatefulWidget {
  final ShopModel shop;

  const MarkVisitedSheet({super.key, required this.shop});

  @override
  ConsumerState<MarkVisitedSheet> createState() => _MarkVisitedSheetState();
}

class _MarkVisitedSheetState extends ConsumerState<MarkVisitedSheet> {
  final _reasonController = TextEditingController();
  String _selectedReasonPreset = 'Owner Not Available';
  bool _scheduleFollowUp = false;
  DateTime _followUpDate = DateTime.now().add(const Duration(days: 1));
  String _followUpSlot = AppConstants.defaultTimeSlots[0];
  bool _isSubmitting = false;

  final List<String> _reasonPresets = [
    'Owner Not Available',
    'Revisit Tomorrow',
    'Stock Checking in Progress',
    'Bank Transfer Later Today',
    'Promised on Next Visit',
    'Shop Closed Temporarily',
  ];

  @override
  void initState() {
    super.initState();
    _reasonController.text = _selectedReasonPreset;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _followUpDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select or enter a visit remark/reason'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.markShopVisitedNoCollection(
        shopId: widget.shop.shopId,
        reason: reason,
        nextFollowUpDate: _scheduleFollowUp ? _followUpDate : null,
        followUpTimeSlot: _scheduleFollowUp ? _followUpSlot : null,
      );

      if (_scheduleFollowUp) {
        final notificationService = ref.read(notificationServiceProvider);
        final reminderTime = DateTime(
          _followUpDate.year,
          _followUpDate.month,
          _followUpDate.day,
          9,
          30,
        );
        await notificationService.scheduleFollowUpReminder(
          id: widget.shop.shopId.hashCode.abs() % 100000,
          shopName: widget.shop.shopName,
          note: 'Visit reminder: $reason',
          scheduledDate: reminderTime,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marked "${widget.shop.shopName}" as Visited (No Collection)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record visit: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.event_busy_rounded, color: AppColors.warning, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Mark Visited (No Collection)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.shop.shopName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Balance & Notice Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Visit Log',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Current Pending Due: ${CurrencyFormatter.format(widget.shop.currentBalance)}. Logging this visit updates the last visited timestamp without affecting the balance.',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason presets chips
            const Text(
              'Select Visit Reason / Remark *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasonPresets.map((reason) {
                final isSelected = _selectedReasonPreset == reason;
                return ChoiceChip(
                  label: Text(reason),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedReasonPreset = reason;
                        _reasonController.text = reason;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Custom Remark Field
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Visit Remark / Note',
                hintText: 'Enter details or shopkeeper statement...',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 14),

            // Follow-up toggle card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Schedule Follow-up Reminder',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Get notified to collect or revisit this store',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    value: _scheduleFollowUp,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => setState(() => _scheduleFollowUp = val),
                  ),
                  if (_scheduleFollowUp) ...[
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month_rounded, size: 16),
                            label: Text(
                              DateFormat('dd MMM yyyy').format(_followUpDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _followUpSlot,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: AppConstants.defaultTimeSlots.map((slot) {
                              return DropdownMenuItem(
                                value: slot,
                                child: Text(
                                  slot.split(' ')[0], // Morning, Afternoon, etc.
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _followUpSlot = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Submit Button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text('Confirm Visited'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
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
