import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';

import '../kit.dart';

/// The foundations: the palette, the type, the rule, the hard shadow and
/// the press, the focus rule, and the 4 px grid.
Widget kitFoundationsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Foundations',
  sections: const [
    KitSection(
      title: 'Palette',
      note:
          'Ink and paper do the work. One flat colour a screen, large; words '
          'on a colour are always black.',
      children: [_Palette()],
    ),
    KitSection(
      title: 'Type',
      note:
          'Space Grotesk, plain. Five sizes on a 4 px line grid; nothing '
          'smaller than 12.',
      children: [_TypeScale()],
    ),
    KitSection(
      title: 'The rule, the shadow, the press',
      note:
          'One 2 px rule on everything. A hard 4 px shadow, down and to the '
          'end side, only under what you can press; pressed, the face slides '
          'into it.',
      children: [_Faces()],
    ),
    KitSection(
      title: 'Grid',
      note: 'Everything sits on 4 px: 8, 12, 16, 24, 32, 48.',
      children: [_Grid()],
    ),
    KitSection(
      title: 'Formats and measures',
      note:
          'Times, ranges, sums and counts in one voice: the true dash and '
          'minus, commas in thousands. The field height, the reading width '
          'and the breakpoints every part reads.',
      children: [_Formats()],
    ),
  ],
);

class _Palette extends StatelessWidget {
  const _Palette();

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    final t = context.brutalTheme.textTheme;
    final swatches = <(String, Color)>[
      ('Ink', c.ink),
      ('Paper', c.paper),
      ('Muted', c.inkMuted),
      ('Signal', c.signal),
      ('Danger', c.danger),
      ('Lime', c.lime),
      ('Blue', c.blue),
      ('Pink', c.pink),
      ('Violet', c.violet),
    ];
    String hex(Color x) =>
        '#${(x.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
    return BrutalSurface(
      face: BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (name, colour)) in swatches.indexed) ...[
            if (i > 0) const BrutalRule(),
            SizedBox(
              height: 48,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 72, child: ColoredBox(color: colour)),
                  const BrutalRule(vertical: true),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(name, style: t.label)),
                          Text(hex(colour), style: t.secondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypeScale extends StatelessWidget {
  const _TypeScale();

  @override
  Widget build(BuildContext context) {
    final t = context.brutalTheme.textTheme;
    final rows = <(String, TextStyle, String)>[
      ('Display 40', t.display, 'Doors 8 pm'),
      ('Headline 28', t.headline, 'Low Tide, Hall 4'),
      ('Title 20', t.title, 'Standing, two tickets'),
      (
        'Body 16',
        t.body,
        'Bring the code on your phone; we scan it at the door.',
      ),
      ('Label 16', t.label, 'Buy tickets'),
      ('Secondary 14', t.secondary, 'Sat 21 Nov, 20:00'),
      ('Caption 12', t.caption, 'SOLD OUT'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, style, sample) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name · $brutalFontFamily', style: t.secondary),
                Text(sample, style: style),
              ],
            ),
          ),
      ],
    );
  }
}

class _Faces extends StatelessWidget {
  const _Faces();

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    final t = context.brutalTheme.textTheme;
    Widget face(String label, BrutalFace f) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          height: 64,
          child: BrutalSurface(
            face: f,
            child: Center(child: Text(label, style: t.label)),
          ),
        ),
      ],
    );
    final rest = BrutalFace(
      fill: c.surface,
      border: c.ink,
      foreground: c.ink,
      shadow: c.ink,
    );
    return KitRow(
      children: [
        face(
          'Flat',
          BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
        ),
        face('Raised', rest),
        face('Pressed', rest.copyWith(travel: 1)),
        face('Focused', rest.copyWith(focus: c.ink)),
        face(
          'Off',
          BrutalFace(
            fill: c.surface,
            border: c.disabled,
            foreground: c.disabled,
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid();

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    final t = context.brutalTheme.textTheme;
    const steps = [
      BrutalSpacing.small,
      BrutalSpacing.medium,
      BrutalSpacing.regular,
      BrutalSpacing.large,
      BrutalSpacing.extraLarge,
      BrutalSpacing.huge,
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        for (final s in steps)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: s,
                child: ColoredBox(color: c.ink),
              ),
              const SizedBox(height: 4),
              Text('${s.toInt()}', style: t.secondary),
            ],
          ),
      ],
    );
  }
}

class _Formats extends StatelessWidget {
  const _Formats();

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    final t = context.brutalTheme.textTheme;
    final doors = DateTime(2026, 11, 21, 19);
    final close = DateTime(2026, 11, 21, 23, 30);
    final rows = <(String, String)>[
      ('Range', BrutalFormat.range(doors, close)),
      ('Day', BrutalFormat.day(doors)),
      ('Sum', BrutalFormat.sum(-1420.5)),
      ('Count', BrutalFormat.count(12840)),
      ('Badge', BrutalFormat.badge(140)),
      ('Length', BrutalFormat.length(const Duration(minutes: 95))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrutalSurface(
          face: BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, (name, sample)) in rows.indexed) ...[
                if (i > 0) const BrutalRule(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(name, style: t.secondary)),
                      Text(sample, style: t.label),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: BrutalChromeMetrics.field,
          child: BrutalSurface(
            face: BrutalFace(fill: c.surface, border: c.ink, foreground: c.ink),
            child: Center(
              child: Text(
                'Field ${BrutalChromeMetrics.field.toInt()} · reading '
                '${BrutalChromeMetrics.readingWidth.toInt()} · tablet '
                '${BrutalChromeMetrics.tablet.toInt()} · desktop '
                '${BrutalChromeMetrics.desktop.toInt()}',
                style: t.secondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
