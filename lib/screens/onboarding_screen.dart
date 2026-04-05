import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gymply/services/settings_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() {
    return _OnboardingScreenState();
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onSkipOrDone() async {
    // Show notification permission dialog before closing onboarding.
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Background Timers'),
          content: const Text(
            'GYMPLY. uses local notifications so your '
            'timers can reliably play their custom alarm sounds even '
            'while the app is running in the background.\n\n'
            'This operates 100% offline, securely on your device, and '
            'never tracks or transmits any personal data anywhere.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await Permission.notification.request();

                // Flag onboarding as completed.
                await settingsService.completeOnboarding();

                // If onboarding started from anywhere else, pop that first.
                if (mounted && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('UNDERSTOOD'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Sliding pages.
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: <Widget>[
                  // SLIDE 1: Welcome.
                  OnboardingSlide(
                    iconWidget: Image.asset(
                      'assets/icons/gymplyIcon.png',
                      height: 128,
                      width: 128,
                    ),
                    title: 'GYMPLY.',
                    subtitle:
                        'The Simple, Private, Local Workout Tracker.\n\n'
                        'GYMPLY will NEVER share ANYTHING outside YOUR DEVICE.',
                  ),
                  // SLIDE 2: Core Values.
                  OnboardingSlide(
                    iconWidget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.bookKey,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.globeLock,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                    title: 'YOUR DATA. YOUR RULES.',
                    subtitle:
                        '100% offline and 100% free\n\n'
                        '0% tracking and 0% ads.',
                  ),
                  // SLIDE 3: Features.
                  OnboardingSlide(
                    iconWidget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          LucideIcons.dumbbell,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.timer,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.trendingUp,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                    title: 'LIFT. LOG. LOAD.',
                    subtitle:
                        'Log your sets, track PRs, and use timers.\n\n'
                        'Visualize your progress over time.',
                  ),
                  // SLIDE 4: Nostr.
                  OnboardingSlide(
                    iconWidget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          LucideIcons.fingerprintPattern,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.hatGlasses,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.keyRound,
                          size: 64,
                          color: colorScheme.secondary,
                        ),
                      ],
                    ),
                    title: 'OWN YOUR IDENTITY',
                    subtitle:
                        'GYMPLY supports the Nostr protocol to share '
                        'your workouts with other GYMPLY users '
                        'securely.\n\n'
                        'This is entirely optional.',
                  ),
                ],
              ),
            ),

            // Bottom Navigation + Indicator.
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Skip Button
                  TextButton(
                    onPressed: () async => await _onSkipOrDone(),
                    child: Text(
                      'SKIP',
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Page Indicator.
                  Row(
                    children: List<Widget>.generate(4, (int index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPageIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPageIndex == index
                              ? colorScheme.secondary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next/Done Button.
                  TextButton(
                    onPressed: () async {
                      if (_currentPageIndex == 3) {
                        await _onSkipOrDone();
                      } else {
                        await _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPageIndex == 3 ? 'FINISH' : 'NEXT',
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    super.key,
    this.actions,
  });

  final Widget iconWidget;
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: <Widget>[
          // Using a fixed percentage height instead of a Spacer.
          SizedBox(height: screenHeight * 0.15),
          SizedBox(
            height: 128,
            child: Center(child: iconWidget),
          ).animate(
            effects: <Effect<dynamic>>[
              const FadeEffect(
                duration: Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(),
            textAlign: TextAlign.center,
          ),
          if (actions != null) ...actions!,
          const Spacer(),
        ],
      ),
    );
  }
}
