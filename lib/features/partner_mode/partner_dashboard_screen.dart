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
                            _buildSharedDataWidgets(),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildSharedDataWidgets() {
    final permissions = _dashboardData!['permissions'] as Map<String, dynamic>;
    List<Widget> widgets = [];

    if (permissions['period_dates'] == true && _dashboardData!['latest_period_start'] != null) {
      widgets.add(_buildInfoCard('Latest Period Start', _dashboardData!['latest_period_start']));
    } else if (permissions['period_dates'] != true) {
      widgets.add(_buildHiddenCard('Period Dates'));
    }

    if (permissions['cycle_predictions'] == true && _dashboardData!['expected_next_period'] != null) {
      widgets.add(_buildInfoCard('Expected Next Period', _dashboardData!['expected_next_period']));
    } else if (permissions['cycle_predictions'] != true) {
      widgets.add(_buildHiddenCard('Cycle Predictions'));
    }

    // You can implement fertile window and ovulation similarly

    if (permissions['symptoms'] == true || permissions['mood'] == true) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(const Text('Recent Health Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      widgets.add(const SizedBox(height: 12));
      
      final logs = _dashboardData!['recent_logs'] as List<dynamic>? ?? [];
      if (logs.isEmpty) {
        widgets.add(const Text('No recent logs available.', style: TextStyle(color: FemFlowColors.textMuted)));
      } else {
        for (var log in logs) {
          widgets.add(_buildLogCard(log, permissions['symptoms'] == true, permissions['mood'] == true));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['pill_reminders'] == true) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(const Text('Pill Reminders (Today)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      widgets.add(const SizedBox(height: 12));
      
      final pills = _dashboardData!['pill_schedule'] as List<dynamic>? ?? [];
      if (pills.isEmpty) {
        widgets.add(const Text('No medication scheduled for today.', style: TextStyle(color: FemFlowColors.textMuted)));
      } else {
        for (var pill in pills) {
          widgets.add(_buildPillCard(pill));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['journal'] == true) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(const Text('Shared Journal Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      widgets.add(const SizedBox(height: 12));
      
      final notes = _dashboardData!['recent_notes'] as List<dynamic>? ?? [];
      if (notes.isEmpty) {
        widgets.add(const Text('No shared notes available.', style: TextStyle(color: FemFlowColors.textMuted)));
      } else {
        for (var note in notes) {
          widgets.add(_buildNoteCard(note));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    if (permissions['wellness'] == true) {
      widgets.add(const SizedBox(height: 24));
      widgets.add(const Text('Recent Wellness Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      widgets.add(const SizedBox(height: 12));
      
      final activities = _dashboardData!['recent_activity'] as List<dynamic>? ?? [];
      if (activities.isEmpty) {
        widgets.add(const Text('No recent activity recorded.', style: TextStyle(color: FemFlowColors.textMuted)));
      } else {
        for (var activity in activities) {
          widgets.add(_buildActivityCard(activity));
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  Widget _buildPillCard(Map<String, dynamic> pill) {
    return AppCard(
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
              color: pill['status'] == 'taken' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
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
        ],
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return AppCard(
      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return AppCard(
      padding: const EdgeInsets.all(16),
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
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: FemFlowColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 4),
            Text(value.split('T').first, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildHiddenCard(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.lock, color: FemFlowColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Text('$title is hidden', style: const TextStyle(color: FemFlowColors.textMuted, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, bool showSymptoms, bool showMood) {
    return AppCard(
      padding: const EdgeInsets.all(16),
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
    );
  }
}
