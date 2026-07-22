import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../services/health_integration_service.dart';
import '../data/health_service.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  final HealthService _healthService = HealthService();
  final HealthIntegrationService _healthIntegrationService = HealthIntegrationService();
  
  bool _isLoading = true;
  bool _isSyncing = false;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchTodayData();
  }

  Future<void> _fetchTodayData() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final data = await _healthService.getDailySummary(dateStr);
      setState(() {
        _summary = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSyncNow() async {
    setState(() => _isSyncing = true);
    try {
      await _healthIntegrationService.syncData();
      await _fetchTodayData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dashboard updated with latest health data')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e'), backgroundColor: FemLyraColors.period));
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        title: const Text('Health Data', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isSyncing ? null : _handleSyncNow,
            icon: _isSyncing 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: FemLyraColors.primary))
              : const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSourceCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Activity'),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildMetricCard('Steps', '${_summary?['steps'] ?? 0}', 'steps', Icons.directions_walk),
                    _buildMetricCard('Calories', '${_summary?['calories_burned'] ?? 0}', 'kcal', Icons.local_fire_department),
                    _buildMetricCard('Active', '${_summary?['active_minutes'] ?? 0}', 'min', Icons.timer),
                    _buildMetricCard('Workouts', '${_summary?['workout_minutes'] ?? 0}', 'min', Icons.fitness_center),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Vitals'),
                _buildListMetric('Heart Rate', '${_summary?['resting_heart_rate'] ?? '--'}', 'bpm', Icons.favorite),
                const SizedBox(height: 12),
                _buildListMetric('Sleep', '${(_summary?['sleep_minutes'] ?? 0) ~/ 60}h ${(_summary?['sleep_minutes'] ?? 0) % 60}m', 'total', Icons.bedtime),
                const SizedBox(height: 32),
                _buildSecurityNote(),
              ],
            ),
          ),
    );
  }

  Widget _buildSourceCard() {
    final source = _summary?['source_device'] ?? 'Connected Device';
    final aggregator = _summary?['aggregator'] ?? 'Health Connect';
    final lastSync = _summary?['last_synced_at'];

    return AppCard(
      color: FemLyraColors.blushMist,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.watch, color: FemLyraColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Synced from $source via ${aggregator.replaceAll('_', ' ').toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          if (lastSync != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last synced: ${DateFormat('MMM d, HH:mm').format(DateTime.parse(lastSync))}',
              style: const TextStyle(fontSize: 11, color: FemLyraColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textMuted, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: FemLyraColors.primary, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary)),
              Text('$unit $label', style: const TextStyle(fontSize: 10, color: FemLyraColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListMetric(String label, String value, String unit, IconData icon) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: FemLyraColors.primary, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary)),
          const SizedBox(width: 4),
          Text(unit, style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Your health data is encrypted and private.',
            style: TextStyle(fontSize: 11, color: FemLyraColors.textMuted, fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 8),
          Text(
            'FemLyra uses Health Connect to provide personalized wellness insights. You can revoke access anytime in settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: FemLyraColors.textMuted),
          ),
        ],
      ),
    );
  }
}
