import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:share_plus/share_plus.dart';
import '../../core/theme/FemLyra_colors.dart';
import 'data/chat_service.dart';
import 'femai_conversation_screen.dart';

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
  List<dynamic> _sessions = [];
  bool _loadingSessions = false;

  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _scrollController.addListener(_scrollListener);
    _loadChatHistory().then((_) {
      _loadSessions();
      if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
        _messageController.text = widget.initialMessage!;
        _handleSendMessage();
      }
    });
  }

  Future<void> _loadSessions() async {
    if (!mounted) return;
    setState(() {
      _loadingSessions = true;
    });
    try {
      final sessions = await _chatService.getChatSessions();
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loadingSessions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingSessions = false;
        });
      }
    }
  }

  Future<void> _loadChatHistory({int? sessionId}) async {
    try {
      final response = await _chatService.getChatHistory(sessionId: sessionId);
      if (mounted) {
        setState(() {
          _sessionId = response['session_id'];
          final messages = response['messages'] as List<dynamic>?;
          if (messages != null && messages.isNotEmpty) {
            _messages.clear();
            for (var msg in messages) {
              final metadata = msg['metadata'];
              List<String>? parsedTools;
              if (metadata is Map && metadata['tools_used'] is List) {
                parsedTools = (metadata['tools_used'] as List).map((e) => e.toString()).toList();
              }
              _messages.add(ChatMessageModel(
                id: msg['id'],
                content: msg['content'],
                role: msg['role'],
                timestamp: DateTime.parse(msg['created_at']),
                toolsUsed: parsedTools,
              ));
            }
          } else {
            _messages.clear();
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
          _messages.clear();
          _messages.add(ChatMessageModel(
            content: 'Hi there! 👋\nHow can I help you today?',
            role: 'assistant',
            timestamp: DateTime.now(),
          ));
        });
      }
    }
  }

  Future<void> _selectSession(int sessionId) async {
    Navigator.of(context).pop(); // Close drawer
    await _loadChatHistory(sessionId: sessionId);
  }

  void _startNewChat() {
    Navigator.of(context).pop(); // Close drawer
    setState(() {
      _messages.clear();
      _messages.add(ChatMessageModel(
        content: 'Hi there! 👋\nHow can I help you today?',
        role: 'assistant',
        timestamp: DateTime.now(),
      ));
      _sessionId = null;
    });
  }

  Future<void> _deleteSession(int sessionId) async {
    try {
      await _chatService.deleteChatSession(sessionId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chat session deleted'), behavior: SnackBarBehavior.floating),
        );
        if (_sessionId == sessionId) {
          setState(() {
            _messages.clear();
            _messages.add(ChatMessageModel(
              content: 'Hi there! 👋\nHow can I help you today?',
              role: 'assistant',
              timestamp: DateTime.now(),
            ));
            _sessionId = null;
          });
        }
        _loadSessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete chat session'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _confirmDeleteSession(int sessionId, String topic) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: FemLyraColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Chat Session',
            style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete the chat session "$topic"? This cannot be undone.',
            style: const TextStyle(color: FemLyraColors.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: FemLyraColors.textSecondary)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSession(sessionId);
              },
            ),
          ],
        );
      },
    );
  }

  Map<String, List<dynamic>> _getGroupedSessions() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));
    final sevenDaysAgoDate = todayDate.subtract(const Duration(days: 7));

    final Map<String, List<dynamic>> groups = {
      'Today': [],
      'Yesterday': [],
      'Last 7 Days': [],
      'Older': [],
    };

    for (var session in _sessions) {
      final dateStr = session['date'] as String?;
      if (dateStr == null) continue;
      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate == null) continue;
      
      final sessionDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      if (sessionDate.isAtSameMomentAs(todayDate)) {
        groups['Today']!.add(session);
      } else if (sessionDate.isAtSameMomentAs(yesterdayDate)) {
        groups['Yesterday']!.add(session);
      } else if (sessionDate.isAfter(sevenDaysAgoDate)) {
        groups['Last 7 Days']!.add(session);
      } else {
        groups['Older']!.add(session);
      }
    }
    
    groups.removeWhere((key, value) => value.isEmpty);
    return groups;
  }

  IconData _getTopicIcon(String topic) {
    final topicLower = topic.toLowerCase();
    if (topicLower.contains('cramp') || topicLower.contains('pain')) return Icons.healing_outlined;
    if (topicLower.contains('period') || topicLower.contains('cycle')) return Icons.calendar_today_outlined;
    if (topicLower.contains('mood') || topicLower.contains('mental')) return Icons.sentiment_satisfied_alt_outlined;
    if (topicLower.contains('nutrition') || topicLower.contains('craving') || topicLower.contains('food')) return Icons.restaurant_outlined;
    if (topicLower.contains('fitness') || topicLower.contains('exercise') || topicLower.contains('yoga')) return Icons.fitness_center_outlined;
    if (topicLower.contains('medication') || topicLower.contains('pill') || topicLower.contains('remind')) return Icons.medical_services_outlined;
    if (topicLower.contains('doctor') || topicLower.contains('consult')) return Icons.person_search_outlined;
    if (topicLower.contains('sleep') || topicLower.contains('fatigue')) return Icons.nights_stay_outlined;
    return Icons.chat_bubble_outline;
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [FemLyraColors.primary, FemLyraColors.deepRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'FemAI Chat History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add, color: FemLyraColors.primary, size: 18),
            label: const Text(
              'New Chat Session',
              style: TextStyle(
                color: FemLyraColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: FemLyraColors.primary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: FemLyraColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'No past conversations',
              style: TextStyle(
                color: FemLyraColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final grouped = _getGroupedSessions();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: grouped.entries.map((entry) {
        final groupName = entry.key;
        final list = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                groupName.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: FemLyraColors.primary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...list.map((session) {
              final id = session['id'] as int;
              final topic = session['topic'] as String? ?? 'General Inquiry';
              final dateStr = session['date'] as String? ?? '';
              
              String displayDate = dateStr;
              try {
                final parsed = DateTime.tryParse(dateStr);
                if (parsed != null) {
                  displayDate = DateFormat('dd MMM yyyy').format(parsed);
                }
              } catch (_) {}

              final isSelected = id == _sessionId;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? FemLyraColors.blushMist
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      _getTopicIcon(topic),
                      color: isSelected ? FemLyraColors.primary : FemLyraColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      topic,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? FemLyraColors.primary : FemLyraColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      displayDate,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FemLyraColors.textMuted,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: FemLyraColors.textMuted,
                      ),
                      onPressed: () => _confirmDeleteSession(id, topic),
                    ),
                    onTap: () => _selectSession(id),
                  ),
                ),
              );
            }),
            const Divider(height: 16, color: FemLyraColors.border),
          ],
        );
      }).toList(),
    );
  }

  void _initSpeech() async {
    try {
      await _speech.initialize(
        onError: (val) {
          if (mounted) {
            setState(() => _isListening = false);
          }
        },
        onStatus: (status) {
          if (mounted) {
            if (status == 'done' || status == 'notListening') {
              setState(() => _isListening = false);
            } else if (status == 'listening') {
              setState(() => _isListening = true);
            }
          }
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
            if (val.finalResult) {
              setState(() => _isListening = false);
              _speech.stop();
              _handleSendMessage();
            }
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
          final toolsVal = response['tools_used'];
          List<String>? parsedTools;
          if (toolsVal is List) {
            parsedTools = toolsVal.map((e) => e.toString()).toList();
          }

          final lastUserIndex = _messages.lastIndexWhere((m) => m.isUser);
          if (lastUserIndex != -1) {
            _messages[lastUserIndex] = ChatMessageModel(
              id: response['user_message_id'],
              content: _messages[lastUserIndex].content,
              role: _messages[lastUserIndex].role,
              timestamp: _messages[lastUserIndex].timestamp,
            );
          }

          _messages.add(ChatMessageModel(
            id: response['ai_message_id'],
            content: response['response'],
            role: 'assistant',
            timestamp: DateTime.now(),
            toolsUsed: parsedTools,
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
      backgroundColor: FemLyraColors.warmWhite,
      drawer: Drawer(
        backgroundColor: FemLyraColors.warmWhite,
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: _loadingSessions
                  ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
                  : _buildSessionsList(),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Column(
          children: [
            Text(
              'FemAI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: FemLyraColors.textPrimary,
              ),
            ),
            Text(
              'Your personal health AI',
              style: TextStyle(
                fontSize: 12,
                color: FemLyraColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
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
                          ? _buildUserChatBubble(index, message, DateFormat('hh:mm a').format(message.timestamp))
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
                            color: FemLyraColors.primary,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: FemLyraColors.primary.withValues(alpha: 0.1),
            radius: 18,
            child: const Icon(
              Icons.face_3,
              color: FemLyraColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: FemLyraColors.aiWellness.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(color: FemLyraColors.aiWellness.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: const TextStyle(color: FemLyraColors.textPrimary, height: 1.4),
                      ),
                      if (message.toolsUsed != null && message.toolsUsed!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(color: FemLyraColors.border, height: 1),
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: FemLyraColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'FemAI Agent Executed Tasks:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: FemLyraColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...message.toolsUsed!.map((tool) {
                          final info = _getAgentActionInfo(tool);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: info.color.withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: info.color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(info.icon, size: 14, color: info.color),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info.title,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: info.color,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        info.description,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: FemLyraColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: FemLyraColors.textMuted),
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
                        color: _messages[index].isLiked ? Colors.red : FemLyraColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        Share.share(message.content);
                      },
                      child: const Icon(Icons.ios_share, size: 16, color: FemLyraColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserChatBubble(int index, ChatMessageModel message, String time) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: FemLyraColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.id != null) ...[
                GestureDetector(
                  onTap: () => _editUserPrompt(index, message),
                  child: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: FemLyraColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                time,
                style: const TextStyle(fontSize: 10, color: FemLyraColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editUserPrompt(int index, ChatMessageModel message) async {
    final TextEditingController editController = TextEditingController(text: message.content);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: FemLyraColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Prompt',
            style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: editController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Edit your message...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: FemLyraColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FemLyraColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                Navigator.pop(context);
                final newText = editController.text.trim();
                if (newText.isNotEmpty && newText != message.content) {
                  _submitEditedPrompt(index, message.id!, newText);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEditedPrompt(int index, int messageId, String newContent) async {
    setState(() {
      if (index + 1 < _messages.length) {
        _messages.removeRange(index + 1, _messages.length);
      }
      _messages[index] = ChatMessageModel(
        id: messageId,
        content: newContent,
        role: 'user',
        timestamp: DateTime.now(),
      );
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final response = await _chatService.editMessage(
        messageId,
        newContent,
        dayContext: widget.dayContext,
      );

      if (mounted) {
        setState(() {
          final toolsVal = response['tools_used'];
          List<String>? parsedTools;
          if (toolsVal is List) {
            parsedTools = toolsVal.map((e) => e.toString()).toList();
          }

          _messages[index] = ChatMessageModel(
            id: response['user_message_id'],
            content: newContent,
            role: 'user',
            timestamp: _messages[index].timestamp,
          );

          _messages.add(ChatMessageModel(
            id: response['ai_message_id'],
            content: response['response'],
            role: 'assistant',
            timestamp: DateTime.now(),
            toolsUsed: parsedTools,
          ));
          _isTyping = false;
        });
        _scrollToBottom();
        _loadSessions();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTyping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update AI response'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: FemLyraColors.primary.withValues(alpha: 0.1),
            radius: 18,
            child: const Icon(
              Icons.face_3,
              color: FemLyraColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: FemLyraColors.aiWellness.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: FemLyraColors.aiWellness.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(FemLyraColors.primary),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'FemAI is thinking...',
                  style: TextStyle(
                    fontSize: 13,
                    color: FemLyraColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyDisclaimer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.orange.withValues(alpha: 0.1))),
      ),
      child: const Text(
        'Medical Disclaimer: FemAI provides educational info only. It is not a medical device and does not diagnose or treat conditions. Always consult a healthcare professional for medical advice.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: FemLyraColors.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: FemLyraColors.warmWhite,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: FemLyraColors.border),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _handleSendMessage(),
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  hintStyle: const TextStyle(color: FemLyraColors.textMuted),
                  border: InputBorder.none,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? FemLyraColors.primary : FemLyraColors.textMuted,
                        ),
                        onPressed: _listen,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FemAIConversationScreen(
                                dayContext: widget.dayContext,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: FemLyraColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.record_voice_over_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
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
                color: FemLyraColors.primary,
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

class _AgentActionInfo {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _AgentActionInfo({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

_AgentActionInfo _getAgentActionInfo(String toolName) {
  switch (toolName) {
    case 'add_medication':
      return _AgentActionInfo(
        icon: Icons.medical_services,
        title: 'Medication Added',
        description: 'Scheduled new medication reminder successfully.',
        color: Colors.teal,
      );
    case 'update_period_cycle_or_symptoms':
      return _AgentActionInfo(
        icon: Icons.calendar_today,
        title: 'Symptoms Logged',
        description: 'Updated cycle tracking & symptom logs.',
        color: Colors.pink,
      );
    case 'write_in_journal':
      return _AgentActionInfo(
        icon: Icons.book,
        title: 'Journal Entry Created',
        description: 'Saved entry to your personal diary/health notes.',
        color: Colors.indigo,
      );
    case 'book_consultation':
      return _AgentActionInfo(
        icon: Icons.video_call,
        title: 'Consultation Booked',
        description: 'Booked appointment with specialized doctor.',
        color: Colors.blue,
      );
    case 'set_alarm_reminder':
      return _AgentActionInfo(
        icon: Icons.alarm,
        title: 'Reminder Set',
        description: 'Scheduled alarm/notification reminder.',
        color: Colors.orange,
      );
    case 'register_for_event':
      return _AgentActionInfo(
        icon: Icons.event,
        title: 'Event Registration',
        description: 'Registered for webinar or health awareness event.',
        color: Colors.deepPurple,
      );
    case 'create_community_post':
      return _AgentActionInfo(
        icon: Icons.forum,
        title: 'Community Post Published',
        description: 'Published post to discussion feed.',
        color: Colors.cyan[700]!,
      );
    case 'save_semantic_memory':
      return _AgentActionInfo(
        icon: Icons.psychology,
        title: 'Preferences Updated',
        description: 'Stored details to personalization profile.',
        color: Colors.purple,
      );
    case 'get_user_profile':
      return _AgentActionInfo(
        icon: Icons.person_search,
        title: 'Profile Accessed',
        description: 'Retrieved base user height, weight & goals.',
        color: Colors.blueGrey,
      );
    case 'get_user_cycle_history':
      return _AgentActionInfo(
        icon: Icons.history,
        title: 'Cycle Analyzed',
        description: 'Analyzed recent cycle & symptom patterns.',
        color: Colors.pinkAccent,
      );
    case 'get_user_wellness_history':
      return _AgentActionInfo(
        icon: Icons.spa,
        title: 'Wellness Checked',
        description: 'Reviewed daily wellness score check-ins.',
        color: Colors.green,
      );
    case 'get_user_bookings':
      return _AgentActionInfo(
        icon: Icons.bookmark_added,
        title: 'Bookings Retrieved',
        description: 'Fetched status of current consultations.',
        color: Colors.orange,
      );
    case 'get_user_medications':
      return _AgentActionInfo(
        icon: Icons.medication,
        title: 'Prescriptions Checked',
        description: 'Read active daily medicine schedules.',
        color: Colors.teal[700]!,
      );
    case 'search_wellness_knowledge':
      return _AgentActionInfo(
        icon: Icons.menu_book,
        title: 'Health Library Searched',
        description: 'Retrieved medical guides from expert vector DB.',
        color: Colors.lightGreen[800]!,
      );
    case 'get_semantic_memories':
      return _AgentActionInfo(
        icon: Icons.remember_me,
        title: 'Memory Recalled',
        description: 'Recalled long-term personal context.',
        color: Colors.purpleAccent,
      );
    default:
      return _AgentActionInfo(
        icon: Icons.smart_toy,
        title: 'FemAI Action Executed',
        description: 'Ran task: $toolName.',
        color: FemLyraColors.primary,
      );
  }
}
