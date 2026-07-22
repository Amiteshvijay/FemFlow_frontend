import 'package:flutter/material.dart';
import '../../core/theme/FemLyra_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/FemLyra_brand_header.dart';
import '../auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Your AI companion for every phase of your life',
      subtitle: 'Track your cycle, understand your body, and get AI-powered insights & support.',
      icon: Icons.favorite_rounded,
    ),
    OnboardingData(
      title: 'Understand your cycle better',
      subtitle: 'Know your period dates, fertile window, ovulation, symptoms, and mood patterns.',
      icon: Icons.calendar_month_rounded,
    ),
    OnboardingData(
      title: 'Personalized support with FemAI',
      subtitle: 'Ask questions, get gentle insights, and feel supported through every phase.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    OnboardingData(
      title: 'Medical Disclaimer',
      subtitle: 'FemLyra is not a medical device and does not diagnose or treat conditions. Always consult a healthcare professional for medical advice or treatment.',
      icon: Icons.info_outline_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToSignup() {
    context.read<AuthProvider>().completeOnboarding();
  }

  void _navigateToLogin() {
    context.read<AuthProvider>().completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FemLyraColors.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const FemLyraBrandHeader(
                    size: BrandHeaderSize.compact,
                  ),
                  if (_currentPage < 2)
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: FemLyraColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildPaginationDots(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  PrimaryButton(
                    label: _currentPage == 2 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_currentPage < 2) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _navigateToSignup();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_currentPage == 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: FemLyraColors.textSecondary, fontSize: 13),
                        ),
                        GestureDetector(
                          onTap: _navigateToLogin,
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: FemLyraColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_currentPage == 0) ...[
            const Text(
              'Cycle, Health & Care',
              style: TextStyle(
                fontSize: 16,
                color: FemLyraColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: FemLyraColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: FemLyraColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            width: 240,
            height: 240,
            decoration: const BoxDecoration(
              color: FemLyraColors.blushMist,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                data.icon,
                size: 80,
                color: FemLyraColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? FemLyraColors.primary : FemLyraColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final IconData icon;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
