import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/community_service.dart';
import 'models/community_models.dart';
import 'widgets/post_content_widget.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final CommunityService _service = CommunityService();
  bool _isLoading = true;
  List<MyPost> _allPosts = [];
  String? _error;
  String _selectedFilter = 'all'; // 'all' | 'pending' | 'approved' | 'rejected'

  @override
  void initState() {
    super.initState();
    _loadMyPosts();
  }

  Future<void> _loadMyPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _service.getMyPosts();
      if (mounted) {
        setState(() {
          _allPosts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load your posts. Please try again.';
        });
      }
    }
  }

  List<MyPost> get _filteredPosts {
    if (_selectedFilter == 'all') {
      return _allPosts;
    }
    return _allPosts.where((post) => post.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: FemLyraColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Posts',
          style: TextStyle(color: FemLyraColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: FemLyraColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadMyPosts,
            color: FemLyraColors.primary,
            child: _filteredPosts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(_filteredPosts[index]);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _filterChip(label: 'All', value: 'all'),
          const SizedBox(width: 8),
          _filterChip(label: 'Under Review', value: 'pending'),
          const SizedBox(width: 8),
          _filterChip(label: 'Approved', value: 'approved'),
          const SizedBox(width: 8),
          _filterChip(label: 'Rejected', value: 'rejected'),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required String value}) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? FemLyraColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? FemLyraColors.primary : FemLyraColors.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: FemLyraColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : FemLyraColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = 'You have not shared any community posts yet.';
    if (_selectedFilter == 'pending') {
      message = 'No posts currently under review.';
    } else if (_selectedFilter == 'approved') {
      message = 'No approved posts found.';
    } else if (_selectedFilter == 'rejected') {
      message = 'No rejected posts.';
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: FemLyraColors.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 48,
                  color: FemLyraColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Posts Found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: FemLyraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: FemLyraColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(MyPost post) {
    final timeStr = DateFormat('MMM d, h:mm a').format(post.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Tag showing the room they posted to
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: FemLyraColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        size: 12,
                        color: FemLyraColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        post.roomName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: FemLyraColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _buildStatusBadge(post.status),
              ],
            ),
            const SizedBox(height: 14),
            PostContentWidget(
              content: post.content,
              style: const TextStyle(
                fontSize: 14,
                color: FemLyraColors.textPrimary,
                height: 1.5,
              ),
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
            const Divider(color: FemLyraColors.border, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                // Created date/time
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: FemLyraColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 11, color: FemLyraColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                if (post.isAnonymous)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Anonymous',
                      style: TextStyle(
                        fontSize: 10,
                        color: FemLyraColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                // Interaction counts (only if approved, otherwise show greyed-out or hide)
                if (post.status == 'approved') ...[
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined, size: 14, color: FemLyraColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        post.likesCount.toString(),
                        style: const TextStyle(fontSize: 11, color: FemLyraColors.textMuted),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.chat_bubble_outline, size: 14, color: FemLyraColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        post.replyCount.toString(),
                        style: const TextStyle(fontSize: 11, color: FemLyraColors.textMuted),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    post.status == 'pending' 
                        ? 'Stats available after approval' 
                        : 'Stats unavailable',
                    style: const TextStyle(
                      fontSize: 11, 
                      fontStyle: FontStyle.italic, 
                      color: FemLyraColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    IconData icon;
    String label;

    switch (status) {
      case 'approved':
        color = FemLyraColors.fertileWindow;
        bgColor = FemLyraColors.fertileWindow.withValues(alpha: 0.1);
        icon = Icons.check_circle_outline;
        label = 'Approved';
        break;
      case 'rejected':
        color = FemLyraColors.period;
        bgColor = FemLyraColors.period.withValues(alpha: 0.1);
        icon = Icons.error_outline;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        color = FemLyraColors.pmsCaution;
        bgColor = FemLyraColors.pmsCaution.withValues(alpha: 0.1);
        icon = Icons.pending_actions_outlined;
        label = 'Under Review';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
