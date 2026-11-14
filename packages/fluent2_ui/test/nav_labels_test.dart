// A navigation label stays whole at every text size a reader sets: the phone
// tab bar's words (one size across the bar, 8 in from each tab's sides, so
// never at the screen's edge), a row of tabs, a phone top bar's title and a
// breadcrumb's current place. None is cut or ellipsized; each paragraph is
// drawn at its natural width, inside its room.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

Widget _host(Widget child, double scale, {Brightness b = Brightness.light}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, route) => Fluent2Host(brightness: b, child: route!),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: ColoredBox(
            color: context.fluent2Theme.background,
            child: child,
          ),
        ),
      ),
    );

/// The global rect [p] paints in (its transforms applied: a label drawn
/// smaller whole stands in its scaled box).
Rect _painted(RenderParagraph p) {
  final a = p.localToGlobal(Offset.zero);
  final b = p.localToGlobal(p.size.bottomRight(Offset.zero));
  return Rect.fromPoints(a, b);
}

/// Every paragraph of words under [of] (an icon's glyph aside), laid out
/// whole: never past its last line, each word on one line (never "Calenda"
/// over "r"), and (unless it may [wrap]) on one line at its natural width.
List<RenderParagraph> _whole(
  WidgetTester t,
  Finder of,
  String where, {
  bool wrap = false,
}) {
  final paragraphs = [
    for (final e
        in find.descendant(of: of, matching: find.byType(RichText)).evaluate())
      if (RegExp('[A-Za-z]')
          .hasMatch((e.renderObject! as RenderParagraph).text.toPlainText()))
        e.renderObject! as RenderParagraph,
  ];
  for (final p in paragraphs) {
    final words = p.text.toPlainText();
    expect(p.didExceedMaxLines, isFalse, reason: '$where: "$words" cut');
    for (final m in RegExp(r'\S+').allMatches(words)) {
      final boxes = p.getBoxesForSelection(
        TextSelection(baseOffset: m.start, extentOffset: m.end),
      );
      expect(
        {for (final b in boxes) b.top.round()},
        hasLength(1),
        reason: '$where: "${m.group(0)}" broken across lines',
      );
    }
    if (wrap) continue;
    expect(
      p.size.width,
      greaterThanOrEqualTo(p.getMaxIntrinsicWidth(double.infinity) - 0.5),
      reason: '$where: "$words" narrower than its words',
    );
  }
  return paragraphs;
}

const _tabs = [
  Fluent2NavItem(Fluent2Icons.home, 'Home'),
  Fluent2NavItem(Fluent2Icons.folder, 'Files'),
  Fluent2NavItem(Fluent2Icons.clipboard, 'Requests'),
  Fluent2NavItem(Fluent2Icons.settings, 'Settings'),
];

const _short = [
  Fluent2NavItem(Fluent2Icons.home, 'Home'),
  Fluent2NavItem(Fluent2Icons.folder, 'Docs'),
  Fluent2NavItem(Fluent2Icons.clipboard, 'Jobs'),
  Fluent2NavItem(Fluent2Icons.settings, 'Me'),
];

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      final where = 'at $width, text $scale';
      testWidgets('the tab bar keeps its four words whole $where', (t) async {
        t.view.physicalSize = Size(width, 700);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          _host(
            Align(
              alignment: Alignment.bottomCenter,
              child: Fluent2NavigationBar(
                items: _tabs,
                selectedIndex: 2,
                onDestinationSelected: (_) {},
              ),
            ),
            scale,
          ),
        );
        await t.pumpAndSettle();
        final bar = find.byType(Fluent2NavigationBar);
        final words = _whole(t, bar, where);
        expect(words, hasLength(4));
        final tab = width / 4;
        final heights = <double>{};
        for (final (i, p) in words.indexed) {
          final r = _painted(p);
          final label = p.text.toPlainText();
          // Inside its own tab, 8 in from each side: never at the screen's
          // edge, never meeting its neighbour.
          expect(
            r.left,
            greaterThanOrEqualTo(i * tab + 8 - 0.5),
            reason: '$where: "$label" starts ${r.left}',
          );
          expect(
            r.right,
            lessThanOrEqualTo((i + 1) * tab - 8 + 0.5),
            reason: '$where: "$label" ends ${r.right}',
          );
          heights.add((r.height * 10).round() / 10);
        }
        // One size across the bar (the chosen tab's bolder words too).
        expect(heights, hasLength(1), reason: '$where: sizes $heights');
        // The words grow with the reader's text while they fit: short words
        // (the test font's glyphs stand a whole em wide, so "Settings"
        // fills its tab at its own size there).
        if (scale > 1) {
          Future<double> height(double s) async {
            await t.pumpWidget(
              _host(
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Fluent2NavigationBar(
                    items: _short,
                    selectedIndex: 2,
                    onDestinationSelected: (_) {},
                  ),
                ),
                s,
              ),
            );
            await t.pumpAndSettle();
            return _painted(_whole(t, bar, '$where short').first).height;
          }

          final grown = await height(scale);
          final rest = await height(1);
          expect(grown, greaterThan(rest), reason: '$where: never grew');
        }
      });
    }
  }

  for (final b in Brightness.values) {
    testWidgets('a row of four tabs fits a phone at text 2 (${b.name})', (
      t,
    ) async {
      t.view.physicalSize = const Size(390, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      for (final appearance in Fluent2TabAppearance.values) {
        for (final size in Fluent2TabSize.values) {
          await t.pumpWidget(
            _host(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  // Names that fit the row at their own size in the test
                  // font (whose glyphs stand a whole em wide), and run
                  // past it at the reader's twice.
                  child: Fluent2TabList(
                    tabs: const ['All', 'New', 'Top', 'Me'],
                    selectedIndex: 0,
                    appearance: appearance,
                    size: size,
                    onChanged: (_) {},
                  ),
                ),
              ),
              2,
              b: b,
            ),
          );
          await t.pumpAndSettle();
          final where = '${appearance.name} ${size.name}';
          final list = find.byType(Fluent2TabList);
          _whole(t, list, where);
          final scroll = t.state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          );
          expect(
            scroll.position.maxScrollExtent,
            0,
            reason: '$where: the row runs past the screen',
          );
          for (final e
              in find
                  .descendant(of: list, matching: find.byType(RichText))
                  .evaluate()) {
            final r = _painted(e.renderObject! as RenderParagraph);
            expect(r.right, lessThanOrEqualTo(390 - 16 + 0.5), reason: where);
          }
        }
      }
    });
  }

  // A short name, one that runs on to a second line (at 390) or (at 320, in
  // the test font's em-wide glyphs) shrinks to fit two, and one word beside
  // two commands, drawn smaller rather than broken.
  for (final (width, long) in [
    (390.0, 'Rail, pages and dots'),
    (320.0, 'Pages and dots'),
  ]) {
    testWidgets('a phone top bar keeps a long title whole at text 2, $width', (
      t,
    ) async {
      t.view.physicalSize = Size(width, 700);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      for (final (title, commands) in [
        ('Home', false),
        (long, false),
        ('Calendar', true),
      ]) {
        await t.pumpWidget(
          _host(
            Fluent2AccountScope(
              account: Fluent2Account(
                name: 'Ines Duarte',
                initials: 'ID',
                unread: 3,
                onProfile: (_) {},
                onNotifications: (_) {},
              ),
              child: RoutePresentationScope(
                presentation: RoutePresentation.root,
                child: Fluent2Scaffold(
                  topBar: Fluent2AppBar(
                    title: title,
                    caption: commands ? 'November 2026' : null,
                    actions: [
                      if (commands) ...[
                        Fluent2IconButton(
                          Fluent2Icons.calendarAdd,
                          label: 'New event',
                          onPressed: () {},
                        ),
                        Fluent2IconButton(
                          Fluent2Icons.filter,
                          label: 'Filter',
                          onPressed: () {},
                        ),
                      ],
                    ],
                  ),
                  body: const SizedBox(),
                ),
              ),
            ),
            2,
          ),
        );
        await t.pumpAndSettle();
        _whole(t, find.byType(Fluent2AppBar), 'title "$title"', wrap: true);
      }
    });
  }

  testWidgets('a breadcrumb keeps its current place whole at text 2', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    for (final size in Fluent2BreadcrumbSize.values) {
      await t.pumpWidget(
        _host(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Fluent2Breadcrumb(
                size: size,
                items: [
                  Fluent2BreadcrumbItem('Northwind', onPressed: () {}),
                  Fluent2BreadcrumbItem('Design', onPressed: () {}),
                  const Fluent2BreadcrumbItem('Brand guidelines.pdf'),
                ],
              ),
            ),
          ),
          2,
        ),
      );
      await t.pumpAndSettle();
      final crumb = find.byType(Fluent2Breadcrumb);
      for (final p in _whole(t, crumb, 'breadcrumb ${size.name}')) {
        expect(
          _painted(p).right,
          lessThanOrEqualTo(390 - 16 + 0.5),
          reason: 'breadcrumb ${size.name}: "${p.text.toPlainText()}"',
        );
      }
    }
  });
}
