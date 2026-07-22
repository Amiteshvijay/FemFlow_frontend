import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../models/insight_models.dart';
import '../screens/insight_detail_screen.dart';

class ExpertInsightCard extends StatelessWidget {
  final ExpertInsight insight;
  final bool isHorizontal;

  const ExpertInsightCard({super.key, required this.insight, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => InsightDetailScreen(slug: insight.slug, initialInsight: insight)),
      ),
      child: Container(
        width: isHorizontal ? 280 : double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Image.network(
                      insight.thumbnail,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (insight.contentType == InsightContentType.video)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                        ),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          insight.categoryName,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: insight.doctor.profileImage != null ? NetworkImage(insight.doctor.profileImage!) : null,
                        child: insight.doctor.profileImage == null ? const Icon(Icons.person, size: 12) : null,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    insight.doctor.fullName,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (insight.doctor.isVerified) ...[
                                  const SizedBox(width: 2),
                                  const Icon(Icons.verified, color: Colors.blue, size: 10),
                                ],
                              ],
                            ),
                            Text(insight.doctor.speciality, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${insight.estimatedReadTime} min read',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.fiber_manual_record, size: 3, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${insight.viewsCount} views',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    children: [
                      _buildEngagementStat(Icons.favorite_border, insight.likesCount.toString()),
                      const SizedBox(width: 12),
                      _buildEngagementStat(Icons.bookmark_border, insight.savesCount.toString()),
                      const Spacer(),
                      const Icon(Icons.share_outlined, size: 16, color: Colors.grey),
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

  Widget _buildEngagementStat(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 4),
        Text(count, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
