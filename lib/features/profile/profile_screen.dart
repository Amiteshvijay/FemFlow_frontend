import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../settings/settings_screen.dart';
import '../reminders/reminders_screen.dart';
import '../partner_mode/partner_mode_screen.dart';
import '../pill_reminder/pill_reminder_list_screen.dart';
import '../auth/data/auth_service.dart';
import '../../core/security/app_lock_service.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';
import 'about_femflow_screen.dart';
import 'personal_info_screen.dart';
import 'cycle_period_settings_screen.dart';
import '../health_vault/health_vault_screen.dart';
import '../journal/journal_screen.dart';
import '../doctor_consultation/doctor_consultation_home_screen.dart';
import '../community/community_home_screen.dart';
import 'data/profile_service.dart';
import '../auth/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../subscriptions/providers/subscription_provider.dart';
import '../subscriptions/screens/premium_plan_screen.dart';
import '../subscriptions/screens/subscription_status_screen.dart';
import 'package:provider/provider.dart';
import '../premium/premium_guard.dart';
import '../referrals/referral_screen.dart';
import '../tips/providers/tips_provider.dart';
import '../exercises/providers/exercise_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  UserProfile? _profile;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
        await _fetchProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      appLock.setTrustedExternalFlowActive(false);
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _profileService.getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 401) {
          _handleLogout(showSnackBar: true);
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not connect to server. Check backend and adb reverse.';
        });
      }
    }
  }

  Future<void> _handleLogout({bool showSnackBar = false}) async {
    // Reset all global providers to clear user-specific state
    if (mounted) {
      context.read<SubscriptionProvider>().reset();
      context.read<TipsProvider>().reset();
      context.read<ExerciseProvider>().reset();
      context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isPartner = auth.profile?.goal == 'support_partner';

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FemFlowColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: FemFlowColors.period)),
                      ),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _fetchProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildUserProfile(context),
                      const SizedBox(height: 32),
                      if (!isPartner) ...[
                        _buildSubscriptionMenu(context),
                        const SizedBox(height: 16),
                      ],
                      _buildMenuSection(context),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildUserProfile(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: _isUploadingAvatar ? null : _pickAndUploadImage,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: FemFlowColors.blushMist,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: _profile?.avatarUrl != null
                      ? Image.network(
                          '${_profile!.avatarUrl!}?v=${DateTime.now().millisecondsSinceEpoch}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: FemFlowColors.primary),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: FemFlowColors.primary,
                          ),
                        ),
                ),
              ),
              if (_isUploadingAvatar)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator(color: FemFlowColors.primary)),
                )
              else
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: FemFlowColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _profile?.displayName ?? 'User',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: FemFlowColors.textPrimary,
          ),
        ),
        Text(
          _profile?.email ?? 'Not available',
          style: const TextStyle(
            fontSize: 14,
            color: FemFlowColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionMenu(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, provider, child) {
        final hasPremium = provider.isPremium;
        
        return AppCard(
          padding: EdgeInsets.zero,
          child: _buildMenuItem(
            context,
            icon: hasPremium ? Icons.star : Icons.workspace_premium_outlined,
            iconColor: hasPremium ? Colors.orange : FemFlowColors.primary,
            label: hasPremium ? 'My Subscription' : 'Upgrade to Premium',
            subtitle: hasPremium ? 'Manage your premium plan' : 'Unlock 11 AI daily tips & more',
            showDivider: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => hasPremium 
                    ? const SubscriptionStatusScreen() 
                    : const PremiumPlanScreen(),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isPartner = auth.profile?.goal == 'support_partner';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            label: 'Personal Information',
            showDivider: true,
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PersonalInfoScreen(profile: _profile)),
              );
              if (result == true) _fetchProfile();
            },
          ),
          if (!isPartner) ...[
            _buildMenuItem(
              context,
              icon: Icons.calendar_today_outlined,
              label: 'Cycle & Period Settings',
              showDivider: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CyclePeriodSettingsScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.shield_outlined,
              label: 'Health Vault',
              isPremium: true,
              showDivider: true,
              onTap: () => PremiumGuard.openPremiumFeature(
                context: context, 
                featureKey: 'health_vault', 
                premiumScreen: const HealthVaultScreen()
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.auto_stories_outlined,
              label: 'FemFlow Journal',
              isPremium: true,
              showDivider: true,
              onTap: () => PremiumGuard.openPremiumFeature(
                context: context, 
                featureKey: 'journal', 
                premiumScreen: const JournalScreen()
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.notifications_none_outlined,
              label: 'General Reminders',
              showDivider: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RemindersScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.medication_outlined,
              label: 'Medication Reminders',
              isPremium: true,
              showDivider: true,
              onTap: () => PremiumGuard.openPremiumFeature(
                context: context, 
                featureKey: 'pill_reminder', 
                premiumScreen: const PillReminderListScreen()
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.medical_services_outlined,
              label: 'Consult a Doctor',
              showDivider: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorConsultationHomeScreen()),
                );
              },
            ),
            _buildMenuItem(
              context,
              icon: Icons.groups_outlined,
              label: 'FemFlow Community',
              isPremium: true,
              showDivider: true,
              onTap: () => PremiumGuard.openPremiumFeature(
                context: context, 
                featureKey: 'community', 
                premiumScreen: const CommunityHomeScreen()
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.favorite_border,
              label: 'Partner Mode',
              isPremium: true,
              showDivider: true,
              onTap: () => PremiumGuard.openPremiumFeature(
                context: context, 
                featureKey: 'partner_mode', 
                premiumScreen: const PartnerModeScreen()
              ),
            ),
            _buildMenuItem(
              context,
              icon: Icons.person_add_outlined,
              label: 'Invite Friends',
              subtitle: 'Get 3 months Premium free',
              showDivider: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReferralScreen()),
                );
              },
            ),
          ],
          _buildMenuItem(
            context,
            icon: Icons.lock_outline,
            label: 'Privacy & Security',
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacySecurityScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            label: 'Help & Support',
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.info_outline,
            label: 'About FemFlow',
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutFemFlowScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.settings_outlined,
            label: 'Settings',
            showDivider: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.logout,
            label: 'Logout',
            showDivider: false,
            onTap: () => _showLogoutDialog(),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            child: const Text('Logout', style: TextStyle(color: FemFlowColors.period)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool showDivider,
    String? subtitle,
    Color? iconColor,
    bool isPremium = false,
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: FemFlowColors.warmWhite,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? FemFlowColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: FemFlowColors.textPrimary,
                            ),
                          ),
                          if (isPremium && !PremiumGuard.isPremium(context)) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: FemFlowColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: FemFlowColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 60,
            endIndent: 16,
            color: FemFlowColors.border,
          ),
      ],
    );
  }
}
