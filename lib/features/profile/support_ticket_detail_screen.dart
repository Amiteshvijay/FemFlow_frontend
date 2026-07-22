import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/support_service.dart';

class SupportTicketDetailScreen extends StatefulWidget {
  final String ticketId;
  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final SupportService _service = SupportService();
  SupportTicket? _ticket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final ticket = await _service.getTicketDetail(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.ticketId, 
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _ticket == null
              ? const Center(child: Text('Ticket not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Conversational Thread'),
                      const SizedBox(height: 16),
                      _buildMessageBubble(
                        role: 'You',
                        message: _ticket!.message,
                        time: _ticket!.createdAt,
                        isUser: true,
                      ),
                      if (_ticket!.history != null)
                        ..._ticket!.history!
                            .where((h) => h.notes != null && h.notes!.isNotEmpty)
                            .map((h) => _buildMessageBubble(
                                  role: _ticket!.assignedToName ?? 'Support Agent',
                                  message: h.notes!,
                                  time: h.createdAt,
                                  isUser: false,
                                )),
                      const SizedBox(height: 32),
                      _buildSectionTitle('Status Timeline'),
                      const SizedBox(height: 16),
                      _buildTimeline(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: FemFlowColors.textMuted,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildHeaderCard() {
    final createdDate = DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(_ticket!.createdAt));
    final closedDate = _ticket!.closedAt != null 
        ? DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(_ticket!.closedAt!))
        : null;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(_ticket!.status, _ticket!.statusDisplay),
              if (_ticket!.assignedToName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        _ticket!.assignedToName!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _ticket!.subject,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, 'Created Date', createdDate),
          if (closedDate != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.check_circle_outline, 'Closed Date', closedDate, color: Colors.green),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? FemFlowColors.textMuted),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
            Text(
              value,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w600, 
                color: color ?? FemFlowColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageBubble({
    required String role,
    required String message,
    required String time,
    required bool isUser,
  }) {
    final formattedTime = DateFormat('h:mm a').format(DateTime.parse(time));
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                role,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Text(formattedTime, style: const TextStyle(fontSize: 10, color: FemFlowColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? FemFlowColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              border: isUser ? null : Border.all(color: FemFlowColors.border),
              boxShadow: [
                if (!isUser)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14, 
                color: isUser ? Colors.white : FemFlowColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_ticket!.history == null || _ticket!.history!.isEmpty) {
      return const Text('No updates yet.', style: TextStyle(color: FemFlowColors.textMuted));
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          ..._ticket!.history!.asMap().entries.map((entry) {
            final index = entry.key;
            final h = entry.value;
            final isLast = index == _ticket!.history!.length - 1 && _ticket!.closedAt == null;
            return _buildTimelineItem(h, isLast);
          }),
          if (_ticket!.closedAt != null)
            _buildClosedTimelineItem(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TicketHistory history, bool isLast) {
    final date = DateFormat('d MMM, h:mm a').format(DateTime.parse(history.createdAt));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
              ),
              if (!isLast || _ticket!.closedAt != null)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: FemFlowColors.primary.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(history.statusDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(date, style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedTimelineItem() {
    final date = DateFormat('d MMM, h:mm a').format(DateTime.parse(_ticket!.closedAt!));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 14),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ticket Resolved', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
              const SizedBox(height: 2),
              Text(date, style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, String display) {
    Color color = Colors.grey;
    if (status == 'pending') color = Colors.orange;
    if (status == 'in_progress') color = Colors.blue;
    if (status == 'resolved') color = Colors.green;
    if (status == 'escalated') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        display.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}
