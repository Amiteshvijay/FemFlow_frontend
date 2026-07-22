import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../core/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'data/reminder_service.dart' as service;

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final service.ReminderService _reminderService = service.ReminderService();
  final NotificationService _notificationService = NotificationService();
  List<service.Reminder> _reminders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchReminders();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final granted = await _notificationService.requestPermissions();
    if (!granted && mounted) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications Disabled'),
        content: const Text('Please enable notifications to receive reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchReminders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final reminders = await _reminderService.getReminders();
      setState(() {
        _reminders = reminders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load reminders';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReminder(service.Reminder reminder) async {
    try {
      await _reminderService.updateReminder(reminder.id!, {'is_active': !reminder.isActive});
      _fetchReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update reminder')));
    }
  }

  Future<void> _deleteReminder(int id) async {
    try {
      await _reminderService.deleteReminder(id);
      _fetchReminders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete reminder')));
    }
  }

  void _showReminderSheet({service.Reminder? reminder}) {
    final isEditing = reminder != null;
    final titleController = TextEditingController(text: reminder?.title);
    final scheduleController = TextEditingController(text: reminder?.scheduleText);
    String type = reminder?.reminderType ?? 'period';
    String repeatType = reminder?.repeatType ?? 'daily';
    TimeOfDay selectedTime = isEditing 
        ? TimeOfDay(
            hour: int.parse(reminder.time.split(':')[0]), 
            minute: int.parse(reminder.time.split(':')[1]))
        : TimeOfDay.now();
    DateTime? selectedDate = reminder?.specificDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEditing ? 'Edit Reminder' : 'Add Reminder', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Vitamin D')),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Category', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary))),
                DropdownButton<String>(
                  value: type,
                  isExpanded: true,
                  items: ['period', 'ovulation', 'pill', 'log_data', 'custom']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t[0].toUpperCase() + t.substring(1)))).toList(),
                  onChanged: (val) => setModalState(() => type = val!),
                ),
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Repeat', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary))),
                DropdownButton<String>(
                  value: repeatType,
                  isExpanded: true,
                  items: [
                    {'value': 'daily', 'label': 'Daily'},
                    {'value': 'once', 'label': 'Once'},
                    {'value': 'period_relative', 'label': 'Period Relative'},
                  ].map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                  onChanged: (val) => setModalState(() => repeatType = val!),
                ),
                if (repeatType == 'once')
                  ListTile(
                    title: Text(selectedDate == null ? 'Select Date' : 'Date: ${DateFormat('d MMM yyyy').format(selectedDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365)));
                      if (date != null) setModalState(() => selectedDate = date);
                    },
                  ),
                if (repeatType == 'period_relative')
                   TextField(controller: scheduleController, decoration: const InputDecoration(labelText: 'Offset', hintText: 'e.g. Day before')),
                ListTile(
                  title: Text('Time: ${selectedTime.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(context: context, initialTime: selectedTime);
                    if (time != null) setModalState(() => selectedTime = time);
                  },
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: isEditing ? 'Update Reminder' : 'Save Reminder',
                  onPressed: () async {
                    if (titleController.text.isEmpty) return;
                    
                    final reminderData = service.Reminder(
                      id: reminder?.id,
                      title: titleController.text,
                      reminderType: type,
                      repeatType: repeatType,
                      scheduleText: repeatType == 'period_relative' ? scheduleController.text : (repeatType == 'once' ? 'One-time' : 'Daily'),
                      time: "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                      specificDate: selectedDate,
                      weekdays: reminder?.weekdays ?? '',
                      isActive: reminder?.isActive ?? true,
                    );
                    
                    if (isEditing) {
                      await _reminderService.updateReminder(reminder.id!, reminderData.toJson());
                    } else {
                      await _reminderService.createReminder(reminderData);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      _fetchReminders();
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _fetchReminders, child: const Text('Retry')),
                      ],
                    ),
                  )
                : Column(
                    children: [
                  Expanded(
                    child: _reminders.isEmpty
                        ? const Center(child: Text('No reminders yet'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _reminders.length,
                            itemBuilder: (context, index) {
                              final reminder = _reminders[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () => _showReminderSheet(reminder: reminder),
                                  borderRadius: BorderRadius.circular(24),
                                  child: _buildReminderCard(
                                    reminder: reminder,
                                    onToggle: () => _toggleReminder(reminder),
                                    onDelete: () => _deleteReminder(reminder.id!),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: PrimaryButton(
                      label: '+ Add Reminder',
                      onPressed: () => _showReminderSheet(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'period': return Icons.water_drop_outlined;
      case 'ovulation': return Icons.adjust;
      case 'pill': return Icons.medication_outlined;
      case 'log_data': return Icons.edit_note_outlined;
      default: return Icons.notifications_none;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'period': return FemFlowColors.period;
      case 'ovulation': return FemFlowColors.ovulation;
      case 'pill': return FemFlowColors.textSecondary;
      case 'log_data': return FemFlowColors.primary;
      default: return FemFlowColors.textMuted;
    }
  }

  Widget _buildReminderCard({
    required service.Reminder reminder,
    required VoidCallback onToggle,
    required VoidCallback onDelete,
  }) {
    final icon = _getIconForType(reminder.reminderType);
    final iconColor = _getColorForType(reminder.reminderType);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: FemFlowColors.textPrimary,
                  ),
                ),
                Text(
                  '${reminder.scheduleText} · ${reminder.time}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: FemFlowColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder.isActive,
            onChanged: (val) => onToggle(),
            activeThumbColor: FemFlowColors.white,
            activeTrackColor: FemFlowColors.primary,
            inactiveThumbColor: FemFlowColors.white,
            inactiveTrackColor: FemFlowColors.border,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: FemFlowColors.textMuted, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Reminder'),
                  content: const Text('Are you sure you want to delete this reminder?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    }, child: const Text('Delete', style: TextStyle(color: FemFlowColors.period))),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
