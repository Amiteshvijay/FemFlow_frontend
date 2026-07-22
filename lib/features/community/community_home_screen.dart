import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/community_service.dart';
import 'models/community_models.dart';
import 'community_room_screen.dart';
import '../../core/network/api_client.dart';
import '../premium/premium_feature_preview_screen.dart';
import 'my_posts_screen.dart';
import 'package:provider/provider.dart';
import 'package:femlyra/features/subscriptions/providers/subscription_provider.dart';
import 'package:femlyra/features/doctor_consultation/care_community_program_screen.dart';
import 'package:femlyra/features/subscriptions/screens/premium_plan_screen.dart';
import '../auth/providers/auth_provider.dart';

class CommunityHomeScreen extends StatefulWidget {
  const CommunityHomeScreen({super.key});

  @override
  State<CommunityHomeScreen> createState() => _CommunityHomeScreenState();
}

class _CommunityHomeScreenState extends State<CommunityHomeScreen> {
  final CommunityService _service = CommunityService();
  bool _isLoading = true;
  bool _isPremium = false;
  CommunityPreview? _preview;
  List<CommunityRoom> _rooms = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCommunityData();
  }

  Future<void> _loadCommunityData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final preview = await _service.getCommunityPreview();
      
      if (!preview.isPremium) {
        if (mounted) {
          setState(() {
            _preview = preview;
            _isPremium = false;
            _isLoading = false;
          });
        }
        return;
      }

      final rooms = await _service.getRooms();
      
      if (mounted) {
        setState(() {
          _preview = preview;
          _rooms = rooms;
          _isPremium = true;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 403) {
          // If explicitly forbidden due to premium, we might not even get preview with is_premium=false
          // But our API is designed to return is_premium=false in preview for all logged in users.
          // Still handling 403 just in case direct rooms call failed.
          _loadPreviewOnly();
        } else {
          setState(() {
            _isLoading = false;
            _error = 'Unable to load Community.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load Community. Check your connection.';
        });
      }
    }
  }

  Future<void> _loadPreviewOnly() async {
    try {
      final preview = await _service.getCommunityPreview();
      if (mounted) {
        setState(() {
          _preview = preview;
          _isPremium = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load Community.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: FemFlowColors.warmWhite,
        body: Center(child: CircularProgressIndicator(color: FemFlowColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: FemFlowColors.warmWhite,
        appBar: AppBar(title: const Text('FemLyra Community')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: FemFlowColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCommunityData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isPremium && _preview != null) {
      return const PremiumFeaturePreviewScreen(featureKey: 'community');
    }

    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'FemLyra Community',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: FemFlowColors.textPrimary),
            tooltip: 'My Posts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyPostsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCommunityData,
        color: FemFlowColors.primary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A safe space to share, learn, and feel supported.',
                style: TextStyle(fontSize: 16, color: FemFlowColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildCareCommunityProgramBanner(context),
              const SizedBox(height: 32),
              const Text(
                'Community Rooms',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
              ),
              const SizedBox(height: 16),
              if (_rooms.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('No rooms available yet.', style: TextStyle(color: FemFlowColors.textMuted)),
                  ),
                )
              else
                ..._rooms.map((room) => _buildRoomCard(room)),
              const SizedBox(height: 32),
              _buildSafetyCard(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyCard() {
    return AppCard(
      color: Colors.blue.withValues(alpha: 0.05),
      border: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Community support is not medical advice. Always consult a doctor for health concerns.',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareCommunityProgramBanner(BuildContext context) {
    final isPremium = context.watch<SubscriptionProvider>().isPremium;
    return AppCard(
      color: FemFlowColors.blushMist,
      border: const BorderSide(color: FemFlowColors.primary, width: 0.5),
      onTap: () {
        final profile = context.read<AuthProvider>().profile;
        final isEnrolled = profile?.isCommunityCareEnrolled ?? false;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isEnrolled
                ? const CareCommunityProgramScreen()
                : (isPremium ? const CareCommunityProgramScreen() : const PremiumPlanScreen()),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: FemFlowColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Care Community Program',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: FemFlowColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get up to 2 free consultations with expert doctors.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: FemFlowColors.primary),
        ],
      ),
    );
  }

  Widget _buildRoomCard(CommunityRoom room) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityRoomScreen(
                roomSlug: room.slug,
                roomName: room.name,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FemFlowColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getRoomIcon(room.icon), color: FemFlowColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    room.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${room.postCount} posts',
                    style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FemFlowColors.textMuted),
          ],
        ),
      ),
    );
  }

  IconData _getRoomIcon(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'sentiment_satisfied': return Icons.sentiment_satisfied;
      case 'favorite': return Icons.favorite;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'spa': return Icons.spa;
      case 'fitness_center': return Icons.fitness_center;
      case 'help_outline': return Icons.help_outline;
      case 'medical_services': return Icons.medical_services;
      default: return Icons.groups;
    }
  }
}
