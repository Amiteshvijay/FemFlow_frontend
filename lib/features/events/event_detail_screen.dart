import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/event_service.dart';
import 'models/event_models.dart';
import 'event_registration_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final String slug;

  const EventDetailScreen({super.key, required this.slug});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final EventService _eventService = EventService();
  bool _isLoading = true;
  FemLyraEvent? _event;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final event = await _eventService.getEventDetail(widget.slug);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Unable to load event details.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
      bottomNavigationBar: _event != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    final event = _event!;
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(event.eventDate);
    final deadlineStr = DateFormat('MMM d, h:mm a').format(event.registrationDeadline);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          backgroundColor: FemLyraColors.primary,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: FemLyraColors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Image.network(
              event.bannerImage,
              fit: BoxFit.cover,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildCategoryBadge(event.category),
                    const Spacer(),
                    _buildModeBadge(event.mode),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                ),
                const SizedBox(height: 20),
                _buildInfoRow(Icons.calendar_today, dateStr),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, '${event.startTime} - ${event.endTime}'),
                if (event.location != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.location_on_outlined, event.location!),
                ],
                const SizedBox(height: 24),
                const Text(
                  'About this Event',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  event.fullDescription,
                  style: const TextStyle(fontSize: 15, color: FemLyraColors.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 32),
                if (event.guestSpeakerName != null) _buildSpeakerSection(),
                const SizedBox(height: 32),
                _buildDeadlineCard(deadlineStr),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: FemLyraColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemLyraColors.primary),
      ),
    );
  }

  Widget _buildModeBadge(String mode) {
    return Row(
      children: [
        Icon(mode == 'online' ? Icons.videocam : Icons.location_on, size: 16, color: FemLyraColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          mode.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: FemLyraColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15, color: FemLyraColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Guest Speaker',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: FemLyraColors.primary.withValues(alpha: 0.1),
                backgroundImage: _event!.guestSpeakerPhoto != null 
                    ? NetworkImage(_event!.guestSpeakerPhoto!) 
                    : null,
                child: _event!.guestSpeakerPhoto == null 
                    ? const Icon(Icons.person, size: 30, color: FemLyraColors.primary) 
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _event!.guestSpeakerName!,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _event!.guestSpeakerDesignation ?? '',
                      style: const TextStyle(fontSize: 13, color: FemLyraColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_event!.guestSpeakerBio != null) ...[
            const SizedBox(height: 12),
            Text(
              _event!.guestSpeakerBio!,
              style: const TextStyle(fontSize: 14, color: FemLyraColors.textSecondary, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeadlineCard(String deadline) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registration Deadline',
                  style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
                ),
                Text(
                  deadline,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Available Seats',
                style: TextStyle(fontSize: 12, color: FemLyraColors.textMuted),
              ),
              Text(
                '${_event!.maxSeats - _event!.registeredCount}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FemLyraColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    bool isClosed = _event!.status == 'closed' || _event!.status == 'completed' || _event!.status == 'cancelled';
    bool canRegister = !isClosed && !_event!.isRegistered;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: canRegister ? _navigateToRegister : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canRegister ? FemLyraColors.primary : Colors.grey[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _event!.isRegistered 
                ? 'Already Registered' 
                : isClosed ? 'Registration Closed' : 'Register Now',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventRegistrationScreen(event: _event!)),
    ).then((result) {
      if (result == true) _fetchDetail();
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_error!, style: const TextStyle(color: FemLyraColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchDetail, child: const Text('Retry')),
        ],
      ),
    );
  }
}
