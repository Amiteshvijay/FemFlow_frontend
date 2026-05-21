import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/femflow_colors.dart';
import '../models/insight_models.dart';
import '../data/expert_insights_service.dart';

class InsightDetailScreen extends StatefulWidget {
  final String slug;
  final ExpertInsight? initialInsight;

  const InsightDetailScreen({super.key, required this.slug, this.initialInsight});

  @override
  State<InsightDetailScreen> createState() => _InsightDetailScreenState();
}

class _InsightDetailScreenState extends State<InsightDetailScreen> {
  final ExpertInsightsService _service = ExpertInsightsService();
  ExpertInsight? _insight;
  bool _isLoading = true;
  final TextEditingController _aiController = TextEditingController();
  final List<AIInteraction> _aiInteractions = [];
  bool _isAILoading = false;

  @override
  void initState() {
    super.initState();
    _insight = widget.initialInsight;
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final detail = await _service.getInsightDetail(widget.slug);
      setState(() {
        _insight = detail;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEngage(String action) async {
    if (_insight == null) return;
    try {
      await _service.engage(_insight!.id, _insight!.slug, action);
      _fetchDetail(); // Refresh to update counts
    } catch (_) {}
  }

  Future<void> _askAI() async {
    if (_aiController.text.trim().isEmpty || _insight == null) return;
    
    final question = _aiController.text.trim();
    _aiController.clear();
    
    setState(() => _isAILoading = true);
    
    try {
      final interaction = await _service.askAI(_insight!.slug, question);
      if (mounted) {
        setState(() {
          _aiInteractions.insert(0, interaction);
          _isAILoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAILoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to get AI response.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _insight == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildContent(),
                  const SizedBox(height: 40),
                  _buildAskAISector(),
                  const SizedBox(height: 40),
                  _buildEngagementBar(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const CircleAvatar(
          backgroundColor: Colors.black26,
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: _insight?.heroMedia != null 
          ? Image.network(_insight!.thumbnail, fit: BoxFit.cover) // Placeholder for video
          : Image.network(_insight!.thumbnail, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: FemFlowColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(_insight!.categoryName, style: const TextStyle(color: FemFlowColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 16),
        Text(_insight!.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
        const SizedBox(height: 20),
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: _insight!.doctor.profileImage != null ? NetworkImage(_insight!.doctor.profileImage!) : null,
              child: _insight!.doctor.profileImage == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_insight!.doctor.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(_insight!.doctor.speciality, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (_insight!.isMedicallyReviewed)
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                 decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                 child: const Row(
                   children: [
                     Icon(Icons.verified_user, color: Colors.green, size: 14),
                     SizedBox(width: 4),
                     Text('Medically Reviewed', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                   ],
                 ),
               ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    return MarkdownBody(
      data: _insight!.content ?? _insight!.summary,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
        h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAskAISector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: FemFlowColors.aiWellness.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('Ask FemAI About This Topic', style: TextStyle(fontWeight: FontWeight.bold, color: FemFlowColors.aiWellness)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _aiController,
            decoration: InputDecoration(
              hintText: 'e.g. Is this relevant for PCOS?',
              hintStyle: const TextStyle(fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              suffixIcon: IconButton(
                onPressed: _askAI,
                icon: const Icon(Icons.send, color: FemFlowColors.aiWellness),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _askAI(),
          ),
          if (_isAILoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (_aiInteractions.isNotEmpty) ...[
            const SizedBox(height: 24),
            ..._aiInteractions.map((ia) => _buildAIResponse(ia)),
          ],
        ],
      ),
    );
  }

  Widget _buildAIResponse(AIInteraction ia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ia.question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 8),
          Text(ia.answer, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildEngagementBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _engagementBtn(
          _insight!.isLiked ? Icons.favorite : Icons.favorite_border, 
          _insight!.isLiked ? Colors.red : Colors.grey, 
          'Like', 
          () => _handleEngage('like')
        ),
        _engagementBtn(
          _insight!.isSaved ? Icons.bookmark : Icons.bookmark_border, 
          _insight!.isSaved ? FemFlowColors.primary : Colors.grey, 
          'Save', 
          () => _handleEngage('save')
        ),
        _engagementBtn(Icons.share_outlined, Colors.grey, 'Share', () => _handleEngage('share')),
        _engagementBtn(Icons.flag_outlined, Colors.grey, 'Report', () {}),
      ],
    );
  }

  Widget _engagementBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
