import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/mood_service.dart';
import 'models/mood_models.dart';
import 'widgets/mood_icon_tile.dart';
import 'edit_mood_list_screen.dart';

class MoodListScreen extends StatefulWidget {
  final DateTime selectedDate;

  const MoodListScreen({super.key, required this.selectedDate});

  @override
  State<MoodListScreen> createState() => _MoodListScreenState();
}

class _MoodListScreenState extends State<MoodListScreen> {
  final MoodService _moodService = MoodService();
  bool _isLoading = true;
  MoodCatalog? _catalog;
  MoodLog? _currentLog;
  List<String> _selectedMoodKeys = [];
  String _searchQuery = "";
  bool _isSearching = false;

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
        _moodService.getMoodForDate(widget.selectedDate),
      ]);
      setState(() {
        _catalog = results[0] as MoodCatalog;
        _currentLog = results[1] as MoodLog;
        _selectedMoodKeys = List.from(_currentLog!.moods);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Unable to load moods.")));
      }
    }
  }

  void _toggleMood(String key) {
    setState(() {
      if (_selectedMoodKeys.contains(key)) {
        _selectedMoodKeys.remove(key);
      } else {
        _selectedMoodKeys.add(key);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await _moodService.saveMoods(
        date: widget.selectedDate,
        moods: _selectedMoodKeys,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mood logged"), duration: Duration(seconds: 2)));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not save mood.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: "Search moods...", border: InputBorder.none),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            )
          : const Text("Moods", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _searchQuery = "";
            }),
          ),
        ],
      ),
      body: _isLoading && _catalog == null
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _isSearching ? _buildSearchResults() : _buildCategories(),
                  ),
                ),
                _buildBottomAction(),
              ],
            ),
    );
  }

  Widget _buildCategories() {
    if (_catalog == null) return const SizedBox.shrink();
    return Column(
      children: [
        _buildCategorySection("General", _catalog!.general),
        const SizedBox(height: 20),
        _buildCategorySection("Positive", _catalog!.positive),
        const SizedBox(height: 20),
        _buildCategorySection("Negative", _catalog!.negative),
        const SizedBox(height: 20),
        _buildCategorySection("Cycle-related", _catalog!.cycleRelated),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCategorySection(String title, List<Mood> moods) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              if (title == "General")
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditMoodListScreen()));
                    if (result == true) _fetchData();
                  },
                  child: const Text("Edit list >", style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: moods.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
              childAspectRatio: 0.7,
            ),
            itemBuilder: (context, index) {
              final mood = moods[index];
              final isSelected = _selectedMoodKeys.contains(mood.key);
              return MoodIconTile(
                mood: mood,
                isSelected: isSelected,
                onTap: () => _toggleMood(mood.key),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final allMoods = _catalog?.getAllMoods() ?? [];
    final results = allMoods.where((m) => m.label.toLowerCase().contains(_searchQuery)).toList();

    if (results.isEmpty) {
      return const Center(child: Text("No moods found."));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final mood = results[index];
        final isSelected = _selectedMoodKeys.contains(mood.key);
        return MoodIconTile(
          mood: mood,
          isSelected: isSelected,
          onTap: () => _toggleMood(mood.key),
        );
      },
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
        label: "Save Moods",
        onPressed: _isLoading ? null : _save,
        isLoading: _isLoading,
      ),
    );
  }
}
