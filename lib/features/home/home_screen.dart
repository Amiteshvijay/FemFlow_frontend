import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/femai_icon.dart';

import '../symptoms/symptoms_screen.dart';
import '../auth/data/auth_service.dart';
import '../cycles/data/cycle_service.dart';
import '../wellness_score/wellness_score_dashboard_screen.dart';
import '../wellness_score/data/wellness_score_service.dart';
import '../wellness_score/models/wellness_score_models.dart';
import '../analytics/data/analytics_service.dart';
import '../premium/premium_guard.dart';
import '../premium/premium_feature_preview_screen.dart';
import '../community/community_home_screen.dart';
import '../exercises/screens/exercise_home_screen.dart';
import '../pill_reminder/pill_reminder_list_screen.dart';
import '../doctor_consultation/doctor_consultation_home_screen.dart';
import '../journal/journal_screen.dart';
import '../calendar/date_detail_screen.dart';
import '../insights/insights_screen.dart';
import '../health_vault/health_vault_screen.dart';
import '../tips/widgets/everyday_tips_section.dart';
import '../tips/providers/tips_provider.dart';
import '../exercises/widgets/recommended_exercise_section.dart';
import '../diet/screens/diet_home_screen.dart';
import '../expert_insights/data/expert_insights_service.dart';
import '../expert_insights/models/insight_models.dart';
import '../expert_insights/widgets/expert_insight_card.dart';
import '../expert_insights/screens/expert_insights_discovery_screen.dart';
import '../events/event_list_screen.dart';
import '../lab_tests/lab_tests_home_screen.dart';
import 'package:provider/provider.dart';
import '../subscriptions/providers/subscription_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final CycleService _cycleService = CycleService();
  final WellnessScoreService _wellnessService = WellnessScoreService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final ExpertInsightsService _insightsService = ExpertInsightsService();
  String _firstName = 'there';
  Map<String, dynamic>? _dashboardData;
  WeeklyWellnessScore? _wellnessData;
  Map<String, dynamic>? _dailyInsight;
  List<ExpertInsight> _topInsights = [];
  bool _isLoadingDashboard = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchDashboardData();
    Future.microtask(() {
      if (mounted) {
        context.read<SubscriptionProvider>().loadStatus();
      }
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final data = await _authService.me();
      if (mounted) {
        setState(() {
          _firstName = extractFirstNameFromMeResponse(data);
        });
      }
    } catch (e) {
      // Keep default 'there' on error
    }
  }

  String extractFirstNameFromMeResponse(Map<String, dynamic> data) {
    final profile = data['profile'];
    String? fullName;
    if (profile is Map<String, dynamic>) {
      fullName = profile['full_name']?.toString().trim();
    }
    fullName ??= data['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName.split(RegExp(r'\s+')).first;
    }
    final username = data['username']?.toString().trim();
    if (username != null && username.isNotEmpty) {
      return username;
    }
    return 'there';
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final results = await Future.wait([
        _cycleService.getDashboard(),
        _wellnessService.getWeeklyScore(),
        _analyticsService.getDailyInsight(),
        _insightsService.getInsights(),
      ]);
      if (mounted) {
        setState(() {
          _dashboardData = results[0] as Map<String, dynamic>?;
          _wellnessData = results[1] as WeeklyWellnessScore?;
          _dailyInsight = results[2] as Map<String, dynamic>?;
          _topInsights = (results[3] as List<ExpertInsight>).take(10).toList();
          _isLoadingDashboard = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDashboard = false);
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      _fetchUserData(),
      _fetchDashboardData(),
      context.read<TipsProvider>().loadDailyTips(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final isPremium = subscriptionProvider.isPremium;

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: FemFlowColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildThisWeekSection(),
                const SizedBox(height: 16),
                _buildPillReminderSection(isPremium),
                const SizedBox(height: 16),
                _buildWellnessScoreCard(isPremium),
                const SizedBox(height: 16),
                _buildLabTestCard(),
                const SizedBox(height: 24),
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FemFlowColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(child: _buildQuickActions(context)),
                const SizedBox(height: 24),
                RepaintBoundary(child: _buildAIInsightCard(isPremium)),
                const SizedBox(height: 24),
                const EverydayTipsSection(),
                const SizedBox(height: 24),
                const RecommendedExerciseSection(),
                const SizedBox(height: 24),
                _buildExpertInsightsSection(),
                const SizedBox(height: 24),
                _buildMedicalDisclaimerBanner(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildMedicalDisclaimerBanner() {
    return AppCard(
      color: Colors.red.withValues(alpha: 0.05),
      border: const BorderSide(color: Colors.red, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'FemFlow is NOT a medical device. Always consult a doctor for medical advice or treatment.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWellnessScoreCard(bool isPremium) {
    if (_isLoadingDashboard) return const SizedBox.shrink();

    return AppCard(
      onTap: () {
        if (isPremium) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessScoreDashboardScreen())).then((_) => _fetchDashboardData());
        } else {
           PremiumGuard.openPremiumFeature(
             context: context, 
             featureKey: 'wellness_score', 
             premiumScreen: const WellnessScoreDashboardScreen()
           );
        }
      },
      color: FemFlowColors.ovulation.withValues(alpha: 0.05),
      border: BorderSide(color: FemFlowColors.ovulation, width: 0.5),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: (_wellnessData?.score ?? 0) / 100,
                  strokeWidth: 4,
                  color: FemFlowColors.ovulation,
                  backgroundColor: FemFlowColors.ovulation.withValues(alpha: 0.1),
                ),
              ),
              Text(
                '${_wellnessData?.score ?? "--"}',
                style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.ovulation),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('FemFlow Wellness Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  _wellnessData?.status ?? 'Start your first wellness check-in',
                  style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildLabTestCard() {
    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LabTestsHomeScreen()),
        );
      },
      color: FemFlowColors.blushMist,
      border: BorderSide(color: FemFlowColors.primary.withValues(alpha: 0.2), width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.science_outlined, color: FemFlowColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Lab Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: FemFlowColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Find trusted diagnostic centres near you and book home sample collection.',
                      style: TextStyle(
                        fontSize: 12,
                        color: FemFlowColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LabTestsHomeScreen()),
                    );
                  },
                  icon: const Icon(Icons.search, size: 16, color: Colors.white),
                  label: const Text('Search Tests', style: TextStyle(fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemFlowColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LabTestsHomeScreen(useCurrentLocation: true)),
                    );
                  },
                  icon: const Icon(Icons.my_location, size: 16, color: FemFlowColors.primary),
                  label: const Text('Use Location', style: TextStyle(fontSize: 12, color: FemFlowColors.primary)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FemFlowColors.primary,
                    side: const BorderSide(color: FemFlowColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, thickness: 0.5, color: FemFlowColors.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestsHomeScreen(initialTab: 1)),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.spa_outlined, size: 14, color: FemFlowColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Browse Packages',
                      style: TextStyle(fontSize: 11, color: FemFlowColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabTestsHomeScreen(initialTab: 0)),
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.upload_file_outlined, size: 14, color: FemFlowColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      'Upload Report',
                      style: TextStyle(fontSize: 11, color: FemFlowColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPillReminderSection(bool isPremium) {
    return AppCard(
      onTap: () => PremiumGuard.openPremiumFeature(
        context: context, 
        featureKey: 'pill_reminder', 
        premiumScreen: const PillReminderListScreen()
      ),
      color: Colors.orange.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.orange, width: 0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.medication_outlined, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Medication Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Text(
                  'Check your schedule for today',
                  style: TextStyle(color: FemFlowColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning!';
    } else if (hour < 15) {
      greeting = 'Good noon!';
    } else if (hour < 17) {
      greeting = 'Good afternoon!';
    } else if (hour < 21) {
      greeting = 'Good evening!';
    } else {
      greeting = 'Good night!';
    }

    final upcomingEvents = _dashboardData?['upcoming_events'] as List?;
    final hasNotifications = upcomingEvents != null && upcomingEvents.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, $_firstName 🌸',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: FemFlowColors.textPrimary,
              ),
            ),
            Text(
              greeting,
              style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () => _showNotificationsBottomSheet(context),
              icon: const Icon(Icons.notifications_none_outlined),
            ),
            if (hasNotifications)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: FemFlowColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    final upcomingEvents = _dashboardData?['upcoming_events'] as List? ?? [];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upcoming Cycle Events',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (upcomingEvents.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No cycle notifications this week.',
                      style: TextStyle(color: FemFlowColors.textSecondary),
                    ),
                  ),
                )
              else
                ...upcomingEvents.map((event) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _getEventColor(event['type']).withValues(alpha: 0.1),
                      child: Icon(_getEventIcon(event['type']), color: _getEventColor(event['type']), size: 20),
                    ),
                    title: Text(event['title'] ?? ''),
                    subtitle: Text(event['date_text'] ?? ''),
                  );
                }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThisWeekSection() {
    if (_isLoadingDashboard) {
      return const AppCard(child: Center(child: CircularProgressIndicator(color: FemFlowColors.primary)));
    }

    final upcomingEvents = _dashboardData?['upcoming_events'] as List? ?? [];
    
    // Hide the entire section if there are no major events
    if (upcomingEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This week',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FemFlowColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ..._buildUpcomingEventCards(upcomingEvents),
      ],
    );
  }

  List<Widget> _buildUpcomingEventCards(List events) {
    // Limit to 2 big cards as per requirements
    final displayEvents = events.take(2).toList();
    final List<Widget> cards = [];

    for (var i = 0; i < displayEvents.length; i++) {
      final event = displayEvents[i];
      if (event['type'] == 'active_period' || event['type'] == 'next_period') {
        cards.add(_buildPrimaryEventCard(event));
      } else {
        // If it's a secondary event (fertile/ovulation), and we have two of them,
        // we might want to put them in a row. 
        // But for simplicity and clean UI, let's follow the standard card style.
        cards.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _buildSecondaryEventCard(event),
        ));
      }
    }

    return cards;
  }

  Widget _buildPrimaryEventCard(Map event) {
    final isActivePeriod = event['type'] == 'active_period';
    final nextDateStr = _dashboardData?['next_period'];
    final lastPeriodEndDate = _dashboardData?['last_period_end_date'];
    final eventDateStr = event['date'];
    
    double progressValue = 0.3;
    if (isActivePeriod) {
      final currentPeriodDay = _dashboardData?['current_period_day'] as num?;
      final averagePeriodLength = _dashboardData?['average_period_length'] as num? ?? 5;
      if (currentPeriodDay != null && averagePeriodLength > 0) {
        progressValue = (currentPeriodDay.toDouble() / averagePeriodLength.toDouble()).clamp(0.0, 1.0);
      }
    } else {
      final daysUntil = event['days_until'] as num?;
      if (daysUntil != null) {
        progressValue = (1.0 - (daysUntil.toDouble() / 7.0)).clamp(0.0, 1.0);
      } else {
        final daysLeft = event['days_left'] as num?;
        if (daysLeft != null) {
          progressValue = (1.0 - (daysLeft.toDouble() / 7.0)).clamp(0.0, 1.0);
        } else {
          progressValue = 0.0;
        }
      }
    }
    
    String subtitle = isActivePeriod 
        ? 'Period started' 
        : (nextDateStr != null ? 'Expected on ${DateFormat('d MMM').format(DateTime.parse(nextDateStr))}' : '');

    return AppCard(
      onTap: () {
        if (eventDateStr != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DateDetailScreen(selectedDate: DateTime.parse(eventDateStr))),
          ).then((_) => _handleRefresh());
        }
      },
      color: FemFlowColors.blushMist,
      border: BorderSide.none,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] ?? '', style: const TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(event['date_text'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
                Text(subtitle, style: const TextStyle(color: FemFlowColors.textSecondary)),
                if (isActivePeriod && lastPeriodEndDate == null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                       final logId = _dashboardData?['last_period_id'];
                       if (logId != null) {
                         await _cycleService.logPeriodEnd(logId, DateTime.now());
                         _fetchDashboardData();
                       }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: FemFlowColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Log period end', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progressValue,
                  strokeWidth: 6,
                  color: FemFlowColors.primary,
                  backgroundColor: FemFlowColors.white.withValues(alpha: 0.5),
                ),
              ),
              isActivePeriod 
                  ? _buildPeriodFlowIcon(event['flow'] ?? _dashboardData?['period']?['flow']?.toString())
                  : Icon(_getEventIcon(event['type']), color: FemFlowColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFlowIcon(String? flow) {
    Color mainColor;
    IconData iconData = Icons.water_drop;
    
    final normalizedFlow = flow?.toLowerCase() ?? 'medium';
    
    switch (normalizedFlow) {
      case 'spotting':
        mainColor = const Color(0xFFFFC0CB); // pink
        iconData = Icons.opacity;
        break;
      case 'light':
        mainColor = const Color(0xFFFF8B94); // soft red/pink
        iconData = Icons.opacity;
        break;
      case 'medium':
        mainColor = FemFlowColors.primary;
        iconData = Icons.water_drop;
        break;
      case 'heavy':
        mainColor = const Color(0xFFC0392B); // deep red
        iconData = Icons.water_drop;
        break;
      default:
        mainColor = FemFlowColors.primary;
        iconData = Icons.water_drop;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: const Offset(0, -3),
          child: Icon(iconData, color: mainColor, size: 26),
        ),
        if (normalizedFlow == 'heavy')
          Transform.translate(
            offset: const Offset(0, 10),
            child: Icon(Icons.water_drop, color: mainColor, size: 10),
          ),
      ],
    );
  }

  Widget _buildSecondaryEventCard(Map event) {
    final color = _getEventColor(event['type']);
    final eventDateStr = event['date'];
    
    return AppCard(
      onTap: () {
        if (eventDateStr != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DateDetailScreen(selectedDate: DateTime.parse(eventDateStr))),
          ).then((_) => _handleRefresh());
        }
      },
      color: color.withValues(alpha: 0.1),
      border: BorderSide.none,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(_getEventIcon(event['type']), color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event['title'] ?? '', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(event['date_text'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
              ],
            ),
          ),
          const Text('Estimated', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
        ],
      ),
    );
  }

  Color _getEventColor(String? type) {
    switch (type) {
      case 'active_period':
      case 'next_period':
        return FemFlowColors.primary;
      case 'fertile_window':
        return FemFlowColors.fertileWindow;
      case 'ovulation':
        return FemFlowColors.ovulation;
      default:
        return FemFlowColors.textSecondary;
    }
  }

  IconData _getEventIcon(String? type) {
    switch (type) {
      case 'active_period':
      case 'next_period':
        return Icons.calendar_today;
      case 'fertile_window':
        return Icons.favorite;
      case 'ovulation':
        return Icons.wb_sunny;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildAIInsightCard(bool isPremium) {
    if (_isLoadingDashboard) return const SizedBox.shrink();

    return AppCard(
      onTap: () {
        if (!isPremium) {
           Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumFeaturePreviewScreen(featureKey: 'cycle_insights')));
        }
      },
      color: const Color(0xFFF3F0FF),
      border: BorderSide.none,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Insight for You', style: TextStyle(color: FemFlowColors.aiWellness, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  isPremium 
                    ? (_dailyInsight?['content'] ?? 'Your cycle looks calm this week.')
                    : 'Unlock daily personalized cycle insights and FemAI guidance with Premium.',
                  style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
                ),
                if (!isPremium) ...[
                   const SizedBox(height: 12),
                   const Text(
                     'Unlock with Premium >',
                     style: TextStyle(color: FemFlowColors.aiWellness, fontWeight: FontWeight.bold, fontSize: 12),
                   ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cleaned up: removed redundant sparkle icon and centered the AI Butterfly icon when needed
          if (isPremium)
            const FemAIIcon(color: FemFlowColors.aiWellness, size: 32)
          else
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: FemFlowColors.aiWellness, shape: BoxShape.circle),
                  child: const FemAIIcon(color: Colors.white, size: 24),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C00)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock, size: 8, color: Colors.white),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _quickActionCard(
          context,
          icon: Icons.science_outlined,
          label: 'Lab Test',
          color: FemFlowColors.primary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LabTestsHomeScreen()),
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.sentiment_satisfied_alt,
          label: 'Symptoms',
          color: FemFlowColors.pmsCaution,
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SymptomsScreen()));
            if (result == true) _handleRefresh();
          },
        ),
        _quickActionCard(
          context,
          icon: Icons.medication_outlined,
          label: 'Pill',
          color: Colors.orange,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'pill_reminder', 
            premiumScreen: const PillReminderListScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.restaurant_menu_outlined,
          label: 'Nutrition',
          color: Colors.orange,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'diet_plan', 
            premiumScreen: const DietHomeScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.shield_outlined,
          label: 'Vault',
          color: Colors.blue,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'health_vault', 
            premiumScreen: const HealthVaultScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.insights_outlined,
          label: 'Insights',
          color: FemFlowColors.aiWellness,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InsightsScreen()),
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.medical_services_outlined,
          label: 'Doctors',
          color: Colors.blue,
          isPremium: false,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DoctorConsultationHomeScreen()),
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.favorite_outline,
          label: 'Wellness',
          color: Colors.green,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'wellness_score', 
            premiumScreen: const WellnessScoreDashboardScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.fitness_center_outlined,
          label: 'Fitness',
          color: Colors.indigo,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'fitness_recommendations', 
            premiumScreen: const ExerciseHomeScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.groups_outlined,
          label: 'Community',
          color: Colors.teal,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'community', 
            premiumScreen: const CommunityHomeScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.edit_note_outlined,
          label: 'Journal',
          color: Colors.purple,
          isPremium: true,
          onTap: () => PremiumGuard.openPremiumFeature(
            context: context, 
            featureKey: 'journal', 
            premiumScreen: const JournalScreen()
          ),
        ),
        _quickActionCard(
          context,
          icon: Icons.event_available_outlined,
          label: 'Events',
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EventListScreen()),
          ),
        ),

      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    bool isPremium = false,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: FemFlowColors.textPrimary),
                ),
              ],
            ),
            if (isPremium && !PremiumGuard.isPremium(context))
              Positioned(
                top: 4,
                right: 4,
                child: Container(
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
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpertInsightsSection() {
    if (_topInsights.isEmpty && !_isLoadingDashboard) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Expert Insights',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExpertInsightsDiscoveryScreen()),
              ),
              child: const Text('View All →', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 340,
          child: _isLoadingDashboard
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _topInsights.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 10),
                      child: ExpertInsightCard(insight: _topInsights[index], isHorizontal: true),
                    );
                  },
                ),
        ),
      ],
    );
  }

}
