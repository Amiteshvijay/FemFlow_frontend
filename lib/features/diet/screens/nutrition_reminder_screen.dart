import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/nutrition_reminder_helper.dart';
import '../models/nutrition_reminder.dart';

class NutritionReminderScreen extends StatefulWidget {
  const NutritionReminderScreen({super.key});

  @override
  State<NutritionReminderScreen> createState() => _NutritionReminderScreenState();
}

class _NutritionReminderScreenState extends State<NutritionReminderScreen> {
  bool _isLoading = true;
  bool _remindersEnabled = false;
  List<NutritionReminder> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final enabled = await NutritionReminderHelper.areRemindersEnabled();
      final list = await NutritionReminderHelper.loadReminders();
      if (mounted) {
        setState(() {
          _remindersEnabled = enabled;
          _reminders = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load reminders.')),
        );
      }
    }
  }

  String _formatTimeOfDay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  Future<void> _toggleReminders(bool value) async {
    await NutritionReminderHelper.setRemindersEnabled(value);
    setState(() {
      _remindersEnabled = value;
    });

    if (value) {
      await NutritionReminderHelper.scheduleAll(_reminders);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily alerts scheduled!')),
        );
      }
    } else {
      await NutritionReminderHelper.cancelAll(_reminders);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily alerts disabled.')),
        );
      }
    }
  }

  Future<void> _editReminderTime(NutritionReminder reminder) async {
    final newTime = await showTimePicker(
      context: context,
      initialTime: reminder.time,
    );

    if (newTime == null) return;

    if (reminder.isCustom) {
      final updated = NutritionReminder(
        key: reminder.key,
        id: reminder.id,
        label: reminder.label,
        title: reminder.title,
        body: reminder.body,
        hour: newTime.hour,
        minute: newTime.minute,
        iconCodePoint: reminder.iconCodePoint,
        isCustom: true,
      );
      await NutritionReminderHelper.saveCustomReminder(updated);
    } else {
      await NutritionReminderHelper.updateDefaultReminderTime(reminder.key, newTime);
    }

    await _loadData();

    if (_remindersEnabled) {
      // Re-schedule all to ensure timezone and order alignment
      final updatedList = await NutritionReminderHelper.loadReminders();
      await NutritionReminderHelper.scheduleAll(updatedList);
    }
  }

  Future<void> _deleteReminder(NutritionReminder reminder) async {
    if (!reminder.isCustom) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: FemFlowColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: FemFlowColors.period, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await NutritionReminderHelper.deleteCustomReminder(reminder.key);
    await _loadData();
    
    if (_remindersEnabled) {
      final updatedList = await NutritionReminderHelper.loadReminders();
      await NutritionReminderHelper.scheduleAll(updatedList);
    }
  }

  Future<void> _addOrEditCustomReminder({NutritionReminder? existing}) async {
    final isEditing = existing != null;
    final labelController = TextEditingController(text: existing?.label ?? '');
    TimeOfDay selectedTime = existing?.time ?? const TimeOfDay(hour: 16, minute: 0);
    String reminderType = 'custom';

    if (isEditing) {
      if (existing.iconCodePoint == Icons.opacity.codePoint) {
        reminderType = 'water';
      } else if (existing.iconCodePoint == Icons.restaurant_menu.codePoint) {
        reminderType = 'meal';
      } else if (existing.iconCodePoint == Icons.apple.codePoint) {
        reminderType = 'snack';
      }
    }

    final newReminder = await showDialog<NutritionReminder?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isEditing ? 'Edit Reminder' : 'Add Reminder', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Label / Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: labelController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Pre-workout Shake',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Reminder Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: reminderType,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'meal', child: Text('Meal (Food)')),
                        DropdownMenuItem(value: 'snack', child: Text('Snack')),
                        DropdownMenuItem(value: 'water', child: Text('Water (Hydration)')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom / Other')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => reminderType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Reminder Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimeOfDay(selectedTime.hour, selectedTime.minute),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const Icon(Icons.access_time_rounded, color: FemFlowColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel', style: TextStyle(color: FemFlowColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    final label = labelController.text.trim();
                    if (label.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a name.')),
                      );
                      return;
                    }

                    int iconCode = Icons.notifications_active_outlined.codePoint;
                    String title = 'Nutrition Alert!';
                    String body = 'Keep your health consistent.';

                    switch (reminderType) {
                      case 'meal':
                        iconCode = Icons.restaurant_menu.codePoint;
                        title = 'Meal Alert!';
                        body = 'Enjoy your nourishing meal: $label';
                        break;
                      case 'snack':
                        iconCode = Icons.apple.codePoint;
                        title = 'Snack Alert!';
                        body = 'Enjoy a healthy snack: $label';
                        break;
                      case 'water':
                        iconCode = Icons.opacity.codePoint;
                        title = 'Hydration Alert!';
                        body = 'Drink a fresh glass of water: $label';
                        break;
                      default:
                        iconCode = Icons.notifications_active_outlined.codePoint;
                        title = 'Nutrition Reminder!';
                        body = 'Reminder for your nutrition plan: $label';
                    }

                    final key = isEditing ? existing.key : 'custom_${DateTime.now().millisecondsSinceEpoch}';
                    final id = isEditing ? existing.id : (DateTime.now().millisecondsSinceEpoch % 10000) + 200;

                    Navigator.pop(
                      context,
                      NutritionReminder(
                        key: key,
                        id: id,
                        label: label,
                        title: title,
                        body: body,
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                        iconCodePoint: iconCode,
                        isCustom: true,
                      ),
                    );
                  },
                  child: Text(
                    isEditing ? 'Save' : 'Add',
                    style: const TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (newReminder == null) return;

    await NutritionReminderHelper.saveCustomReminder(newReminder);
    await _loadData();

    if (_remindersEnabled) {
      final updatedList = await NutritionReminderHelper.loadReminders();
      await NutritionReminderHelper.scheduleAll(updatedList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daily Reminders',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.notifications_active_outlined, color: FemFlowColors.primary, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Enable Notifications',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                            ),
                          ],
                        ),
                        Switch(
                          value: _remindersEnabled,
                          onChanged: _toggleReminders,
                          activeTrackColor: FemFlowColors.primary.withValues(alpha: 0.5),
                          activeThumbColor: FemFlowColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Customize Timeline',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  if (_reminders.isEmpty)
                    _buildEmptyState()
                  else
                    ..._reminders.map((reminder) => _buildReminderItem(reminder)),
                  const SizedBox(height: 32),
                  if (_remindersEnabled)
                    PrimaryButton(
                      label: 'Add Custom Reminder',
                      onPressed: () => _addOrEditCustomReminder(),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildReminderItem(NutritionReminder reminder) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FemFlowColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    reminder.icon,
                    size: 18,
                    color: FemFlowColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FemFlowColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reminder.isCustom ? 'Custom Reminder' : 'System Reminder',
                      style: const TextStyle(
                        fontSize: 11,
                        color: FemFlowColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                InkWell(
                  onTap: () {
                    if (reminder.isCustom) {
                      _addOrEditCustomReminder(existing: reminder);
                    } else {
                      _editReminderTime(reminder);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: FemFlowColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _formatTimeOfDay(reminder.hour, reminder.minute),
                          style: const TextStyle(
                            color: FemFlowColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: FemFlowColors.primary),
                      ],
                    ),
                  ),
                ),
                if (reminder.isCustom) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: FemFlowColors.period, size: 20),
                    onPressed: () => _deleteReminder(reminder),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.notifications_off_outlined, color: FemFlowColors.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text(
              'No reminders configured',
              style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
