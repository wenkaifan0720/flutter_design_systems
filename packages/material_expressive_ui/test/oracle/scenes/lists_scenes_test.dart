/// The `lists` oracle group (Compose twin: `ListsScenes.kt`): the list item
/// in one, two and three lines with leading and trailing slots, a
/// segmented group of three with its middle item selected, selected,
/// checked and disabled items, a pressed item's corner morph, and dividers
/// full and inset (CONTRACT §7 "lists standard/segmented × 1–3 lines ×
/// slots × selected").
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';
import 'selection_scenes_test.dart' show VisualTag;

void _none() {}

void _ignore(bool _) {}

/// Leading content both sides use: an empty 24 dp box, tagged (the oracle
/// carries no icon font; the box has an icon's geometry); tagged [tag], once
/// per scene, when given.
Widget _lead([String? tag]) => tag == null
    ? const SizedBox.square(dimension: 24)
    : OracleTag(tag, child: const SizedBox.square(dimension: 24));

/// A 360 dp column, as the oracle lays its items out.
Widget _column(List<Widget> children, {double spacing = 0}) => SizedBox(
  width: 360,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: spacing,
    children: children,
  ),
);

/// Compose's `segmentedShapes(index, 3)` base shape, and the selected shape.
ExpressiveCornerBorder _segmentShape(BuildContext context, int index) {
  final s = context.expressiveTheme.shapes;
  final outer = s.large;
  final inner = s.extraSmall;
  if (index == 1) return outer;
  final first = index == 0;
  return ExpressiveCornerBorder(
    topStart: first ? outer.topStart : inner.topStart,
    topEnd: first ? outer.topEnd : inner.topEnd,
    bottomEnd: first ? inner.bottomEnd : outer.bottomEnd,
    bottomStart: first ? inner.bottomStart : outer.bottomStart,
  );
}

final OracleGroup listsScenes = OracleGroup(
  id: 'lists',
  frame: (context, scene) => ExpressiveHost(
    light: context.expressiveTheme,
    dark: context.expressiveTheme,
    brightness: context.expressiveTheme.brightness,
    child: scene,
  ),
  scenes: [
    OracleScene(
      key: 'lists/lines',
      size: const Size(392, 248),
      build: (context) => _column([
        OracleTag(
          'one',
          child: ExpressiveListTile(
            title: const OracleTag('one-headline', child: Text('Wi-Fi')),
            leading: _lead('one-lead'),
            trailing: const Text('9:41'),
            onTap: _none,
          ),
        ),
        OracleTag(
          'two',
          child: ExpressiveListTile(
            title: const OracleTag('two-headline', child: Text('Maya Okafor')),
            subtitle: const OracleTag(
              'two-supporting',
              child: Text('Sent the itinerary'),
            ),
            leading: _lead(),
            onTap: _none,
          ),
        ),
        OracleTag(
          'three',
          child: ExpressiveListTile(
            overline: const OracleTag('three-overline', child: Text('Recipe')),
            title: const OracleTag(
              'three-headline',
              child: Text('Charred corn'),
            ),
            subtitle: const Text('Lime and mint'),
            leading: _lead(),
            onTap: _none,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'lists/segmented',
      size: const Size(392, 200),
      build: (context) => SizedBox(
        width: 360,
        child: ExpressiveListSection(
          containerColor: context.expressiveTheme.colors.surfaceContainer,
          children: [
            for (final (i, label, tag) in [
              (0, 'Standard', 'first'),
              (1, 'Express', 'middle'),
              (2, 'Pick up', 'last'),
            ])
              OracleTag(
                tag,
                shape: _segmentShape(context, i),
                child: ExpressiveListTile.selectable(
                  title: Text(label),
                  leading: _lead(),
                  selected: i == 1,
                  onTap: _none,
                ),
              ),
          ],
        ),
      ),
    ),
    OracleScene(
      key: 'lists/states',
      size: const Size(392, 200),
      build: (context) => _column([
        OracleTag(
          'selected',
          child: ExpressiveListTile.selectable(
            title: const Text('Selected'),
            leading: _lead(),
            selected: true,
            onTap: _none,
          ),
        ),
        OracleTag(
          'checked',
          child: ExpressiveListTile.toggleable(
            title: const Text('Checked'),
            leading: _lead(),
            value: true,
            onChanged: _ignore,
          ),
        ),
        OracleTag(
          'disabled',
          child: ExpressiveListTile(
            title: const Text('Disabled'),
            leading: _lead(),
            enabled: false,
            onTap: _none,
          ),
        ),
      ]),
    ),
    OracleScene(
      key: 'lists/pressed',
      size: const Size(392, 88),
      interaction: const OraclePress('item'),
      build: (context) => SizedBox(
        width: 360,
        child: OracleTag(
          'item',
          shape: context.expressiveTheme.shapes.large,
          child: ExpressiveListTile(
            title: const Text('Wi-Fi'),
            leading: _lead(),
            onTap: _none,
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'lists/dividers',
      size: const Size(392, 64),
      build: (context) => _column(spacing: 16, const [
        VisualTag('full', child: ExpressiveDivider()),
        VisualTag(
          'inset',
          child: ExpressiveDivider(inset: ExpressiveDividerInset.start),
        ),
      ]),
    ),
  ],
);

void main() => runOracleGroup(listsScenes);
