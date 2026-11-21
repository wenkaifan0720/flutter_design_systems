// Every underlined part draws one line under its words, left to right and
// right to left, at rest and under the keyboard's focus (where the ink bar is
// the one line), and the top bar's way home under a pointer. Right to left
// the line is drawn below the words, clear of Arabic's tails, so the words'
// own underline must draw nothing there.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'screens_matrix.dart' show loadScreenFonts;

const _shot = ValueKey('shot');

/// The runs of ink down one column under [words], to [below] past the foot
/// of their line: each a stretch of rows that stand from the ground towards
/// the words' own colour. The column runs through the first space between
/// the words, from the middle of the line (its ground); or, for a single
/// word, through its middle from just under the baseline (where, in Civic's
/// own faces, only a line can be), its ground the top of the line.
Future<int> _linesUnder(
  WidgetTester tester,
  String words, {
  double below = 12,
}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final paragraph = tester.renderObject<RenderParagraph>(find.text(words));
  final space = words.indexOf(' ');
  final origin = paragraph.localToGlobal(Offset.zero, ancestor: boundary);
  final double x;
  final double from;
  final double clear;
  if (space > 0) {
    final box = paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: space, extentOffset: space + 1),
        )
        .single;
    x = origin.dx + (box.left + box.right) / 2;
    // From the middle of the line: inside a focused part's plate.
    from = origin.dy + (box.top + box.bottom) / 2;
    clear = from;
  } else {
    x = origin.dx + paragraph.size.width / 2;
    from =
        origin.dy +
        paragraph.computeDistanceToActualBaseline(TextBaseline.alphabetic) +
        1;
    clear = origin.dy + 1;
  }
  final to = origin.dy + paragraph.size.height + below;
  final image = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData();
    final out = (bytes!.buffer.asUint8List(), image.width, image.height);
    image.dispose();
    return out;
  }))!;
  final (Uint8List rgba, int width, int height) = image;
  final column = x.round().clamp(0, width - 1);
  // The shot holds the part alone, over nothing: each pixel as it would
  // stand over white (its bytes are premultiplied by their alpha).
  int at(int y) {
    final i = (y * width + column) * 4;
    return rgba[i] + rgba[i + 1] + rgba[i + 2] + 3 * (255 - rgba[i + 3]);
  }

  final top = from.round();
  final ground = at(clear.round());
  final ink = paragraph.text.style!.color!;
  final toward = (ink.r + ink.g + ink.b) * 255 > ground ? 1 : -1;
  var runs = 0;
  var inside = false;
  for (var y = top; y < to.round().clamp(0, height); y++) {
    // A line is ink, on the far side of the ground from the page under a
    // focused part's plate: as dark as the words, or as light on a band.
    final line = (at(y) - ground) * toward > 60;
    if (line && !inside) runs++;
    inside = line;
  }
  return runs;
}

/// An underlined part: its words, how it is built, and the states it is
/// held to.
typedef _Part = ({
  String name,
  String words,
  Widget Function() build,
  bool rest,
  bool focus,
  bool hover,
  double below,
});

_Part _part(
  String name,
  String words,
  Widget Function() build, {
  bool rest = true,
  bool focus = true,
  bool hover = false,
  double below = 12,
}) => (
  name: name,
  words: words,
  build: build,
  rest: rest,
  focus: focus,
  hover: hover,
  below: below,
);

final _url = Uri.parse('https://example.org/permits');

final List<_Part> _parts = [
  _part(
    'link',
    'Change your name',
    () => CivicLink(onPressed: () {}, child: const Text('Change your name')),
  ),
  _part(
    'link to a url',
    'Read the guidance',
    () => CivicLink(url: _url, child: const Text('Read the guidance')),
  ),
  _part(
    'back link',
    'Back to permits',
    () => CivicBackLink(onPressed: () {}, label: 'Back to permits'),
  ),
  _part(
    'breadcrumb',
    'Your council',
    () => CivicBreadcrumbs(
      items: [
        CivicBreadcrumb(label: 'Your council', onPressed: () {}),
        const CivicBreadcrumb(label: 'Apply'),
      ],
    ),
  ),
  _part(
    'breadcrumb to a url',
    'Parking permits',
    () => CivicBreadcrumbs(
      items: [
        CivicBreadcrumb(label: 'Parking permits', onPressed: () {}, url: _url),
        const CivicBreadcrumb(label: 'Apply'),
      ],
    ),
  ),
  _part(
    'summary row action',
    'Change name',
    () => CivicSummaryList(
      rows: [
        CivicSummaryRow(
          label: 'Name',
          value: const Text('Sam Brook'),
          actionLabel: 'Change name',
          onActionPressed: () {},
        ),
      ],
    ),
  ),
  _part(
    'summary row action to a url',
    'Change address',
    () => CivicSummaryList(
      rows: [
        CivicSummaryRow(
          label: 'Address',
          value: const Text('4 Mill Lane'),
          actionLabel: 'Change address',
          onActionPressed: () {},
          actionUrl: _url,
        ),
      ],
    ),
  ),
  _part(
    'error summary item',
    'Enter your full name',
    () => CivicErrorSummary(
      title: 'There is a problem',
      errors: [
        CivicErrorSummaryItem(text: 'Enter your full name', onPressed: () {}),
        CivicErrorSummaryItem(
          text: 'Enter a postcode',
          onPressed: () {},
          url: _url,
        ),
      ],
    ),
  ),
  _part(
    'card title',
    'Resident permit',
    () => SizedBox(
      width: 720,
      child: CivicCard(
        title: 'Resident permit',
        onPressed: () {},
        child: const Text('For a car kept at home.'),
      ),
    ),
  ),
  _part(
    'card title to a url',
    'Visitor permit',
    () => SizedBox(
      width: 720,
      child: CivicCard(
        title: 'Visitor permit',
        onPressed: () {},
        url: _url,
        child: const Text('For a guest who parks.'),
      ),
    ),
  ),
  _part(
    'pagination',
    'Next page',
    () => SizedBox(
      width: 720,
      child: CivicPagination(
        pageCount: 3,
        selectedIndex: 0,
        onPageChanged: (_) {},
        urlOf: (index) => _url.replace(queryParameters: {'page': '$index'}),
        nextLabel: 'Next page',
      ),
    ),
  ),
  _part(
    'pagination number',
    '2',
    () => SizedBox(
      width: 720,
      child: CivicPagination(
        pageCount: 3,
        selectedIndex: 0,
        onPageChanged: (_) {},
      ),
    ),
  ),
  _part('sortable heading', 'Days left', () {
    final permits = RawDataTableController<(String, int)>(
      rows: const [('CU57 ABC', 12), ('LB19 XYZ', 40)],
      columns: [
        RawDataColumn(id: 'car', label: 'Vehicle', sortKey: (row) => row.$1),
        RawDataColumn(
          id: 'days',
          label: 'Days left',
          numeric: true,
          sortKey: (row) => row.$2,
        ),
      ],
    );
    addTearDown(permits.dispose);
    return SizedBox(
      width: 720,
      child: CivicTable<(String, int)>(
        caption: 'Your permits',
        controller: permits,
        cellBuilder: (context, row, column) =>
            Text(column.id == 'car' ? row.$1 : '${row.$2}'),
      ),
    );
  }, below: 6),
  _part(
    'tab',
    'Your documents',
    () => SizedBox(
      width: 720,
      child: CivicTabBar(
        tabs: const ['Details', 'Your documents'],
        selectedIndex: 0,
        onTap: (_) {},
      ),
    ),
    // The strip's one stop is the chosen tab, which wears no underline.
    focus: false,
    below: 6,
  ),
  _part(
    'accordion toggle',
    'Show all sections',
    () => const SizedBox(
      width: 720,
      child: CivicAccordion(
        sections: [
          CivicAccordionSection(
            title: 'Opening hours',
            child: Text('Monday to Friday, 9am to 5pm.'),
          ),
        ],
      ),
    ),
  ),
  _part(
    'details',
    'Help with your reference',
    () => const SizedBox(
      width: 720,
      child: CivicDetails(
        title: 'Help with your reference',
        child: Text('It is on the letter we sent you.'),
      ),
    ),
  ),
  _part(
    'top bar way home',
    'Brindlemere council',
    () => SizedBox(
      width: 720,
      child: CivicTopBar(title: 'Brindlemere council', onTitlePressed: () {}),
    ),
    // It underlines under a pointer or a press, as a link answers.
    rest: false,
    hover: true,
  ),
  _part(
    'skip link',
    'Skip to main content',
    () => const SizedBox(
      width: 720,
      height: 200,
      child: CivicScaffold(
        skipLinkLabel: 'Skip to main content',
        body: SizedBox.expand(),
      ),
    ),
    // It stands only while it has the focus.
    rest: false,
  ),
];

/// Whether the keyboard's focus is on [words] or a part round them.
bool _holdsFocus(WidgetTester tester, String words) {
  final node = FocusManager.instance.primaryFocus;
  // A scope (the route's, before any Tab) holds everything and is no stop.
  final focused = node is FocusScopeNode ? null : node?.context;
  if (focused == null) return false;
  var held = false;
  tester.element(find.text(words)).visitAncestorElements((element) {
    held = element == focused;
    return !held;
  });
  return held;
}

Future<void> _show(WidgetTester tester, Widget part, TextDirection direction) =>
    tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => CivicHost(child: child!),
        home: Directionality(
          textDirection: direction,
          child: Center(
            child: RepaintBoundary(key: _shot, child: part),
          ),
        ),
      ),
    );

void main() {
  setUpAll(loadScreenFonts);
  setUp(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional,
  );
  tearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  for (final part in _parts) {
    for (final direction in TextDirection.values) {
      final states = [
        if (part.rest) 'at rest',
        if (part.focus) 'focused',
        if (part.hover) 'under a pointer',
      ];
      for (final state in states) {
        testWidgets(
          '${part.name}, ${direction.name}, $state: one line under the words',
          (tester) async {
            await _show(tester, part.build(), direction);
            await tester.pumpAndSettle();
            if (state == 'focused') {
              // Tab on to the stop that holds the words.
              for (var i = 0; i < 6 && !_holdsFocus(tester, part.words); i++) {
                await tester.sendKeyEvent(LogicalKeyboardKey.tab);
                await tester.pumpAndSettle();
              }
              expect(
                _holdsFocus(tester, part.words),
                isTrue,
                reason: 'Tab reaches the stop that holds "${part.words}"',
              );
            }
            if (state == 'under a pointer') {
              final mouse = await tester.createGesture(
                kind: PointerDeviceKind.mouse,
              );
              addTearDown(mouse.removePointer);
              await mouse.addPointer(location: Offset.zero);
              await mouse.moveTo(tester.getCenter(find.text(part.words)));
              await tester.pumpAndSettle();
            }
            expect(find.text(part.words), findsOneWidget);
            expect(await _linesUnder(tester, part.words, below: part.below), 1);
          },
        );
      }
    }
  }
}
