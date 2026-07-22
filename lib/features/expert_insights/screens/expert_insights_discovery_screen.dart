import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../models/insight_models.dart';
import '../data/expert_insights_service.dart';
import '../widgets/expert_insight_card.dart';

class ExpertInsightsDiscoveryScreen extends StatefulWidget {
  const ExpertInsightsDiscoveryScreen({super.key});

  @override
  State<ExpertInsightsDiscoveryScreen> createState() => _ExpertInsightsDiscoveryScreenState();
}

class _ExpertInsightsDiscoveryScreenState extends State<ExpertInsightsDiscoveryScreen> {
  final ExpertInsightsService _service = ExpertInsightsService();
  List<InsightCategory> _categories = [];
  List<ExpertInsight> _insights = [];
  bool _isLoading = true;
  String? _selectedCategorySlug;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getCategories(),
        _service.getInsights(categorySlug: _selectedCategorySlug, search: _searchController.text.trim()),
      ]);
      setState(() {
        _categories = results[0] as List<InsightCategory>;
        _insights = results[1] as List<ExpertInsight>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Expert Health Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchAndCategories(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _insights.isEmpty
                  ? const Center(child: Text('No insights found.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _insights.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: ExpertInsightCard(insight: _insights[index]),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndCategories() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search topic, symptoms, or doctor',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _fetchData(),
          ),
        ),
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategorySlug == cat.slug;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedCategorySlug = val ? cat.slug : null);
                    _fetchData();
                  },
                  backgroundColor: Colors.white,
                  selectedColor: FemFlowColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  side: BorderSide.none,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
