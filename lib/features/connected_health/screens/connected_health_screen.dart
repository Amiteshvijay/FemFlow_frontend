import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/FemLyra_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../services/health_integration_service.dart';
import '../data/health_service.dart';
import 'health_dashboard_screen.dart';

class ConnectedHealthScreen extends StatefulWidget {
  const ConnectedHealthScreen({super.key});

  @override
  State<ConnectedHealthScreen> createState() => _ConnectedHealthScreenState();
}

class _ConnectedHealthScreenState extends State<ConnectedHealthScreen> {
  final HealthIntegrationService _healthIntegrationService = HealthIntegrationService();
  final HealthService _healthService = HealthService();
  
  List<dynamic> _connections = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchConnections();
  }

  Future<void> _fetchConnections() async {
    setState(() => _isLoading = true);
    try {
      final connections = await _healthService.getConnections();
      if (mounted) {
        setState(() {
          _connections = connections;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleConnection(String platform, bool currentStatus) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      if (!currentStatus) {
        // Step 0: Platform-specific availability checks
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && platform == 'health_connect') {
          final isAvailable = await _healthIntegrationService.isHealthConnectAvailable();
          if (!isAvailable) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Health Connect is not available. Please install it from Play Store.')),
              );
            }
            setState(() => _isProcessing = false);
            return;
          }
        }

        // Step 1: Request Permissions
        final hasPermission = await _healthIntegrationService.requestPermissions();

        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissions required to connect.')),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }

        // Step 2: Initial Sync & Connect
        await _healthIntegrationService.syncData(platform: platform);
      } else {
        // Disconnect
        await _healthService.disconnect(platform);
      }

      await _fetchConnections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(currentStatus ? 'Disconnected $platform' : 'Successfully connected $platform')),
        );
        if (!currentStatus) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemFlowColors.warmWhite,
      appBar: AppBar(
        title: const Text('Connected Health', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : Column(
              children: [
                _buildTrustBanner(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: _buildPlatformItems(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: FemFlowColors.primary.withValues(alpha: 0.05),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: FemFlowColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your health data is encrypted and used only for personalized wellness insights.',
              style: TextStyle(fontSize: 12, color: FemFlowColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlatformItems() {
    final List<Widget> items = [];
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    if (isAndroid) {
      items.add(_buildIntegrationCard(
        platform: 'health_connect',
        title: 'Android Health Connect',
        subtitle: 'Sync steps, sleep, heart rate, and more from Google Fit, Samsung Health, etc.',
        icon: Icons.health_and_safety_outlined,
      ));
    } else if (isIOS) {
      items.add(_buildIntegrationCard(
        platform: 'apple_health',
        title: 'Apple Health',
        subtitle: 'Sync wellness and activity data from HealthKit.',
        icon: Icons.favorite_outline,
      ));
    } else if (kIsWeb) {
      items.add(const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Health device syncing is available on our mobile app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FemFlowColors.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      ));
    }

    return items;
  }

  Widget _buildIntegrationCard({
    required String platform,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final connection = _connections.firstWhere(
      (c) => c['platform'] == platform,
      orElse: () => null,
    );

    final bool isConnected = connection != null && connection['is_active'] == true;
    final String? lastSync = connection?['last_synced_at'];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: FemFlowColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: FemFlowColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: FemFlowColors.textSecondary)),
                  ],
                ),
              ),
              Switch(
                value: isConnected,
                activeThumbColor: FemFlowColors.primary,
                activeTrackColor: FemFlowColors.primary.withValues(alpha: 0.5),
                onChanged: (val) => _toggleConnection(platform, isConnected),
              ),
            ],
          ),
          if (isConnected && lastSync != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connection Status', style: TextStyle(fontSize: 12, color: FemFlowColors.textMuted)),
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    const Text('Connected', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Text(
                      'Synced ${DateFormat('HH:mm').format(DateTime.parse(lastSync))}',
                      style: const TextStyle(fontSize: 11, color: FemFlowColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthDashboardScreen()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined, color: Colors.white, size: 16),
                label: const Text('View Health Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FemFlowColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
