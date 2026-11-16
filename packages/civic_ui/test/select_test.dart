// A select's open list is the field's width, wider only to fit its longest
// item and then no wider than 320 (a field wider than that keeps its own),
// never the screen's, and starts on the field's leading edge: at 390 and
// 1440 wide, left to right and right to left. Civic's select is 320 from
// 600 wide, so there a long item wraps in a list the field's width.
//
// And the keys, as a platform's own select: Enter, Space or Down open the
// list on the answer chosen (the first while none is), as a press does;
// Up and Down walk it round, Home and End go to its ends, a typed letter
// goes to the next answer starting with it, Enter takes an answer and
// closes the list, Escape closes it, and the focus is back on the field.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/kit_gallery/kit.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : civicFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

const _short = [
  CivicSelectItem(value: 'car', label: 'Car or van'),
  CivicSelectItem(value: 'motorcycle', label: 'Motorcycle'),
];

const _long = [
  CivicSelectItem(value: 'car', label: 'Car or van'),
  CivicSelectItem(
    value: 'badge',
    label: "A vehicle that carries a disabled person's parking badge",
  ),
];

/// Opens a select of [items] at [width] in [direction]; returns the field's
/// box and the open list's.
Future<(Rect field, Rect list)> _open(
  WidgetTester tester, {
  required double width,
  required TextDirection direction,
  required List<CivicSelectItem<String>> items,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kitApp(
      brightness: Brightness.light,
      direction: direction,
      home: Padding(
        padding: const EdgeInsets.all(CivicSpacing.s20),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: CivicSelect<String>(
            labelText: 'Vehicle',
            value: 'car',
            items: items,
            onChanged: (_) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final field = tester.getRect(
    find
        .ancestor(
          of: find.text('Car or van'),
          matching: find.byType(DesignPressable),
        )
        .first,
  );
  await tester.tap(find.text('Car or van'));
  await tester.pumpAndSettle();
  // The list's box: the first painted box round its scroll view.
  final list = tester.getRect(
    find
        .ancestor(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (field, list);
}

void main() {
  setUpAll(_loadFonts);

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      final where = '$width, ${direction.name}';

      testWidgets('a list of short items is the field\'s width ($where)', (
        tester,
      ) async {
        final (field, list) = await _open(
          tester,
          width: width,
          direction: direction,
          items: _short,
        );
        expect(list.width, moreOrLessEquals(field.width, epsilon: 0.5));
        expect(
          direction == TextDirection.ltr ? list.left : list.right,
          moreOrLessEquals(
            direction == TextDirection.ltr ? field.left : field.right,
            epsilon: 0.5,
          ),
        );
      });

      testWidgets('a list with a long item keeps to the field and wraps it '
          '($where)', (tester) async {
        final (field, list) = await _open(
          tester,
          width: width,
          direction: direction,
          items: _long,
        );
        // The phone's field (350) is past the cap and keeps its own width;
        // the desktop's is the cap. Either way the list is the field's, and
        // never the screen's.
        expect(list.width, moreOrLessEquals(field.width, epsilon: 0.5));
        expect(list.width, lessThan(width - 2 * CivicSpacing.s8));
        final item = tester.getRect(
          find.text("A vehicle that carries a disabled person's parking badge"),
        );
        final line = tester.getRect(find.text('Car or van').last);
        expect(item.height, greaterThan(line.height * 1.5));
        expect(
          direction == TextDirection.ltr ? list.left : list.right,
          moreOrLessEquals(
            direction == TextDirection.ltr ? field.left : field.right,
            epsilon: 0.5,
          ),
        );
      });
    }
  }

  group('keys', () {
    const vehicles = [
      CivicSelectItem(value: 'car', label: 'Car or van'),
      CivicSelectItem(value: 'motorcycle', label: 'Motorcycle'),
      CivicSelectItem(value: 'minibus', label: 'Minibus'),
      CivicSelectItem(value: 'lorry', label: 'Lorry', enabled: false),
      CivicSelectItem(value: 'trailer', label: 'Trailer'),
    ];

    /// A select of [vehicles] holding [value], its field focused.
    Future<(FocusNode field, List<String> chosen)> keysOn(
      WidgetTester tester, {
      String? value,
    }) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final field = FocusNode();
      addTearDown(field.dispose);
      final chosen = <String>[];
      await tester.pumpWidget(
        kitApp(
          brightness: Brightness.light,
          home: Padding(
            padding: const EdgeInsets.all(CivicSpacing.s20),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: CivicSelect<String>(
                labelText: 'Vehicle',
                value: value,
                hintText: 'Choose a vehicle',
                focusNode: field,
                items: vehicles,
                onChanged: chosen.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      field.requestFocus();
      await tester.pumpAndSettle();
      return (field, chosen);
    }

    /// The words of the answer the focus is on; null when it is on none.
    String? reached() {
      final at = FocusManager.instance.primaryFocus?.context;
      if (at == null) return null;
      String? words;
      void visit(Element e) {
        final w = e.widget;
        if (words == null && w is Text) words = w.data;
        if (words == null) e.visitChildren(visit);
      }

      at.visitChildElements(visit);
      return words;
    }

    bool open() => find.byType(SingleChildScrollView).evaluate().isNotEmpty;

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String letter) async {
      final key = LogicalKeyboardKey.findKeyByKeyId(
        LogicalKeyboardKey.keyA.keyId + letter.codeUnitAt(0) - 0x61,
      )!;
      await tester.sendKeyDownEvent(key, character: letter);
      await tester.sendKeyUpEvent(key);
      await tester.pumpAndSettle();
    }

    for (final key in [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.arrowDown,
    ]) {
      testWidgets('${key.keyLabel} opens the list on the answer chosen', (
        tester,
      ) async {
        await keysOn(tester, value: 'minibus');
        await press(tester, key);
        expect(open(), isTrue);
        expect(reached(), 'Minibus');
      });
    }

    testWidgets('with none chosen, the list opens on the first answer', (
      tester,
    ) async {
      await keysOn(tester);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(reached(), 'Car or van');
    });

    testWidgets('Up and Down walk the list round, past an answer that '
        'cannot be chosen; Home and End go to its ends', (tester) async {
      await keysOn(tester, value: 'minibus');
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(reached(), 'Trailer');
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(reached(), 'Car or van');
      await press(tester, LogicalKeyboardKey.arrowUp);
      expect(reached(), 'Trailer');
      await press(tester, LogicalKeyboardKey.home);
      expect(reached(), 'Car or van');
      await press(tester, LogicalKeyboardKey.end);
      expect(reached(), 'Trailer');
    });

    testWidgets('a typed letter goes to the next answer starting with it; '
        'letters typed quickly spell one', (tester) async {
      await keysOn(tester, value: 'car');
      await press(tester, LogicalKeyboardKey.enter);
      await type(tester, 'm');
      expect(reached(), 'Motorcycle');
      await type(tester, 'm');
      expect(reached(), 'Minibus');
      await type(tester, 'm');
      expect(reached(), 'Motorcycle');
      await tester.pump(const Duration(seconds: 2));
      await type(tester, 't');
      expect(reached(), 'Trailer');
      await tester.pump(const Duration(seconds: 2));
      await type(tester, 'm');
      await type(tester, 'i');
      expect(reached(), 'Minibus');
      await tester.pump(const Duration(seconds: 2));
      // Lorry cannot be chosen: its letter finds nothing, and the focus stays.
      await type(tester, 'l');
      expect(reached(), 'Minibus');
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('Enter takes the answer reached and closes the list; the '
        'focus is back on the field', (tester) async {
      final (field, chosen) = await keysOn(tester, value: 'car');
      await press(tester, LogicalKeyboardKey.space);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.enter);
      expect(chosen, ['motorcycle']);
      expect(open(), isFalse);
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('Escape closes the list, takes nothing, and the focus is '
        'back on the field', (tester) async {
      final (field, chosen) = await keysOn(tester, value: 'car');
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.arrowDown);
      await press(tester, LogicalKeyboardKey.escape);
      expect(chosen, isEmpty);
      expect(open(), isFalse);
      expect(field.hasPrimaryFocus, isTrue);
    });

    testWidgets('after a press opens it, the arrows go on from the answer '
        'chosen', (tester) async {
      await keysOn(tester, value: 'motorcycle');
      await tester.tap(find.text('Motorcycle'));
      await tester.pumpAndSettle();
      expect(open(), isTrue);
      expect(reached(), 'Motorcycle');
      await press(tester, LogicalKeyboardKey.arrowDown);
      expect(reached(), 'Minibus');
    });
  });
}
