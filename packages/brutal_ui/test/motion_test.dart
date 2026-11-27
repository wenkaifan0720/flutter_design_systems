// The example app in motion: every state change it shows (a press, the focus, a place, a pushed page, a dialog, a
// field's error, the date's calendar, the appearance and the palette) moves through frames between its two states;
// none snaps. A probe takes the app's picture before, a few frames in, and settled: the middle frame differs from both.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:brutal_ui/brutal_ui.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/main.dart';

const _shot = ValueKey('shot');

Finder words(String text) => find.byWidgetPredicate(
  (w) =>
      w is RichText &&
      w.text.toPlainText().trim().toLowerCase() == text.toLowerCase(),
);

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

// The app's picture, or the part of it [within] (logical pixels, at a device pixel ratio of 1).
Future<List<int>> _picture(WidgetTester tester, [Rect? within]) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final width = boundary.size.width.round();
  final all = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return data!.buffer.asUint8List();
  }))!;
  if (within == null) return all.toList();
  return [
    for (var y = within.top.round(); y < within.bottom.round(); y++)
      ...all.sublist(
        (y * width + within.left.round()) * 4,
        (y * width + within.right.round()) * 4,
      ),
  ];
}

/// Runs [act], then reads the picture [into] after it and once settled: the middle frame must differ from the picture
/// before and from the settled one.
Future<void> probe(
  WidgetTester tester,
  String what,
  Future<void> Function() act, {
  Duration into = const Duration(milliseconds: 40),
  bool settleAfter = true,
  Rect? within,
}) async {
  final before = await _picture(tester, within);
  await act();
  await tester.pump(into);
  final during = await _picture(tester, within);
  if (settleAfter) {
    await settle(tester);
  } else {
    await tester.pump(const Duration(seconds: 1));
  }
  final after = await _picture(tester, within);
  expect(
    listEquals(before, after),
    isFalse,
    reason: '$what changes nothing drawn',
  );
  expect(
    listEquals(during, before),
    isFalse,
    reason: '$what has not begun ${into.inMilliseconds} ms in',
  );
  expect(
    listEquals(during, after),
    isFalse,
    reason: '$what snapped: settled ${into.inMilliseconds} ms in',
  );
}

Future<void> open(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const RepaintBoundary(key: _shot, child: ShelfApp()));
  await settle(tester);
}

void main() {
  setUpAll(brutalLoadFonts);

  for (final width in const [390.0, 1440.0]) {
    testWidgets(
      'at $width a press, a pushed page, a dialog and the way back move',
      (tester) async {
        await open(tester, width);
        final row = tester.getCenter(words('Piranesi'));
        late TestGesture press;
        // A press in a list shows once the press is told from a scroll (kPressTimeout, 100 ms), then moves in.
        await probe(tester, 'pressing a row', () async {
          press = await tester.startGesture(row);
          await tester.pump();
        }, into: const Duration(milliseconds: 140));
        await probe(tester, 'releasing a row (the page pushed)', () async {
          await press.up();
          await tester.pump();
        });
        await probe(tester, 'the dialog opening', () async {
          await tester.tap(words('Remove from the shelf'));
          await tester.pump();
        });
        await probe(tester, 'the dialog closing', () async {
          await tester.tap(words('Keep'));
          await tester.pump();
        });
        await probe(tester, 'the page popping', () async {
          Navigator.of(tester.element(words('Remove from the shelf'))).pop();
          await tester.pump();
        });
      },
    );

    testWidgets(
      'at $width a place, the focus, an error and the calendar move',
      (tester) async {
        await open(tester, width);
        await probe(tester, 'choosing a place', () async {
          await tester.tap(find.bySemanticsLabel(RegExp('^Add a book')).first);
          await tester.pump();
        });
        await probe(tester, 'the errors showing', () async {
          await tester.tap(words('Save'));
          await tester.pump();
        }, settleAfter: false);
        // The focus leaves the field the errors gave it to, then comes back by the keyboard.
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
        await probe(tester, 'the keyboard focus arriving', () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
        }, settleAfter: false);
        FocusManager.instance.primaryFocus?.unfocus();
        await settle(tester);
        final date = find.bySemanticsLabel(RegExp('Started')).last;
        await probe(tester, 'the calendar opening', () async {
          await tester.tap(date);
          await tester.pump();
        });
        await probe(tester, 'the calendar closing', () async {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pump();
        });
      },
    );

    testWidgets('at $width the appearance, the palette and a hover move', (
      tester,
    ) async {
      await open(tester, width);
      await tester.tap(find.bySemanticsLabel(RegExp('^Settings')).first);
      await settle(tester);
      // The page's ground under the list, away from what is tapped: the theme itself moves, not only the control.
      final ground = Rect.fromLTWH(width - 120, 820, 100, 40);
      await probe(tester, 'the appearance turning dark', () async {
        await tester.tap(words('Dark'));
        await tester.pump();
      }, within: ground);
      await probe(tester, 'another palette', () async {
        await tester.tap(words(BrutalThemeData.palettes[2].label));
        await tester.pump();
      }, within: ground);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      // A pointer over a part changes nothing but the cursor, by the look's law: nothing to move.
      final still = await _picture(tester);
      await mouse.moveTo(
        tester.getCenter(words(BrutalThemeData.palettes[4].label)),
      );
      await settle(tester);
      expect(listEquals(await _picture(tester), still), isTrue);
    });
  }

  testWidgets(
    'a switch, a checkbox and a disclosure move between their states',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          key: _shot,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, child) => BrutalHost(child: child!),
            home: const BrutalScreen(body: _Parts()),
          ),
        ),
      );
      await settle(tester);
      await probe(tester, 'the switch turning on', () async {
        await tester.tap(find.byType(BrutalSwitch));
        await tester.pump();
      });
      await probe(tester, 'the checkbox checking', () async {
        await tester.tap(find.byType(BrutalCheckbox));
        await tester.pump();
      });
      await probe(tester, 'the disclosure opening', () async {
        await tester.tap(words('More'));
        await tester.pump();
      });
      await probe(tester, 'the disclosure closing', () async {
        await tester.tap(words('More'));
        await tester.pump();
      });
    },
  );
}

class _Parts extends StatefulWidget {
  const _Parts();

  @override
  State<_Parts> createState() => _PartsState();
}

class _PartsState extends State<_Parts> {
  bool on = false, checked = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 16,
    children: [
      BrutalSwitch(
        value: on,
        semanticLabel: 'Sync',
        onChanged: (v) => setState(() => on = v),
      ),
      BrutalCheckbox(
        value: checked,
        semanticLabel: 'Done',
        onChanged: (v) => setState(() => checked = v ?? false),
      ),
      const BrutalDisclosure(
        title: 'More',
        child: Text('Inside the disclosure'),
      ),
    ],
  );
}
