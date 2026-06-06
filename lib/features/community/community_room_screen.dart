import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/community_service.dart';
import 'models/community_models.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import 'widgets/post_content_widget.dart';

class CommunityRoomScreen extends StatefulWidget {
  final String roomSlug;
  final String? roomName;

  const CommunityRoomScreen({
    super.key,
    required this.roomSlug,
    this.roomName,
  });

  @override
  State<CommunityRoomScreen> createState() => _CommunityRoomScreenState();
}

class _CommunityRoomScreenState extends State<CommunityRoomScreen> {
  final CommunityService _service = CommunityService();
  bool _isLoading = true;
  CommunityRoom? _room;
  List<CommunityPost> _posts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _service.getRoomDetail(widget.roomSlug),
        _service.getRoomPosts(widget.roomSlug),
      ]);

      if (mounted) {
        setState(() {
          _room = results[0] as CommunityRoom;
          _posts = results[1] as List<CommunityPost>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load this room.';
        });
      }
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
        title: Text(
          _room?.name ?? widget.roomName ?? 'Community Room',
          style: const TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      floatingActionButton: !_isLoading && _error == null
          ? FloatingActionButton(
              onPressed: _navigateToCreatePost,
              backgroundColor: FemFlowColors.primary,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: FemFlowColors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_room?.description != null)
            Text(
              _room!.description,
              style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
            ),
          const SizedBox(height: 20),
          _buildSafetyBanner(),
          const SizedBox(height: 24),
          const Text(
            'Supportive Discussions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
          ),
          const SizedBox(height: 16),
          if (_posts.isEmpty)
            _buildEmptyState()
          else
            ..._posts.map((post) => _buildPostCard(post)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Community support is not medical advice. Please consult a doctor for health concerns.',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final timeStr = DateFormat('MMM d, h:mm a').format(post.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                  backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                  child: post.authorAvatar == null ? const Icon(Icons.person, size: 16, color: FemFlowColors.primary) : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.authorName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PostContentWidget(
              content: post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary, height: 1.5),
            ),
            if (post.imageUrl != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _actionItem(
                  post.userReaction == 'up' ? Icons.thumb_up : Icons.thumb_up_outlined, 
                  post.likesCount.toString(),
                  color: post.userReaction == 'up' ? FemFlowColors.primary : FemFlowColors.textMuted,
                ),
                const SizedBox(width: 20),
                _actionItem(
                  post.userReaction == 'down' ? Icons.thumb_down : Icons.thumb_down_outlined, 
                  post.dislikesCount.toString(),
                  color: post.userReaction == 'down' ? Colors.redAccent : FemFlowColors.textMuted,
                ),
                const SizedBox(width: 20),
                _actionItem(Icons.chat_bubble_outline, post.replyCount.toString(), color: FemFlowColors.textMuted),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flag_outlined, size: 18, color: FemFlowColors.textMuted),
                  onPressed: () => _showReportDialog(post.id),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionItem(IconData icon, String count, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? FemFlowColors.textMuted),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            const Text(
              'No posts yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the first supportive conversation in this room.',
              textAlign: TextAlign.center,
              style: TextStyle(color: FemFlowColors.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _navigateToCreatePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: FemFlowColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Create Post'),
            ),
          ],
        ),
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

  void _navigateToCreatePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          roomSlug: widget.roomSlug,
          roomName: _room?.name ?? widget.roomName ?? '',
        ),
      ),
    );
    if (result == true) _loadData();
  }

  void _showReportDialog(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: const Text('Are you sure you want to report this post for inappropriate content?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final sm = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              await _service.report({'post_id': postId, 'reason': 'Reported by user'});
              if (mounted) {
                nav.pop();
                sm.showSnackBar(const SnackBar(content: Text('Report submitted.')));
              }
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
