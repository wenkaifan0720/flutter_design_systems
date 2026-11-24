// A choice group's words stand whole in every language, at 1.0 and 2.0 text size, as a SegmentedButton's do: from 600 a
// segmented button keeps its segments at its widest word's width, and below that it shares its column, stacking its
// segments when a word won't fit. A web app draws a script its faces lack (Arabic) in a face the browser fetches after
// the first frame. The group measures its words again when that face arrives, so each segment keeps the width its
// words take in the face they are drawn in: one measured before the face came cut "منخفضة" to "منخفض".
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _arabic = ['منخفضة', 'عادية', 'عالية'];
const _english = ['Low', 'Normal', 'High'];
const _long = ['Low', 'Normal', 'Whenever there is time'];
const _wide = ['Soon', 'Whenever there is time', 'Today'];

// Each test's late face: a family of its own.
var _faces = 0;

Widget _segments(List<String> words, {RetroDesktopStyle? style}) =>
    RetroDesktopSegmentedButton<int>(
      label: 'Priority',
      segments: [
        for (final (i, w) in words.indexed) RetroDesktopButtonSegment(i, w),
      ],
      value: words.length - 1,
      onChanged: (_) {},
      style: style,
    );

Widget _radios(List<String> words) => RetroDesktopRadioGroup<int>(
  labelText: 'Priority',
  options: [for (final (i, w) in words.indexed) RetroDesktopRadio(i, w)],
  value: 0,
  onChanged: (_) {},
);

void _view(WidgetTester tester, double width) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Expects [words] whole. In a [row] its one line fits the width it was given; in a stack, laid out again at that
/// width, every line of it fits the box (nothing cut off below, nothing cut short).
void _expectWhole(WidgetTester tester, String words, {required bool row}) {
  final p = tester.renderObject<RenderParagraph>(find.text(words));
  final painter = TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textScaler: p.textScaler,
    maxLines: p.maxLines,
    ellipsis: p.overflow == TextOverflow.ellipsis ? '…' : null,
    locale: p.locale,
    strutStyle: p.strutStyle,
    textWidthBasis: p.textWidthBasis,
    textHeightBehavior: p.textHeightBehavior,
  );
  if (row) {
    painter.layout();
    expect(
      painter.width,
      lessThanOrEqualTo(p.size.width + .5),
      reason: '"$words" needs ${painter.width} on its line, has ${p.size}',
    );
  } else {
    painter.layout(maxWidth: p.size.width);
    expect(painter.didExceedMaxLines, isFalse, reason: '"$words" cut short');
    expect(
      painter.height,
      lessThanOrEqualTo(p.size.height + .5),
      reason: '"$words" needs ${painter.height} in ${p.size}',
    );
  }
  painter.dispose();
}

/// The box a group hugs its choices in (from 600).
Size _hug(WidgetTester tester, Type group) => tester.getSize(
  find.descendant(
    of: find.byType(group),
    matching: find.byType(IntrinsicWidth),
  ),
);

/// Loads [file] (under assets/fonts) under [family].
Future<void> _load(WidgetTester tester, String family, String file) =>
    tester.runAsync(
      () =>
          (FontLoader(family)..addFont(
                Future.value(
                  ByteData.sublistView(
                    File('assets/fonts/$file').readAsBytesSync(),
                  ),
                ),
              ))
              .load(),
    );

/// A face arriving late: [file] loaded under [family], drawn in a narrower face until then, as a browser draws a
/// script in what it has until it has fetched the script's face; then the system telling the app its fonts changed,
/// as the engine does.
Future<void> _arrive(WidgetTester tester, String family, String file) async {
  await _load(tester, family, file);
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.system.name,
    SystemChannels.system.codec.encodeMessage(<String, Object?>{
      'type': 'fontsChange',
    }),
    (_) {},
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  group('a face that arrives after the first frame', () {
    for (final dir in TextDirection.values) {
      testWidgets('a segmented button measures its words again, ${dir.name}', (
        tester,
      ) async {
        _view(tester, 1440);
        final late = 'Late face ${_faces++}';
        await _load(tester, late, 'Jersey15-OneFace.ttf');
        final style = RetroDesktopStyle(
          textStyle: WidgetStatePropertyAll(TextStyle(fontFamily: late)),
        );
        Widget app(Key key) => retroDesktopApp(
          Align(
            key: key,
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(width: 1000, child: _segments(_wide, style: style)),
          ),
          direction: dir,
        );
        await tester.pumpWidget(app(const ValueKey('first')));
        await tester.pumpAndSettle();
        final before = _hug(tester, RetroDesktopSegmentedButton<int>);
        await _arrive(tester, late, 'AtkinsonMono-700.ttf');
        for (final w in _wide) {
          _expectWhole(tester, w, row: true);
        }
        final after = _hug(tester, RetroDesktopSegmentedButton<int>);
        expect(
          after.width,
          greaterThan(before.width),
          reason: '$before $after',
        );
        // As wide as a group first built with the face in place.
        await tester.pumpWidget(app(const ValueKey('built after')));
        await tester.pumpAndSettle();
        expect(_hug(tester, RetroDesktopSegmentedButton<int>), after);
      });
    }

    testWidgets('a radio group measures its words again', (tester) async {
      _view(tester, 1440);
      final late = 'Late face ${_faces++}';
      await _load(tester, late, 'Jersey15-OneFace.ttf');
      Widget app(Key key) => retroDesktopApp(
        Align(
          key: key,
          alignment: AlignmentDirectional.topStart,
          child: Builder(
            builder: (context) => RetroDesktopTheme(
              data: RetroDesktopTheme.of(context)
                  .copyWith(typeface: RetroDesktopTypeface(bodyFamily: late)),
              child: SizedBox(width: 640, child: _radios(_long)),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(const ValueKey('first')));
      await tester.pumpAndSettle();
      final before = _hug(tester, RetroDesktopRadioGroup<int>);
      await _arrive(tester, late, 'AtkinsonMono-700.ttf');
      for (final w in _long) {
        _expectWhole(tester, w, row: true);
      }
      final after = _hug(tester, RetroDesktopRadioGroup<int>);
      expect(after.width, greaterThan(before.width), reason: '$before $after');
      await tester.pumpWidget(app(const ValueKey('built after')));
      await tester.pumpAndSettle();
      expect(_hug(tester, RetroDesktopRadioGroup<int>), after);
    });
  });

  group('every word whole', () {
    for (final (name, words) in [
      ('Arabic', _arabic),
      ('English', _english),
      ('a long English label', _long),
    ]) {
      for (final width in const [390.0, 1440.0]) {
        for (final scale in const [1.0, 2.0]) {
          testWidgets('$name at ${width.round()}, ${scale}x', (tester) async {
            _view(tester, width);
            await tester.pumpWidget(
              retroDesktopApp(
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: _segments(words),
                  ),
                ),
                direction: identical(words, _arabic)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                scale: scale,
              ),
            );
            await tester.pumpAndSettle();
            final tops = {
              for (final w in words) tester.getRect(find.text(w)).top.round(),
            };
            // A row keeps each segment's words on one line; a stack lets them
            // wrap, the segment growing with them.
            for (final w in words) {
              _expectWhole(tester, w, row: tops.length == 1);
            }
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  });
}
