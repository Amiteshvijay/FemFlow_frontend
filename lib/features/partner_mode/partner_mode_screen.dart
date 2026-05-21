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

  Future<void> _updatePermissions(Map<String, dynamic> currentPermissions, String key, bool value) async {
    final updated = Map<String, bool>.from(currentPermissions);
    updated[key] = value;
    
    try {
      await _partnerService.updatePermissions(updated);
      await _fetchInvites();
    } catch (e) {
      if (mounted) {
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
                      _buildActivePartnerCard(),
                      const SizedBox(height: 24),
                      _buildPermissionsCard(_activeInvite!['permissions']),
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

  Widget _buildPermissionsCard(Map<String, dynamic> permissions) {
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
          _buildToggle('Period Dates', permissions, 'period_dates'),
          _buildToggle('Fertile Window', permissions, 'fertile_window'),
          _buildToggle('Ovulation Day', permissions, 'ovulation_day'),
          _buildToggle('Symptoms', permissions, 'symptoms'),
          _buildToggle('Mood', permissions, 'mood'),
          _buildToggle('Cycle Predictions', permissions, 'cycle_predictions'),
        ],
      ),
    );
  }

  Widget _buildToggle(String label, Map<String, dynamic> permissions, String key) {
    final value = permissions[key] == true;
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 15, color: FemFlowColors.textPrimary)),
      value: value,
      activeThumbColor: FemFlowColors.primary,
      onChanged: (val) => _updatePermissions(permissions, key, val),
    );
  }
}
