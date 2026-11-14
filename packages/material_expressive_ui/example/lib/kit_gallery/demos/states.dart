/// The states group's demo: the state layers over each container role, and
/// the shared pressable every pressable component is built on — the press
/// and selected shape morph on a spring, elevation by state, the disabled
/// state and the 48dp touch target around a small control.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The states group's demo, in [brightness].
Widget kitStatesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Interaction states',
  sections: const <Widget>[
    _Layers(),
    _Morph(),
    _Toggle(),
    _Elevated(),
    _Small(),
  ],
);

/// A labelled pill of content: what a demo pressable holds.
Widget _label(String text, {IconData? icon}) => Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: ExpressiveSpacing.s24,
    vertical: ExpressiveSpacing.s16,
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      if (icon != null) ...<Widget>[
        ExpressiveIcon(icon),
        const SizedBox(width: ExpressiveSpacing.s8),
      ],
      Text(text),
    ],
  ),
);

class _Layers extends StatelessWidget {
  const _Layers();

  static const List<(String, Set<WidgetState>)> _states =
      <(String, Set<WidgetState>)>[
        ('Rest', <WidgetState>{}),
        ('Hovered', <WidgetState>{WidgetState.hovered}),
        ('Focused', <WidgetState>{WidgetState.focused}),
        ('Pressed', <WidgetState>{WidgetState.pressed}),
        ('Dragged', <WidgetState>{WidgetState.dragged}),
      ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final pairs = <(String, Color, Color)>[
      ('Primary', c.primary, c.onPrimary),
      ('Secondary container', c.secondaryContainer, c.onSecondaryContainer),
      ('Surface', c.surfaceContainerLow, c.onSurface),
    ];
    return kitSection(
      'State layers',
      children: <Widget>[
        for (final (name, container, content) in pairs) ...<Widget>[
          // Under the section's heading: a label, not the body's size.
          Text(
            name,
            style: t.type.labelMedium.copyWith(color: c.onSurfaceVariant),
          ),
          Wrap(
            spacing: ExpressiveSpacing.s4,
            runSpacing: ExpressiveSpacing.s4,
            children: <Widget>[
              // The content's glyph on each layer, the state named under
              // it: a state is a moment, so its name is not read as words
              // resting on the layer.
              for (final (label, states) in _states)
                SizedBox(
                  width: ExpressiveSpacing.s64,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: ExpressiveSpacing.s48,
                        child: DecoratedBox(
                          decoration: ShapeDecoration(
                            color: t.states.composite(
                              container,
                              content,
                              states,
                            ),
                            shape: t.shapes.small,
                          ),
                          child: Center(
                            child: ExpressiveIcon(
                              ExpressiveSymbols.star,
                              color: content,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ExpressiveSpacing.s4),
                      Text(
                        label,
                        style: t.type.labelSmall.copyWith(
                          color: c.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Morph extends StatelessWidget {
  const _Morph();

  // A button's corners spring to its size's pressed shape and back: round
  // or square at rest, both to the same small corners held down. The
  // buttons draw their labels with the capitals on the face's middle.
  @override
  Widget build(BuildContext context) => kitSection(
    'Press morph — hold to see the corners spring',
    children: <Widget>[
      Wrap(
        spacing: kitGap,
        runSpacing: kitGap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ExpressiveFilledButton(
            'Book table',
            icon: ExpressiveSymbols.check,
            size: ExpressiveButtonSize.medium,
            onPressed: () {},
          ),
          ExpressiveFilledButton.tonal(
            'Share',
            icon: ExpressiveSymbols.share,
            size: ExpressiveButtonSize.medium,
            shape: ExpressiveButtonShape.square,
            onPressed: () {},
          ),
          const ExpressiveFilledButton(
            'Unavailable',
            size: ExpressiveButtonSize.medium,
            onPressed: null,
          ),
        ],
      ),
    ],
  );
}

class _Toggle extends StatefulWidget {
  const _Toggle();

  @override
  State<_Toggle> createState() => _ToggleState();
}

class _ToggleState extends State<_Toggle> {
  bool _saved = true;
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    // The look's toggle button: its round face squares when chosen, and
    // its label stands on the face's middle by its capitals.
    Widget toggle(String label, IconData icon, bool on, VoidCallback flip) =>
        ExpressiveToggleButton(
          value: on,
          onChanged: (_) => flip(),
          label: label,
          icon: icon,
          kind: ExpressiveToggleButtonKind.tonal,
        );
    return kitSection(
      'Selected shape — tap to toggle',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            toggle(
              _saved ? 'Saved' : 'Save',
              _saved
                  ? ExpressiveSymbols.bookmark
                  : ExpressiveSymbols.bookmarkBorder,
              _saved,
              () => setState(() => _saved = !_saved),
            ),
            toggle(
              _following ? 'Following' : 'Follow',
              ExpressiveSymbols.notifications,
              _following,
              () => setState(() => _following = !_following),
            ),
          ],
        ),
      ],
    );
  }
}

class _Elevated extends StatelessWidget {
  const _Elevated();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return kitSection(
      'Elevation by state — press to lift',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            ExpressivePressable(
              shapes: ExpressivePressShapes(
                shape: t.shapes.full,
                pressed: t.shapes.small,
              ),
              motion: ExpressiveMotionKey.defaultEffects,
              color: c.surfaceContainerLow,
              contentColor: c.primary,
              elevation: const ExpressiveStateElevation(
                rest: ExpressiveElevationLevel.level1,
                hovered: ExpressiveElevationLevel.level2,
                pressed: ExpressiveElevationLevel.level1,
                focused: ExpressiveElevationLevel.level1,
                disabled: ExpressiveElevationLevel.level0,
              ),
              onPressed: () {},
              child: _label('Directions', icon: ExpressiveSymbols.arrowForward),
            ),
            ExpressivePressable(
              shapes: ExpressivePressShapes(
                shape: t.shapes.large,
                pressed: t.shapes.medium,
              ),
              motion: ExpressiveMotionKey.fastSpatial,
              color: c.primaryContainer,
              contentColor: c.onPrimaryContainer,
              elevation: const ExpressiveStateElevation(
                rest: ExpressiveElevationLevel.level3,
                hovered: ExpressiveElevationLevel.level4,
              ),
              onPressed: () {},
              semanticLabel: 'Edit',
              child: Padding(
                padding: const EdgeInsets.all(ExpressiveSpacing.s16),
                child: ExpressiveIcon(ExpressiveSymbols.edit),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Small extends StatelessWidget {
  const _Small();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    Widget small() => ExpressivePressable(
      shapes: ExpressivePressShapes(
        shape: t.shapes.full,
        pressed: t.shapes.small,
      ),
      motion: ExpressiveMotionKey.fastSpatial,
      color: c.surfaceContainerHighest,
      contentColor: c.onSurfaceVariant,
      semanticLabel: 'Favourite',
      onPressed: () {},
      child: const Padding(
        padding: EdgeInsets.all(ExpressiveSpacing.s4),
        child: ExpressiveIcon(
          ExpressiveSymbols.favorite,
          size: ExpressiveSpacing.s24,
        ),
      ),
    );
    return kitSection(
      'Touch target',
      children: <Widget>[
        Text(
          'A 32dp control keeps a 48dp touch target around it; a dense row '
          'can shrink it.',
          style: TextStyle(color: c.onSurfaceVariant),
        ),
        Row(
          children: <Widget>[
            small(),
            const SizedBox(width: kitGap),
            ExpressiveShrinkTapTargets(child: small()),
          ],
        ),
      ],
    );
  }
}
