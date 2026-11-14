/// The `fab` oracle group (Compose twin: `FabScenes.kt`): the FAB's sizes
/// and colour styles, the extended FAB open and folded, the FAB menu open
/// with 2 and 5 items, and the motion rows FAB ↔ menu (the medium toggle
/// opening a 3-item menu) and the extended FAB folding.
///
/// The icon slots hold a blank glyph of the icon's size: the oracle app
/// bundles no Material Symbols, so its twin holds a blank box of that size.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

/// A glyph that draws nothing: the icon's box without its ink.
const IconData _blank = IconData(
  0x20,
  fontFamily: ExpressiveSymbolsFont.family,
);

/// The menu's item labels, top to bottom (as `FabScenes.LABELS`).
const List<String> _labels = [
  'Photo',
  'Voice note',
  'Checklist',
  'Note',
  'Event',
];

void _none() {}

Widget _sizes(BuildContext context) {
  final shapes = context.expressiveTheme.shapes;
  // Top-aligned, as Compose's `Row` places its children by default.
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: ExpressiveSpacing.s16,
    children: [
      OracleTag(
        'fab-standard',
        shape: shapes.large,
        child: const ExpressiveFloatingActionButton(
          icon: _blank,
          onPressed: _none,
        ),
      ),
      OracleTag(
        'fab-medium',
        shape: shapes.largeIncreased,
        child: const ExpressiveFloatingActionButton(
          icon: _blank,
          size: ExpressiveFabSize.medium,
          onPressed: _none,
        ),
      ),
      OracleTag(
        'fab-large',
        shape: shapes.extraLarge,
        child: const ExpressiveFloatingActionButton(
          icon: _blank,
          size: ExpressiveFabSize.large,
          onPressed: _none,
        ),
      ),
    ],
  );
}

Widget _colors(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: ExpressiveSpacing.s16,
  children: [
    for (final row in const [
      [
        ('primary-container', ExpressiveFabColor.primaryContainer),
        ('secondary-container', ExpressiveFabColor.secondaryContainer),
        ('tertiary-container', ExpressiveFabColor.tertiaryContainer),
      ],
      [
        ('primary', ExpressiveFabColor.primary),
        ('secondary', ExpressiveFabColor.secondary),
        ('tertiary', ExpressiveFabColor.tertiary),
      ],
    ])
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: ExpressiveSpacing.s16,
        children: [
          for (final (name, color) in row)
            OracleTag(
              'fab-$name',
              child: ExpressiveFloatingActionButton(
                icon: _blank,
                color: color,
                onPressed: _none,
              ),
            ),
        ],
      ),
  ],
);

Widget _extended({required bool expanded}) {
  final children = [
    for (final (tag, size) in const [
      ('ext-small', ExpressiveFabSize.standard),
      ('ext-medium', ExpressiveFabSize.medium),
      ('ext-large', ExpressiveFabSize.large),
    ])
      OracleTag(
        tag,
        child: ExpressiveFloatingActionButton.extended(
          icon: _blank,
          label: 'Compose',
          size: size,
          expanded: expanded,
          onPressed: _none,
        ),
      ),
  ];
  return expanded
      ? Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ExpressiveSpacing.s16,
          children: children,
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ExpressiveSpacing.s16,
          children: children,
        );
}

Widget _menu(
  int count, {
  bool? expanded,
  bool initiallyExpanded = false,
  ExpressiveFabSize size = ExpressiveFabSize.standard,
}) => ExpressiveHeroMoment(
  child: ExpressiveFabMenu(
    icon: _blank,
    closeIcon: _blank,
    size: size,
    expanded: expanded,
    initiallyExpanded: initiallyExpanded,
    items: [
      for (final label in _labels.take(count))
        ExpressiveFabMenuItem(icon: _blank, label: label, onPressed: (_) {}),
    ],
  ),
);

/// Starts the value at [from] and flips it the way the oracle's
/// `LaunchedEffect` does, then builds with it.
///
/// The oracle flips its state after the first frame, recomposes on the
/// second, and its transition (`updateTransition`, `animate*AsState`)
/// starts its clock on the third: a Compose animation driven by a state
/// change takes the frame after the recomposition as its start. A Flutter
/// spring started from a rebuild counts that rebuild's frame instead, so
/// the twin flips one frame later (after the second frame): both springs
/// then start their clocks on the same frame and the scene measures them,
/// not the two frameworks' scheduling.
class _AfterFirstFrame extends StatefulWidget {
  const _AfterFirstFrame({required this.from, required this.builder});

  final bool from;
  final Widget Function(bool value) builder;

  @override
  State<_AfterFirstFrame> createState() => _AfterFirstFrameState();
}

class _AfterFirstFrameState extends State<_AfterFirstFrame> {
  late bool _value = widget.from;

  @override
  void initState() {
    super.initState();
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      binding.addPostFrameCallback((_) {
        if (mounted) setState(() => _value = !widget.from);
      });
      // The second frame draws although nothing on it changed, as the
      // oracle's does.
      binding.scheduleFrame();
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(_value);
}

final OracleGroup fabScenes = OracleGroup(
  id: 'fab',
  // The FABs are pressables: they need the host's ink above them. The
  // menu's toggle, items and item labels are tagged as the oracle tags them.
  frame: (context, scene) {
    ExpressiveFabMenu.debugPartWrapper ??= (part, child) =>
        OracleTag(part, child: child);
    return ExpressiveHost(
      light: context.expressiveTheme,
      dark: context.expressiveTheme,
      brightness: context.expressiveTheme.brightness,
      child: scene,
    );
  },
  scenes: [
    OracleScene(key: 'fab/sizes', size: const Size(296, 128), build: _sizes),
    OracleScene(key: 'fab/colors', size: const Size(232, 160), build: _colors),
    OracleScene(
      key: 'fab/extended',
      size: const Size(264, 296),
      build: (context) => _extended(expanded: true),
    ),
    OracleScene(
      key: 'fab/extended/collapsed',
      size: const Size(296, 128),
      build: (context) => _extended(expanded: false),
    ),
    OracleScene(
      key: 'fab/menu/2',
      size: const Size(232, 200),
      build: (context) => _menu(2, initiallyExpanded: true),
    ),
    OracleScene(
      key: 'fab/menu/5',
      size: const Size(232, 376),
      build: (context) => _menu(5, initiallyExpanded: true),
    ),
    OracleScene(
      key: 'fab/menu/open',
      size: const Size(264, 280),
      // The toggle's bounds per frame; the item stagger is held by the
      // frames' pixels (a hidden item has no node to measure).
      motion: const OracleMotion(tags: ['toggle'], frames: 60, images: true),
      build: (context) => _AfterFirstFrame(
        from: false,
        builder: (open) =>
            _menu(3, expanded: open, size: ExpressiveFabSize.medium),
      ),
    ),
    OracleScene(
      key: 'fab/extended/collapse',
      size: const Size(200, 96),
      motion: const OracleMotion(tags: ['container'], frames: 60),
      build: (context) => _AfterFirstFrame(
        from: true,
        builder: (expanded) => OracleTag(
          'container',
          child: ExpressiveFloatingActionButton.extended(
            icon: _blank,
            label: 'Compose',
            expanded: expanded,
            onPressed: _none,
          ),
        ),
      ),
    ),
  ],
);

void main() => runOracleGroup(fabScenes);
