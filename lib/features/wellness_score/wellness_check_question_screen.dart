import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/wellness_score_service.dart';
import 'models/wellness_check_models.dart';
import 'wellness_check_result_screen.dart';

class WellnessCheckQuestionScreen extends StatefulWidget {
  final WellnessCheckTemplate template;
  const WellnessCheckQuestionScreen({super.key, required this.template});

  @override
  State<WellnessCheckQuestionScreen> createState() => _WellnessCheckQuestionScreenState();
}

class _WellnessCheckQuestionScreenState extends State<WellnessCheckQuestionScreen> {
  final WellnessScoreService _service = WellnessScoreService();
  int _currentIndex = 0;
  final Map<int, dynamic> _answers = {};
  bool _isSubmitting = false;

  void _next() {
    if (_currentIndex < widget.template.questions!.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _submit();
    }
  }

  void _previous() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final formattedAnswers = _answers.map((key, value) {
        final qId = widget.template.questions![key].id;
        return MapEntry(qId.toString(), value);
      });
      
      final result = await _service.submitWellnessCheck(widget.template.code, formattedAnswers);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => WellnessCheckResultScreen(result: result)),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.template.questions![_currentIndex];
    final progress = (_currentIndex + 1) / widget.template.questions!.length;

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: FemFlowColors.textPrimary),
          onPressed: _previous,
        ),
        title: Column(
          children: [
            Text(widget.template.title, style: const TextStyle(color: FemFlowColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            Text(
              'Question ${_currentIndex + 1} of ${widget.template.questions!.length}',
              style: const TextStyle(color: FemFlowColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: FemFlowColors.border.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(FemFlowColors.primary),
            minHeight: 4,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionText,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary, height: 1.3),
                  ),
                  const SizedBox(height: 48),
                  _buildAnswerInput(question),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildAnswerInput(WellnessCheckQuestion question) {
    if (question.answerType == 'scale') {
      return _buildSliderInput(question);
    }
    
    // For single_choice, rating_choice, frequency_choice
    return Column(
      children: question.options.map((opt) => _buildOptionCard(opt)).toList(),
    );
  }

  Widget _buildOptionCard(WellnessAnswerOption opt) {
    final isSelected = _answers[_currentIndex] == opt.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () {
          setState(() => _answers[_currentIndex] = opt.value);
          // Small delay for visual feedback before auto-next
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) _next();
          });
        },
        color: isSelected ? FemFlowColors.primary : Colors.white,
        border: BorderSide(color: isSelected ? FemFlowColors.primary : FemFlowColors.border, width: isSelected ? 2 : 1),
        child: Row(
          children: [
            Expanded(
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : FemFlowColors.textPrimary,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderInput(WellnessCheckQuestion question) {
    double currentVal = (_answers[_currentIndex] ?? 0).toDouble();
    return Column(
      children: [
        Text(
          '${currentVal.toInt()}',
          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
        ),
        const SizedBox(height: 24),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: FemFlowColors.primary,
            inactiveTrackColor: FemFlowColors.border,
            thumbColor: FemFlowColors.primary,
            overlayColor: FemFlowColors.primary.withValues(alpha: 0.2),
            valueIndicatorColor: FemFlowColors.primary,
          ),
          child: Slider(
            value: currentVal,
            min: (question.minValue ?? 0).toDouble(),
            max: (question.maxValue ?? 10).toDouble(),
            divisions: (question.maxValue ?? 10) - (question.minValue ?? 0),
            label: currentVal.toInt().toString(),
            onChanged: (val) {
              setState(() => _answers[_currentIndex] = val.toInt());
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
             Text(question.minValue == 0 && question.domain == 'stress' ? 'Not stressed' : 'Low', style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
             Text(question.maxValue == 10 ? 'High' : 'Very high', style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    bool hasAnswer = _answers.containsKey(_currentIndex);
    bool isLast = _currentIndex == widget.template.questions!.length - 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previous,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: FemFlowColors.primary),
                      ),
                      child: const Text('Back', style: TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: isLast ? 'Submit Check' : 'Next Question',
                    onPressed: hasAnswer ? _next : null,
                    isLoading: isLast && _isSubmitting,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Private and secure • Not a diagnosis',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
