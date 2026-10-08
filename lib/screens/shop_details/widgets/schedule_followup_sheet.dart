import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/shop_model.dart';
import '../../../providers/firestore_providers.dart';

class ScheduleFollowupSheet extends ConsumerStatefulWidget {
  final ShopModel shop;

  const ScheduleFollowupSheet({super.key, required this.shop});

  @override
  ConsumerState<ScheduleFollowupSheet> createState() => _ScheduleFollowupSheetState();
}

class _ScheduleFollowupSheetState extends ConsumerState<ScheduleFollowupSheet> {
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 30);
  String _selectedSlot = AppConstants.defaultTimeSlots[0];
  bool _enableReminder = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _setDatePreset(int daysFromNow) {
    setState(() {
      _selectedDate = DateTime.now().add(Duration(days: daysFromNow));
    });
  }

  Future<void> _submitFollowUp() async {
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a brief note about the promise/reason'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final notificationService = ref.read(notificationServiceProvider);

      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final followUp = await firestoreService.scheduleFollowUp(
        shopId: widget.shop.shopId,
        shopName: widget.shop.shopName,
        promiseDate: combinedDateTime,
        timeSlot: _selectedSlot,
        note: note,
      );

      // If user enabled local notification reminder
      if (_enableReminder) {
        await notificationService.scheduleFollowUpReminder(
          id: followUp.followUpId.hashCode.abs(),
          shopName: widget.shop.shopName,
          note: note,
          scheduledDate: combinedDateTime,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Follow-up scheduled for ${DateFormat('dd MMM').format(_selectedDate)}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scheduling follow-up: $e'),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Promise / Follow-up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.shop.shopName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            const SizedBox(height: 16),

            // Date Selection with Presets
            const Text(
              'Promise Date *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surfaceVariant.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Quick Date Presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    label: const Text('Tomorrow'),
                    onPressed: () => _setDatePreset(1),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('In 3 Days'),
                    onPressed: () => _setDatePreset(3),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('Next Week (+7d)'),
                    onPressed: () => _setDatePreset(7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Time Slot Selector
            const Text(
              'Preferred Time Slot *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppConstants.defaultTimeSlots.map((slot) {
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedSlot = slot);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Custom Alarm Time & Reminder Toggle
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Time: ${_selectedTime.format(context)}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Switch(
                      value: _enableReminder,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _enableReminder = val),
                    ),
                    const Text('Reminder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Note / Promise Reason
            const Text(
              'Reason / Promise Details *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'e.g. Will clear ₹3,000 on Tuesday morning when stock clears',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitFollowUp,
              icon: const Icon(Icons.notification_add_rounded, size: 18),
              label: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save & Schedule Follow-up'),
            ),
          ],
        ),
      ),
    );
  }
}
