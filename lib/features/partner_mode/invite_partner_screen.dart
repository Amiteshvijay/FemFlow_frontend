import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/partner_service.dart';

class InvitePartnerScreen extends StatefulWidget {
  const InvitePartnerScreen({super.key});

  @override
  State<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

class _InvitePartnerScreenState extends State<InvitePartnerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final PartnerService _partnerService = PartnerService();
  bool _isLoading = false;

  final Map<String, bool> _permissions = {
    'period_dates': true,
    'fertile_window': true,
    'ovulation_day': true,
    'symptoms': false,
    'mood': false,
    'cycle_predictions': false,
    'pill_reminders': false,
    'journal': false,
    'nutrition': false,
    'wellness': false,
    'health_documents': false,
  };

  Future<void> _sendInvite() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and email are required'), backgroundColor: FemLyraColors.period),
      );
      return;
    }

    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email'), backgroundColor: FemLyraColors.period),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _partnerService.sendPartnerInvite(
        partnerEmail: email,
        partnerName: name,
        permissions: _permissions,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        final String code = response['pairing_code'] ?? '';
        final String acceptUrl = response['accept_url'] ?? '';

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Invitation Sent!', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Your partner has been invited via email. You can also share the pairing code and link directly:'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FemLyraColors.warmWhite,
                      border: Border.all(color: FemLyraColors.primary.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Pairing Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          code,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: FemLyraColors.primary,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Acceptance Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemLyraColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    acceptUrl,
                    style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext); // Close dialog
                    Navigator.pop(context, true); // Return to previous screen with success
                  },
                  child: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Share.share(
                      'Join my FemLyra Partner Mode using pairing code: $code and accept link: $acceptUrl',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FemLyraColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send invite: $e'), backgroundColor: FemLyraColors.period),
        );
      }
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
        title: const Text('Invite Partner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Partner Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Partner Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Partner Email', border: OutlineInputBorder()),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Select what your partner can see.', style: TextStyle(fontSize: 12, color: FemLyraColors.textSecondary)),
                  const Divider(),
                  _buildPermissionToggle('Period Dates', 'period_dates'),
                  _buildPermissionToggle('Fertile Window', 'fertile_window'),
                  _buildPermissionToggle('Ovulation Day', 'ovulation_day'),
                  _buildPermissionToggle('Symptoms', 'symptoms'),
                  _buildPermissionToggle('Mood', 'mood'),
                  _buildPermissionToggle('Cycle Predictions', 'cycle_predictions'),
                  const Divider(),
                  _buildPermissionToggle('Pill Reminders', 'pill_reminders'),
                  _buildPermissionToggle('Journal Entries', 'journal'),
                  _buildPermissionToggle('Nutrition & Diet', 'nutrition'),
                  _buildPermissionToggle('Wellness & Activity', 'wellness'),
                  _buildPermissionToggle('Health Documents', 'health_documents'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              label: 'Send Invite',
              onPressed: _sendInvite,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionToggle(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      value: _permissions[key]!,
      activeThumbColor: FemLyraColors.primary,
      onChanged: (val) {
        setState(() {
          _permissions[key] = val;
        });
      },
    );
  }
}
