/// Slides one at a time: full width with its controls, peeking
/// neighbours, and playing on its own.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const List<(IconData, String, String)> _slides = [
  (LucideIcons.listChecks, 'Plan the week', 'Every promise, one row each.'),
  (LucideIcons.calendarCheck, 'Keep the day', 'Tick it off where you stand.'),
  (LucideIcons.chartLine, 'See the trend', 'Weeks as bars, no guilt.'),
  (LucideIcons.bellOff, 'Quiet by default', 'No reminder you did not ask for.'),
];

/// One slide: a card on the ground, its hairline round the words, the
/// glyph in the quiet ink (a slide is no act to take), the words in the
/// middle of the slide.
class _Slide extends StatelessWidget {
  const _Slide(this.slide);

  final (IconData, String, String) slide;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final (icon, title, body) = slide;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.card,
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinimalSpacing.s20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MinimalIcon(
              icon,
              size: MinimalIconSize.i24,
              color: t.mutedForeground,
            ),
            const MinimalGap(MinimalSpacing.s12),
            Text(title, style: t.h3.c(t.foreground)),
            const MinimalGap(MinimalSpacing.s4),
            Text(body, style: t.bodySmall.c(t.mutedForeground)),
          ],
        ),
      ),
    );
  }
}

/// The slides in a carousel as tall as their words: 160 at the default
/// size, growing with the text scale so a larger size never cuts a slide.
class _Slides extends StatelessWidget {
  const _Slides({
    this.label,
    this.viewportFraction = 1,
    this.loop = false,
    this.autoplay,
  });

  final String? label;
  final double viewportFraction;
  final bool loop;
  final Duration? autoplay;

  @override
  Widget build(BuildContext context) => MinimalCarouselView(
    label: label,
    height: MediaQuery.textScalerOf(context).scale(160),
    viewportFraction: viewportFraction,
    loop: loop,
    autoplay: autoplay,
    children: [for (final s in _slides) _Slide(s)],
  );
}

Widget kitCarouselDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Carousel',
  sections: [
    kitSection(
      'One at a time',
      children: [
        // As tall as a slide's words, so none stands half empty.
        const _Slides(label: 'What Ritual does'),
        kitNote('Swipe, press an arrow or a dot, or tab in and use ← →.'),
      ],
    ),
    kitSection(
      'Peeking',
      children: [const _Slides(viewportFraction: 0.82, loop: true)],
    ),
    kitSection(
      'Playing',
      children: [
        const _Slides(autoplay: Duration(seconds: 4), loop: true),
        kitNote(
          'It pauses under a pointer and never plays under Reduce Motion.',
        ),
      ],
    ),
  ],
);

// --- catalog specimens -------------------------------------------------------

/// The first slide, its arrows and dots under it.
Widget kitSpecimenCarousel() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalCarouselView(
    height: 180,
    children: [for (final s in _slides) _Slide(s)],
  ),
);
