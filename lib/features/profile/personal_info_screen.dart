import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/security/app_lock_service.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/app_card.dart';
import 'data/profile_service.dart';
import '../auth/data/auth_service.dart';
import 'wellness_onboarding_flow.dart';
import 'sections/profile_section_form_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final UserProfile? profile;
  const PersonalInfoScreen({super.key, this.profile});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  UserProfile? _currentProfile;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _hasChanges = false;
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
    if (_currentProfile == null) {
      _fetchProfile();
    }
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final appLock = context.read<AppLockService>();
    try {
      appLock.setTrustedExternalFlowActive(true);
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() => _isUploadingAvatar = true);
        final bytes = await image.readAsBytes();
        await _authService.updateAvatar(bytes, image.name);
        _hasChanges = true;
        await _fetchProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      appLock.setTrustedExternalFlowActive(false);
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Parent screen will be notified via the return value of Navigator.pop
      },
      child: Scaffold(
        backgroundColor: FemFlowColors.warmWhite,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text('My Profile Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 32),
                    _buildProfileSummary(),
                    const SizedBox(height: 24),
                    _buildSectionCard(
                      icon: Icons.person_outline,
                      title: 'Basic Information',
                      subtitle: 'Name, DOB, Location',
                      completion: _currentProfile?.sectionProgress['basic_information'] ?? 0.0,
                      onTap: () => _editSection('basic_information', 'Basic Information'),
                    ),
                    _buildSectionCard(
                      icon: Icons.fitness_center_outlined,
                      title: 'Body & Fitness',
                      subtitle: 'BMI, Activity, Fitness Goals',
                      completion: _currentProfile?.sectionProgress['body_fitness'] ?? 0.0,
                      onTap: () => _editSection('body_fitness', 'Body & Fitness'),
                    ),
                    _buildSectionCard(
                      icon: Icons.wb_sunny_outlined,
                      title: 'Health & Wellness',
                      subtitle: 'Stress, Mood, Energy',
                      completion: _currentProfile?.sectionProgress['health_wellness'] ?? 0.0,
                      onTap: () => _editSection('health_wellness', 'Health & Wellness'),
                    ),
                    _buildSectionCard(
                      icon: Icons.favorite_border,
                      title: 'Hormonal Health',
                      subtitle: 'PCOS, Thyroid, Cycle Regularity',
                      completion: _currentProfile?.sectionProgress['hormonal_health'] ?? 0.0,
                      onTap: () => _editSection('hormonal_health', 'Hormonal Health'),
                    ),
                    _buildSectionCard(
                      icon: Icons.self_improvement_outlined,
                      title: 'Lifestyle Factors',
                      subtitle: 'Sleep, Stress, Diet',
                      completion: _currentProfile?.sectionProgress['lifestyle_factors'] ?? 0.0,
                      onTap: () => _editSection('lifestyle_factors', 'Lifestyle Factors'),
                    ),
                    _buildSectionCard(
                      icon: Icons.sync_outlined,
                      title: 'Connected Health',
                      subtitle: 'Google Fit, Smart Devices',
                      completion: _currentProfile?.sectionProgress['connected_health'] ?? 0.0,
                      onTap: () => _editSection('connected_health', 'Connected Health'),
                    ),
                    _buildSectionCard(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy & AI Consent',
                      subtitle: 'Insights, Recommendations',
                      completion: _currentProfile?.sectionProgress['privacy_consent'] ?? 0.0,
                      onTap: () => _editSection('privacy_consent', 'Privacy & AI Consent'),
                    ),
                    _buildSectionCard(
                      icon: Icons.history_toggle_off,
                      title: 'Cycle History',
                      subtitle: 'Recent Period Dates',
                      completion: 1.0, // History is optional/always accessible
                      onTap: () => _editSection('cycle_history', 'Cycle History'),
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Setup Wellness Profile',
                      onPressed: () => _openOnboarding(0),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _openOnboarding(int step) async {
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => WellnessOnboardingFlow(
                  initialProfile: _currentProfile,
                  initialPage: step,
                )));
    if (result == true) _fetchProfile();
  }

  Future<void> _editSection(String key, String title) async {
    if (_currentProfile == null) return;
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ProfileSectionFormScreen(
                  sectionKey: key,
                  title: title,
                  initialProfile: _currentProfile!,
                )));
    if (result == true) _fetchProfile();
  }

  Widget _buildAvatarSection() {
    return Center(
      child: GestureDetector(
        onTap: _isUploadingAvatar ? null : _pickAndUploadImage,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(color: FemFlowColors.blushMist, shape: BoxShape.circle),
              child: _currentProfile?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        '${_currentProfile!.avatarUrl!}?v=${DateTime.now().millisecondsSinceEpoch}',
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.person, size: 60, color: FemFlowColors.primary),
            ),
            if (_isUploadingAvatar)
              const Positioned.fill(child: Center(child: CircularProgressIndicator(color: FemFlowColors.primary)))
            else
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummary() {
    return Column(
      children: [
        Text(_currentProfile?.safeDisplayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(_currentProfile?.email ?? '', style: const TextStyle(color: FemFlowColors.textSecondary)),
        if (_currentProfile?.bmi != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('BMI: ${_currentProfile!.bmi}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
      ],
    );
  }

  Widget _buildSectionCard({required IconData icon, required String title, required String subtitle, double completion = 0.0, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: FemFlowColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                value: completion,
                strokeWidth: 4,
                backgroundColor: FemFlowColors.border.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(FemFlowColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
