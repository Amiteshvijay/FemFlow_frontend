import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../core/network/api_client.dart';
import '../auth/providers/auth_provider.dart';
import 'data/partner_service.dart';

class PartnerDashboardScreen extends StatefulWidget {
  const PartnerDashboardScreen({super.key});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  final PartnerService _partnerService = PartnerService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final data = await _partnerService.getDashboard();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (e is ApiException && (e.statusCode == 404 || e.statusCode == 403)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your partner connection is no longer active. Logging out...'),
              backgroundColor: FemFlowColors.period,
            ),
          );
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              context.read<AuthProvider>().logout();
            }
          });
        } else {
          setState(() {
            _errorMessage = e.toString();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final partnerName = authProvider.profile?.fullName ?? '';
    final firstName = partnerName.isNotEmpty ? partnerName.split(' ').first : 'there';

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

    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Partner Dashboard', style: TextStyle(color: FemFlowColors.textPrimary)),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: FemFlowColors.period),
                        const SizedBox(height: 16),
                        Text('Failed to load dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: FemFlowColors.textSecondary)),
                        ),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _fetchDashboard, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _dashboardData == null
                    ? const Center(child: Text('No active connection found.'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hi, $firstName 🌸',
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
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Viewing data for ${_dashboardData!['user_name']}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                            ),
                            const SizedBox(height: 16),
                            _buildQuickActionsSection(),
                            _buildSharedDataWidgets(),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final permissions = _dashboardData!['permissions'] as Map<String, dynamic>;
    final List<Map<String, dynamic>> quickActions = [];
    
    if (permissions['period_dates'] == true || permissions['cycle_predictions'] == true || permissions['fertile_window'] == true || permissions['ovulation_day'] == true) {
      quickActions.add({
        'label': 'Period',
        'icon': Icons.opacity,
        'color': FemFlowColors.period,
        'screen': PartnerPeriodDetailScreen(dashboardData: _dashboardData!),
      });
    }
    
    if (permissions['symptoms'] == true || permissions['mood'] == true) {
      quickActions.add({
        'label': 'Symptoms',
        'icon': Icons.sentiment_satisfied_alt,
        'color': FemFlowColors.pmsCaution,
        'screen': PartnerSymptomsDetailScreen(dashboardData: _dashboardData!),
      });
    }
    
    if (permissions['pill_reminders'] == true) {
      quickActions.add({
        'label': 'Pill',
        'icon': Icons.medication_outlined,
        'color': Colors.orange,
        'screen': PartnerPillDetailScreen(dashboardData: _dashboardData!),
      });
    }
    
    if (permissions['journal'] == true) {
      quickActions.add({
        'label': 'Journal',
        'icon': Icons.edit_note_outlined,
        'color': Colors.purple,
        'screen': PartnerJournalDetailScreen(dashboardData: _dashboardData!),
      });
    }
    
    if (permissions['wellness'] == true) {
      quickActions.add({
        'label': 'Wellness',
        'icon': Icons.favorite_outline,
        'color': Colors.green,
        'screen': PartnerWellnessDetailScreen(dashboardData: _dashboardData!),
      });
    }
    
    if (permissions['nutrition'] == true) {
      quickActions.add({
        'label': 'Nutrition',
        'icon': Icons.restaurant_menu_outlined,
        'color': Colors.orange,
        'screen': PartnerNutritionDetailScreen(dashboardData: _dashboardData!),
      });
    }

    if (quickActions.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: FemFlowColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: quickActions.length,
          itemBuilder: (context, index) {
            final action = quickActions[index];
            return _quickActionCard(
              context,
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              color: action['color'] as Color,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => action['screen'] as Widget),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _quickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
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
      ),
    );
  }

  Widget _buildSharedDataWidgets() {
    final permissions = _dashboardData!['permissions'] as Map<String, dynamic>;
    List<Widget> widgets = [];

    if (permissions['period_dates'] == true && _dashboardData!['latest_period_start'] != null) {
      widgets.add(_buildInfoCard('Latest Period Start', _dashboardData!['latest_period_start'], onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerPeriodDetailScreen(dashboardData: _dashboardData!)));
      }));
    }

    if (permissions['cycle_predictions'] == true && _dashboardData!['expected_next_period'] != null) {
      widgets.add(_buildInfoCard('Expected Next Period', _dashboardData!['expected_next_period'], onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerPeriodDetailScreen(dashboardData: _dashboardData!)));
      }));
    }

    if (permissions['symptoms'] == true || permissions['mood'] == true) {
      final logs = _dashboardData!['recent_logs'] as List<dynamic>? ?? [];
      if (logs.isNotEmpty) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(const Text('Recent Health Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
        widgets.add(const SizedBox(height: 12));
        
        for (var log in logs) {
          widgets.add(_buildLogCard(log, permissions['symptoms'] == true, permissions['mood'] == true, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerSymptomsDetailScreen(dashboardData: _dashboardData!)));
          }));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['pill_reminders'] == true) {
      final pills = _dashboardData!['pill_schedule'] as List<dynamic>? ?? [];
      if (pills.isNotEmpty) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(const Text('Pill Reminders (Today)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
        widgets.add(const SizedBox(height: 12));
        
        for (var pill in pills) {
          widgets.add(_buildPillCard(pill, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerPillDetailScreen(dashboardData: _dashboardData!)));
          }));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['journal'] == true) {
      final notes = _dashboardData!['recent_notes'] as List<dynamic>? ?? [];
      if (notes.isNotEmpty) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(const Text('Shared Journal Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
        widgets.add(const SizedBox(height: 12));
        
        for (var note in notes) {
          widgets.add(_buildNoteCard(note, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerJournalDetailScreen(dashboardData: _dashboardData!)));
          }));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['wellness'] == true) {
      final activities = _dashboardData!['recent_activity'] as List<dynamic>? ?? [];
      if (activities.isNotEmpty) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(const Text('Recent Wellness Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
        widgets.add(const SizedBox(height: 12));
        
        for (var activity in activities) {
          widgets.add(_buildActivityCard(activity, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerWellnessDetailScreen(dashboardData: _dashboardData!)));
          }));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['nutrition'] == true) {
      final foodLogs = _dashboardData!['recent_food_logs'] as List<dynamic>? ?? [];
      if (foodLogs.isNotEmpty) {
        widgets.add(const SizedBox(height: 24));
        widgets.add(const Text('Recent Nutrition Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
        widgets.add(const SizedBox(height: 12));
        
        for (var log in foodLogs) {
          widgets.add(_buildFoodCard(log, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PartnerNutritionDetailScreen(dashboardData: _dashboardData!)));
          }));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildPillCard(Map<String, dynamic> pill, {VoidCallback? onTap}) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.medication, color: FemFlowColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pill['medication_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(pill['time'], style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pill['status'] == 'taken' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              pill['status'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: pill['status'] == 'taken' ? Colors.green : Colors.orange,
              ),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note, {VoidCallback? onTap}) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(note['date'], style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(note['content'], style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary)),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, {VoidCallback? onTap}) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activity['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(activity['date'], style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${activity['duration']} mins', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${activity['calories']} kcal', style: const TextStyle(fontSize: 11, color: FemFlowColors.period)),
                  ],
                ),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> log, {VoidCallback? onTap}) {
    final calories = log['calories'];
    final protein = log['protein'];
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['custom_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${log['meal_type'].toString().toUpperCase()} • ${log['quantity']}', style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (calories != null) Text('$calories kcal', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (protein != null) Text('$protein g protein', style: const TextStyle(fontSize: 11, color: Colors.green)),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value.split('T').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool showSymptoms, bool showMood, {VoidCallback? onTap}) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['date'], style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (showSymptoms && log['symptoms'] != null) ...[
                  const Text('Symptoms: ', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                  Text(log['symptoms'].toString()),
                ],
                if (showMood && log['mood'] != null) ...[
                  const SizedBox(height: 4),
                  const Text('Mood: ', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                  Text(log['mood'].toString()),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted, size: 20),
          ]
        ],
      ),
    );
  }
}

class PartnerPeriodDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  const PartnerPeriodDetailScreen({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final permissions = dashboardData['permissions'] as Map<String, dynamic>;
    final hasPeriod = permissions['period_dates'] == true;
    final hasPrediction = permissions['cycle_predictions'] == true;

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Period Details', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPeriod) ...[
              const Text('Period Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: FemFlowColors.period, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Latest Period Start', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          dashboardData['latest_period_start'] != null
                              ? dashboardData['latest_period_start'].toString().split('T').first
                              : 'Not logged yet',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (hasPrediction) ...[
              const Text('Predictions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: FemFlowColors.ovulation, size: 36),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expected Next Period', style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          dashboardData['expected_next_period'] != null
                              ? dashboardData['expected_next_period'].toString().split('T').first
                              : 'Calculating...',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            AppCard(
              padding: const EdgeInsets.all(16),
              color: FemFlowColors.primary.withOpacity(0.05),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: FemFlowColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This information is shared by your partner to help you align with their cycle phases.',
                      style: TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerSymptomsDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  const PartnerSymptomsDetailScreen({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final permissions = dashboardData['permissions'] as Map<String, dynamic>;
    final showSymptoms = permissions['symptoms'] == true;
    final showMood = permissions['mood'] == true;
    final logs = dashboardData['recent_logs'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Shared Health Logs', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: logs.isEmpty ? 1 : logs.length,
        itemBuilder: (context, index) {
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No health logs shared by partner.', style: TextStyle(color: FemFlowColors.textSecondary)),
              ),
            );
          }
          final log = logs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        log['date'].toString().split('T').first,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemFlowColors.textPrimary),
                      ),
                      const Icon(Icons.favorite, color: FemFlowColors.period, size: 18),
                    ],
                  ),
                  const Divider(height: 20),
                  if (showSymptoms && log['symptoms'] != null) ...[
                    const Text('Symptoms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(log['symptoms'].toString(), style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary)),
                    const SizedBox(height: 12),
                  ],
                  if (showMood && log['mood'] != null) ...[
                    const Text('Mood', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(log['mood'].toString(), style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PartnerPillDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  const PartnerPillDetailScreen({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final pills = dashboardData['pill_schedule'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Pill Reminders', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: pills.isEmpty ? 1 : pills.length,
        itemBuilder: (context, index) {
          if (pills.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No pill reminders scheduled for today.', style: TextStyle(color: FemFlowColors.textSecondary)),
              ),
            );
          }
          final pill = pills[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.medication, color: Colors.orange, size: 30),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pill['medication_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Scheduled for ${pill['time']}', style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: pill['status'] == 'taken' ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pill['status'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pill['status'] == 'taken' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PartnerJournalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  const PartnerJournalDetailScreen({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final notes = dashboardData['recent_notes'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Shared Journal', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: notes.isEmpty ? 1 : notes.length,
        itemBuilder: (context, index) {
          if (notes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No journal entries shared.', style: TextStyle(color: FemFlowColors.textSecondary)),
              ),
            );
          }
          final note = notes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(note['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(note['date'], style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted)),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    note['content'],
                    style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PartnerWellnessDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  const PartnerWellnessDetailScreen({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final activities = dashboardData['recent_activity'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Wellness Activity', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: activities.isEmpty ? 1 : activities.length,
        itemBuilder: (context, index) {
          if (activities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No recent wellness activities shared.', style: TextStyle(color: FemFlowColors.textSecondary)),
              ),
            );
          }
          final activity = activities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fitness_center, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['type'].toString().toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(activity['date'], style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${activity['duration']} mins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('${activity['calories']} kcal', style: const TextStyle(fontSize: 12, color: FemFlowColors.period, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class PartnerNutritionDetailScreen extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  const PartnerNutritionDetailScreen({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final foodLogs = dashboardData['recent_food_logs'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Nutrition Logs', style: TextStyle(color: FemFlowColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: foodLogs.isEmpty ? 1 : foodLogs.length,
        itemBuilder: (context, index) {
          if (foodLogs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Text('No nutrition logs shared by partner.', style: TextStyle(color: FemFlowColors.textSecondary)),
              ),
            );
          }
          final log = foodLogs[index];
          final calories = log['calories'];
          final protein = log['protein'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['custom_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          '${log['meal_type'].toString().toUpperCase()} • ${log['quantity']}',
                          style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(log['date'], style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (calories != null) Text('$calories kcal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (protein != null) ...[
                        const SizedBox(height: 4),
                        Text('$protein g protein', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
