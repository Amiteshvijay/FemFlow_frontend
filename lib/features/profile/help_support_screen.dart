import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'faq_screen.dart';
import 'safety_disclaimer_screen.dart';
import 'contact_us_screen.dart';
import 'support_ticket_list_screen.dart';
import 'support_ticket_detail_screen.dart';
import 'data/support_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final SupportService _service = SupportService();
  List<SupportTicket> _tickets = [];
  bool _isLoadingTickets = true;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets() async {
    try {
      final tickets = await _service.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _isLoadingTickets = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTickets = false);
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
        title: const Text('Help & Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavigationCard(
              context,
              title: 'FAQs',
              subtitle: 'Find answers to common FemLyra questions.',
              icon: Icons.question_answer_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FAQScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildNavigationCard(
              context,
              title: 'Safety Disclaimer',
              subtitle: 'FemAI gives educational information only and is not a substitute for medical advice.',
              icon: Icons.security_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SafetyDisclaimerScreen()),
              ),
            ),
            const SizedBox(height: 16),
            _buildNavigationCard(
              context,
              title: 'Contact Us',
              subtitle: 'Need more help? Send us a message or email.',
              icon: Icons.contact_support_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              ).then((_) => _fetchTickets()),
            ),
            
            if (_isLoadingTickets)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator(color: FemLyraColors.primary)),
              )
            else if (_tickets.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SupportTicketListScreen()),
                    ).then((_) => _fetchTickets()),
                    child: const Text('View All', style: TextStyle(color: FemLyraColors.primary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._tickets.take(2).map((ticket) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTicketPreview(ticket),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPreview(SupportTicket ticket) {
    Color statusColor = Colors.grey;
    if (ticket.status == 'pending') statusColor = Colors.orange;
    if (ticket.status == 'in_progress') statusColor = Colors.blue;
    if (ticket.status == 'resolved') statusColor = Colors.green;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SupportTicketDetailScreen(ticketId: ticket.ticketId)),
      ).then((_) => _fetchTickets()),
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.confirmation_number_outlined, color: statusColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ticket.subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(ticket.statusDisplay, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FemLyraColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: FemLyraColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: FemLyraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: FemLyraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FemLyraColors.textMuted),
          ],
        ),
      ),
    );
  }
}
