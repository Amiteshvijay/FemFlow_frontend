import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import '../../core/theme/femflow_colors.dart';
import 'data/chat_service.dart';

class FemAIChatScreen extends StatefulWidget {
  final String? initialMessage;
  final Map<String, dynamic>? dayContext;
  const FemAIChatScreen({super.key, this.initialMessage, this.dayContext});

  @override
  State<FemAIChatScreen> createState() => _FemAIChatScreenState();
}

class _FemAIChatScreenState extends State<FemAIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<ChatMessageModel> _messages = [];
  bool _isTyping = false;
  bool _showScrollToBottom = false;
  int? _sessionId;

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _scrollController.addListener(_scrollListener);
    _loadChatHistory().then((_) {
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _messageController.text = widget.initialMessage!;
        _handleSendMessage();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final response = await _chatService.getChatHistory();
      if (mounted) {
        setState(() {
          _sessionId = response['session_id'];
          final messages = response['messages'] as List<dynamic>?;
          if (messages != null && messages.isNotEmpty) {
            _messages.clear();
            for (var msg in messages) {
              _messages.add(ChatMessageModel(
                content: msg['content'],
                role: msg['role'],
                timestamp: DateTime.parse(msg['created_at']),
              ));
            }
          } else {
            // Add welcome message if no history
            _messages.add(ChatMessageModel(
              content: 'Hi there! 👋\nHow can I help you today?',
              role: 'assistant',
              timestamp: DateTime.now(),
            ));
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessageModel(
            content: 'Hi there! 👋\nHow can I help you today?',
            role: 'assistant',
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onError: (val) {
          // Log error internally or show snackbar if critical
        },
        onStatus: (val) {
          // Track status internally
        },
      );
    } catch (e) {
      // Fail silently or handle initialization error
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _messageController.text = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final show = _scrollController.offset < _scrollController.position.maxScrollExtent - 200;
      if (show != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = show;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessageModel(
        content: text,
        role: 'user',
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        text, 
        sessionId: _sessionId,
        dayContext: widget.dayContext,
      );
      if (mounted) {
        setState(() {
          _sessionId = response['session_id'];
          _messages.add(ChatMessageModel(
            content: response['response'],
            role: 'assistant',
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get AI response'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'FemAI ✨',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FemFlowColors.textPrimary,
              ),
            ),
            Text(
              'Your personal health AI',
              style: TextStyle(
                fontSize: 12,
                color: FemFlowColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
               setState(() {
                 _messages.clear();
                 _messages.add(ChatMessageModel(
                    content: 'How can I help you today?',
                    role: 'assistant',
                    timestamp: DateTime.now(),
                  ));
                 _sessionId = null;
               });
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _buildTypingIndicator(),
                      );
                    }
                    final message = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: message.isUser
                          ? _buildUserChatBubble(message.content, DateFormat('hh:mm a').format(message.timestamp))
                          : _buildAIChatBubble(index, message, DateFormat('hh:mm a').format(message.timestamp)),
                    );
                  },
                ),
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: FemFlowColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildSafetyDisclaimer(),
          _buildInputArea(context),
        ],
      ),
    );
  }

  Widget _buildAIChatBubble(int index, ChatMessageModel message, String time) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FemFlowColors.aiWellness.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: FemFlowColors.aiWellness.withValues(alpha: 0.2)),
            ),
            child: Text(
              message.content,
              style: const TextStyle(color: FemFlowColors.textPrimary, height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _messages[index].isLiked = !_messages[index].isLiked;
                  });
                },
                child: Icon(
                  _messages[index].isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 16,
                  color: _messages[index].isLiked ? Colors.red : FemFlowColors.textMuted,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Share.share(message.content);
                },
                child: const Icon(Icons.ios_share, size: 16, color: FemFlowColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserChatBubble(String message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: FemFlowColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(fontSize: 10, color: FemFlowColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: FemFlowColors.aiWellness.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const SizedBox(
          width: 30,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(FemFlowColors.aiWellness),
            minHeight: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: const Text(
        'FemAI gives educational information only and is not a substitute for medical advice.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: FemFlowColors.textMuted),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: FemFlowColors.warmWhite,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: FemFlowColors.border),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: const TextStyle(color: FemFlowColors.textMuted),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? FemFlowColors.primary : FemFlowColors.textMuted,
                    ),
                    onPressed: _listen,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _handleSendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: FemFlowColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
