import 'package:cut_match_app/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingPage {
  final String imagePath;
  final String title;
  final String description;

  OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'ค้นพบสไตล์ที่ใช่',
      description: 'เลือกดูทรงผมมากมายที่คัดสรรมาให้เหมาะกับคุณโดยเฉพาะ',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'ลองก่อนตัดด้วย AI',
      description:
          'ใช้กล้องลองทรงผมกับใบหน้าของคุณแบบเรียลไทม์ ไม่ต้องเสี่ยงอีกต่อไป',
    ),
    OnboardingPage(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'เข้าร่วมชุมชนของเรา',
      description: 'แชร์ลุคใหม่ของคุณ และรับแรงบันดาลใจจากสไตล์ของคนอื่นๆ',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _onGetStarted,
                  child: Text(
                    'ข้าม',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightText,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _isLastPage = index == _pages.length - 1;
                    });
                  },
                  itemBuilder: (_, index) {
                    return Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            _pages[index].imagePath,
                            height: MediaQuery.of(context).size.height * 0.3,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            _pages[index].title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _pages[index].description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.lightText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: AppTheme.primary,
                  dotColor: AppTheme.lightText,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLastPage
                        ? _onGetStarted
                        : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                    child: Text(_isLastPage ? 'เริ่มต้นใช้งาน' : 'ถัดไป'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
