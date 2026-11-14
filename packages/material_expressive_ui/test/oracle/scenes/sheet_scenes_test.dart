/// The `sheet` oracle group (Compose twin: `SheetScenes.kt`): the bottom
/// sheet over the scrim as whole windows — a tall sheet at its partial
/// anchor, a short one at its own height, and a medium one springing from
/// its partial anchor to its expanded one (`SheetState.expand`, the show
/// spring the drag handle's tap runs), frame by frame.
///
/// Compose's `BottomSheet` places its container inside its own layout
/// node, so neither side can tag the container: the scenes tag the drag
/// handle's box (`BottomSheetDefaults.DragHandle`, the bar and its 22dp
/// above and below), and the short sheet's content under it (a sheet at
/// its partial anchor runs below the window, where the capture measures
/// nothing); the container is held by the pixels.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

/// Rows in the tall sheet: more than the window holds, so the sheet is
/// the window's height and rests at half of it.
const int sheetTallRows = 24;

/// Rows in the short sheet: shorter than half the window, so the sheet
/// rests at its own height.
const int sheetShortRows = 3;

/// Rows in the medium sheet: taller than half the window and shorter than
/// the window, so its partial and expanded anchors differ and its spring
/// stays inside the window.
const int sheetMediumRows = 12;

/// Frames the expand spring is recorded for (0.96 s).
const int sheetExpandFrames = 60;

/// One content row: a 56 dp band with a rounded block inset 16 × 8 dp,
/// in `surfaceContainerHighest`, the full width of the sheet (Compose's
/// `fillMaxWidth`).
Widget _row(BuildContext context) => SizedBox(
  width: double.infinity,
  height: 56,
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: context.expressiveTheme.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
);

/// A column of [rows] rows; a scrolling one when [scroll] (Compose's
/// `verticalScroll`), which then fills the height it is given.
Widget _content(BuildContext context, int rows, {required bool scroll}) {
  final children = [for (var i = 0; i < rows; i += 1) _row(context)];
  return scroll
      ? SingleChildScrollView(child: Column(children: children))
      : Column(mainAxisSize: MainAxisSize.min, children: children);
}

/// The window: the scrim (`BottomSheetDefaults.ScrimColor`) over the
/// surface, and [sheet] over it.
Widget _window(BuildContext context, Widget sheet) {
  final colors = context.expressiveTheme.colors;
  return Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: colors.scrim.withValues(alpha: 0.32)),
      sheet,
    ],
  );
}

const Widget _handle = OracleTag('handle', child: ExpressiveSheetDragHandle());

/// A medium sheet at its partial anchor, expanded after its first frame,
/// as the oracle's `LaunchedEffect { state.expand() }`.
class _Expanding extends StatefulWidget {
  const _Expanding();

  @override
  State<_Expanding> createState() => _ExpandingState();
}

class _ExpandingState extends State<_Expanding> {
  final ExpressiveSheetController _controller = ExpressiveSheetController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.expand();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpressiveBottomSheet(
    controller: _controller,
    initialValue: ExpressiveSheetValue.partiallyExpanded,
    dragHandle: _handle,
    child: _content(context, sheetMediumRows, scroll: false),
  );
}

final OracleGroup sheetScenes = OracleGroup(
  id: 'sheet',
  // The drag handle's ripple is Material ink under the host.
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
    OracleScene.screen(
      key: 'sheet/partial',
      build: (context) => _window(
        context,
        ExpressiveBottomSheet(
          initialValue: ExpressiveSheetValue.partiallyExpanded,
          dragHandle: _handle,
          child: _content(context, sheetTallRows, scroll: true),
        ),
      ),
    ),
    OracleScene.screen(
      key: 'sheet/expanded',
      build: (context) => _window(
        context,
        ExpressiveBottomSheet(
          initialValue: ExpressiveSheetValue.expanded,
          dragHandle: _handle,
          child: OracleTag(
            'content',
            child: _content(context, sheetShortRows, scroll: false),
          ),
        ),
      ),
    ),
    OracleScene.screen(
      key: 'sheet/expand',
      motion: const OracleMotion(tags: ['handle'], frames: sheetExpandFrames),
      build: (context) => _window(context, const _Expanding()),
    ),
  ],
);

void main() => runOracleGroup(sheetScenes);
