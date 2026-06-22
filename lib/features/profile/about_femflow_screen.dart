import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/femflow_colors.dart';
import '../../shared/widgets/app_card.dart';
import 'data/support_service.dart';
import 'safety_disclaimer_screen.dart';

class AboutFemFlowScreen extends StatefulWidget {
  const AboutFemFlowScreen({super.key});

  @override
  State<AboutFemFlowScreen> createState() => _AboutFemFlowScreenState();
}

class _AboutFemFlowScreenState extends State<AboutFemFlowScreen> {
  final SupportService _supportService = SupportService();
  bool _isLoading = true;
  SupportData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _supportService.getAbout();
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load about data';
        _isLoading = false;
      });
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
        title: const Text('About FemFlow', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FemFlowColors.primary))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _fetchData, child: const Text('Retry')),
                  ],
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Image.asset(
                        'assets/icons/femflow_app_icon_1024.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.water_drop, size: 100, color: FemFlowColors.primary),
                      ),
                      const SizedBox(height: 20),
                      Text(_data?.appName ?? 'FemFlow', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FemFlowColors.primary)),
                      Text(_data?.tagline ?? '', style: const TextStyle(fontSize: 16, color: FemFlowColors.textSecondary)),
                      const SizedBox(height: 40),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Version: ${_data?.version ?? '1.0.21'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(_data?.description ?? '', style: const TextStyle(color: FemFlowColors.textSecondary, height: 1.5)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildLinkItem(
                              icon: Icons.policy_outlined,
                              label: 'Privacy Policy',
                              onTap: () => _launchURL('https://www.femflow.in/privacy-policy'),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildLinkItem(
                              icon: Icons.description_outlined,
                              label: 'Terms of Service',
                              onTap: () => _launchURL('https://www.femflow.in/terms'),
                            ),
                            const Divider(height: 1, indent: 56),
                            _buildLinkItem(
                              icon: Icons.info_outline,
                              label: 'Safety Disclaimer',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const SafetyDisclaimerScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLinkItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: FemFlowColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.open_in_new, size: 16, color: FemFlowColors.textMuted),
      onTap: onTap,
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error
    }
  }
}
