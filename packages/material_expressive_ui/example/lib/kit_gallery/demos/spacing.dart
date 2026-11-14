/// The spacing group's demo: the 8dp scale, every step drawn as a bar its
/// own length long beside its name.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The spacing group's demo, in [brightness].
Widget kitSpacingDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Spacing',
  sections: const <Widget>[_Scale()],
);

class _Scale extends StatelessWidget {
  const _Scale();

  @override
  Widget build(BuildContext context) {
    final c = context.expressiveTheme.colors;
    return kitSection(
      'The spacing scale',
      children: <Widget>[
        for (final step in ExpressiveSpacing.scale)
          Row(
            children: <Widget>[
              SizedBox(
                width: ExpressiveSpacing.s64 + ExpressiveSpacing.s32,
                child: Text(
                  's${step.round()} · ${step.round()}dp',
                  style: TextStyle(color: c.onSurfaceVariant),
                ),
              ),
              SizedBox(
                width: step,
                height: ExpressiveSpacing.s16,
                child: ColoredBox(color: c.primary),
              ),
            ],
          ),
      ],
    );
  }
}
