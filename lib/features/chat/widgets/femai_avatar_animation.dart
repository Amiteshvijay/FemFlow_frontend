import 'package:flutter/material.dart';
import '../models/femai_conversation_state.dart';
import '../../../core/theme/FemLyra_colors.dart';

class FemAIAvatarAnimation extends StatefulWidget {
  final FemAIConversationState state;
  final VoidCallback? onTap;

  const FemAIAvatarAnimation({
    super.key,
    required this.state,
    this.onTap,
  });

  @override
  State<FemAIAvatarAnimation> createState() => _FemAIAvatarAnimationState();
}

class _FemAIAvatarAnimationState extends State<FemAIAvatarAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant FemAIAvatarAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      switch (widget.state) {
        case FemAIConversationState.listening:
          _controller.duration = const Duration(milliseconds: 800);
          _controller.repeat(reverse: true);
          break;
        case FemAIConversationState.thinking:
        case FemAIConversationState.transcribing:
          _controller.duration = const Duration(milliseconds: 500);
          _controller.repeat(reverse: true);
          break;
        case FemAIConversationState.speaking:
          _controller.duration = const Duration(milliseconds: 1100);
          _controller.repeat(reverse: true);
          break;
        default:
          _controller.duration = const Duration(milliseconds: 2000);
          _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getRingColor() {
    switch (widget.state) {
      case FemAIConversationState.listening:
        return FemLyraColors.primary;
      case FemAIConversationState.transcribing:
      case FemAIConversationState.thinking:
        return const Color(0xFF9C27B0);
      case FemAIConversationState.speaking:
        return const Color(0xFF00BCD4);
      case FemAIConversationState.error:
        return Colors.redAccent;
      default:
        return FemLyraColors.softBlush;
    }
  }

  IconData _getCenterIcon() {
    switch (widget.state) {
      case FemAIConversationState.listening:
        return Icons.mic_rounded;
      case FemAIConversationState.transcribing:
      case FemAIConversationState.thinking:
        return Icons.psychology_rounded;
      case FemAIConversationState.speaking:
        return Icons.record_voice_over_rounded;
      case FemAIConversationState.error:
        return Icons.warning_amber_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = _getRingColor();

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring
                if (widget.state.isActive)
                  Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ringColor.withOpacity(0.15),
                      ),
                    ),
                  ),

                // Middle Ring
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          ringColor.withOpacity(0.4),
                          ringColor.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),

                // Core Avatar Circle
                Container(
                  width: 95,
                  height: 95,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        FemLyraColors.primary,
                        const Color(0xFFE91E63),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ringColor.withOpacity(0.4),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getCenterIcon(),
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
