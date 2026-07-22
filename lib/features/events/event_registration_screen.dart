import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../profile/data/profile_service.dart';
import 'data/event_service.dart';
import 'models/event_models.dart';
import '../wellness_score/wellness_score_dashboard_screen.dart';
import '../diet/screens/diet_home_screen.dart';

class EventRegistrationScreen extends StatefulWidget {
  final FemLyraEvent event;

  const EventRegistrationScreen({super.key, required this.event});

  @override
  State<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();
  final ProfileService _profileService = ProfileService();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _professionController = TextEditingController();
  final _questionController = TextEditingController();
  
  bool _isLoading = false;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getProfile();
      setState(() {
        _nameController.text = profile.fullName ?? profile.username;
        _emailController.text = profile.email;
        _phoneController.text = profile.mobileNumber ?? '';
        
        // Calculate age dynamically from DOB
        int? calculatedAge;
        if (profile.dob != null) {
          final today = DateTime.now();
          calculatedAge = today.year - profile.dob!.year;
          if (today.month < profile.dob!.month || (today.month == profile.dob!.month && today.day < profile.dob!.day)) {
            calculatedAge--;
          }
        }
        
        final ageVal = calculatedAge ?? profile.age;
        if (ageVal != null) {
          _ageController.text = ageVal.toString();
        }
        
        _cityController.text = profile.city ?? '';
        _professionController.text = profile.profession ?? '';
      });
    } catch (e) {
      // Non-fatal if profile load fails
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the registration terms.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final request = EventRegistrationRequest(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobile: _phoneController.text.trim(),
        age: int.tryParse(_ageController.text),
        city: _cityController.text.trim(),
        profession: _professionController.text.trim(),
        question: _questionController.text.trim(),
        consent: _consent,
      );

      await _eventService.registerForEvent(widget.event.slug, request);
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 40,
              backgroundColor: FemFlowColors.fertileWindow,
              child: Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 24),
            const Text(
              'Registration Successful!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'You have successfully registered for the event. A confirmation email has been sent to you.',
              style: TextStyle(color: FemFlowColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  final category = widget.event.category.toLowerCase();
                  if (category.contains('nutrition') || category.contains('diet')) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const DietHomeScreen()),
                      (route) => route.isFirst,
                    );
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const WellnessScoreDashboardScreen()),
                      (route) => route.isFirst,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemFlowColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Great!', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Event Registration', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.event.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
              ),
              const SizedBox(height: 24),
              _buildTextField('Full Name*', _nameController, Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField('Email Address*', _emailController, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Mobile Number*', _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField('Age', _ageController, Icons.cake_outlined, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('City', _cityController, Icons.location_city_outlined)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField('Profession', _professionController, Icons.work_outline),
              const SizedBox(height: 16),
              _buildTextField(
                'Question for Speaker (Optional)', 
                _questionController, 
                Icons.help_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _consent,
                      onChanged: (val) => setState(() => _consent = val ?? false),
                      activeColor: FemFlowColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'I consent to share my details with FemLyra for event coordination and health updates.',
                      style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemFlowColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Registration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: FemFlowColors.primary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: FemFlowColors.primary)),
      ),
      validator: (value) {
        if (label.contains('*') && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
