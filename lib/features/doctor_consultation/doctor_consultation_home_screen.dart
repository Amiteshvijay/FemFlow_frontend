import 'package:flutter/material.dart';
import 'package:femflow/core/theme/femflow_colors.dart';
import 'package:femflow/shared/widgets/app_card.dart';
import 'data/doctor_consultation_service.dart';
import 'models/doctor_models.dart';
import 'doctor_list_screen.dart';
import 'my_doctor_bookings_screen.dart';

class DoctorConsultationHomeScreen extends StatefulWidget {
  const DoctorConsultationHomeScreen({super.key});

  @override
  State<DoctorConsultationHomeScreen> createState() => _DoctorConsultationHomeScreenState();
}

class _DoctorConsultationHomeScreenState extends State<DoctorConsultationHomeScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  List<DoctorCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _service.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load categories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Consult a Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyDoctorBookingsScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Talk to trusted women\'s health experts',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),



                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search doctors, symptoms, specialties',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Categories Grid
                  const Text(
                    'Categories',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _buildCategoryCard(context, cat);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Premium Section
                  const Text(
                    'Recommended for you',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRecommendationCard(
                    context,
                    'Period cramps?',
                    'Consult a Gynecologist',
                    Icons.opacity,
                    Colors.pink.shade50,
                    'gynecologist',
                  ),
                  _buildRecommendationCard(
                    context,
                    'Stress or mood swings?',
                    'Talk to Mental Wellness Expert',
                    Icons.psychology,
                    Colors.purple.shade50,
                    'mental-wellness',
                  ),
                  _buildRecommendationCard(
                    context,
                    'Acne or hair fall?',
                    'Consult Dermatologist',
                    Icons.face,
                    Colors.orange.shade50,
                    'dermatologist',
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, DoctorCategory cat) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DoctorListScreen(category: cat)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getIconData(cat.iconName), color: FemFlowColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(
              cat.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              cat.description,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(BuildContext context, String title, String subtitle, IconData icon, Color bgColor, String categorySlug) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () {
          if (_categories.isEmpty) return;
          final cat = _categories.firstWhere((c) => c.slug == categorySlug, orElse: () => _categories.first);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DoctorListScreen(category: cat)),
          );
        },
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }

  IconData _getIconData(String? name) {
    switch (name) {
      case 'opacity':
        return Icons.opacity;
      case 'favorite':
        return Icons.favorite;
      case 'face':
        return Icons.face;
      case 'psychology':
        return Icons.psychology;
      case 'restaurant':
        return Icons.restaurant;
      case 'healing':
        return Icons.healing;
      case 'child_care':
        return Icons.child_care;
      case 'favorite_border':
        return Icons.favorite_border;
      default:
        return Icons.person_outline;
    }
  }


}
