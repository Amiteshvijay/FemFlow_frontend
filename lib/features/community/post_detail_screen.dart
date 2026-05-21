import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/community_service.dart';
import 'models/community_models.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final CommunityService _service = CommunityService();
  final TextEditingController _replyController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmittingReply = false;
  CommunityPost? _post;
  List<PostReply> _replies = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getPostDetail(widget.postId),
        _service.getPostReplies(widget.postId),
      ]);

      if (mounted) {
        setState(() {
          _post = results[0] as CommunityPost;
          _replies = results[1] as List<PostReply>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load post details.';
        });
      }
    }
  }

  Future<void> _submitReply() async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSubmittingReply = true);
    try {
      await _service.createReply(widget.postId, {
        'content': content,
        'is_anonymous': true,
      });

      _replyController.clear();
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to post reply.'))
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmittingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: FemFlowColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Discussion',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _post != null ? _buildReplyInput() : null,
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPostSection(),
          const SizedBox(height: 32),
          Text(
            'Replies (${_replies.length})',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_replies.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Text('No replies yet. Be the first to reply!', style: TextStyle(color: FemFlowColors.textMuted)),
              ),
            )
          else
            ..._replies.map((reply) => _buildReplyCard(reply)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPostSection() {
    final timeStr = DateFormat('MMM d, h:mm a').format(_post!.createdAt);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                backgroundImage: _post!.authorAvatar != null ? NetworkImage(_post!.authorAvatar!) : null,
                child: _post!.authorAvatar == null ? const Icon(Icons.person, size: 20, color: FemFlowColors.primary) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_post!.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _post!.content,
            style: const TextStyle(fontSize: 15, color: FemFlowColors.textPrimary, height: 1.6),
          ),
          if (_post!.imageUrl != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                _post!.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: FemFlowColors.textMuted),
                onPressed: () {}, // TODO: React
              ),
              Text(_post!.reactionCount.toString(), style: const TextStyle(color: FemFlowColors.textMuted)),
              const SizedBox(width: 24),
              const Icon(Icons.chat_bubble_outline, color: FemFlowColors.textMuted, size: 20),
              const SizedBox(width: 8),
              Text(_post!.replyCount.toString(), style: const TextStyle(color: FemFlowColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReplyCard(PostReply reply) {
    final timeStr = DateFormat('MMM d, h:mm a').format(reply.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, size: 14, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(reply.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      Text(timeStr, style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(reply.content, style: const TextStyle(fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              decoration: InputDecoration(
                hintText: 'Add a reply...',
                hintStyle: const TextStyle(fontSize: 14),
                filled: true,
                fillColor: FemFlowColors.warmWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _isSubmittingReply
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(
                  icon: const Icon(Icons.send_rounded, color: FemFlowColors.primary),
                  onPressed: _submitReply,
                ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: FemFlowColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
        ],
      ),
    );
  }
}
