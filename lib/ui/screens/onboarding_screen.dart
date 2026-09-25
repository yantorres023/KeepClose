import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../data/repository.dart';
import 'settings_screen.dart';

/// Three short pages: the promise, privacy, and when to nudge.
/// No permissions are requested here.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  int _minutes = AppSettings.defaultReminderMinutes;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _finish() async {
    final repo = AppScope.of(context).repository;
    await repo.setReminderMinutes(_minutes);
    await repo.setOnboardingDone();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _Page(
        icon: Icons.chat_bubble_outline,
        title: 'Remember to ask.',
        body:
            'When someone tells you about an interview, a move, or a hard '
            'week, jot it down. We\'ll remind you to ask how it went.',
      ),
      const _Page(
        icon: Icons.lock_outline,
        title: 'Private by design.',
        body:
            'Everything stays on this phone. No account. We never read your '
            'messages or upload your contacts.',
      ),
      _Page(
        icon: Icons.wb_sunny_outlined,
        title: 'When should we nudge you?',
        body:
            'At most one gentle reminder a day, only when there\'s something '
            'to remember.',
        extra: OutlinedButton.icon(
          key: const Key('onboarding-time'),
          onPressed: () async {
            final m = await pickReminderTime(context, _minutes);
            if (m != null) setState(() => _minutes = m);
          },
          icon: const Icon(Icons.schedule),
          label: Text(formatMinutes(context, _minutes)),
        ),
      ),
    ];
    final last = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: last
                  ? const SizedBox(height: 48)
                  : TextButton(onPressed: _finish, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: pages,
              ),
            ),
            Semantics(
              label: 'Page ${_page + 1} of ${pages.length}',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < pages.length; i++)
                      Container(
                        margin: const EdgeInsets.all(4),
                        width: i == _page ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding-next'),
                  onPressed: last ? _finish : _next,
                  child: Text(last ? 'Get started' : 'Next'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    this.extra,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 64, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (extra != null) ...[const SizedBox(height: 24), extra!],
        ],
      ),
    );
  }
}
