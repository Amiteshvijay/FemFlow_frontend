import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import 'data/chat_service.dart';
import 'models/conversation_language.dart';
import 'models/femai_conversation_state.dart';
import 'services/speech_tts_service.dart';
import 'widgets/emergency_action_card.dart';
import 'widgets/end_conversation_summary_dialog.dart';
import 'widgets/femai_avatar_animation.dart';
import 'widgets/language_selection_dialog.dart';

class FemAIConversationScreen extends StatefulWidget {
  final Map<String, dynamic>? dayContext;
  final String? initialLanguageCode;

  const FemAIConversationScreen({
    super.key,
    this.dayContext,
    this.initialLanguageCode,
  });

  @override
  State<FemAIConversationScreen> createState() => _FemAIConversationScreenState();
}

class _FemAIConversationScreenState extends State<FemAIConversationScreen> {
  final ChatService _chatService = ChatService();
  final SpeechTtsService _ttsService = SpeechTtsService();
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  FemAIConversationState _state = FemAIConversationState.idle;
  late ConversationLanguage _selectedLanguage;
  bool _autoDetect = false;

  String _userTranscript = '';
  String _latestAiResponseText = '';
  int? _sessionId;
  int? _lastAiMessageId;

  bool _showEmergencyCard = false;
  String _emergencyMessage = '';
  bool _isTextInputVisible = false;

  final List<Map<String, String>> _turns = [];

  @override
  void initState() {
    super.initState();
    _selectedLanguage = ConversationLanguage.getByCode(widget.initialLanguageCode ?? 'hi-IN');
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.stopListening();
    _ttsService.stopSpeaking();
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openLanguageSelector() async {
    final result = await showDialog<LanguageSelectionResult>(
      context: context,
      builder: (context) => LanguageSelectionDialog(
        initialLanguage: _selectedLanguage,
        initialAutoDetect: _autoDetect,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLanguage = result.selectedLanguage;
        _autoDetect = result.autoDetect;
      });
    }
  }

  Future<void> _toggleListening() async {
    if (_state == FemAIConversationState.listening) {
      await _ttsService.stopListening();
      if (_userTranscript.isNotEmpty) {
        _submitTranscript(_userTranscript);
      } else {
        setState(() {
          _state = FemAIConversationState.idle;
        });
      }
      return;
    }

    if (_state == FemAIConversationState.speaking) {
      await _ttsService.stopSpeaking();
    }

    setState(() {
      _state = FemAIConversationState.listening;
      _userTranscript = '';
    });

    await _ttsService.startListening(
      localeId: _selectedLanguage.localeId,
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _userTranscript = text;
          });
          if (isFinal && text.trim().isNotEmpty) {
            _submitTranscript(text);
          }
        }
      },
      onListeningComplete: () {
        if (mounted && _state == FemAIConversationState.listening) {
          if (_userTranscript.trim().isNotEmpty) {
            _submitTranscript(_userTranscript);
          } else {
            setState(() {
              _state = FemAIConversationState.idle;
            });
          }
        }
      },
    );
  }

  Future<void> _submitTranscript(String transcriptText) async {
    final trimmed = transcriptText.trim();
    if (trimmed.isEmpty) return;

    await _ttsService.stopListening();

    setState(() {
      _userTranscript = trimmed;
      _state = FemAIConversationState.thinking;
    });

    try {
      final response = await _chatService.sendConversationTurn(
        transcript: trimmed,
        sessionId: _sessionId,
        languageCode: _selectedLanguage.code,
        autoDetect: _autoDetect,
        dayContext: widget.dayContext,
      );

      if (!mounted) return;

      final sessionVal = response['session_id'];
      if (sessionVal != null && sessionVal is int) {
        _sessionId = sessionVal;
      }

      final aiText = response['response_text'] ?? '';
      final riskLevel = response['risk_level'] ?? 'normal';
      final emergencyMsg = response['emergency_message'] ?? '';
      _lastAiMessageId = response['ai_message_id'];

      setState(() {
        _latestAiResponseText = aiText;
        _turns.add({'user': trimmed, 'ai': aiText});
        if (riskLevel == 'emergency' && emergencyMsg.isNotEmpty) {
          _showEmergencyCard = true;
          _emergencyMessage = emergencyMsg;
        } else {
          _showEmergencyCard = false;
        }
        _state = FemAIConversationState.speaking;
      });

      _scrollToBottom();

      // Trigger Text-to-Speech Output
      await _ttsService.speak(
        text: aiText,
        languageCode: response['detected_language'] ?? _selectedLanguage.code,
        onStart: () {
          if (mounted) {
            setState(() {
              _state = FemAIConversationState.speaking;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _state = FemAIConversationState.idle;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = FemAIConversationState.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _replayLatestResponse() {
    if (_latestAiResponseText.isEmpty) return;
    _ttsService.replay(
      text: _latestAiResponseText,
      languageCode: _selectedLanguage.code,
      onStart: () {
        if (mounted) {
          setState(() {
            _state = FemAIConversationState.speaking;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _state = FemAIConversationState.idle;
          });
        }
      },
    );
  }

  void _stopSpeaking() {
    _ttsService.stopSpeaking();
    setState(() {
      _state = FemAIConversationState.idle;
    });
  }

  void _endConversation() {
    showDialog(
      context: context,
      builder: (context) => EndConversationSummaryDialog(
        totalTurns: _turns.length,
        languageName: _selectedLanguage.name,
        onConfirmEnd: () {
          setState(() {
            _state = FemAIConversationState.ended;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _reportResponse() {
    if (_lastAiMessageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No response to report yet.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Incorrect Response'),
        content: const Text('Would you like to flag this response for clinical accuracy review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _chatService.reportResponse(
                messageId: _lastAiMessageId!,
                reason: 'Inaccurate or unsatisfactory voice response',
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you. Response flagged for clinical review.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: FemLyraColors.primary),
            child: const Text('Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: FemLyraColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "FemAI Conversation",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
            ),
            GestureDetector(
              onTap: _openLanguageSelector,
              child: Row(
                children: [
                  Text(
                    "Language: ${_selectedLanguage.name} (${_selectedLanguage.nativeName})",
                    style: const TextStyle(fontSize: 12, color: FemLyraColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: FemLyraColors.primary),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: FemLyraColors.textPrimary),
            onSelected: (val) {
              if (val == 'language') _openLanguageSelector();
              if (val == 'report') _reportResponse();
              if (val == 'end') _endConversation();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'language', child: Text('Change Language')),
              const PopupMenuItem(value: 'report', child: Text('Report Incorrect Response')),
              const PopupMenuItem(value: 'end', child: Text('End Conversation')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Center Avatar Animation
            FemAIAvatarAnimation(
              state: _state,
              onTap: _toggleListening,
            ),
            const SizedBox(height: 12),

            // Live Status Text Banner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _state.getStatusMessage(_selectedLanguage.code),
                key: ValueKey(_state),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _state == FemAIConversationState.listening
                      ? FemLyraColors.primary
                      : Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Emergency Action Card if triggered
            if (_showEmergencyCard)
              EmergencyActionCard(
                emergencyMessage: _emergencyMessage,
                onConsultDoctor: () {
                  Navigator.of(context).pop();
                  // Navigate to doctor consultation feature if route registered
                },
                onDismiss: () {
                  setState(() {
                    _showEmergencyCard = false;
                  });
                },
              ),

            // Scrollable Conversation History View
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _turns.isEmpty && _userTranscript.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_none_rounded, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text(
                              "Speak naturally about your health,\ncycle, pregnancy, nutrition or wellness.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        itemCount: _turns.length + (_userTranscript.isNotEmpty ? 1 : 0),
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          if (index < _turns.length) {
                            final turn = _turns[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildUserBubble(turn['user'] ?? ''),
                                const SizedBox(height: 6),
                                _buildAiBubble(turn['ai'] ?? ''),
                              ],
                            );
                          } else {
                            return _buildUserBubble(_userTranscript, isLive: true);
                          }
                        },
                      ),
              ),
            ),

            // Text Input Box (Toggleable)
            if (_isTextInputVisible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                          hintText: "Type your question...",
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: FemLyraColors.primary),
                      onPressed: () {
                        final text = _textEditingController.text.trim();
                        if (text.isNotEmpty) {
                          _textEditingController.clear();
                          _submitTranscript(text);
                        }
                      },
                    ),
                  ],
                ),
              ),

            // Turn-based Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primary Microphone Button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _state == FemAIConversationState.listening
                              ? [Colors.redAccent, Colors.red]
                              : [FemLyraColors.primary, const Color(0xFFE91E63)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: FemLyraColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _state == FemAIConversationState.listening
                                ? Icons.stop_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _state == FemAIConversationState.listening
                                ? "Stop & Process"
                                : "🎤 Speak",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Control Options Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Replay / Stop Speaking
                      if (_state == FemAIConversationState.speaking)
                        InkWell(
                          onTap: _stopSpeaking,
                          child: Row(
                            children: const [
                              Icon(Icons.stop_circle_outlined, color: Colors.redAccent, size: 18),
                              SizedBox(width: 4),
                              Text("Stop", style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: _replayLatestResponse,
                          child: Row(
                            children: const [
                              Icon(Icons.volume_up_rounded, color: FemLyraColors.primary, size: 18),
                              SizedBox(width: 4),
                              Text("Replay", style: TextStyle(fontSize: 13, color: FemLyraColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),

                      // Toggle Type Mode
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isTextInputVisible = !_isTextInputVisible;
                          });
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.keyboard_rounded, color: Colors.grey, size: 18),
                            SizedBox(width: 4),
                            Text("Type", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),

                      // End Conversation
                      InkWell(
                        onTap: _endConversation,
                        child: Row(
                          children: const [
                            Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                            SizedBox(width: 4),
                            Text("End", style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(String text, {bool isLive = false}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FemLyraColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLive)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: FemLyraColors.primary),
                  ),
                if (isLive) const SizedBox(width: 6),
                const Text("You", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: FemLyraColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.auto_awesome_rounded, size: 14, color: FemLyraColors.primary),
                SizedBox(width: 4),
                Text("FemAI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              text,
              style: const TextStyle(fontSize: 14, color: FemLyraColors.textPrimary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
