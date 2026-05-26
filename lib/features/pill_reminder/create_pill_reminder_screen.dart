import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/pill_reminder_service.dart';
import 'models/pill_reminder_models.dart';
import 'package:intl/intl.dart';

class CreatePillReminderScreen extends StatefulWidget {
  final Medication? reminder; 
  const CreatePillReminderScreen({super.key, this.reminder});

  @override
  State<CreatePillReminderScreen> createState() => _CreatePillReminderScreenState();
}

class _CreatePillReminderScreenState extends State<CreatePillReminderScreen> {
  final PillReminderService _service = PillReminderService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _medicineType = 'pill';
  String _instructions = 'none';
  String _repeatType = 'daily';
  
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isOngoing = true;
  
  List<MedicationTiming> _timings = [
    MedicationTiming(time: '08:00', label: 'Morning', doseQuantity: 1.0)
  ];

  Map<String, dynamic> _repeatPattern = {};

  bool _isSaving = false;
  bool _notificationsEnabled = true;
  String _notificationSound = 'default';

  final List<Map<String, String>> _medicineTypes = [
    {'value': 'pill', 'label': 'Pill'},
    {'value': 'capsule', 'label': 'Capsule'},
    {'value': 'tablet', 'label': 'Tablet'},
    {'value': 'syrup', 'label': 'Syrup'},
    {'value': 'injection', 'label': 'Injection'},
    {'value': 'supplement', 'label': 'Supplement'},
    {'value': 'other', 'label': 'Other'},
  ];

  final List<Map<String, String>> _foodInstructions = [
    {'value': 'none', 'label': 'No Preference'},
    {'value': 'before', 'label': 'Before Food'},
    {'value': 'after', 'label': 'After Food'},
    {'value': 'with', 'label': 'With Food'},
    {'value': 'empty', 'label': 'Empty Stomach'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.reminder != null) {
      final r = widget.reminder!;
      _nameController.text = r.name;
      _dosageController.text = r.dosageValue ?? '';
      _notesController.text = r.notes ?? '';
      _medicineType = r.medicineType;
      _instructions = r.instructions;
      _repeatType = r.repeatType;
      _startDate = r.startDate;
      _endDate = r.endDate;
      _isOngoing = r.isOngoing;
      _timings = List.from(r.timings);
      _repeatPattern = Map.from(r.repeatPattern);
      _notificationsEnabled = r.notificationEnabled;
      _notificationSound = r.repeatPattern['notification_sound'] ?? 'default';
    }
  }

  void _addTiming() {
    setState(() {
      _timings.add(MedicationTiming(time: '12:00', label: 'Dose ${_timings.length + 1}', doseQuantity: 1.0));
    });
  }

  void _removeTiming(int index) {
    if (_timings.length > 1) {
      setState(() => _timings.removeAt(index));
    }
  }

  Future<void> _selectTime(int index) async {
    final currentParts = _timings[index].time.split(':');
    final initialTime = TimeOfDay(hour: int.parse(currentParts[0]), minute: int.parse(currentParts[1]));
    
    final picked = await showTimePicker(context: context, initialTime: initialTime);
    if (picked != null) {
      setState(() {
        final timeStr = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
        _timings[index] = MedicationTiming(
          time: timeStr,
          label: _getLabelForTime(picked),
          doseQuantity: _timings[index].doseQuantity,
        );
      });
    }
  }

  String _getLabelForTime(TimeOfDay time) {
    if (time.hour >= 5 && time.hour < 11) return 'Morning';
    if (time.hour >= 11 && time.hour < 16) return 'Afternoon';
    if (time.hour >= 16 && time.hour < 21) return 'Evening';
    return 'Night';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final medication = Medication(
      id: widget.reminder?.id ?? 0,
      name: _nameController.text.trim(),
      medicineType: _medicineType,
      dosageValue: _dosageController.text.trim(),
      instructions: _instructions,
      repeatType: _repeatType,
      repeatPattern: {
        ..._repeatPattern,
        'notification_sound': _notificationSound,
      },
      startDate: _startDate,
      endDate: _isOngoing ? null : _endDate,
      isOngoing: _isOngoing,
      isActive: true,
      notificationEnabled: _notificationsEnabled,
      isSecret: false,
      notes: _notesController.text.trim(),
      timings: _timings,
    );

    try {
      if (widget.reminder != null) {
        await _service.updateMedication(widget.reminder!.id, medication.toJson());
      } else {
        await _service.createMedication(medication);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Add Medication' : 'Edit Medication'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfo(),
              const SizedBox(height: 24),
              _buildRepeatSection(),
              const SizedBox(height: 24),
              if (_repeatType != 'prn') _buildTimingSection(),
              const SizedBox(height: 24),
              _buildDurationSection(),
              const SizedBox(height: 24),
              _buildAdditionalInfo(),
              const SizedBox(height: 40),
              PrimaryButton(
                label: _isSaving ? 'Saving...' : 'Save Medication',
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfo() {
    return AppCard(
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Medicine Name *', border: OutlineInputBorder()),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _medicineType,
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
            items: _medicineTypes.map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
            onChanged: (v) => setState(() => _medicineType = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _dosageController,
            decoration: const InputDecoration(labelText: 'Dosage (e.g. 500mg, 1 tablet)', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        AppCard(
          child: DropdownButtonFormField<String>(
            initialValue: _repeatType,
            decoration: const InputDecoration(border: InputBorder.none),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              DropdownMenuItem(value: 'once', child: Text('Once')),
              DropdownMenuItem(value: 'custom', child: Text('Custom Interval')),
              DropdownMenuItem(value: 'prn', child: Text('As Needed (PRN)')),
            ],
            onChanged: (v) => setState(() {
              _repeatType = v!;
              if (_repeatType == 'weekly' && _repeatPattern['days'] == null) {
                _repeatPattern['days'] = [DateTime.now().weekday - 1];
              }
            }),
          ),
        ),
        if (_repeatType == 'weekly') ...[
          const SizedBox(height: 12),
          _buildWeeklySelector(),
        ],
        if (_repeatType == 'custom') ...[
          const SizedBox(height: 12),
          _buildCustomIntervalSelector(),
        ],
      ],
    );
  }

  Widget _buildWeeklySelector() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final selectedDays = List<int>.from(_repeatPattern['days'] ?? []);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = selectedDays.contains(index);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                if (selectedDays.length > 1) selectedDays.remove(index);
              } else {
                selectedDays.add(index);
              }
              _repeatPattern['days'] = selectedDays;
            });
          },
          child: CircleAvatar(
            backgroundColor: isSelected ? FemFlowColors.primary : Colors.grey.shade200,
            radius: 20,
            child: Text(days[index], style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12)),
          ),
        );
      }),
    );
  }

  Widget _buildCustomIntervalSelector() {
    return AppCard(
      child: Row(
        children: [
          const Text('Every '),
          SizedBox(
            width: 40,
            child: TextFormField(
              initialValue: (_repeatPattern['interval'] ?? 2).toString(),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (v) => _repeatPattern['interval'] = int.tryParse(v) ?? 2,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _repeatPattern['interval_type'] ?? 'days',
              items: const [
                DropdownMenuItem(value: 'days', child: Text('Days')),
                DropdownMenuItem(value: 'hours', child: Text('Hours')),
              ],
              onChanged: (v) => setState(() => _repeatPattern['interval_type'] = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Dose Timings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            TextButton.icon(onPressed: _addTiming, icon: const Icon(Icons.add, size: 18), label: const Text('Add Dose')),
          ],
        ),
        ..._timings.asMap().entries.map((entry) {
          final index = entry.key;
          final timing = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(index),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(timing.label, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                          Text(timing.time, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue: timing.doseQuantity.toString(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(suffixText: 'qty', isDense: true),
                      onChanged: (v) {
                        final qty = double.tryParse(v) ?? 1.0;
                        _timings[index] = MedicationTiming(time: timing.time, label: timing.label, doseQuantity: qty);
                      },
                    ),
                  ),
                  if (_timings.length > 1)
                    IconButton(onPressed: () => _removeTiming(index), icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Duration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(DateFormat('dd MMM yyyy').format(_startDate)),
                trailing: const Icon(Icons.calendar_today, size: 20),
                onTap: () async {
                   final picked = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
                   if (picked != null) setState(() => _startDate = picked);
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Ongoing Medication'),
                subtitle: const Text('No fixed end date'),
                value: _isOngoing,
                onChanged: (v) => setState(() => _isOngoing = v),
              ),
              if (!_isOngoing) ...[
                const Divider(),
                ListTile(
                  title: const Text('End Date'),
                  subtitle: Text(_endDate == null ? 'Select Date' : DateFormat('dd MMM yyyy').format(_endDate!)),
                  trailing: const Icon(Icons.calendar_today, size: 20),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: _endDate ?? _startDate.add(const Duration(days: 7)), firstDate: _startDate, lastDate: DateTime.now().add(const Duration(days: 365 * 5)));
                    if (picked != null) setState(() => _endDate = picked);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reminders & Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Get reminded when it\'s time to take your dose'),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                activeThumbColor: FemFlowColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              if (_notificationsEnabled) ...[
                const Divider(),
                DropdownButtonFormField<String>(
                  initialValue: _notificationSound,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Sound',
                    prefixIcon: Icon(Icons.music_note, color: FemFlowColors.primary),
                    border: InputBorder.none,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Default System Sound 🔊')),
                    DropdownMenuItem(value: 'chime_melodic', child: Text('Premium Melodic Chime 🎵')),
                    DropdownMenuItem(value: 'chime_zen', child: Text('Premium Zen Gong 🧘')),
                    DropdownMenuItem(value: 'chime_digital', child: Text('Premium Digital Beep ⚡')),
                  ],
                  onChanged: (v) => setState(() => _notificationSound = v!),
                ),
              ],
              const Divider(),
              DropdownButtonFormField<String>(
                initialValue: _instructions,
                decoration: const InputDecoration(labelText: 'Food Instructions', border: InputBorder.none),
                items: _foodInstructions.map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!))).toList(),
                onChanged: (v) => setState(() => _instructions = v!),
              ),
              const Divider(),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Add notes or reasons...', border: InputBorder.none),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
