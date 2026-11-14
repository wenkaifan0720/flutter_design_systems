/// Minimal's adjusters: the thin-track slider (continuous, stepped, with
/// end glyphs, bare and disabled), the bordered − n + stepper in a form's
/// rows and at its bounds, and the mono counter that rolls to each new
/// value.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSliderStepperDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Slider, stepper, counter',
  sections: [
    kitSection('Slider', children: const [_Sliders()]),
    kitSection(
      'Slider · disabled',
      children: const [
        MinimalSlider(
          label: 'Snooze length',
          value: 0.3,
          valueLabel: '10',
          unit: 'min',
        ),
      ],
    ),
    kitSection('Stepper · in rows', children: const [_Steppers()]),
    kitSection(
      'Stepper · bounds',
      children: [
        kitRow([
          MinimalNumberField(
            value: 0,
            min: 0,
            max: 3,
            label: 'Rest days',
            onChanged: (_) {},
          ),
          MinimalNumberField(
            value: 3,
            min: 0,
            max: 3,
            label: 'Rest days',
            onChanged: (_) {},
          ),
          const MinimalNumberField(
            value: 2,
            min: 0,
            max: 3,
            label: 'Rest days',
          ),
        ]),
        kitNote(
          'At its limit a button rests; a stepper that cannot change right '
          'now dims as a whole.',
        ),
      ],
    ),
    kitSection('Counter', children: const [_Streak()]),
    kitSection('Counter · money', children: const [_Takings()]),
  ],
);

/// Three live sliders: a percentage, a stepped goal and a glyph-ended one
/// without its label line.
class _Sliders extends StatefulWidget {
  const _Sliders();

  @override
  State<_Sliders> createState() => _SlidersState();
}

class _SlidersState extends State<_Sliders> {
  double _volume = 0.7;
  double _pages = 20;
  double _brightness = 0.45;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalSlider(
        label: 'Reminder volume',
        value: _volume,
        format: (v) => '${(v * 100).round()}%',
        onChanged: (v) => setState(() => _volume = v),
      ),
      const MinimalGap(MinimalSpacing.s12),
      MinimalSlider(
        label: 'Daily reading goal',
        value: _pages,
        min: 10,
        max: 50,
        divisions: 8,
        unit: 'pages',
        onChanged: (v) => setState(() => _pages = v),
      ),
      const MinimalGap(MinimalSpacing.s12),
      MinimalSlider(
        label: 'Chime loudness',
        showLabel: false,
        value: _brightness,
        leadingIcon: LucideIcons.volume1,
        trailingIcon: LucideIcons.volume2,
        onChanged: (v) => setState(() => _brightness = v),
      ),
    ],
  );
}

/// A habit's targets as form rows, each a live stepper.
class _Steppers extends StatefulWidget {
  const _Steppers();

  @override
  State<_Steppers> createState() => _SteppersState();
}

class _SteppersState extends State<_Steppers> {
  int _glasses = 6;
  int _pages = 20;
  int _sets = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Each row reads its inset under the list's KitBleed.
    Widget row(String title, Widget stepper) => Builder(
      builder: (context) => Container(
        constraints: BoxConstraints(minHeight: t.rowHeight),
        padding: KitBleed.inset(context),
        decoration: BoxDecoration(border: Border(bottom: t.rule)),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: t.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const MinimalGap(MinimalSpacing.s12),
            stepper,
          ],
        ),
      ),
    );
    // A full-bleed list, as on a form page: rows between hairlines, no card;
    // edge to edge on a phone, on the column's keylines in a wider window.
    return KitBleed(
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: t.rule)),
        child: Column(
          children: [
            row(
              'Drink water',
              MinimalNumberField(
                value: _glasses,
                min: 1,
                max: 12,
                label: 'Glasses',
                format: (v) => '$v×',
                onChanged: (v) => setState(() => _glasses = v),
              ),
            ),
            row(
              'Read',
              MinimalNumberField(
                value: _pages,
                min: 5,
                max: 50,
                step: 5,
                label: 'Pages',
                unit: 'pages',
                onChanged: (v) => setState(() => _pages = v),
              ),
            ),
            row(
              'Stretch sets',
              MinimalNumberField(
                value: _sets,
                min: 1,
                max: 5,
                label: 'Sets',
                onChanged: (v) => setState(() => _sets = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A counter that rolls: a streak in the giant register, driven by its
/// buttons.
class _Streak extends StatefulWidget {
  const _Streak();

  @override
  State<_Streak> createState() => _StreakState();
}

class _StreakState extends State<_Streak> {
  int _streak = 12;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      padding: MinimalInsets.all12,
      decoration: ShapeDecoration(
        shape: t.shapes.medium.copyWith(
          side: BorderSide(color: t.border, width: t.hairline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MORNING RUN · STREAK', style: t.label),
                const MinimalGap(MinimalSpacing.s4),
                MinimalCounter(_streak, style: t.giant, format: (v) => '${v}d'),
                // The figure in the mono face, as the streak over it and
                // the takings' count below; the word in the body face.
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'best ', style: t.caption),
                      TextSpan(text: '21d', style: t.mono.c(t.mutedForeground)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          MinimalIconButton(
            LucideIcons.minus,
            label: 'Shorter streak',
            variant: MinimalIconButtonVariant.outline,
            onPressed: _streak > 0 ? () => setState(() => _streak -= 1) : null,
          ),
          const MinimalGap(6),
          MinimalIconButton(
            LucideIcons.plus,
            label: 'Longer streak',
            variant: MinimalIconButtonVariant.outline,
            onPressed: () => setState(() => _streak += 1),
          ),
        ],
      ),
    );
  }
}

/// Counters that roll in a money total and inside the line of prose under
/// it: a sale adds to both.
class _Takings extends StatefulWidget {
  const _Takings();

  @override
  State<_Takings> createState() => _TakingsState();
}

class _TakingsState extends State<_Takings> {
  int _takings = 128450;
  int _sales = 14;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = t.bodySmall.c(t.mutedForeground);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The default style: the theme's figure.
              MinimalCounter(
                _takings,
                format: (v) => MinimalFormat.money(v, symbol: '€'),
              ),
              const MinimalGap(MinimalSpacing.s2),
              // The count is a figure (mono); the words stay in the body
              // face.
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('from', style: words),
                  const MinimalGap(MinimalSpacing.s4),
                  MinimalCounter(_sales, style: t.mono.copyWith(fontSize: 13)),
                  const MinimalGap(MinimalSpacing.s4),
                  Flexible(
                    child: Text(
                      'sales today',
                      style: words,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        MinimalButton(
          'Add sale',
          size: MinimalButtonSize.small,
          variant: MinimalButtonVariant.secondary,
          icon: LucideIcons.plus,
          onPressed: () => setState(() {
            _takings += 1250;
            _sales += 1;
          }),
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A continuous value under its label, the value printed in mono.
Widget kitSpecimenSliderContinuous() => MinimalSlider(
  label: 'Reminder volume',
  value: 0.7,
  format: (v) => '${(v * 100).round()}%',
  onChanged: (_) {},
);

/// A stepped value on a ticked track, with its unit.
Widget kitSpecimenSliderStepped() => MinimalSlider(
  label: 'Daily reading goal',
  value: 20,
  min: 10,
  max: 50,
  divisions: 8,
  unit: 'pages',
  onChanged: (_) {},
);

/// A bounded count in steps of five, in the row that names it.
Widget kitSpecimenStepperRow() => MinimalFormRow(
  label: 'Pages a day',
  icon: LucideIcons.bookOpen,
  trailing: MinimalNumberField(
    value: 20,
    min: 5,
    max: 50,
    step: 5,
    unit: 'pages',
    label: 'Pages a day',
    onChanged: (_) {},
  ),
);

/// The screen's one live quantity, in the giant figure.
Widget kitSpecimenCounterStreak() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('MORNING RUN · STREAK', style: t.label),
        const MinimalGap(MinimalSpacing.s4),
        MinimalCounter(12, style: t.giant, format: (v) => '${v}d'),
      ],
    );
  },
);
