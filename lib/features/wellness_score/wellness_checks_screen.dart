import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_check_models.dart';
import 'wellness_check_intro_screen.dart';
import 'wellness_accuracy_screen.dart';
import 'wellness_check_history_screen.dart';
import 'wellness_check_result_screen.dart';
import 'package:intl/intl.dart';

class WellnessChecksScreen extends StatefulWidget {
  const WellnessChecksScreen({super.key});

  @override
  State<WellnessChecksScreen> createState() => _WellnessChecksScreenState();
}

class _WellnessChecksScreenState extends State<WellnessChecksScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  List<WellnessCheckTemplate> _checks = [];
  Map<String, dynamic>? _accuracyData;
  List<WellnessCheckResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getWellnessChecks(),
        _service.getAccuracy(),
        _service.getWellnessCheckHistory(),
      ]);
      setState(() {
        _checks = results[0] as List<WellnessCheckTemplate>;
        _accuracyData = results[1] as Map<String, dynamic>;
        _history = results[2] as List<WellnessCheckResult>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Wellness Checks',
          style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: FemLyraColors.textPrimary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessCheckHistoryScreen())),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: FemLyraColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccuracyCard(),
                    const SizedBox(height: 24),
                    _buildTrustCard(),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Recommended Today'),
                    _buildCheckList('quick'),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Clinical-Inspired Checks'),
                    _buildCheckList('clinical_inspired'),
                    const SizedBox(height: 24),
                    _buildSectionHeader('Cycle-Linked Checks'),
                    _buildCheckList('cycle_linked'),
                    const SizedBox(height: 32),
                    if (_history.isNotEmpty) ...[
                      _buildSectionHeader('Recent Results'),
                      ..._history.take(3).map((res) => _buildHistoryItem(res)),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessCheckHistoryScreen())),
                          child: const Text('View All History', style: TextStyle(color: FemLyraColors.primary)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrustCard() {
    return AppCard(
      color: Colors.blue.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Private, educational, and personalized',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                SizedBox(height: 4),
                Text(
                  'These checks are wellness indicators, not medical diagnosis. Your answers are private and used to improve your femlyra.comsights.',
                  style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
      ),
    );
  }

  Widget _buildCheckList(String category) {
    final filtered = _checks.where((c) => c.category == category).toList();
    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('Wellness checks are being prepared.', style: TextStyle(color: FemLyraColors.textMuted, fontSize: 12)),
      );
    }

    return Column(
      children: filtered.map((check) => _buildCheckCard(check)).toList(),
    );
  }

  Widget _buildCheckCard(WellnessCheckTemplate check) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WellnessCheckIntroScreen(templateCode: check.code))).then((_) => _fetchData()),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(check.category).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCheckIcon(check.code), color: _getCategoryColor(check.category), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(check.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    '${check.questionCount} questions • ${check.estimatedMinutes} min',
                    style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  if (check.inspiredBy != null)
                    Text(
                      check.inspiredBy!,
                      style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: FemLyraColors.textMuted),
                    ),
                  if (check.lastCompleted != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last completed: ${DateFormat('MMM dd').format(DateTime.parse(check.lastCompleted!))}',
                      style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FemLyraColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildAccuracyCard() {
    if (_accuracyData == null) return const SizedBox.shrink();
    final level = _accuracyData!['accuracy_level'];
    final score = _accuracyData!['accuracy_score'];

    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WellnessAccuracyScreen())),
      color: FemLyraColors.fertileWindow.withValues(alpha: 0.1),
      border: const BorderSide(color: FemLyraColors.fertileWindow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('FemLyra Accuracy Level', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                level.toString().toUpperCase(),
                style: TextStyle(color: _getAccuracyColor(level), fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: _getAccuracyColor(level).withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_getAccuracyColor(level)),
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 12),
          Text(
            _accuracyData!['next_best_action'] ?? '',
            style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(WellnessCheckResult res) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WellnessCheckResultScreen(result: res),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(res.templateTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                  '${res.resultLabel} • ${DateFormat('MMM dd').format(DateTime.parse(res.completedAt))}',
                  style: const TextStyle(fontSize: 12, color: FemLyraColors.textSecondary),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text(
                '${res.normalizedScore}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'quick': return FemLyraColors.primary;
      case 'clinical_inspired': return Colors.blue;
      case 'cycle_linked': return FemLyraColors.period;
      default: return FemLyraColors.textMuted;
    }
  }

  IconData _getCheckIcon(String code) {
    switch (code) {
      case 'who5': return Icons.wb_sunny_outlined;
      case 'gad7': return Icons.psychology_outlined;
      case 'phq2': return Icons.sentiment_satisfied_outlined;
      case 'pms_lite': return Icons.water_drop_outlined;
      case 'quick_body_mind': return Icons.flash_on_outlined;
      case 'sleep_fatigue': return Icons.bedtime_outlined;
      case 'pain_impact': return Icons.healing_outlined;
      case 'focus_memory': return Icons.auto_stories_outlined;
      default: return Icons.assignment_outlined;
    }
  }

  Color _getAccuracyColor(dynamic level) {
    switch (level.toString().toLowerCase()) {
      case 'high': return Colors.green;
      case 'medium': return Colors.orange;
      default: return Colors.red;
    }
  }
}
