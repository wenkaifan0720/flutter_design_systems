// The mouse cursor over everything that takes a tap or a drag (0.1.1): the click cursor over a live control, as
// Material's widgets show it, the text cursor over a field, and a disabled control defers to what is around it.
//
// The sliders are held part by part, over the track well away from the handle (0.1.0 showed the click cursor on the
// handle alone). Then every gallery page is hovered at 1440 wide, node by node: each live node that takes a tap, a long
// press or a step (a slider), and each field, shows its cursor. Set EXPRESSIVE_CURSOR_SWEEP_OUT to a file to list
// every node the sweep hovered.
import 'dart:io';
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show InkResponse, MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'gallery_support.dart';

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ExpressiveHost(
    light: ExpressiveThemeData.preset('baseline', Brightness.light),
    brightness: Brightness.light,
    // A help cursor around the part: a part that defers shows it.
    child: MouseRegion(
      cursor: SystemMouseCursors.help,
      child: Center(child: SizedBox(width: 320, height: 320, child: child)),
    ),
  ),
);

/// A mouse at the top left corner, gone when the test ends.
Future<TestGesture> _mouse(WidgetTester tester) async {
  final mouse = await tester.createGesture(
    kind: PointerDeviceKind.mouse,
    pointer: 1,
  );
  await mouse.addPointer(location: Offset.zero);
  addTearDown(mouse.removePointer);
  return mouse;
}

/// The cursor [mouse] shows at [at].
Future<MouseCursor?> _cursorAt(
  WidgetTester tester,
  TestGesture mouse,
  Offset at,
) async {
  await mouse.moveTo(at);
  await tester.pump();
  return RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1);
}

/// The point [fraction] along [rect]'s long side, through its middle.
Offset _along(Rect rect, double fraction, {bool vertical = false}) => vertical
    ? Offset(rect.center.dx, rect.top + rect.height * fraction)
    : Offset(rect.left + rect.width * fraction, rect.center.dy);

const _sweepWidth = 1440.0;

final _swept = <String>[];

void main() {
  group('sliders: the click cursor over the whole slider', () {
    final parts = <(String, Widget Function(bool live), bool)>[
      (
        'ExpressiveSlider',
        (live) => Center(
          child: ExpressiveSlider(
            value: 0.1,
            semanticLabel: 'Volume',
            onChanged: live ? (_) {} : null,
          ),
        ),
        false,
      ),
      (
        'ExpressiveRangeSlider',
        (live) => Center(
          child: ExpressiveRangeSlider(
            start: 0.1,
            end: 0.3,
            onChanged: live ? (_, _) {} : null,
          ),
        ),
        false,
      ),
      (
        'ExpressiveVerticalSlider',
        (live) => Center(
          child: ExpressiveVerticalSlider(
            value: 0.1,
            semanticLabel: 'Volume',
            onChanged: live ? (_) {} : null,
          ),
        ),
        true,
      ),
    ];
    for (final (name, build, vertical) in parts) {
      Finder slider(WidgetTester tester) =>
          find.byWidgetPredicate((w) => w.runtimeType.toString() == name);

      testWidgets('$name: click over the track when live', (tester) async {
        await tester.pumpWidget(_host(build(true)));
        final mouse = await _mouse(tester);
        final rect = tester.getRect(slider(tester));
        // The handle sits low (0.1, and 0.3 for a range's end): the track's
        // far end is bare track. A vertical slider fills from the bottom.
        expect(
          await _cursorAt(
            tester,
            mouse,
            _along(rect, vertical ? 0.15 : 0.85, vertical: vertical),
          ),
          SystemMouseCursors.click,
          reason: '$name: the track',
        );
        expect(
          await _cursorAt(
            tester,
            mouse,
            _along(rect, vertical ? 0.9 : 0.1, vertical: vertical),
          ),
          SystemMouseCursors.click,
          reason: '$name: the handle',
        );
      });

      testWidgets('$name: defers when off', (tester) async {
        await tester.pumpWidget(_host(build(false)));
        final region = tester.widget<MouseRegion>(
          find
              .descendant(
                of: slider(tester),
                matching: find.byType(MouseRegion),
              )
              .first,
        );
        expect(region.cursor, MouseCursor.defer, reason: '$name: its frame');
        final rect = tester.getRect(slider(tester));
        final mouse = await _mouse(tester);
        expect(
          await _cursorAt(
            tester,
            mouse,
            _along(rect, vertical ? 0.15 : 0.85, vertical: vertical),
          ),
          SystemMouseCursors.help,
          reason: '$name: the cursor around it shows through',
        );
      });
    }
  });

  group('every gallery page at 1440: each live control shows its cursor', () {
    setUpAll(loadExpressiveFonts);
    tearDownAll(() {
      final out = Platform.environment['EXPRESSIVE_CURSOR_SWEEP_OUT'];
      if (out != null) File(out).writeAsStringSync('${_swept.join('\n')}\n');
    });
    for (final page in galleryPages) {
      testWidgets(page.id, (tester) async {
        final semantics = tester.ensureSemantics();
        await pumpGalleryPage(
          tester,
          page,
          'baseline',
          Brightness.light,
          width: _sweepWidth,
        );
        final view = Offset.zero & tester.view.physicalSize;
        final root = tester
            .binding
            .renderViews
            .first
            .owner!
            .semanticsOwner!
            .rootSemanticsNode!;
        final wrong = <String>[];
        final mouse = await _mouse(tester);
        for (final (node, rect) in _placed(root, Matrix4.identity()).toList()) {
          final d = node.getSemanticsData();
          final wanted = _wanted(d);
          if (wanted == null || rect.shortestSide < 4) continue;
          final at = rect.center;
          if (!view.contains(at)) continue;
          await _cursorAt(tester, mouse, at);
          final shown = _onTheWeb(tester, at);
          final what = '${page.id} | ${_role(d)} | ${_name(d)}';
          _swept.add('$what | $shown');
          // A node's centre that no gesture or text entry answers (a form
          // field's merged node, label to help text) is not where a click
          // acts: the arrow is right there.
          if (!wanted.allows(shown) && !_acts(tester, at)) {
            _swept.add('DEAD $what | $shown');
            continue;
          }
          if (!wanted.allows(shown)) {
            final why =
                '$what: $shown, wanted $wanted '
                '(${_regionAt(tester, at)})';
            wrong.add(why);
            _swept.add('WRONG $why');
          }
        }
        expect(wrong, isEmpty, reason: wrong.join('\n'));
        semantics.dispose();
      });
    }
  });
}

/// The cursors a live node may show: null for a node the pointer does not act on.
_Wanted? _wanted(SemanticsData d) {
  final f = d.flagsCollection;
  if (f.isEnabled == Tristate.isFalse || f.isHidden) return null;
  if (f.isTextField) return _Wanted.field;
  final acts =
      d.hasAction(SemanticsAction.tap) ||
      d.hasAction(SemanticsAction.longPress) ||
      d.hasAction(SemanticsAction.increase) ||
      d.hasAction(SemanticsAction.decrease);
  return acts ? _Wanted.notTheArrow : null;
}

/// What a live node's cursor must be.
enum _Wanted {
  /// A field: the text cursor, or the click cursor over a read-only one that opens something (a select's, a date's).
  field,

  /// Anything else that acts: not the arrow. The click cursor mostly; a drag handle's grab, a pane divider's and a
  /// colour strip's resize, a colour area's crosshair say it as well.
  notTheArrow;

  bool allows(MouseCursor? cursor) => switch (this) {
    field =>
      cursor == SystemMouseCursors.text || cursor == SystemMouseCursors.click,
    notTheArrow =>
      cursor != null &&
          cursor != SystemMouseCursors.basic &&
          cursor != MouseCursor.defer &&
          cursor != MouseCursor.uncontrolled &&
          cursor != SystemMouseCursors.none &&
          cursor != SystemMouseCursors.forbidden,
  };

  @override
  String toString() => switch (this) {
    field => 'text or click',
    notTheArrow => 'not the arrow',
  };
}

String _role(SemanticsData d) {
  final f = d.flagsCollection;
  if (f.isTextField) return 'field';
  if (d.hasAction(SemanticsAction.increase) ||
      d.hasAction(SemanticsAction.decrease)) {
    return 'slider';
  }
  if (f.isLink) return 'link';
  if (f.isButton) return 'button';
  if (f.isToggled != Tristate.none) return 'toggle';
  if (f.isChecked != CheckedState.none) return 'check';
  if (f.isSelected != Tristate.none) return 'selectable';
  return d.hasAction(SemanticsAction.longPress) ? 'long-press' : 'tap';
}

String _name(SemanticsData d) {
  final words = [
    d.label,
    d.value,
    d.tooltip,
  ].where((w) => w.isNotEmpty).join(' / ');
  final one = words.replaceAll('\n', ' ');
  return one.length > 60 ? '${one.substring(0, 60)}…' : one;
}

/// Every semantics node in the tree, with its rect on the screen.
Iterable<(SemanticsNode, Rect)> _placed(
  SemanticsNode node,
  Matrix4 above,
) sync* {
  final at = above.clone();
  if (node.transform != null) at.multiply(node.transform!);
  yield (node, MatrixUtils.transformRect(at, node.rect));
  final children = <SemanticsNode>[];
  node.visitChildren((child) {
    children.add(child);
    return true;
  });
  for (final child in children) {
    yield* _placed(child, at);
  }
}

/// The cursor the web gallery shows at [at]: the first mouse region under the pointer that does not defer, as the
/// mouse tracker picks it. A button's ink response asks for Flutter's adaptive clickable cursor, the click cursor on
/// the web and the platform's arrow elsewhere (tests included), as Material's own buttons do; a live one counts as
/// click here.
MouseCursor _onTheWeb(WidgetTester tester, Offset at) {
  final result = HitTestResult();
  RendererBinding.instance.hitTestInView(result, at, tester.view.viewId);
  for (final entry in result.path) {
    final target = entry.target;
    if (target is! RenderMouseRegion || target.cursor == MouseCursor.defer) {
      continue;
    }
    // A region given the adaptive cursor itself resolves it with no states: live, so click on the web.
    if (target.cursor == WidgetStateMouseCursor.adaptiveClickable) {
      return SystemMouseCursors.click;
    }
    if (target.cursor != SystemMouseCursors.basic) return target.cursor;
    final creator = target.debugCreator;
    InkResponse? ink;
    var depth = 0;
    if (creator is DebugCreator) {
      creator.element.visitAncestorElements((e) {
        if (e.widget is InkResponse) ink = e.widget as InkResponse;
        return ink == null && ++depth < 12;
      });
    }
    final live =
        ink != null &&
        ink!.mouseCursor == null &&
        (ink!.onTap != null ||
            ink!.onLongPress != null ||
            ink!.onDoubleTap != null ||
            ink!.onTapDown != null);
    return live ? SystemMouseCursors.click : target.cursor;
  }
  return SystemMouseCursors.basic;
}

/// Where the cursor at [at] comes from: the deciding mouse region's creator chain, for a failure's message.
String _regionAt(WidgetTester tester, Offset at) {
  final result = HitTestResult();
  RendererBinding.instance.hitTestInView(result, at, tester.view.viewId);
  final top = result.path.first.target;
  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderMouseRegion && target.cursor != MouseCursor.defer) {
      return 'region: ${target.debugCreator.toString().split(' ← ').take(8).join(' ← ')}';
    }
  }
  final chain = top is RenderObject
      ? top.debugCreator.toString().split(' ← ').take(8).join(' ← ')
      : '$top';
  return 'no region; top: $chain';
}

/// Whether a click at [at] reaches something that acts on it: a gesture detector with a gesture (a scroll view's own
/// aside) or a text entry.
bool _acts(WidgetTester tester, Offset at) {
  final result = HitTestResult();
  RendererBinding.instance.hitTestInView(result, at, tester.view.viewId);
  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderEditable) return true;
    if (target is! RenderPointerListener) continue;
    final chain = target.debugCreator.toString().split(' ← ').take(6).toList();
    if (chain.any((w) => w.contains('_ScrollableScope'))) continue;
    // A detector with no gestures (an ink response with no handler, such as
    // a chip's body that only its remove glyph acts for) does not act.
    final creator = target.debugCreator;
    var live = false;
    if (creator is DebugCreator) {
      creator.element.visitAncestorElements((e) {
        final w = e.widget;
        if (w is RawGestureDetector) live = w.gestures.isNotEmpty;
        return w is! RawGestureDetector;
      });
    }
    if (live) return true;
  }
  return false;
}
