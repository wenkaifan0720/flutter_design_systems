// A pointer over a part lays its Ben-Day dots on it and changes nothing else (0.2.0, the second signature move; 0.1.0
// showed nothing, polish3 §1). For every pressable, field and slider on every live page, in every corner family: a
// press that takes presses changes its own face under the pointer and not one pixel more than a hairline beyond its
// box (a grouped row's rules stand aside at its edge); a disabled or busy press, a field and a slider change nothing;
// and the pointer shows the right cursor: the hand on what presses, the I-beam on a field, the open hand on a slider,
// the arrow on whatever is disabled. A press inside one that lights as a whole (a table's row round its pick box) may
// light that one with it, the pointer being over both; a press the pointer can't reach at its middle (a switch row's
// own switch, a carousel's card beside the current one) is the press over it's to light, and is left out. The look's
// exceptions are left out too: an open menu's or an autocomplete's active row (it follows the pointer), a tooltip, a
// chart's readout and the rating's preview of the stars it would set.
// Reduce Motion is on, so a hover change shows at once and a spinner stands still between the two pictures.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/raised.dart' show ComicRaisedFrame;

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/live_pages.dart';
import 'gallery_support.dart';
import 'support.dart';

const _shot = ValueKey('hover/shot');

/// Whether [e] sits inside one of the look's hover exceptions.
bool _excepted(Element e) {
  var out = false;
  bool check(Widget w) =>
      w is ComicTooltip ||
      w is ComicRating ||
      w is ComicMenu ||
      // Its rows light as a menu's: the pointer moves the active row, as the keys do.
      w is ComicActionSheet ||
      w is ComicChart ||
      w.runtimeType.toString().startsWith('_AutocompleteList');
  if (check(e.widget)) return true;
  e.visitAncestorElements((a) {
    if (check(a.widget)) out = true;
    return !out;
  });
  return out;
}

T? _above<T extends Widget>(Element e) => e.findAncestorWidgetOfExactType<T>();

/// The cursor a person should see over [e]'s part.
MouseCursor _expected(Element e, String kind) {
  switch (kind) {
    case 'slider':
      return (e.widget as ComicSlider).onChanged == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.grab;
    case 'field':
      final enabled =
          _above<ComicTextField>(e)?.enabled ??
          _above<ComicSearchField>(e)?.enabled ??
          _above<ComicTextArea>(e)?.enabled ??
          true;
      return enabled ? SystemMouseCursors.text : SystemMouseCursors.basic;
    default:
      final press = e.widget as ComicPressable;
      return press.mouseCursor ??
          (press.onPressed != null && !press.busy
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic);
  }
}

/// The picture of [rect] at one pixel a point, and its width in pixels.
Future<(Uint8List, int)> _pixels(WidgetTester tester, Rect rect) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final layer = boundary.debugLayer! as OffsetLayer;
  final local = rect.shift(-boundary.localToGlobal(Offset.zero));
  final bytes = await tester.runAsync(() async {
    final image = await layer.toImage(local, pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (data!.buffer.asUint8List(), width);
  });
  return bytes!;
}

/// The pixels that differ between [a] and [b], pictures [width] wide: within [inner] and outside it.
(int, int) _differing(Uint8List a, Uint8List b, int width, Rect inner) {
  if (a.length != b.length) return (-1, -1);
  var (inside, outside) = (0, 0);
  for (var i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      final p = i ~/ 4;
      if (inner.contains(Offset((p % width) + .5, (p ~/ width) + .5))) {
        inside++;
      } else {
        outside++;
      }
    }
  }
  return (inside, outside);
}

/// How far past a part's box its hover may reach: a grouped row's rules standing aside at its edge.
const _hairline = 3.0;

void main() {
  setUpAll(() async {
    await loadComicFonts();
    await loadBundledFonts();
  });

  // Focus is the caret and the look's focus edge, never a tint behind the words (polish3, 12:30): every field's
  // fills are the same focused as not, by day and by night.
  for (final mode in Brightness.values) {
    testWidgets('a focused field keeps its own fill, ${mode.name}', (
      tester,
    ) async {
      final fields = <String, Widget>{
        'text field': const ComicTextField(label: 'Name', initialValue: 'Alex'),
        'search field': const ComicSearchField(hint: 'Search'),
        'text area': const ComicTextArea(label: 'Notes'),
        'code field': const ComicInputOtp(label: 'Code'),
        'plain input': const ComicInput(hint: 'Your name'),
        'reply': const ComicTextField(hint: 'A reply', onPaper: true),
        'autocomplete': const ComicCombobox<String>(
          label: 'City',
          options: ['Lisbon', 'London'],
        ),
      };
      for (final MapEntry(key: name, value: field) in fields.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: ComicTheme(
              data: ComicThemeData.offset(mode),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 320,
                  child: KeyedSubtree(
                    key: const ValueKey('field'),
                    child: field,
                  ),
                ),
              ),
            ),
          ),
        );
        // The field's own fills: an autocomplete's list, which opens as its field takes the focus, has its own.
        List<Color?> fills() => [
          for (final e
              in find
                  .descendant(
                    of: find.byKey(const ValueKey('field')),
                    matching: find.byType(DecoratedBox),
                  )
                  .evaluate()
                  .toSet()
                  .difference(
                    find
                        .descendant(
                          of: find.byType(ComicRaisedFrame),
                          matching: find.byType(DecoratedBox),
                        )
                        .evaluate()
                        .toSet(),
                  ))
            if ((e.widget as DecoratedBox).decoration
                case final ShapeDecoration d)
              d.color
            else if ((e.widget as DecoratedBox).decoration
                case final BoxDecoration d)
              d.color,
        ];
        final idle = fills();
        final node = tester
            .state<EditableTextState>(find.byType(EditableText).first)
            .widget
            .focusNode;
        node.requestFocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(node.hasFocus, isTrue, reason: '$name took no focus');
        expect(fills(), idle, reason: '$name: a fill changed under focus');
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final corners in GalleryCorners.values) {
    final custom = CornerCustom(corners: corners);
    for (final page in livePages) {
      testWidgets(
        '${corners.name}: a pointer over ${page.id} lays dots on what it presses and nothing else',
        (tester) async {
          kitShownTheme = (b) => custom.theme('offset', b);
          addTearDown(() => kitShownTheme = null);
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(
            tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
          );
          await pumpGalleryPage(
            tester,
            (
              id: page.id,
              title: page.title,
              build: (brightness) => RepaintBoundary(
                key: _shot,
                child: kitScreen(
                  brightness: brightness,
                  title: page.title,
                  sections: page.sections(),
                ),
              ),
            ),
            'offset',
            Brightness.light,
            width: 1024,
          );
          final targets = <(Element, String)>[
            for (final e in find.byType(ComicPressable).evaluate())
              (e, 'press'),
            for (final e in find.byType(ComicSlider).evaluate()) (e, 'slider'),
            for (final e in find.byType(EditableText).evaluate()) (e, 'field'),
          ];
          const park = Offset(1, 1);
          final mouse = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await mouse.addPointer(location: park);
          addTearDown(mouse.removePointer);
          final view = tester.view.physicalSize / tester.view.devicePixelRatio;
          final failures = <String>[];
          var checked = 0;
          for (final (element, kind) in targets) {
            if (!element.mounted || _excepted(element)) continue;
            final box = element.renderObject;
            if (box is! RenderBox || !box.hasSize || !box.attached) continue;
            final rect = box.localToGlobal(Offset.zero) & box.size;
            if (rect.isEmpty ||
                rect.left < 0 ||
                rect.top < 0 ||
                rect.right > view.width ||
                rect.bottom > view.height) {
              continue;
            }
            final name = switch (kind) {
              'press' => (element.widget as ComicPressable).label ?? 'a press',
              'slider' => 'slider',
              _ => 'field',
            };
            final where = '$kind "$name" at ${rect.topLeft}';
            // What the pointer reaches at the part's middle: a press it can't reach is the one over it's to light.
            final hit = tester
                .hitTestOnBinding(rect.center)
                .path
                .map((entry) => entry.target)
                .whereType<RenderBox>()
                .toList();
            final reached = hit.any((t) => _inside(t, box));
            if (kind == 'press' && !reached) continue;
            // A press inside one that lights as a whole lights that one with it: the pointer is over both.
            var around = rect;
            element.visitAncestorElements((a) {
              if (a.widget is! ComicPressable && a.widget is! ComicHighlight) {
                return true;
              }
              final outer = a.renderObject;
              if (outer is RenderBox && outer.hasSize) {
                around = outer.localToGlobal(Offset.zero) & outer.size;
              }
              return false;
            });
            final region = around.inflate(8);
            await mouse.moveTo(park);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            final idle = await _pixels(tester, region);
            await mouse.moveTo(rect.center);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            if (!element.mounted) continue;
            final hovered = await _pixels(tester, region);
            final inner = Rect.fromLTWH(
              8 - _hairline,
              8 - _hairline,
              around.width + _hairline * 2,
              around.height + _hairline * 2,
            );
            final (inside, outside) = _differing(
              idle.$1,
              hovered.$1,
              hovered.$2,
              inner,
            );
            final live =
                kind == 'press' &&
                (element.widget as ComicPressable).onPressed != null &&
                !(element.widget as ComicPressable).busy;
            if (outside != 0) {
              failures.add('$where: $outside pixels change beyond it');
            }
            if (live && inside == 0) {
              failures.add('$where: no dots under the pointer');
            } else if (!live && inside != 0) {
              failures.add(
                '$where: $inside pixels change, and it takes no press',
              );
            }
            final cursor = RendererBinding.instance.mouseTracker
                .debugDeviceActiveCursor(1);
            final want = _expected(element, kind);
            // A part whose centre another pressable covers shows that one's cursor; only check uncovered parts.
            final top = hit.firstOrNull;
            final covered =
                top != null &&
                top != box &&
                !_inside(top, box) &&
                kind == 'press';
            if (!covered && cursor != want) {
              failures.add('$where: cursor $cursor, wanted $want');
            }
            checked++;
          }
          await mouse.moveTo(park);
          await tester.pump();
          debugPrint('hover ${corners.name}/${page.id}: $checked parts');
          expect(tester.takeException(), isNull);
          expect(failures, isEmpty, reason: failures.join('\n'));
        },
        // It compares drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
        tags: 'goldens',
      );
    }
  }
}

/// Whether [inner] is [outer] or below it in the render tree.
bool _inside(RenderObject inner, RenderObject outer) {
  RenderObject? at = inner;
  while (at != null) {
    if (identical(at, outer)) return true;
    at = at.parent;
  }
  return false;
}
