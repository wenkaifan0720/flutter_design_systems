// At twice the text size on a phone, parts keep every word whole: a table
// scrolls sideways, a step's or a dock place's name lowers its size to fit,
// an input group's add-ons print smaller rather than be cut, and a group's
// keys scroll inside their slab, never past its ends.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

typedef _Habit = ({String name, int kept, int streak});

const _habits = <_Habit>[
  (name: 'Drink water', kept: 6, streak: 12),
  (name: 'Morning walk', kept: 5, streak: 9),
  (name: 'Read', kept: 4, streak: 4),
  (name: 'Stretch', kept: 7, streak: 21),
];

const _cells = [
  'Drink water', '6 of 7', '12', 'Morning walk', '5 of 7', '9', //
  'Read', '4 of 7', '4', 'Stretch', '7 of 7', '21',
];

Future<void> _phone(
  WidgetTester tester,
  Widget child, {
  double scale = 2,
  TextDirection direction = TextDirection.ltr,
  bool scroll = true,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ClayTheme(
        data: ClayThemeData.clay(Brightness.light),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: scroll
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: child,
              )
            : child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// Each word of [text] lies on one line: a word broken in two spans two.
void _expectWordsWhole(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  var start = 0;
  for (final word in text.split(' ')) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + word.length),
    );
    final lines = {for (final box in boxes) box.top.round()};
    expect(
      lines,
      hasLength(1),
      reason: '"$word" of "$text" runs over ${lines.length} lines',
    );
    start += word.length + 1;
  }
}

Finder _sideways(Type table) => find.descendant(
  of: find.byType(table),
  matching: find.byWidgetPredicate(
    (w) => w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
  ),
);

const _table = ClayTable(
  columns: [
    ClayTableColumn('Habit', flex: 2),
    ClayTableColumn('This week', numeric: true),
    ClayTableColumn('Streak', numeric: true),
  ],
  rows: [
    ['Drink water', '6 of 7', '12'],
    ['Morning walk', '5 of 7', '9'],
    ['Read', '4 of 7', '4'],
    ['Stretch', '7 of 7', '21'],
  ],
);

Widget _dataTable(ClayTableController<_Habit> controller) =>
    ClayDataTable<_Habit>(
      controller: controller,
      selectable: true,
      cell: (h, column) => switch (column) {
        'name' => h.name,
        'kept' => '${h.kept} of 7',
        _ => '${h.streak}',
      },
    );

ClayTableController<_Habit> _controller() {
  final controller = ClayTableController<_Habit>(
    rows: _habits,
    rowKey: (h) => h.name,
    columns: [
      ClayDataColumn(id: 'name', label: 'Habit', sortKey: (h) => h.name),
      ClayDataColumn(
        id: 'kept',
        label: 'This week',
        sortKey: (h) => h.kept,
        numeric: true,
      ),
      ClayDataColumn(
        id: 'streak',
        label: 'Streak',
        sortKey: (h) => h.streak,
        numeric: true,
      ),
    ],
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  setUpAll(clayLoadFonts);

  for (final direction in TextDirection.values) {
    testWidgets('a table keeps its words whole at 2x ($direction)', (
      tester,
    ) async {
      await _phone(tester, _table, direction: direction);
      for (final text in ['Habit', 'This week', 'Streak', ..._cells]) {
        _expectWordsWhole(tester, text);
      }
    });

    testWidgets('a data table keeps headings and words whole at 2x '
        '($direction)', (tester) async {
      await _phone(tester, _dataTable(_controller()), direction: direction);
      for (final text in ['Habit', 'This week', 'Streak']) {
        expect(
          tester.renderObject<RenderParagraph>(find.text(text)),
          isA<RenderParagraph>().having(
            (p) => p.didExceedMaxLines,
            '"$text" cut short',
            isFalse,
          ),
        );
      }
      for (final text in _cells) {
        _expectWordsWhole(tester, text);
      }
    });

    testWidgets('a step keeps its name whole at 2x ($direction)', (
      tester,
    ) async {
      await _phone(
        tester,
        const SizedBox(
          width: 300,
          child: ClayStepProgress(
            steps: ['Habit', 'Schedule', 'Reminder'],
            current: 1,
          ),
        ),
        direction: direction,
      );
      for (final text in ['Habit', 'Schedule', 'Reminder']) {
        _expectWordsWhole(tester, text);
      }
    });

    testWidgets('a dock place keeps its name whole at 2x ($direction)', (
      tester,
    ) async {
      await _phone(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          // A dock as wide as a phone page's column inside a card.
          child: SizedBox(
            width: 300,
            child: ClayNavigationBar(
              destinations: const [
                ClayDestination(icon: LucideIcons.sun, label: 'Today'),
                ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
                ClayDestination(icon: LucideIcons.smile, label: 'Mood'),
                ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
              action: ClayIconButton.filled(
                onPressed: () {},
                icon: const Icon(LucideIcons.plus),
                tooltip: 'Add habit',
              ),
            ),
          ),
        ),
        direction: direction,
        scroll: false,
      );
      final dock = tester.getRect(find.byType(ClayNavigationBar));
      for (final text in ['Today', 'Habits', 'Mood', 'Settings']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
        expect(paragraph.didExceedMaxLines, isFalse, reason: '"$text" cut');
        final rect = tester.getRect(find.text(text));
        expect(
          rect.left >= dock.left && rect.right <= dock.right,
          isTrue,
          reason: '"$text" at $rect leaves the dock $dock',
        );
      }
    });
  }

  for (final direction in TextDirection.values) {
    testWidgets('an input group keeps its add-ons whole at 2x ($direction)', (
      tester,
    ) async {
      await _phone(
        tester,
        const Column(
          children: [
            ClayInputGroup(label: 'Goal', suffixText: 'glasses a day'),
            SizedBox(height: 16),
            ClayInputGroup(
              label: 'Address',
              prefixText: 'https://',
              suffixText: '.habits',
            ),
          ],
        ),
        direction: direction,
      );
      for (final words in ['glasses a day', 'https://', '.habits']) {
        expect(
          tester.renderObject<RenderParagraph>(find.text(words)),
          isA<RenderParagraph>().having(
            (p) => p.didExceedMaxLines,
            '"$words" cut short',
            isFalse,
          ),
        );
      }
    });
  }

  testWidgets('add-ons print full size at the usual text size', (tester) async {
    await _phone(
      tester,
      const ClayInputGroup(
        label: 'Address',
        prefixText: 'https://',
        suffixText: '.habits',
      ),
      scale: 1,
    );
    for (final words in ['https://', '.habits']) {
      final paragraph = tester.renderObject<RenderParagraph>(find.text(words));
      expect(paragraph.textScaler.scale(16), 16, reason: '"$words" smaller');
      expect(paragraph.didExceedMaxLines, isFalse);
    }
  });

  testWidgets('tables at the usual text size on a phone do not scroll', (
    tester,
  ) async {
    await _phone(
      tester,
      Column(
        children: [
          _table,
          const SizedBox(height: 16),
          _dataTable(_controller()),
        ],
      ),
      scale: 1,
    );
    expect(_sideways(ClayTable), findsNothing);
    expect(_sideways(ClayDataTable<_Habit>), findsNothing);
  });

  testWidgets('keys too wide for their group stay inside its slab (rtl)', (
    tester,
  ) async {
    const backdrop = Color(0xFF00FF00);
    final boundary = GlobalKey();
    await _phone(
      tester,
      RepaintBoundary(
        key: boundary,
        child: ColoredBox(
          color: backdrop,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(140, 40, 16, 40),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: ClayButtonGroup(
                items: [
                  ClayButtonGroupItem(label: 'Skip today', onPressed: () {}),
                  ClayButtonGroupItem(label: 'Snooze', onPressed: () {}),
                  ClayButtonGroupItem(label: 'Add a note', onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
      direction: TextDirection.rtl,
      scroll: false,
    );
    final slab = tester.getRect(find.byType(ClayButtonGroup));
    final shot = await tester.runAsync(() async {
      final paint =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await paint.toImage();
      final bytes = await image.toByteData();
      final width = image.width;
      image.dispose();
      return (width, bytes!);
    });
    final (width, bytes) = shot!;
    // Dark ink (a key's words) to the left of the slab, past its soft
    // shadow, is a key drawn outside it.
    var ink = 0;
    for (var y = slab.top.round(); y < slab.bottom.round(); y++) {
      for (var x = 0; x < slab.left - 32; x++) {
        final i = (y * width + x) * 4;
        final r = bytes.getUint8(i), g = bytes.getUint8(i + 1);
        final b = bytes.getUint8(i + 2);
        if (0.2126 * r + 0.7152 * g + 0.0722 * b < 120) ink++;
      }
    }
    expect(ink, 0, reason: 'key ink drawn left of the slab at $slab');
  });
}
