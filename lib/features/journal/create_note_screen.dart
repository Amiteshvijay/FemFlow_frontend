import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/journal_service.dart';
import 'models/journal_entry.dart';
import 'models/note_category.dart';
import '../reminders/data/reminder_service.dart';

class CreateNoteScreen extends StatefulWidget {
  final JournalEntry? initialEntry;
  const CreateNoteScreen({super.key, this.initialEntry});

  @override
  State<CreateNoteScreen> createState() => _CreateNoteScreenState();
}

class _CreateNoteScreenState extends State<CreateNoteScreen> {
  final JournalService _service = JournalService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _selectedType = 'period';
  String? _selectedMood;
  double _painLevel = 0;
  String? _energyLevel;
  List<String> _selectedTags = [];
  bool _isPrivate = true;
  bool _isPinned = false;
  bool _isSaving = false;
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  final List<String> _moods = ['Happy', 'Okay', 'Tired', 'Sad', 'Anxious', 'Irritated', 'Calm', 'Emotional'];
  final List<String> _suggestedTags = ['cramps', 'fatigue', 'headache', 'bloating', 'sleep', 'stress', 'medicine', 'doctor', 'period', 'ovulation', 'mood', 'anxiety'];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      _titleController.text = widget.initialEntry!.title;
      _contentController.text = widget.initialEntry!.content;
      _selectedType = widget.initialEntry!.noteType;
      _selectedMood = widget.initialEntry!.mood;
      _painLevel = widget.initialEntry!.painLevel.toDouble();
      _energyLevel = widget.initialEntry!.energyLevel;
      _selectedTags = List.from(widget.initialEntry!.tags);
      _isPrivate = widget.initialEntry!.isPrivate;
      _isPinned = widget.initialEntry!.isPinned;
    }
  }

  Future<void> _handleSave() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in title and content')));
      return;
    }

    setState(() => _isSaving = true);
    
    final entry = JournalEntry(
      title: _titleController.text,
      content: _contentController.text,
      noteType: _selectedType,
      mood: _selectedMood,
      painLevel: _painLevel.toInt(),
      energyLevel: _energyLevel,
      tags: _selectedTags,
      isPrivate: _isPrivate,
      isPinned: _isPinned,
    );

    try {
      if (widget.initialEntry != null) {
        await _service.updateEntry(widget.initialEntry!.id!, entry);
      } else {
        await _service.createEntry(entry);
      }
      
      if (_reminderEnabled) {
        final reminderService = ReminderService();
        final formattedHour = _reminderTime.hour.toString().padLeft(2, '0');
        final formattedMinute = _reminderTime.minute.toString().padLeft(2, '0');
        final reminder = Reminder(
          title: 'Write in your Journal: ${_titleController.text}',
          reminderType: 'log_data',
          repeatType: 'daily',
          scheduleText: 'Daily',
          time: '$formattedHour:$formattedMinute',
          weekdays: '',
          isActive: true,
        );
        await reminderService.createReminder(reminder);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal entry saved successfully')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = NoteCategory.fromValue(_selectedType);

    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: const [
            Text('New Journal Entry', style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Capture how your body feels today', style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Note Type'),
            _buildTypeSelector(),
            const SizedBox(height: 24),
            _buildTextField(_titleController, 'Give your note a title', isTitle: true),
            const SizedBox(height: 16),
            _buildTextField(_contentController, category.hint, isContent: true),
            const SizedBox(height: 24),
            _buildSectionTitle('Mood'),
            _buildMoodSelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('Pain Level: ${_painLevel.toInt()}/10'),
            _buildPainSlider(),
            const SizedBox(height: 24),
            _buildSectionTitle('Energy Level'),
            _buildEnergySelector(),
            const SizedBox(height: 24),
            _buildSectionTitle('Tags'),
            _buildTagSelector(),
            const SizedBox(height: 32),
            _buildPrivacyCard(),
            const SizedBox(height: 16),
            _buildPinToggle(),
            const SizedBox(height: 16),
            _buildReminderToggle(),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Save Journal Entry',
              onPressed: _handleSave,
              isLoading: _isSaving,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary, fontSize: 16),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: NoteCategory.all.length,
        itemBuilder: (context, index) {
          final cat = NoteCategory.all[index];
          final isSelected = _selectedType == cat.value;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = cat.value),
            child: Container(
              width: 85,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? cat.color : cat.background,
                borderRadius: BorderRadius.circular(16),
                border: isSelected ? Border.all(color: cat.color.withValues(alpha: 0.5), width: 2) : null,
                boxShadow: isSelected ? [BoxShadow(color: cat.color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.icon, color: isSelected ? Colors.white : cat.color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : cat.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isTitle = false, bool isContent = false}) {
    return AppCard(
      padding: EdgeInsets.zero,
      color: isTitle ? Colors.white : Colors.white,
      child: TextField(
        controller: controller,
        maxLines: isContent ? 8 : 1,
        style: TextStyle(
          fontSize: isTitle ? 18 : 15,
          fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: FemLyraColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildMoodSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _moods.map((mood) {
        final isSelected = _selectedMood == mood;
        return FilterChip(
          label: Text(mood),
          selected: isSelected,
          onSelected: (selected) => setState(() => _selectedMood = selected ? mood : null),
          backgroundColor: FemLyraColors.blushMist,
          selectedColor: FemLyraColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : FemLyraColors.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildPainSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: FemLyraColors.primary,
          inactiveTrackColor: FemLyraColors.blushMist,
          thumbColor: FemLyraColors.primary,
          overlayColor: FemLyraColors.primary.withValues(alpha: 0.2),
          valueIndicatorColor: FemLyraColors.primary,
          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        ),
        child: Slider(
          value: _painLevel,
          min: 0,
          max: 10,
          divisions: 10,
          label: _painLevel.toInt().toString(),
          onChanged: (value) => setState(() => _painLevel = value),
        ),
      ),
    );
  }

  Widget _buildEnergySelector() {
    final levels = [
      {'label': 'Low', 'icon': Icons.battery_1_bar, 'color': Colors.red},
      {'label': 'Medium', 'icon': Icons.battery_4_bar, 'color': Colors.orange},
      {'label': 'High', 'icon': Icons.battery_full, 'color': Colors.green},
    ];

    return Row(
      children: levels.map((lvl) {
        final isSelected = _energyLevel == lvl['label'];
        final color = lvl['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _energyLevel = lvl['label'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? Border.all(color: color, width: 2) : null,
              ),
              child: Column(
                children: [
                  Icon(lvl['icon'] as IconData, color: isSelected ? Colors.white : color),
                  const SizedBox(height: 4),
                  Text(
                    lvl['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._selectedTags.map((tag) => _buildTagChip(tag, true)),
        ..._suggestedTags.where((t) => !_selectedTags.contains(t)).map((tag) => _buildTagChip(tag, false)),
      ],
    );
  }

  Widget _buildTagChip(String tag, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTags.remove(tag);
          } else {
            _selectedTags.add(tag);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? FemLyraColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? FemLyraColors.primary : FemLyraColors.border),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : FemLyraColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return AppCard(
      color: Colors.blue.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Private by default', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text('Only you can see this journal note.', style: TextStyle(fontSize: 11, color: FemLyraColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (val) => setState(() => _isPrivate = val),
            activeThumbColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildPinToggle() {
    return Row(
      children: [
        const Icon(Icons.push_pin_outlined, size: 18, color: FemLyraColors.textMuted),
        const SizedBox(width: 8),
        const Text('Pin this note', style: TextStyle(fontSize: 14, color: FemLyraColors.textPrimary)),
        const Spacer(),
        Switch(
          value: _isPinned,
          onChanged: (val) => setState(() => _isPinned = val),
          activeThumbColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildReminderToggle() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_none_outlined, size: 18, color: FemLyraColors.textMuted),
            const SizedBox(width: 8),
            const Text('Set daily reminder', style: TextStyle(fontSize: 14, color: FemLyraColors.textPrimary)),
            const Spacer(),
            Switch(
              value: _reminderEnabled,
              onChanged: (val) => setState(() => _reminderEnabled = val),
              activeThumbColor: FemLyraColors.primary,
            ),
          ],
        ),
        if (_reminderEnabled) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _reminderTime,
              );
              if (time != null) {
                setState(() => _reminderTime = time);
              }
            },
            child: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: FemLyraColors.blushMist.withValues(alpha: 0.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Schedule Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Row(
                    children: [
                      Text(
                        _reminderTime.format(context),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.access_time, size: 16, color: FemLyraColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
