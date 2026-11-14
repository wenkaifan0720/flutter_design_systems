/// The splash's demo: the shape mark on the surface and full-bleed on
/// primary, a custom mark, the mark restoring (the loading indicator's
/// sequence), and a live handoff into a first screen's anchor — replay it,
/// or hold the restore and release it.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The splash's demo, in [brightness].
Widget kitSplashDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Splash',
  sections: const <Widget>[_Marks(), _Restoring(), _Handoff()],
);

/// A phone-shaped window onto a splash.
class _Window extends StatelessWidget {
  const _Window({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(ExpressiveSpacing.s16),
    child: SizedBox(height: kitGap * 40, child: child),
  );
}

class _Marks extends StatelessWidget {
  const _Marks();

  @override
  Widget build(BuildContext context) => kitSection(
    'Marks: a library shape on the surface, full-bleed primary, custom',
    children: <Widget>[
      const _Window(child: ExpressiveSplashScreenMark(wordmark: 'Harbor')),
      const _Window(
        child: ExpressiveSplashScreenMark(
          shape: ExpressiveMaterialShape.sunny,
          wordmark: 'Isobar',
          ground: ExpressiveSplashScreenGround.primary,
        ),
      ),
      _Window(
        child: ExpressiveSplashScreenMark.custom(
          wordmark: 'Blocks',
          builder: (context, restoring) {
            final c = context.expressiveTheme.colors;
            return Row(
              mainAxisSize: MainAxisSize.min,
              spacing: kitGap,
              children: <Widget>[
                for (final color in <Color>[
                  c.tertiaryContainer,
                  c.secondaryContainer,
                ])
                  SizedBox.square(
                    dimension: kitGap * 5,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: color,
                        shape: context.expressiveTheme.shapes.large,
                      ),
                    ),
                  ),
                ExpressiveSplashScreenSource(
                  corner: ExpressiveCorner.extraLarge,
                  color: c.primaryContainer,
                  child: SizedBox.square(
                    dimension: kitGap * 9,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: c.primaryContainer,
                        shape: context.expressiveTheme.shapes.extraLarge,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ],
  );
}

class _Restoring extends StatelessWidget {
  const _Restoring();

  @override
  Widget build(BuildContext context) => kitSection(
    'Restoring: the loading indicator\'s sequence',
    children: const <Widget>[
      _Window(
        child: ExpressiveSplashScreenMark(wordmark: 'Harbor', restoring: true),
      ),
    ],
  );
}

class _Handoff extends StatefulWidget {
  const _Handoff();

  @override
  State<_Handoff> createState() => _HandoffState();
}

class _HandoffState extends State<_Handoff> {
  int _run = 0;
  bool _restoring = false;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Handoff into the first screen\'s anchor',
      children: <Widget>[
        _Window(
          child: ExpressiveSplashScreen(
            key: ValueKey<int>(_run),
            restoring: _restoring,
            restoringLabel: 'Restoring your session',
            mark: const ExpressiveSplashScreenMark(wordmark: 'Harbor'),
            child: ColoredBox(
              color: t.colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(ExpressiveSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Today',
                      style: t.type.headlineMedium.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    ExpressiveSplashScreenAnchor(
                      corner: ExpressiveCorner.full,
                      color: t.colors.primary,
                      child: ExpressiveFilledButton(
                        'Measure now',
                        size: ExpressiveButtonSize.medium,
                        expand: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            ExpressiveFilledButton.tonal(
              'Replay',
              onPressed: () => setState(() {
                _run++;
                _restoring = false;
              }),
            ),
            ExpressiveOutlinedButton(
              _restoring ? 'Finish restoring' : 'Restore again',
              onPressed: () => setState(() {
                if (!_restoring) _run++;
                _restoring = !_restoring;
              }),
            ),
          ],
        ),
      ],
    );
  }
}
