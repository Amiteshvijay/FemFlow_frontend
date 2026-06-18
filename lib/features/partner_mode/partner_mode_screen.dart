import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/primary_button.dart';
import 'data/partner_service.dart';
import 'invite_partner_screen.dart';

class PartnerModeScreen extends StatefulWidget {
  const PartnerModeScreen({super.key});

  @override
  State<PartnerModeScreen> createState() => _PartnerModeScreenState();
}

class _PartnerModeScreenState extends State<PartnerModeScreen> {
  final PartnerService _partnerService = PartnerService();
  bool _isLoading = true;
  Map<String, dynamic>? _activeInvite;
  Map<String, bool>? _localPermissions;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _fetchInvites();
  }

  Future<void> _fetchInvites() async {
    setState(() => _isLoading = true);
    try {
      final invites = await _partnerService.getInvites();
      if (mounted) {
        setState(() {
          // Only show invites that are not revoked
          final activeInvites = invites.where((inv) => inv['status'] != 'revoked').toList();
          _activeInvite = activeInvites.isNotEmpty ? activeInvites.first : null;
          if (_activeInvite != null) {
            _localPermissions = Map<String, bool>.from(
              (_activeInvite!['permissions'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v == true))
            );
          } else {
            _localPermissions = null;
          }
          _hasChanges = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load partner status: $e'), backgroundColor: FemFlowColors.period),
        );
      }
    }
  }

  Future<void> _revokeAccess() async {
    setState(() => _isLoading = true);
    try {
      await _partnerService.revokePartner();
      await _fetchInvites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Access revoked successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke access: $e'), backgroundColor: FemFlowColors.period),
        );
      }
    }
  }

  Future<void> _savePermissions() async {
    if (_localPermissions == null) return;
    setState(() => _isLoading = true);
    try {
      await _partnerService.updatePermissions(_localPermissions!);
      await _fetchInvites();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permissions updated successfully'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update permissions: $e'), backgroundColor: FemFlowColors.period),
        );
      }
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
        title: const Text(
          'Partner Mode',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeroSection(),
                    const SizedBox(height: 32),
                    
                    if (_activeInvite != null) ...[
                      if (_activeInvite!['status'] == 'accepted') ...[
                        _buildActivePartnerCard(),
                        const SizedBox(height: 24),
                        _buildPermissionsCard(),
                        if (_hasChanges) ...[
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Save Changes',
                            onPressed: _savePermissions,
                            isLoading: _isLoading,
                          ),
                        ],
                      ] else ...[
                        _buildPendingInviteCard(),
                      ],
                      const SizedBox(height: 40),
                      TextButton(
                        onPressed: _revokeAccess,
                        child: const Text('Revoke Access', style: TextStyle(color: FemFlowColors.period, fontSize: 16)),
                      ),
                    ] else ...[
                      const Text(
                        'You control what your partner can see. You can revoke access anytime.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FemFlowColors.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      PrimaryButton(
                        label: 'Invite Partner',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const InvitePartnerScreen()),
                          );
                          if (result == true) {
                            _fetchInvites();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            color: FemFlowColors.blushMist,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.favorite_rounded, size: 60, color: FemFlowColors.primary),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Share your journey with your partner',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildActivePartnerCard() {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Partner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person, color: FemFlowColors.primary, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_activeInvite!['partner_name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(_activeInvite!['partner_email'], style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Status: ${_activeInvite!['status']}', style: TextStyle(fontSize: 12, color: _activeInvite!['status'] == 'accepted' ? Colors.green : FemFlowColors.primary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInviteCard() {
    final code = _activeInvite!['pairing_code'] ?? '';
    final acceptUrl = _activeInvite!['accept_url'] ?? '';
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_empty, color: FemFlowColors.primary),
              SizedBox(width: 8),
              Text(
                'Invitation Pending',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sent to: ${_activeInvite!['partner_name']} (${_activeInvite!['partner_email']})',
            style: const TextStyle(fontSize: 14, color: FemFlowColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'Share pairing details with your partner:',
            style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FemFlowColors.warmWhite,
              border: Border.all(color: FemFlowColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text('Pairing Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
                const SizedBox(height: 4),
                SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: FemFlowColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Acceptance Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: FemFlowColors.textSecondary)),
          const SizedBox(height: 4),
          SelectableText(
            acceptUrl,
            style: const TextStyle(fontSize: 12, color: Colors.blue, decoration: TextDecoration.underline),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard() {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text('Shared Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FemFlowColors.textPrimary)),
          ),
          const Divider(color: FemFlowColors.border),
          _buildToggle('Period Dates', 'period_dates'),
          _buildToggle('Fertile Window', 'fertile_window'),
          _buildToggle('Ovulation Day', 'ovulation_day'),
          _buildToggle('Symptoms', 'symptoms'),
          _buildToggle('Mood', 'mood'),
          _buildToggle('Cycle Predictions', 'cycle_predictions'),
          _buildToggle('Pill Reminders', 'pill_reminders'),
          _buildToggle('Journal Entries', 'journal'),
          _buildToggle('Nutrition & Diet', 'nutrition'),
          _buildToggle('Wellness & Activity', 'wellness'),
          _buildToggle('Health Documents', 'health_documents'),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, String key) {
    final value = _localPermissions?[key] == true;
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15, color: FemFlowColors.textPrimary)),
      value: value,
      activeThumbColor: FemFlowColors.primary,
      onChanged: (val) {
        setState(() {
          _localPermissions?[key] = val;
          final initialPermissions = _activeInvite!['permissions'] as Map<String, dynamic>;
          bool changesFound = false;
          _localPermissions?.forEach((k, v) {
            if (initialPermissions[k] != v) {
              changesFound = true;
            }
          });
          _hasChanges = changesFound;
        });
      },
    );
  }
}
