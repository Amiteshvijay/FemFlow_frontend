import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/support_service.dart';
import 'support_ticket_detail_screen.dart';

class SupportTicketListScreen extends StatefulWidget {
  const SupportTicketListScreen({super.key});

  @override
  State<SupportTicketListScreen> createState() => _SupportTicketListScreenState();
}

class _SupportTicketListScreenState extends State<SupportTicketListScreen> {
  final SupportService _service = SupportService();
  List<SupportTicket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await _service.getMyTickets();
      setState(() {
        _tickets = tickets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Support Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemLyraColors.primary))
          : _tickets.isEmpty
              ? const Center(child: Text('No support tickets raised yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTicketCard(context, ticket),
                    );
                  },
                ),
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket) {
    final date = DateTime.parse(ticket.createdAt);
    final formattedDate = DateFormat('d MMM yyyy, h:mm a').format(date);

    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SupportTicketDetailScreen(ticketId: ticket.ticketId)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.ticketId,
                style: const TextStyle(fontWeight: FontWeight.bold, color: FemLyraColors.primary, fontSize: 13),
              ),
              _buildStatusBadge(ticket.status, ticket.statusDisplay),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ticket.subject,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FemLyraColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: FemLyraColors.textSecondary, fontSize: 14),
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: FemLyraColors.textMuted),
              const SizedBox(width: 6),
              Text(formattedDate, style: const TextStyle(fontSize: 12, color: FemLyraColors.textMuted)),
              const Spacer(),
              const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.primary)),
              const Icon(Icons.chevron_right, size: 16, color: FemLyraColors.primary),
            ],
          ),
        ],
      ),
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
