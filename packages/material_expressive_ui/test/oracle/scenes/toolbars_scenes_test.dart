/// The `toolbars` oracle group (Compose twin: `ToolbarsScenes.kt`):
/// floating toolbars standard and vibrant, leading and trailing content
/// expanded and collapsed, the toolbar beside its FAB (expanded, collapsed,
/// vibrant at the start, and the fold as motion), vertical toolbars and the
/// docked toolbar spread and fixed. Actions are standard icon buttons in
/// their 48dp touch targets with blank glyphs (the oracle ships no Material
/// Symbols font), measured at their 40dp containers as the twin's testTag
/// reports them.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'package:material_expressive_ui/src/material_expressive/internal/tokens/fab_baseline_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/floating_toolbar_tokens.g.dart';

import '../harness/oracle.dart';

/// A glyph that draws nothing, the twin's empty icon box.
const IconData _blank = IconData(
  0x20,
  fontFamily: ExpressiveSymbolsFont.family,
);

void _noop() {}

/// A standard icon button, tagged [tag] when given.
Widget _action([String? tag]) {
  const button = ExpressiveIconButton(_blank, onPressed: _noop);
  return tag == null ? button : OracleTag(tag, drawn: true, child: button);
}

List<Widget> _actions(int n, {bool tagged = false}) => <Widget>[
  for (var i = 0; i < n; i++) _action(tagged ? 'a$i' : null),
];

ShapeBorder _toolbarShape(BuildContext context) =>
    context.expressiveTheme.shapes.of(FloatingToolbarTokens.containerShape);

Widget _fab(
  BuildContext context, {
  ExpressiveToolbarKind kind = ExpressiveToolbarKind.standard,
}) => OracleTag(
  'fab',
  shape: context.expressiveTheme.shapes.of(FabBaselineTokens.containerShape),
  child: ExpressiveToolbarFab(
    icon: _blank,
    semanticLabel: 'New',
    kind: kind,
    onPressed: _noop,
  ),
);

/// The toolbar's container: the surface inside the toolbar, which the
/// twin's `testTag` (its first modifier) measures.
Widget _floating(
  BuildContext context, {
  required ExpressiveFloatingToolbar Function() build,
}) => OracleTag('toolbar', shape: _toolbarShape(context), child: build());

Widget _withFab(
  BuildContext context, {
  required bool expanded,
  bool vibrant = false,
  bool start = false,
}) {
  final kind = vibrant
      ? ExpressiveToolbarKind.vibrant
      : ExpressiveToolbarKind.standard;
  return OracleTag(
    'container',
    child: ExpressiveFloatingToolbar(
      expanded: expanded,
      kind: kind,
      fabPosition: start
          ? ExpressiveToolbarFabPosition.start
          : ExpressiveToolbarFabPosition.end,
      floatingActionButton: _fab(context, kind: kind),
      children: _actions(3),
    ),
  );
}

Widget _docked({required int count, required bool fixed}) => OracleTag(
  'toolbar',
  child: ExpressiveDockedToolbar(
    safeArea: false,
    kind: fixed
        ? ExpressiveToolbarKind.vibrant
        : ExpressiveToolbarKind.standard,
    arrangement: fixed
        ? ExpressiveDockedToolbarArrangement.fixed
        : ExpressiveDockedToolbarArrangement.spaceBetween,
    children: _actions(count, tagged: true),
  ),
);

/// Flips its value after the first frame, as the twin's `LaunchedEffect`.
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

final OracleGroup toolbarsScenes = OracleGroup(
  id: 'toolbars',
  // The icon buttons and the FAB are pressables: they need the host's ink
  // and ambient colours above them.
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return ExpressiveHost(
      light: theme,
      dark: theme,
      brightness: theme.brightness,
      child: scene,
    );
  },
  scenes: [
    for (final kind in ExpressiveToolbarKind.values)
      OracleScene(
        key: 'toolbars/floating/${kind.name}',
        size: const Size(208, 96),
        build: (context) => _floating(
          context,
          build: () => ExpressiveFloatingToolbar(
            kind: kind,
            children: _actions(3, tagged: true),
          ),
        ),
      ),
    for (final expanded in [true, false])
      OracleScene(
        key: 'toolbars/floating/${expanded ? 'expanded' : 'collapsed'}',
        size: const Size(256, 96),
        build: (context) => _floating(
          context,
          build: () => ExpressiveFloatingToolbar(
            expanded: expanded,
            leading: <Widget>[_action()],
            trailing: <Widget>[_action()],
            children: _actions(2),
          ),
        ),
      ),
    for (final expanded in [true, false])
      OracleScene(
        key: 'toolbars/fab/${expanded ? 'expanded' : 'collapsed'}',
        size: const Size(256, 112),
        build: (context) => _withFab(context, expanded: expanded),
      ),
    OracleScene(
      key: 'toolbars/fab/vibrant-start',
      size: const Size(256, 112),
      build: (context) =>
          _withFab(context, expanded: true, vibrant: true, start: true),
    ),
    OracleScene(
      key: 'toolbars/vertical',
      size: const Size(208, 256),
      // Top-aligned, as the twin's `Row`.
      build: (context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: <Widget>[
          _floating(
            context,
            build: () => ExpressiveFloatingToolbar(
              axis: Axis.vertical,
              children: _actions(3),
            ),
          ),
          OracleTag(
            'container',
            child: ExpressiveFloatingToolbar(
              axis: Axis.vertical,
              floatingActionButton: _fab(context),
              children: _actions(3),
            ),
          ),
        ],
      ),
    ),
    OracleScene(
      key: 'toolbars/docked',
      size: const Size(360, 96),
      build: (context) => _docked(count: 4, fixed: false),
    ),
    OracleScene(
      key: 'toolbars/docked/fixed-vibrant',
      size: const Size(360, 96),
      build: (context) => _docked(count: 3, fixed: true),
    ),
    OracleScene(
      key: 'toolbars/fab/collapse',
      size: const Size(256, 112),
      motion: const OracleMotion(tags: ['container', 'fab'], images: true),
      build: (context) => _AfterFirstFrame(
        from: true,
        builder: (expanded) => _withFab(context, expanded: expanded),
      ),
    ),
  ],
);

void main() => runOracleGroup(toolbarsScenes);
