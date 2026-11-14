/// The `button` oracle group (Compose twin: `ButtonScenes.kt`): the common
/// buttons' five styles × five sizes, square, disabled, pressed and
/// focused; leading icons; toggle buttons unchecked and checked; the
/// standard group and the connected group (the segmented control); and the
/// two motion rows the family owns — the press morph and the group squish.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/button_large_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/button_medium_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/button_small_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/button_x_large_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/button_x_small_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/keys.g.dart';

import '../harness/oracle.dart';

/// The sizes by key segment, with the crop the filled scene uses.
const List<(String, ExpressiveButtonSize, Size)> buttonSizes = [
  ('xs', ExpressiveButtonSize.extraSmall, Size(136, 64)),
  ('s', ExpressiveButtonSize.small, Size(136, 72)),
  ('m', ExpressiveButtonSize.medium, Size(176, 96)),
  ('l', ExpressiveButtonSize.large, Size(264, 136)),
  ('xl', ExpressiveButtonSize.extraLarge, Size(336, 176)),
];

/// The styles by key segment.
const List<(String, ExpressiveButtonKind)> buttonStyles = [
  ('filled', ExpressiveButtonKind.filled),
  ('tonal', ExpressiveButtonKind.tonal),
  ('outlined', ExpressiveButtonKind.outlined),
  ('elevated', ExpressiveButtonKind.elevated),
  ('text', ExpressiveButtonKind.text),
];

/// The toggle styles by key segment.
const List<(String, ExpressiveToggleButtonKind)> toggleStyles = [
  ('filled', ExpressiveToggleButtonKind.filled),
  ('elevated', ExpressiveToggleButtonKind.elevated),
  ('tonal', ExpressiveToggleButtonKind.tonal),
  ('outlined', ExpressiveToggleButtonKind.outlined),
];

/// The styles scene's column height: five buttons, each at least the 48dp
/// touch target tall, 8dp apart, plus a 16dp margin top and bottom.
const Map<String, double> _stylesHeight = {
  'xs': 304,
  's': 304,
  'm': 344,
  'l': 544,
  'xl': 744,
};

/// The icon scenes' crops: the filled crop widened for the icon.
const Map<String, Size> _iconCrop = {
  'xs': Size(136, 64),
  's': Size(160, 72),
  'm': Size(208, 96),
  'l': Size(304, 136),
  'xl': Size(400, 176),
};

/// `ButtonDefaults.iconSizeFor(height)`.
double _iconSize(ExpressiveButtonSize size) => switch (size) {
  ExpressiveButtonSize.extraSmall => ButtonXSmallTokens.iconSize,
  ExpressiveButtonSize.small => ButtonSmallTokens.iconSize,
  ExpressiveButtonSize.medium => ButtonMediumTokens.iconSize,
  ExpressiveButtonSize.large => ButtonLargeTokens.iconSize,
  ExpressiveButtonSize.extraLarge => ButtonXLargeTokens.iconSize,
};

(ExpressiveShapeKey, ExpressiveShapeKey, ExpressiveShapeKey) _shapeKeys(
  ExpressiveButtonSize size,
) => switch (size) {
  ExpressiveButtonSize.extraSmall => (
    ButtonXSmallTokens.containerShapeRound,
    ButtonXSmallTokens.containerShapeSquare,
    ButtonXSmallTokens.pressedContainerShape,
  ),
  ExpressiveButtonSize.small => (
    ButtonSmallTokens.containerShapeRound,
    ButtonSmallTokens.containerShapeSquare,
    ButtonSmallTokens.pressedContainerShape,
  ),
  ExpressiveButtonSize.medium => (
    ButtonMediumTokens.containerShapeRound,
    ButtonMediumTokens.containerShapeSquare,
    ButtonMediumTokens.pressedContainerShape,
  ),
  ExpressiveButtonSize.large => (
    ButtonLargeTokens.containerShapeRound,
    ButtonLargeTokens.containerShapeSquare,
    ButtonLargeTokens.pressedContainerShape,
  ),
  ExpressiveButtonSize.extraLarge => (
    ButtonXLargeTokens.containerShapeRound,
    ButtonXLargeTokens.containerShapeSquare,
    ButtonXLargeTokens.pressedContainerShape,
  ),
};

ShapeBorder _rest(BuildContext context, ExpressiveButtonSize size) =>
    context.expressiveTheme.shapes.of(_shapeKeys(size).$1);

/// A button in [style] at [size], labelled "Button", optionally tagged
/// label and leading icon slot.
Widget _button(
  ExpressiveButtonKind style,
  ExpressiveButtonSize size, {
  bool enabled = true,
  ExpressiveButtonShape shape = ExpressiveButtonShape.round,
  bool tagLabel = false,
  bool iconSlot = false,
}) {
  final onPressed = enabled ? () {} : null;
  final content = tagLabel
      ? const OracleTag('label', child: Text('Button'))
      : null;
  // The oracle bundles no Material Symbols, so both sides measure the icon
  // slot as an empty box of the size's icon size.
  final leading = iconSlot
      ? OracleTag('icon', child: SizedBox.square(dimension: _iconSize(size)))
      : null;
  return switch (style) {
    ExpressiveButtonKind.filled => ExpressiveFilledButton(
      'Button',
      size: size,
      shape: shape,
      onPressed: onPressed,
      leading: leading,
      child: content,
    ),
    ExpressiveButtonKind.tonal => ExpressiveFilledButton.tonal(
      'Button',
      size: size,
      shape: shape,
      onPressed: onPressed,
      leading: leading,
      child: content,
    ),
    ExpressiveButtonKind.outlined => ExpressiveOutlinedButton(
      'Button',
      size: size,
      shape: shape,
      onPressed: onPressed,
      leading: leading,
      child: content,
    ),
    ExpressiveButtonKind.elevated => ExpressiveElevatedButton(
      'Button',
      size: size,
      shape: shape,
      onPressed: onPressed,
      leading: leading,
      child: content,
    ),
    ExpressiveButtonKind.text => ExpressiveTextButton(
      'Button',
      size: size,
      shape: shape,
      onPressed: onPressed,
      leading: leading,
      child: content,
    ),
  };
}

/// [child] tagged [tag] on its visual container, as Compose's semantics
/// bounds report it: the outer box keeps the 48dp touch target in the
/// layout (Compose's `minimumInteractiveComponentSize`), while the button
/// inside draws and measures at its own size, so the tag never includes
/// the touch-target margin.
Widget _tagged(String tag, Widget child, {ShapeBorder? shape}) =>
    ExpressiveMinimumInteractiveSize(
      child: ExpressiveShrinkTapTargets(
        child: OracleTag(tag, shape: shape, child: child),
      ),
    );

/// [children] top to bottom, 8dp apart and start-aligned (Compose
/// `Column(verticalArrangement = spacedBy(8.dp))`).
Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 8,
  children: children,
);

/// Three tonal S buttons in a standard group 312dp wide, weighted equally.
Widget _standardGroup() => SizedBox(
  width: 312,
  child: ExpressiveButtonGroup(
    expand: true,
    children: [
      for (final label in ['Day', 'Week', 'Month'])
        _tagged(
          label.toLowerCase(),
          ExpressiveFilledButton.tonal(label, onPressed: () {}),
        ),
    ],
  ),
);

/// A three-segment connected group at [size], the middle checked, 312dp
/// wide (tag `group`).
Widget _connected(ExpressiveButtonSize size) => SizedBox(
  width: 312,
  child: OracleTag(
    'group',
    child: ExpressiveSegmentedButton<int>(
      size: size,
      value: 1,
      onChanged: (_) {},
      segments: const [
        ExpressiveButtonSegment(0, 'Day'),
        ExpressiveButtonSegment(1, 'Week'),
        ExpressiveButtonSegment(2, 'Month'),
      ],
    ),
  ),
);

final OracleGroup buttonScenes = OracleGroup(
  id: 'button',
  // The host gives the pressables the platform ripple.
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return ExpressiveHost(
      light: theme,
      dark: theme,
      brightness: theme.brightness,
      child: ExpressiveHeroMoment(child: scene),
    );
  },
  scenes: [
    // Wave 0's filled scenes: every size, round, enabled.
    for (final (id, size, crop) in buttonSizes)
      OracleScene(
        key: 'button/filled/$id',
        size: crop,
        build: (context) => _tagged(
          'container',
          _button(ExpressiveButtonKind.filled, size, tagLabel: true),
          shape: _rest(context, size),
        ),
      ),
    // The five styles at each size.
    for (final (id, size, crop) in buttonSizes)
      OracleScene(
        key: 'button/styles/$id',
        size: Size(crop.width, _stylesHeight[id]!),
        build: (context) => _column([
          for (final (name, style) in buttonStyles)
            _tagged(
              'container-$name',
              _button(style, size),
              shape: _rest(context, size),
            ),
        ]),
      ),
    // Filled, square, at each size.
    OracleScene(
      key: 'button/square',
      size: const Size(336, 448),
      build: (context) => _column([
        for (final (id, size, _) in buttonSizes)
          _tagged(
            'container-$id',
            _button(
              ExpressiveButtonKind.filled,
              size,
              shape: ExpressiveButtonShape.square,
            ),
            shape: context.expressiveTheme.shapes.of(_shapeKeys(size).$2),
          ),
      ]),
    ),
    // The five styles disabled, S.
    OracleScene(
      key: 'button/disabled',
      size: const Size(136, 304),
      build: (context) => _column([
        for (final (name, style) in buttonStyles)
          _tagged(
            'container-$name',
            _button(style, ExpressiveButtonSize.small, enabled: false),
            shape: _rest(context, ExpressiveButtonSize.small),
          ),
      ]),
    ),
    // Pressed (the pressed shape) and focused, S, per style.
    for (final (name, style) in buttonStyles) ...[
      OracleScene(
        key: 'button/pressed/$name',
        size: const Size(136, 72),
        interaction: const OraclePress('container'),
        build: (context) => _tagged(
          'container',
          _button(style, ExpressiveButtonSize.small),
          shape: context.expressiveTheme.shapes.of(
            _shapeKeys(ExpressiveButtonSize.small).$3,
          ),
        ),
      ),
      OracleScene(
        key: 'button/focused/$name',
        size: const Size(136, 72),
        interaction: const OracleFocus('container'),
        build: (context) => _tagged(
          'container',
          _button(style, ExpressiveButtonSize.small),
          shape: _rest(context, ExpressiveButtonSize.small),
        ),
      ),
    ],
    // A leading icon at each size.
    for (final (id, size, _) in buttonSizes)
      OracleScene(
        key: 'button/icon/$id',
        size: _iconCrop[id]!,
        build: (context) => _tagged(
          'container',
          _button(
            ExpressiveButtonKind.filled,
            size,
            tagLabel: true,
            iconSlot: true,
          ),
          shape: _rest(context, size),
        ),
      ),
    // Toggle buttons, S, unchecked and checked.
    for (final checked in [false, true])
      OracleScene(
        key: 'button/toggle/${checked ? 'checked' : 'unchecked'}',
        size: const Size(136, 248),
        build: (context) => _column([
          for (final (name, style) in toggleStyles)
            _tagged(
              'container-$name',
              ExpressiveToggleButton(
                value: checked,
                onChanged: (_) {},
                label: 'Button',
                kind: style,
              ),
              shape: context.expressiveTheme.shapes.of(
                checked
                    ? ButtonSmallTokens.selectedContainerShapeSquare
                    : ButtonSmallTokens.containerShapeRound,
              ),
            ),
        ]),
      ),
    // The standard group at rest.
    OracleScene(
      key: 'button/group/standard',
      size: const Size(336, 72),
      build: (context) => _standardGroup(),
    ),
    // The connected group, the middle segment checked.
    for (final (id, size, crop) in buttonSizes.take(3))
      OracleScene(
        key: 'button/group/connected-$id',
        size: Size(336, crop.height),
        build: (context) => _connected(size),
      ),
    // Motion: the press morph (a filled M button's corners springing to
    // the pressed shape) and the group squish (the middle of the standard
    // group widening, its neighbours giving way).
    OracleScene(
      key: 'button/motion/press-morph',
      size: const Size(176, 96),
      interaction: const OraclePress('container'),
      motion: const OracleMotion(tags: ['container'], frames: 30, images: true),
      build: (context) => _tagged(
        'container',
        _button(ExpressiveButtonKind.filled, ExpressiveButtonSize.medium),
      ),
    ),
    OracleScene(
      key: 'button/motion/group-squish',
      size: const Size(336, 72),
      interaction: const OraclePress('week'),
      motion: const OracleMotion(tags: ['day', 'week', 'month'], frames: 40),
      build: (context) => _standardGroup(),
    ),
  ],
);

void main() => runOracleGroup(buttonScenes);
