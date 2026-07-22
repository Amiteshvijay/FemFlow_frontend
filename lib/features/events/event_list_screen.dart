import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/event_service.dart';
import 'models/event_models.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  List<FemLyraEvent> _events = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final events = await _eventService.getEvents();
      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load events. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text(
          'Wellness Events',
          style: TextStyle(color: FemFlowColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: FemFlowColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _error != null
              ? _buildErrorState()
              : _events.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchEvents,
                      color: FemFlowColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _events.length,
                        itemBuilder: (context, index) => _buildEventCard(_events[index]),
                      ),
                    ),
    );
  }

  Widget _buildEventCard(FemLyraEvent event) {
    final dateStr = DateFormat('EEE, MMM d, yyyy').format(event.eventDate);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: AppCard(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => EventDetailScreen(slug: event.slug)),
          ).then((_) => _fetchEvents());
        },
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                event.bannerImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: FemFlowColors.blushMist,
                  child: const Icon(Icons.event, size: 48, color: FemFlowColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryBadge(event.category),
                      _buildModeBadge(event.mode),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: FemFlowColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '$dateStr | ${event.startTime}',
                        style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (event.guestSpeakerName != null)
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: FemFlowColors.primary.withValues(alpha: 0.1),
                                backgroundImage: event.guestSpeakerPhoto != null 
                                    ? NetworkImage(event.guestSpeakerPhoto!) 
                                    : null,
                                child: event.guestSpeakerPhoto == null 
                                    ? const Icon(Icons.person, size: 14, color: FemFlowColors.primary) 
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  event.guestSpeakerName!,
                                  style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _buildCTA(event),
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

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: FemFlowColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: FemFlowColors.primary),
      ),
    );
  }

  Widget _buildModeBadge(String mode) {
    Color color = Colors.blue;
    if (mode == 'online') color = Colors.green;
    if (mode == 'hybrid') color = Colors.orange;

    return Row(
      children: [
        Icon(mode == 'online' ? Icons.videocam : Icons.location_on, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          mode.toUpperCase(),
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildCTA(FemLyraEvent event) {
    bool isClosed = event.status == 'closed' || event.status == 'completed' || event.status == 'cancelled';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: event.isRegistered 
            ? FemFlowColors.fertileWindow.withValues(alpha: 0.1)
            : isClosed ? Colors.grey[200] : FemFlowColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        event.isRegistered 
            ? 'Registered' 
            : isClosed ? 'Closed' : 'Register Now',
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold, 
          color: event.isRegistered 
              ? FemFlowColors.fertileWindow 
              : isClosed ? Colors.grey : Colors.white
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'No upcoming events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Check back soon for more wellness sessions.',
            style: TextStyle(color: FemFlowColors.textSecondary),
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
          ElevatedButton(
            onPressed: _fetchEvents,
            style: ElevatedButton.styleFrom(backgroundColor: FemFlowColors.primary),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
