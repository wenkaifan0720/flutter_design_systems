/// The `icon-buttons` oracle group (Compose twin: `IconButtonsScenes.kt`):
/// icon buttons in every style and size, widths, square, disabled, pressed,
/// focused, toggles, the press morph and the group squish; split buttons in
/// every size and
/// style, open, pressed and disabled. Buttons draw at their own size (touch
/// targets shrunk, as the twin provides 0dp), and glyphs are blank: the
/// oracle ships no Material Symbols font.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'package:material_expressive_ui/src/material_expressive/internal/tokens/keys.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/large_icon_button_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/medium_icon_button_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/small_icon_button_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/x_large_icon_button_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/x_small_icon_button_tokens.g.dart';

import '../harness/oracle.dart';

/// A glyph that draws nothing, the twin's empty icon box.
const IconData _blank = IconData(
  0x20,
  fontFamily: ExpressiveSymbolsFont.family,
);

const List<(String, ExpressiveIconButtonSize, Size)> _sizes = [
  ('xs', ExpressiveIconButtonSize.extraSmall, Size(96, 96)),
  ('s', ExpressiveIconButtonSize.small, Size(112, 112)),
  ('m', ExpressiveIconButtonSize.medium, Size(144, 144)),
  ('l', ExpressiveIconButtonSize.large, Size(224, 224)),
  ('xl', ExpressiveIconButtonSize.extraLarge, Size(304, 304)),
];

const List<(String, ExpressiveSplitButtonSize, Size)> _splitSizes = [
  ('xs', ExpressiveSplitButtonSize.extraSmall, Size(136, 56)),
  ('s', ExpressiveSplitButtonSize.small, Size(136, 56)),
  ('m', ExpressiveSplitButtonSize.medium, Size(176, 72)),
  ('l', ExpressiveSplitButtonSize.large, Size(272, 112)),
  ('xl', ExpressiveSplitButtonSize.extraLarge, Size(368, 152)),
];

const List<(String, ExpressiveIconButtonWidth)> _widths = [
  ('narrow', ExpressiveIconButtonWidth.narrow),
  ('uniform', ExpressiveIconButtonWidth.uniform),
  ('wide', ExpressiveIconButtonWidth.wide),
];

const List<ExpressiveIconButtonSize> _small = [
  ExpressiveIconButtonSize.extraSmall,
  ExpressiveIconButtonSize.small,
  ExpressiveIconButtonSize.medium,
];

void _noop() {}

/// A row top-aligned, as the twin's `Row` (default `Alignment.Top`).
Widget _row(List<Widget> children) => Row(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 16,
  children: children,
);

Widget _column(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: 16,
  children: children,
);

/// The token shape keys of [size]: (round, square, selected round).
(ExpressiveShapeKey, ExpressiveShapeKey, ExpressiveShapeKey) _keys(
  ExpressiveIconButtonSize size,
) => switch (size) {
  ExpressiveIconButtonSize.extraSmall => (
    XSmallIconButtonTokens.containerShapeRound,
    XSmallIconButtonTokens.containerShapeSquare,
    XSmallIconButtonTokens.selectedContainerShapeRound,
  ),
  ExpressiveIconButtonSize.small => (
    SmallIconButtonTokens.containerShapeRound,
    SmallIconButtonTokens.containerShapeSquare,
    SmallIconButtonTokens.selectedContainerShapeRound,
  ),
  ExpressiveIconButtonSize.medium => (
    MediumIconButtonTokens.containerShapeRound,
    MediumIconButtonTokens.containerShapeSquare,
    MediumIconButtonTokens.selectedContainerShapeRound,
  ),
  ExpressiveIconButtonSize.large => (
    LargeIconButtonTokens.containerShapeRound,
    LargeIconButtonTokens.containerShapeSquare,
    LargeIconButtonTokens.selectedContainerShapeRound,
  ),
  ExpressiveIconButtonSize.extraLarge => (
    XLargeIconButtonTokens.containerShapeRound,
    XLargeIconButtonTokens.containerShapeSquare,
    XLargeIconButtonTokens.selectedContainerShapeRound,
  ),
};

/// The shape an icon button of [size] paints at rest (round or [square]),
/// or [checked] (a round toggle's checked shape).
ShapeBorder _iconShape(
  BuildContext context,
  ExpressiveIconButtonSize size, {
  bool square = false,
  bool checked = false,
}) {
  final (round, squareKey, selected) = _keys(size);
  return context.expressiveTheme.shapes.of(
    checked ? selected : (square ? squareKey : round),
  );
}

Widget _icon(
  ExpressiveIconButtonKind style,
  ExpressiveIconButtonSize size, {
  ExpressiveIconButtonWidth width = ExpressiveIconButtonWidth.uniform,
  ExpressiveIconButtonShape shape = ExpressiveIconButtonShape.round,
  bool enabled = true,
}) => switch (style) {
  ExpressiveIconButtonKind.standard => ExpressiveIconButton(
    _blank,
    size: size,
    width: width,
    shape: shape,
    onPressed: enabled ? _noop : null,
  ),
  ExpressiveIconButtonKind.filled => ExpressiveIconButton.filled(
    _blank,
    size: size,
    width: width,
    shape: shape,
    onPressed: enabled ? _noop : null,
  ),
  ExpressiveIconButtonKind.filledTonal => ExpressiveIconButton.filledTonal(
    _blank,
    size: size,
    width: width,
    shape: shape,
    onPressed: enabled ? _noop : null,
  ),
  ExpressiveIconButtonKind.outlined => ExpressiveIconButton.outlined(
    _blank,
    size: size,
    width: width,
    shape: shape,
    onPressed: enabled ? _noop : null,
  ),
};

/// A split button from its halves, the way the twin composes one.
Widget _split(
  BuildContext context,
  ExpressiveSplitButtonKind style,
  ExpressiveSplitButtonSize size, {
  String suffix = '',
  bool checked = false,
  bool enabled = true,
  bool tagLabel = false,
}) {
  const label = Text('Send');
  final shapes = context.expressiveTheme.shapes;
  final ratio = MediaQuery.devicePixelRatioOf(context);
  return ExpressiveSplitButtonLayout(
    size: size,
    leading: OracleTag(
      'leading$suffix',
      shape: ExpressiveSplitButton.leadingShapeOf(shapes, size),
      child: ExpressiveSplitLeadingButton(
        onPressed: enabled ? _noop : null,
        kind: style,
        size: size,
        child: tagLabel ? const OracleTag('label', child: label) : label,
      ),
    ),
    trailing: OracleTag(
      'trailing$suffix',
      shape: ExpressiveSplitButton.trailingShapeOf(
        shapes,
        size,
        checked: checked,
      ),
      child: ExpressiveSplitTrailingButton(
        onPressed: enabled ? _noop : null,
        checked: checked,
        kind: style,
        size: size,
        // The twin's `Box(Modifier.size(...))`, whole device pixels.
        child: SizedBox.square(
          dimension:
              (ExpressiveSplitButton.trailingIconSizeOf(size) * ratio)
                  .roundToDouble() /
              ratio,
        ),
      ),
    ),
  );
}

/// A kind's id in scene keys and tags: its name, `tonal` for
/// [ExpressiveIconButtonKind.filledTonal] (the id its Compose references
/// were captured under, and keys take no capitals).
String _kindId(ExpressiveIconButtonKind kind) =>
    kind == ExpressiveIconButtonKind.filledTonal ? 'tonal' : kind.name;

final OracleGroup iconButtonsScenes = OracleGroup(
  id: 'icon-buttons',
  // The host gives the pressables the platform ripple and the ambient icon
  // colour; the hero admits L and XL; touch targets shrink to the drawn
  // size, as the twin provides LocalMinimumInteractiveComponentSize 0dp.
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return ExpressiveHost(
      light: theme,
      dark: theme,
      brightness: theme.brightness,
      child: ExpressiveHeroMoment(
        child: ExpressiveShrinkTapTargets(child: scene),
      ),
    );
  },
  scenes: [
    for (final (id, size, crop) in _sizes)
      OracleScene(
        key: 'icon-buttons/styles/$id',
        size: crop,
        build: (context) => _column([
          for (final pair in [
            [
              ExpressiveIconButtonKind.standard,
              ExpressiveIconButtonKind.filled,
            ],
            [
              ExpressiveIconButtonKind.filledTonal,
              ExpressiveIconButtonKind.outlined,
            ],
          ])
            _row([
              for (final style in pair)
                OracleTag(
                  'container-${_kindId(style)}',
                  shape: _iconShape(context, size),
                  child: _icon(style, size),
                ),
            ]),
        ]),
      ),
    OracleScene(
      key: 'icon-buttons/widths',
      size: const Size(224, 176),
      build: (context) => _column([
        for (final size in _small)
          _row([
            for (final (name, width) in _widths)
              OracleTag(
                '${size.name}-$name',
                child: _icon(
                  ExpressiveIconButtonKind.filled,
                  size,
                  width: width,
                ),
              ),
          ]),
      ]),
    ),
    OracleScene(
      key: 'icon-buttons/square',
      size: const Size(176, 72),
      build: (context) => _row([
        for (final size in _small)
          OracleTag(
            'container-${size.name}',
            shape: _iconShape(context, size, square: true),
            child: _icon(
              ExpressiveIconButtonKind.filled,
              size,
              shape: ExpressiveIconButtonShape.square,
            ),
          ),
      ]),
    ),
    OracleScene(
      key: 'icon-buttons/disabled',
      size: const Size(224, 56),
      build: (context) => _row([
        for (final style in ExpressiveIconButtonKind.values)
          OracleTag(
            'container-${_kindId(style)}',
            child: _icon(style, ExpressiveIconButtonSize.small, enabled: false),
          ),
      ]),
    ),
    for (final style in ExpressiveIconButtonKind.values)
      OracleScene(
        key: 'icon-buttons/pressed/${_kindId(style)}',
        size: const Size(64, 64),
        interaction: const OraclePress('container'),
        build: (context) => OracleTag(
          'container',
          child: _icon(style, ExpressiveIconButtonSize.small),
        ),
      ),
    OracleScene(
      key: 'icon-buttons/focused',
      size: const Size(64, 64),
      interaction: const OracleFocus('container'),
      build: (context) => OracleTag(
        'container',
        child: _icon(
          ExpressiveIconButtonKind.filled,
          ExpressiveIconButtonSize.small,
        ),
      ),
    ),
    for (final checked in [false, true])
      OracleScene(
        key: 'icon-buttons/toggle/${checked ? 'checked' : 'unchecked'}',
        size: const Size(224, 56),
        build: (context) => _row([
          for (final style in ExpressiveIconButtonKind.values)
            OracleTag(
              'container-${_kindId(style)}',
              shape: _iconShape(
                context,
                ExpressiveIconButtonSize.small,
                checked: checked,
              ),
              child: switch (style) {
                ExpressiveIconButtonKind.standard => ExpressiveIconToggleButton(
                  _blank,
                  value: checked,
                  onChanged: (_) {},
                ),
                ExpressiveIconButtonKind.filled =>
                  ExpressiveIconToggleButton.filled(
                    _blank,
                    value: checked,
                    onChanged: (_) {},
                  ),
                ExpressiveIconButtonKind.filledTonal =>
                  ExpressiveIconToggleButton.filledTonal(
                    _blank,
                    value: checked,
                    onChanged: (_) {},
                  ),
                ExpressiveIconButtonKind.outlined =>
                  ExpressiveIconToggleButton.outlined(
                    _blank,
                    value: checked,
                    onChanged: (_) {},
                  ),
              },
            ),
        ]),
      ),
    OracleScene(
      key: 'icon-buttons/press-morph',
      size: const Size(80, 80),
      interaction: const OraclePress('container'),
      motion: const OracleMotion(tags: ['container'], frames: 30, images: true),
      build: (context) => OracleTag(
        'container',
        child: _icon(
          ExpressiveIconButtonKind.filled,
          ExpressiveIconButtonSize.medium,
        ),
      ),
    ),
    // The group squish reaches icon buttons: a player's transport, a
    // tonal narrow M either side of a filled wide M, the middle pressed
    // (it widens, its neighbours give way on the group's spatial spring).
    OracleScene(
      key: 'icon-buttons/group-squish',
      size: const Size(240, 96),
      interaction: const OraclePress('play'),
      motion: const OracleMotion(tags: ['back', 'play', 'forward'], frames: 40),
      build: (context) => ExpressiveButtonGroup(
        children: [
          for (final (tag, style, width) in const [
            (
              'back',
              ExpressiveIconButtonKind.filledTonal,
              ExpressiveIconButtonWidth.narrow,
            ),
            (
              'play',
              ExpressiveIconButtonKind.filled,
              ExpressiveIconButtonWidth.wide,
            ),
            (
              'forward',
              ExpressiveIconButtonKind.filledTonal,
              ExpressiveIconButtonWidth.narrow,
            ),
          ])
            OracleTag(
              tag,
              child: _icon(
                style,
                ExpressiveIconButtonSize.medium,
                width: width,
              ),
            ),
        ],
      ),
    ),
    for (final (id, size, crop) in _splitSizes)
      OracleScene(
        key: 'icon-buttons/split/$id',
        size: crop,
        build: (context) => _split(
          context,
          ExpressiveSplitButtonKind.filled,
          size,
          tagLabel: true,
        ),
      ),
    OracleScene(
      key: 'icon-buttons/split/styles',
      size: const Size(144, 224),
      build: (context) => _column([
        for (final style in ExpressiveSplitButtonKind.values)
          _split(
            context,
            style,
            ExpressiveSplitButtonSize.small,
            suffix: '-${style.name}',
          ),
      ]),
    ),
    OracleScene(
      key: 'icon-buttons/split/open',
      size: const Size(144, 112),
      build: (context) => _column([
        for (final style in [
          ExpressiveSplitButtonKind.filled,
          ExpressiveSplitButtonKind.outlined,
        ])
          _split(
            context,
            style,
            ExpressiveSplitButtonSize.small,
            suffix: '-${style.name}',
            checked: true,
          ),
      ]),
    ),
    OracleScene(
      key: 'icon-buttons/split/pressed',
      size: const Size(136, 56),
      interaction: const OraclePress('leading'),
      build: (context) => _split(
        context,
        ExpressiveSplitButtonKind.filled,
        ExpressiveSplitButtonSize.small,
      ),
    ),
    OracleScene(
      key: 'icon-buttons/split/disabled',
      size: const Size(136, 56),
      build: (context) => _split(
        context,
        ExpressiveSplitButtonKind.filled,
        ExpressiveSplitButtonSize.small,
        enabled: false,
      ),
    ),
  ],
);

void main() => runOracleGroup(iconButtonsScenes);
