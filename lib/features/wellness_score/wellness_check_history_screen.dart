import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_check_models.dart';
import 'wellness_check_result_screen.dart';
import 'package:intl/intl.dart';

class WellnessCheckHistoryScreen extends StatefulWidget {
  const WellnessCheckHistoryScreen({super.key});

  @override
  State<WellnessCheckHistoryScreen> createState() => _WellnessCheckHistoryScreenState();
}

class _WellnessCheckHistoryScreenState extends State<WellnessCheckHistoryScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  List<WellnessCheckResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await _service.getWellnessCheckHistory();
      setState(() {
        _history = history;
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
        title: const Text('Check History', style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _history.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  color: FemLyraColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(_history[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildHistoryCard(WellnessCheckResult res) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WellnessCheckResultScreen(result: res))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    res.templateTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(DateTime.parse(res.completedAt)),
                  style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: FemLyraColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Score: ${res.normalizedScore}',
                    style: const TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res.resultLabel,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: FemLyraColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: FemLyraColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: FemLyraColors.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          const Text('No wellness checks yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Start your first check to personalize your score.', style: TextStyle(color: FemLyraColors.textSecondary)),
        ],
      ),
    );
  }
}
