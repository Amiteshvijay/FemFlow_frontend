import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/pill_reminder_service.dart';
import 'models/pill_reminder_models.dart';
import 'create_pill_reminder_screen.dart';

class PillReminderDetailScreen extends StatefulWidget {
  final Medication reminder;
  const PillReminderDetailScreen({super.key, required this.reminder});

  @override
  State<PillReminderDetailScreen> createState() => _PillReminderDetailScreenState();
}

class _PillReminderDetailScreenState extends State<PillReminderDetailScreen> {
  final PillReminderService _service = PillReminderService();
  late Medication _reminder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reminder = widget.reminder;
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final updatedReminder = await _service.getMedication(_reminder.id);
      if (!mounted) return;
      setState(() {
        _reminder = updatedReminder;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication? This will also remove upcoming reminders.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteMedication(_reminder.id);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _logPrn() async {
    try {
      await _service.logPrn(_reminder.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dose logged.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: Text(_reminder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreatePillReminderScreen(reminder: _reminder)),
            ).then((_) => _fetchDetails()),
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Schedule & Frequency'),
                  _buildScheduleCard(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Instructions & Notes'),
                  _buildInfoCard(),
                  const SizedBox(height: 32),
                  if (_reminder.repeatType == 'prn')
                    PrimaryButton(
                      label: 'Log Dose Now (PRN)',
                      onPressed: _logPrn,
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary, fontSize: 13)),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: FemLyraColors.primary.withValues(alpha: 0.1),
            child: Icon(_getMedicineIcon(_reminder.medicineType), color: FemLyraColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_reminder.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(_reminder.dosageValue ?? 'No dosage info', style: const TextStyle(color: FemLyraColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    return AppCard(
      child: Column(
        children: [
          _row('Repeat', _reminder.repeatType.toUpperCase()),
          const Divider(),
          _row('Doses', '${_reminder.timings.length} per day'),
          const Divider(),
          Column(
            children: _reminder.timings.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _row(t.label, t.time),
            )).toList(),
          ),
          const Divider(),
          _row('Start Date', DateFormat('dd MMM yyyy').format(_reminder.startDate)),
          if (!_reminder.isOngoing && _reminder.endDate != null) ...[
            const Divider(),
            _row('End Date', DateFormat('dd MMM yyyy').format(_reminder.endDate!)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Food', _reminder.instructions.toUpperCase()),
          if (_reminder.notes != null && _reminder.notes!.isNotEmpty) ...[
            const Divider(),
            const Text('Notes', style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
            const SizedBox(height: 4),
            Text(_reminder.notes!, style: const TextStyle(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: FemLyraColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getMedicineIcon(String type) {
    switch (type) {
      case 'pill': return Icons.medication;
      case 'capsule': return Icons.medication_liquid;
      case 'tablet': return Icons.medication;
      case 'syrup': return Icons.liquor;
      case 'injection': return Icons.vaccines;
      default: return Icons.medication;
    }
  }
}
