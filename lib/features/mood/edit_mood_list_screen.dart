import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/mood_service.dart';
import 'models/mood_models.dart';

class EditMoodListScreen extends StatefulWidget {
  const EditMoodListScreen({super.key});

  @override
  State<EditMoodListScreen> createState() => _EditMoodListScreenState();
}

class _EditMoodListScreenState extends State<EditMoodListScreen> {
  final MoodService _moodService = MoodService();
  bool _isLoading = true;
  MoodCatalog? _catalog;
  List<String> _enabledMoodKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _moodService.getMoodCatalog(),
        _moodService.getMoodPreferences(),
      ]);
      setState(() {
        _catalog = results[0] as MoodCatalog;
        _enabledMoodKeys = (results[1] as MoodPreference).enabledMoods;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _toggleMood(String key) {
    setState(() {
      if (_enabledMoodKeys.contains(key)) {
        if (_enabledMoodKeys.length > 4) {
          _enabledMoodKeys.remove(key);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please keep at least 4 moods enabled.")));
        }
      } else {
        _enabledMoodKeys.add(key);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await _moodService.updateMoodPreferences(_enabledMoodKeys);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text("Edit List", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading && _catalog == null
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildSections(),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildSections() {
    if (_catalog == null) return const SizedBox.shrink();
    return Column(
      children: [
        _buildCategoryCard("General", _catalog!.general),
        const SizedBox(height: 20),
        _buildCategoryCard("Positive", _catalog!.positive),
        const SizedBox(height: 20),
        _buildCategoryCard("Negative", _catalog!.negative),
        const SizedBox(height: 20),
        _buildCategoryCard("Cycle-related", _catalog!.cycleRelated),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCategoryCard(String title, List<Mood> moods) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: moods.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isEnabled = _enabledMoodKeys.contains(mood.key);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                title: Text(mood.label),
                trailing: Switch(
                  value: isEnabled,
                  onChanged: (_) => _toggleMood(mood.key),
                  activeTrackColor: FemLyraColors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: PrimaryButton(
        label: "Save Preferences",
        onPressed: _isLoading ? null : _save,
        isLoading: _isLoading,
      ),
    );
  }
}
