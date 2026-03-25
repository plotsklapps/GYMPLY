import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gymply/signals/onboarding_signal.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkipOrDone() {
    // Flag onboarding as completed.
    sOnboardingCompleted.value = true;

    // If the widget is within a navigator that can pop (like from menu_modal), pop it.
    // Otherwise, since main.dart watches sOnboardingCompleted, it will automatically switch to HomeScreen.
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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
            // The sliding pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int index) {
                  setState(() {
                    _currentPageIndex = index;
                  });
                },
                children: <Widget>[
                  // SLIDE 1: Welcome
                  _buildOnboardingSlide(
                    context: context,
                    iconWidget: Image.asset(
                      'assets/icons/gymplyIcon.png',
                      height: 128,
                      width: 128,
                    ),
                    title: 'GYMPLY.',
                    subtitle:
                        'The Simple, Private, Local Workout Tracker. Your workout data is yours alone.',
                  ),
                  // SLIDE 2: Core Values
                  _buildOnboardingSlide(
                    context: context,
                    iconWidget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          LucideIcons.shieldCheck,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.hardDrive,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.minimize,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    title: 'YOUR DATA. YOUR RULES.',
                    subtitle:
                        'GYMPLY runs entirely offline. No tracking, no ads, 100% local storage.',
                  ),
                  // SLIDE 3: Features
                  _buildOnboardingSlide(
                    context: context,
                    iconWidget: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          LucideIcons.dumbbell,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.timer,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          LucideIcons.trendingUp,
                          size: 64,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                    title: 'LIFT. LOG. LOAD.',
                    subtitle:
                        'Easily log your sets, track PRs, use cardio timers, and visualize your progress over time.',
                  ),
                  // SLIDE 4: Nostr
                  _buildOnboardingSlide(
                    context: context,
                    iconWidget: Icon(
                      LucideIcons.key,
                      size: 96,
                      color: colorScheme.primary,
                    ),
                    title: 'OWN YOUR IDENTITY',
                    subtitle:
                        'GYMPLY supports Nostr to share your workouts securely. Want to generate keys to get started, or skip for now?',
                    actions: <Widget>[
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _onSkipOrDone,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text('Generate Keys (Soon)'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _onSkipOrDone,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: const Text('Skip / No Thanks'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Navigation and Indicator
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Skip Button
                  TextButton(
                    onPressed: _onSkipOrDone,
                    child: Text(
                      'SKIP',
                      style: textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  // Page Indicators
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

                  // Next / Done Button
                  TextButton(
                    onPressed: () {
                      if (_currentPageIndex == 3) {
                        _onSkipOrDone();
                      } else {
                        _pageController.nextPage(
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

  Widget _buildOnboardingSlide({
    required BuildContext context,
    required Widget iconWidget,
    required String title,
    required String subtitle,
    List<Widget>? actions,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Spacer(flex: 2),
          iconWidget,
          const SizedBox(height: 48),
          Text(
            title,
            style: textTheme.displayMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actions != null) ...actions,
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
