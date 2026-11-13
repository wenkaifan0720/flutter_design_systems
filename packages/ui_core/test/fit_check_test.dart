// DesignWordBreakCheck and DesignClipCheck: no word broken across two lines,
// and no control or line of words cut by a clip round it.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';

// The Flutter SDK's Roboto, so words are drawn in a typeface, not the test's
// boxes.
Future<void> _loadRoboto() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final font = File(
    '$root/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
  await (FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync()))))
      .load();
}

const _ink = Color(0xFF16181D);
const _fill = Color(0xFFDDE4F5);
const _style = TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _ink);

final _key = GlobalKey();

Future<void> _pump(WidgetTester tester, Widget body) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFF7F7F5),
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: KeyedSubtree(key: _key, child: body),
          ),
        ),
      ),
    ),
  );
}

List<String> _broken() =>
    const DesignWordBreakCheck(look: 'Fixture')
        .check(_key.currentContext!)
        .problems;

List<String> _cut() =>
    const DesignClipCheck(look: 'Fixture').check(_key.currentContext!).problems;

// A button: [label] on a face [width] wide (null: its words' own), 40 high.
Widget _button(String label, {double? width, Widget? child}) => Semantics(
  button: true,
  label: label,
  child: GestureDetector(
    onTap: () {},
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: width,
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            widthFactor: 1,
            child: child ?? Text(label, style: _style, maxLines: 1),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadRoboto);

  group('a word broken across lines', () {
    testWidgets('a word wider than its box is named with where it breaks', (
      tester,
    ) async {
      await _pump(
        tester,
        const SizedBox(width: 48, child: Text('Groceries', style: _style)),
      );
      expect(
        _broken(),
        equals([
          matches(
            RegExp(
              r'^the words "Groceries": "Groceries" is broken across two '
              r'lines as "\w+" and "\w+" \(it needs [0-9.]+ px, its box is 48\)$',
            ),
          ),
        ]),
      );
    });

    testWidgets('words that wrap between words, at a hyphen, or that keep to '
        'one line are not', (tester) async {
      await _pump(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text('Spending this month', style: _style),
            ),
            SizedBox(width: 60, child: Text('well-known', style: _style)),
            SizedBox(
              width: 48,
              child: Text(
                'Groceries',
                style: _style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
      expect(_broken(), isEmpty);
    });

    testWidgets('what is not painted is not read', (tester) async {
      await _pump(
        tester,
        const Offstage(
          child: SizedBox(width: 48, child: Text('Groceries', style: _style)),
        ),
      );
      expect(_broken(), isEmpty);
    });
  });

  group('nothing cut', () {
    // Seven day buttons 48 wide side by side in a room [room] wide that
    // clips them.
    Widget week(double room) => ClipRect(
      child: SizedBox(
        width: room,
        height: 40,
        child: OverflowBox(
          alignment: Alignment.centerLeft,
          minWidth: 0,
          maxWidth: double.infinity,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                _button(d, width: 48, child: Text(d, style: _style)),
            ],
          ),
        ),
      ),
    );

    testWidgets('a control a clip cuts is named; one wholly past it is '
        'hidden, not cut', (tester) async {
      // 320 shows six whole days and 32 of Sunday... 6 x 48 = 288, Sunday
      // from 288 to 336: 32 of its 48 show.
      await _pump(tester, week(320));
      expect(
        _cut(),
        equals([
          'a button "Sun" is cut at its right by 16 px: 32 of its 48 px '
              'across show',
        ]),
      );
      // 288: Sunday wholly past the clip, hidden.
      await _pump(tester, week(288));
      expect(_cut(), isEmpty);
      await _pump(tester, week(336));
      expect(_cut(), isEmpty);
    });

    testWidgets('what scrolls is not cut: the rest shows when scrolled', (
      tester,
    ) async {
      await _pump(
        tester,
        SizedBox(
          width: 320,
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final d in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
                _button(d, width: 48, child: Text(d, style: _style)),
            ],
          ),
        ),
      );
      expect(_cut(), isEmpty);
    });

    testWidgets('words past the end of a box that clips them are cut; an '
        'ellipsis shortens them, and is not read', (tester) async {
      await _pump(
        tester,
        const SizedBox(
          width: 60,
          child: Text(
            'Saturday morning',
            style: _style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),
      );
      expect(
        _cut(),
        equals([
          matches(
            RegExp(
              r'^the words "Saturday morning" are cut at their right by '
              r'[0-9.]+ px: 60 of their [0-9.]+ px across show$',
            ),
          ),
        ]),
      );
      await _pump(
        tester,
        const SizedBox(
          width: 60,
          child: Text(
            'Saturday morning',
            style: _style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
      expect(_cut(), isEmpty);
      // Run past their last line with no ellipsis: cut short there.
      await _pump(
        tester,
        const SizedBox(
          width: 60,
          child: Text(
            'Saturday morning and evening',
            style: _style,
            maxLines: 2,
            overflow: TextOverflow.clip,
          ),
        ),
      );
      expect(
        _cut(),
        equals([
          'the words "Saturday morning and ev…" run past their last line '
              'and are cut short there',
        ]),
      );
    });

    testWidgets("a line's leading clipped off a tight pill is no cut", (
      tester,
    ) async {
      // A 16 px pill clips a 14 px line whose box is 16.4 high.
      await _pump(
        tester,
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const SizedBox(
            height: 15,
            child: ColoredBox(
              color: _fill,
              child: Text('New', style: _style),
            ),
          ),
        ),
      );
      expect(_cut(), isEmpty);
    });
  });
}
