// A pointer over a part changes nothing it paints (polish3 §1). For every pressable, field and slider on every live
// page, in every corner family, the pixels around the part are the same with the pointer away and with it over the
// part, and the pointer shows the right cursor: the hand on what presses, the I-beam on a field, the open hand on a
// slider, the arrow on whatever is disabled. The look's exceptions are left out: an open menu's or an autocomplete's
// active row (it follows the pointer), a tooltip, a chart's readout and the rating's preview of the stars it would set.
// Reduce Motion is on, so a hover change would show at once and a spinner stands still between the two pictures.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';
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

Future<Uint8List> _pixels(WidgetTester tester, Rect rect) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final layer = boundary.debugLayer! as OffsetLayer;
  final local = rect.shift(-boundary.localToGlobal(Offset.zero));
  final bytes = await tester.runAsync(() async {
    final image = await layer.toImage(local, pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  return bytes!;
}

int _differing(Uint8List a, Uint8List b) {
  if (a.length != b.length) return -1;
  var n = 0;
  for (var i = 0; i < a.length; i += 4) {
    if (a[i] != b[i] ||
        a[i + 1] != b[i + 1] ||
        a[i + 2] != b[i + 2] ||
        a[i + 3] != b[i + 3]) {
      n++;
    }
  }
  return n;
}

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
        List<Color?> fills() => [
          for (final e
              in find
                  .descendant(
                    of: find.byKey(const ValueKey('field')),
                    matching: find.byType(DecoratedBox),
                  )
                  .evaluate())
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
    final custom = GalleryCustom(corners: corners);
    for (final page in livePages) {
      testWidgets(
        '${corners.name}: a pointer over ${page.id} changes nothing',
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
            final region = rect.inflate(8);
            await mouse.moveTo(park);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            final idle = await _pixels(tester, region);
            await mouse.moveTo(rect.center);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            if (!element.mounted) continue;
            final hovered = await _pixels(tester, region);
            final changed = _differing(idle, hovered);
            if (changed != 0) {
              failures.add('$where: $changed pixels change under the pointer');
            }
            final cursor = RendererBinding.instance.mouseTracker
                .debugDeviceActiveCursor(1);
            final want = _expected(element, kind);
            // A part whose centre another pressable covers shows that one's cursor; only check uncovered parts.
            final top = tester
                .hitTestOnBinding(rect.center)
                .path
                .map((entry) => entry.target)
                .whereType<RenderBox>()
                .firstOrNull;
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
