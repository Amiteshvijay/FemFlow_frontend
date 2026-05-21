import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/femflow_colors.dart';
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
      setState(() {
        _ticket = ticket;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
        title: Text(widget.ticketId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _ticket == null
              ? const Center(child: Text('Ticket not found.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      const Text('Original Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      AppCard(
                        child: Text(_ticket!.message, style: const TextStyle(fontSize: 14, color: FemFlowColors.textPrimary)),
                      ),
                      const SizedBox(height: 32),
                      const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      if (_ticket!.history != null) ...[
                        ..._ticket!.history!.map((h) => _buildTimelineItem(h)),
                      ],
                      if (_ticket!.closedAt != null) ...[
                        _buildClosedTimelineItem(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusBadge(_ticket!.status, _ticket!.statusDisplay),
              if (_ticket!.assignedToName != null)
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: FemFlowColors.textMuted),
                    const SizedBox(width: 4),
                    Text('Agent: ${_ticket!.assignedToName}', style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(_ticket!.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Created on ${DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(_ticket!.createdAt))}',
            style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(TicketHistory history) {
    final date = DateTime.parse(history.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(color: FemFlowColors.primary, shape: BoxShape.circle),
              ),
              Container(width: 2, height: 40, color: FemFlowColors.primary.withValues(alpha: 0.2)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(history.statusDisplay, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(DateFormat('d MMM yyyy, h:mm a').format(date), style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                if (history.notes != null && history.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(history.notes!, style: const TextStyle(fontSize: 13, color: FemFlowColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedTimelineItem() {
    final date = DateTime.parse(_ticket!.closedAt!);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 16),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ticket Closed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
              Text(DateFormat('d MMM yyyy, h:mm a').format(date), style: const TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        display,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
