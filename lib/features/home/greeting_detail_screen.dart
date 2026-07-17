import 'package:flutter/material.dart';
import '../../core/theme/femflow_colors.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/app_card.dart';

class GreetingDetailScreen extends StatefulWidget {
  final String greetingType; // 'birthday' or 'anniversary'

  const GreetingDetailScreen({super.key, required this.greetingType});

  @override
  State<GreetingDetailScreen> createState() => _GreetingDetailScreenState();
}

class _GreetingDetailScreenState extends State<GreetingDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String _title = '';
  String _content = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGreeting();
  }

  Future<void> _fetchGreeting() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get(
        '/users/greeting/',
        queryParams: {'type': widget.greetingType},
      );
      if (response != null && response is Map) {
        setState(() {
          _title = response['title'] ?? 'Greeting';
          _content = response['content'] ?? '';
          _isLoading = false;
        });
      } else {
        throw Exception('Invalid response format');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('ApiException: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBirthday = widget.greetingType == 'birthday';
    final Color themeColor = isBirthday ? Colors.pinkAccent : Colors.purpleAccent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: FemFlowColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withValues(alpha: 0.15),
              FemFlowColors.white,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FemFlowColors.primary,
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: FemFlowColors.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: FemFlowColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FemFlowColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: _fetchGreeting,
                              child: const Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                            // Top illustration / icon container
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isBirthday ? Icons.cake : Icons.celebration,
                                size: 80,
                                color: themeColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // Title
                            Text(
                              _title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Special greeting from FemAI 🌸',
                              style: TextStyle(
                                fontSize: 14,
                                color: FemFlowColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 32),
                            // MNC Style Card
                            AppCard(
                              color: FemFlowColors.white,
                              elevation: 2,
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                _content,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color: FemFlowColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  'Thank You! 💖',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
