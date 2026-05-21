import 'package:flutter/material.dart';
import '../../../core/theme/femflow_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/profile_service.dart';
import 'basic_information_section.dart';
import 'body_fitness_section.dart';
import 'health_wellness_section.dart';
import 'hormonal_health_section.dart';
import 'lifestyle_factors_section.dart';
import 'connected_health_section.dart';
import 'privacy_ai_consent_section.dart';
import '../../onboarding/cycle_history_section.dart';
import '../../cycles/data/cycle_service.dart';

class ProfileSectionFormScreen extends StatefulWidget {
  final String sectionKey;
  final String title;
  final UserProfile initialProfile;

  const ProfileSectionFormScreen({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.initialProfile,
  });

  @override
  State<ProfileSectionFormScreen> createState() => _ProfileSectionFormScreenState();
}

class _ProfileSectionFormScreenState extends State<ProfileSectionFormScreen> {
  late Map<String, dynamic> _formData;
  List<CycleLog> _historyData = [];
  bool _isSaving = false;
  final ProfileService _profileService = ProfileService();
  final CycleService _cycleService = CycleService();

  @override
  void initState() {
    super.initState();
    _formData = widget.initialProfile.toJson();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      if (widget.sectionKey == 'cycle_history') {
        for (var log in _historyData) {
          await _cycleService.createCycleLog(log);
        }
      } else {
        await _profileService.saveOnboardingSection(widget.sectionKey, _formData);
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: FemFlowColors.period),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => Navigator.pop(context)),
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildSectionForm(),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildSectionForm() {
    switch (widget.sectionKey) {
      case 'basic_information':
        return BasicInformationSection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'body_fitness':
        return BodyFitnessSection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'health_wellness':
        return HealthWellnessSection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'hormonal_health':
        return HormonalHealthSection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'lifestyle_factors':
        return LifestyleFactorsSection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'connected_health':
        return ConnectedHealthSection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'privacy_consent':
        return PrivacyAISection(initialData: _formData, onChanged: (data) => _formData = data);
      case 'cycle_history':
        return CycleHistorySection(onHistoryChanged: (history) => _historyData = history);
      default:
        return const Center(child: Text('Section not found'));
    }
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
      ),
      child: PrimaryButton(
        label: _isSaving ? 'Saving...' : 'Save Changes',
        onPressed: _isSaving ? null : _handleSave,
      ),
    );
  }
}
