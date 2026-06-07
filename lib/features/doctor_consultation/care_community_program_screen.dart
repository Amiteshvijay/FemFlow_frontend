import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../auth/providers/auth_provider.dart';
import '../subscriptions/providers/subscription_provider.dart';
import '../subscriptions/screens/premium_plan_screen.dart';
import 'data/doctor_consultation_service.dart';
import 'models/doctor_models.dart';

class CareCommunityProgramScreen extends StatefulWidget {
  const CareCommunityProgramScreen({super.key});

  @override
  State<CareCommunityProgramScreen> createState() => _CareCommunityProgramScreenState();
}

class _CareCommunityProgramScreenState extends State<CareCommunityProgramScreen> {
  final DoctorConsultationService _service = DoctorConsultationService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _usageCount = 0;
  bool _isCooldownActive = false;
  String? _cooldownText;

  @override
  void initState() {
    super.initState();
    _fetchUsageData();
  }

  Future<void> _fetchUsageData() async {
    try {
      final bookings = await _service.getMyBookings();
      
      // Filter bookings belonging to the Community Care Program
      final freeBookings = bookings.where((b) {
        final statusLower = b.status.toLowerCase();
        final paymentLower = b.paymentStatus.toLowerCase();
        return statusLower == 'community care' || 
               paymentLower == 'community care' || 
               paymentLower == 'free';
      }).toList();

      int count = freeBookings.length;
      bool cooldown = false;
      String? cooldownMessage;

      if (count >= 1) {
        // Sort by date to find the most recent free booking
        freeBookings.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
        final latestBookingDate = freeBookings.first.appointmentDate;
        
        final difference = DateTime.now().difference(latestBookingDate).inDays;
        if (difference < 30) {
          cooldown = true;
          final daysLeft = 30 - difference;
          cooldownMessage = '$daysLeft days left in cooldown';
        }
      }

      setState(() {
        _usageCount = count;
        _isCooldownActive = cooldown;
        _cooldownText = cooldownMessage;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading program usage data: $e');
    }
  }

  Future<void> _enrollInProgram() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await _service.enrollCareProgram();
      
      if (!mounted) return;
      
      // Refresh user profile state to update isCommunityCareEnrolled
      await context.read<AuthProvider>().checkAuth();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully enrolled in the Care Community Program!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrollment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final subProvider = context.watch<SubscriptionProvider>();
    final profile = authProvider.profile;
    
    final isPremium = subProvider.isPremium;
    final isEnrolled = profile?.isCommunityCareEnrolled ?? false;

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Care Community Program', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: FemFlowColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroHeader(),
                  const SizedBox(height: 24),
                  
                  // Status card
                  _buildStatusCard(isEnrolled, isPremium),
                  const SizedBox(height: 24),

                  if (isEnrolled) ...[
                    _buildUsageMetrics(),
                    const SizedBox(height: 24),
                  ],

                  _buildProgramDetails(),
                  const SizedBox(height: 40),
                  
                  _buildActionButton(isEnrolled, isPremium),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voluntary Care Program',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: FemFlowColors.primary,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Join our social impact initiative offering sponsored medical consultations for users in need.',
          style: TextStyle(fontSize: 15, color: FemFlowColors.textSecondary, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isEnrolled, bool isPremium) {
    Color cardColor;
    Color iconColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    if (isEnrolled) {
      cardColor = Colors.green.withValues(alpha: 0.08);
      iconColor = Colors.green;
      icon = Icons.check_circle_rounded;
      statusTitle = 'Enrolled';
      statusSubtitle = 'You are an active participant in the program.';
    } else if (isPremium) {
      cardColor = FemFlowColors.primary.withValues(alpha: 0.08);
      iconColor = FemFlowColors.primary;
      icon = Icons.info_outline;
      statusTitle = 'Not Enrolled';
      statusSubtitle = 'You are eligible to join. Tap participate below.';
    } else {
      cardColor = Colors.grey.withValues(alpha: 0.1);
      iconColor = Colors.grey;
      icon = Icons.lock_outline;
      statusTitle = 'Premium Benefit';
      statusSubtitle = 'Requires active Premium membership to enroll.';
    }

    return AppCard(
      color: cardColor,
      border: BorderSide(color: iconColor, width: 0.5),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
                  style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Benefits',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lifetime Consultations', style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                    const SizedBox(height: 6),
                    Text('$_usageCount / 2 used', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cooldown Status', style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                    const SizedBox(height: 6),
                    Text(
                      _isCooldownActive ? 'Active' : 'No Cooldown',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold, 
                        color: _isCooldownActive ? Colors.orange : Colors.green
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_isCooldownActive && _cooldownText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '⚠️ $_cooldownText. A 30-day gap is required between your first and second bookings.',
              style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProgramDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How the program works',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _detailItem(
          Icons.favorite_outline_rounded,
          'Voluntary Contribution',
          'Registered doctors contribute their time voluntarily on a social-impact basis. These teleconsultations are completely free (₹0 fee).',
        ),
        _detailItem(
          Icons.star_outline_rounded,
          'Premium Exclusive',
          'Enrollment in the program is a benefits feature reserved exclusively for FemFlow Premium members.',
        ),
        _detailItem(
          Icons.looks_two_outlined,
          '2 Bookings Max',
          'Enrolled members are eligible for up to 2 free consultations in total to ensure equal opportunity and fair access for all users.',
        ),
        _detailItem(
          Icons.hourglass_empty_rounded,
          '30-Day Cooldown',
          'To ensure other high-need patients can book, there must be a minimum 30-day gap between your first and second free bookings.',
        ),
      ],
    );
  }

  Widget _detailItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FemFlowColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: FemFlowColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemFlowColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isEnrolled, bool isPremium) {
    if (isEnrolled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Enrolled in Program',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      );
    }

    if (isPremium) {
      return SizedBox(
        width: double.infinity,
        height: 56,
        child: PrimaryButton(
          label: 'Participate in Program',
          isLoading: _isSubmitting,
          onPressed: _enrollInProgram,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: PrimaryButton(
        label: 'Upgrade to Premium to Enroll',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumPlanScreen()),
          );
        },
      ),
    );
  }
}
