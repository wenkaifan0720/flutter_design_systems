/// Gloss's feedback: banners in local gels, the page states, the spinner
/// and progress bars filling with jade gel.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The feedback page.
Widget kitFeedbackDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Feedback',
  sections: [
    KitSection(
      title: 'Banners',
      note: 'One tone each: smoke, jade, amber, ruby.',
      children: [
        const _Narrow(
          GlossBanner(
            title: 'Sync is paused',
            message: 'Changes stay on this device until you are online.',
          ),
        ),
        const _Narrow(
          GlossBanner(title: 'Plan saved', tone: GlossBannerTone.success),
        ),
        _Narrow(
          GlossBanner(
            title: 'Two recipes use the same pan',
            message: 'Thursday has the risotto and the curry at 18:30.',
            tone: GlossBannerTone.warning,
            actions: [GlossButton.text('Move one', onPressed: () {})],
          ),
        ),
        _Narrow(
          GlossBanner(
            title: 'The week did not sync',
            tone: GlossBannerTone.danger,
            actions: [GlossButton('Try again', onPressed: () {})],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Page states',
      children: [
        Wrap(
          spacing: GlossSpacing.large,
          runSpacing: GlossSpacing.large,
          children: [
            SizedBox(
              width: 300,
              child: GlossStateView(
                state: GlossState.empty,
                title: 'Nothing planned yet',
                message: 'Drag a recipe onto a day.',
                actions: [GlossButton.filled('Find recipes', onPressed: () {})],
              ),
            ),
            SizedBox(
              width: 300,
              child: GlossStateView(
                state: GlossState.error,
                title: 'The week did not load',
                icon: const Icon(LucideIcons.cloudOff),
                actions: [GlossButton('Try again', onPressed: () {})],
              ),
            ),
            const SizedBox(
              width: 300,
              child: GlossStateView(
                state: GlossState.loading,
                title: 'Loading the week',
              ),
            ),
            const SizedBox(
              width: 300,
              child: GlossStateView(
                state: GlossState.success,
                title: 'All bought',
              ),
            ),
          ],
        ),
      ],
    ),
    const KitSection(
      title: 'Progress',
      children: [
        KitRow(
          children: [
            GlossSpinner(semanticLabel: 'Loading'),
            GlossSpinner(size: 36, semanticLabel: 'Loading'),
          ],
        ),
        _Narrow(GlossProgressBar(value: 0.35, semanticLabel: 'Upload')),
        _Narrow(GlossProgressBar(value: 0.8, semanticLabel: 'Sync')),
        _Narrow(GlossProgressBar(semanticLabel: 'Under way')),
      ],
    ),
  ],
);

class _Narrow extends StatelessWidget {
  const _Narrow(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 420),
    child: child,
  );
}
