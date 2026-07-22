import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_card.dart';
import 'add_exercise_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        final provider = context.read<ExerciseProvider>();
        provider.loadCategories();
        provider.loadExercises();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Exercise Library', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: FemLyraColors.primary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExerciseScreen())),
          ),
        ],
      ),
      body: Consumer<ExerciseProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              _buildCategoryList(provider),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildExerciseList(provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryList(ExerciseProvider provider) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: provider.categories.length + 2,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _categoryChip(null, 'All');
          }
          if (index == 1) {
            return _mineChip();
          }
          final cat = provider.categories[index - 2];
          return _categoryChip(cat.key, cat.label);
        },
      ),
    );
  }

  bool _showOnlyMine = false;
  String? _selectedCategoryKey;

  Widget _mineChip() {
    final isSelected = _showOnlyMine;
    return FilterChip(
      label: const Text('My Exercises'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _showOnlyMine = selected;
          if (selected) _selectedCategoryKey = null;
        });
        context.read<ExerciseProvider>().loadExercises(
          mine: selected ? true : null,
          category: _selectedCategoryKey,
        );
      },
      selectedColor: FemLyraColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : FemLyraColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? FemLyraColors.primary : Colors.grey[300]!),
      ),
    );
  }

  Widget _categoryChip(String? key, String label) {
    final isSelected = _selectedCategoryKey == key && !_showOnlyMine;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategoryKey = key;
          _showOnlyMine = false;
        });
        context.read<ExerciseProvider>().loadExercises(category: key);
      },
      selectedColor: FemLyraColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : FemLyraColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? FemLyraColors.primary : Colors.grey[300]!),
      ),
    );
  }

  Widget _buildExerciseList(ExerciseProvider provider) {
    if (provider.exercises.isEmpty) {
      return const Center(child: Text('No exercises found in this category.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: provider.exercises.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ExerciseCard(exercise: provider.exercises[index]),
      ),
    );
  }
}
