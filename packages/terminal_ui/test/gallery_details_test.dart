// Details of the gallery's pages, pinned: a
// combobox's list goes over a field at the foot of the screen; the caret is
// a block on its own cell on every platform, and right to left the words
// typed start where the hint does; the keys' block shows on a chosen tab;
// a banner's title stands by its glyph right to left; the window list's
// names are on the character grid; a double frame's lines are whole pixels.
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's pages are the ones looked at.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/demos/pickers.dart';
import 'faces.dart';

Widget _host(
  Widget child, {
  TextDirection direction = TextDirection.ltr,
  AlignmentGeometry alignment = AlignmentDirectional.topStart,
  bool still = false,
}) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: still),
        child: TermTheme(
          data: TermThemeData.dark(),
          child: Builder(
            builder: (context) => ColoredBox(
              color: TermTheme.of(context).background,
              child: Align(alignment: alignment, child: child),
            ),
          ),
        ),
      ),
    ),
  ),
);

void _size(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}

Finder get _caretPaint => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_Caret',
);

void main() {
  setUpAll(loadFaces);

  group("a combobox's list", () {
    const branches = ['main', 'release/2.4', 'feat/main-menu'];

    Future<void> open(WidgetTester tester, AlignmentGeometry at) async {
      _size(tester, 390, 400);
      await tester.pumpWidget(
        _host(
          alignment: at,
          const SizedBox(
            width: 360,
            child: TermCombobox<String>(labelText: 'branch', options: branches),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.enterText(find.byType(EditableText), 'ma');
      await tester.pumpAndSettle();
    }

    testWidgets('opens under a field with the room for it', (tester) async {
      await open(tester, Alignment.topCenter);
      final field = tester.getRect(find.byType(TermTextField));
      for (final branch in ['main', 'feat/main-menu']) {
        final row = tester.getRect(find.text(branch));
        expect(row.top, greaterThanOrEqualTo(field.bottom), reason: branch);
        expect(row.bottom, lessThanOrEqualTo(400), reason: branch);
      }
    });

    testWidgets('goes over a field at the foot of the screen, whole', (
      tester,
    ) async {
      await open(tester, Alignment.bottomCenter);
      final field = tester.getRect(find.byType(TermTextField));
      expect(field.bottom, 400);
      final line = tester.element(find.byType(TermTextField)).termGrid;
      for (final branch in ['main', 'feat/main-menu']) {
        final row = tester.getRect(find.text(branch));
        expect(row.bottom, lessThanOrEqualTo(field.top), reason: branch);
        expect(row.top, greaterThanOrEqualTo(0), reason: branch);
        expect(row.height, line.lineHeight, reason: branch);
      }
      // Its frame sits on the field's.
      final pane = tester.getRect(
        find.ancestor(of: find.text('main'), matching: find.byType(TermPane)),
      );
      expect(pane.bottom, field.top);
    });

    for (final (width, height) in [(390.0, 844.0), (1440.0, 900.0)]) {
      testWidgets("the gallery's offline search says it is looking, then "
          'that it failed over the row that tries again, at '
          '${width.toInt()}', (tester) async {
        _size(tester, width, height);
        await tester.pumpWidget(kitPickersDemo(Brightness.dark));
        await tester.pumpAndSettle();
        final input = find.byType(EditableText).last;
        await tester.ensureVisible(input);
        await tester.pumpAndSettle();
        final field = find.ancestor(
          of: input,
          matching: find.byType(TermTextField),
        );
        // At the page's end the field stands at the foot of the screen.
        expect(height - tester.getRect(field).bottom, lessThan(144));
        await tester.tap(input);
        await tester.enterText(input, 'ma');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final grid = tester.element(field).termGrid;
        void whole(String words) {
          final rect = tester.getRect(find.text(words));
          expect(rect.height, grid.lineHeight, reason: words);
          expect(
            rect.bottom,
            lessThanOrEqualTo(tester.getRect(field).top),
            reason: words,
          );
          expect(rect.top, greaterThanOrEqualTo(0), reason: words);
        }

        whole('searching');
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 100));
        whole('search failed');
        whole('try again');
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      });
    }
  });

  group('the caret', () {
    Future<void> type(
      WidgetTester tester, {
      TextDirection direction = TextDirection.ltr,
      bool still = false,
    }) async {
      await tester.pumpWidget(
        _host(
          direction: direction,
          still: still,
          const SizedBox(
            width: 360,
            child: TermTextField(labelText: 'branch', hintText: 'type here'),
          ),
        ),
      );
      await tester.tap(find.byType(TermTextField));
      await tester.pump();
    }

    // The words typed, in the caret painter's box.
    Rect words(WidgetTester tester) {
      final editable = tester.renderObject<RenderEditable>(
        find.byElementPredicate((e) => e.renderObject is RenderEditable),
      );
      final ends = editable.getEndpointsForSelection(
        const TextSelection(baseOffset: 0, extentOffset: 2),
      );
      final paint = tester.renderObject<RenderBox>(_caretPaint);
      final xs = [
        for (final end in ends)
          paint.globalToLocal(editable.localToGlobal(end.point)).dx,
      ];
      return Rect.fromLTRB(
        xs.reduce((a, b) => a < b ? a : b),
        0,
        xs.reduce((a, b) => a > b ? a : b),
        paint.size.height,
      );
    }

    Rect? block(WidgetTester tester) {
      final paint = tester.renderObject<RenderBox>(_caretPaint);
      final accent = TermThemeData.dark().accent;
      Rect? found;
      // The first rectangle in the accent is the caret's.
      final matcher = paints
        ..something((method, arguments) {
          if (method != #drawRect) return false;
          if ((arguments[1] as Paint).color.toARGB32() != accent.toARGB32()) {
            return false;
          }
          found = arguments[0] as Rect;
          return true;
        });
      (matcher as Matcher).matches(paint, <dynamic, dynamic>{});
      return found;
    }

    for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
      testWidgets('is a block on the cell after the words on '
          '${platform.name}', (tester) async {
        debugDefaultTargetPlatformOverride = platform;
        await type(tester);
        final field = tester.widget<EditableText>(find.byType(EditableText));
        // Flutter's own caret is never shown and holds no room.
        expect(field.showCursor, isFalse);
        expect(field.cursorWidth, 0);
        final grid = tester.element(find.byType(TermTextField)).termGrid;
        // Empty: on the first cell, where the hint starts.
        final paint = tester.renderObject<RenderBox>(_caretPaint);
        final hint = paint.globalToLocal(
          tester.getTopLeft(find.text('type here')),
        );
        expect(block(tester)!.left, hint.dx);
        await tester.enterText(find.byType(EditableText), 'ma');
        await tester.pump();
        final typed = words(tester);
        final caret = block(tester)!;
        expect(typed.left, hint.dx);
        expect(typed.width, closeTo(grid.cols(2), 0.01));
        expect(caret.left, closeTo(typed.right, 0.01));
        expect(caret.width, grid.cellWidth);
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('right to left, the words start where the hint does and the '
        'block stands before them', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await type(tester, direction: TextDirection.rtl);
      final paint = tester.renderObject<RenderBox>(_caretPaint);
      final hint = paint
          .globalToLocal(tester.getTopRight(find.text('type here')))
          .dx;
      // The frame's inside: a cell in from the frame's line.
      expect(hint, closeTo(paint.size.width, 0.01));
      expect(block(tester)!.right, closeTo(hint, 0.01));
      await tester.enterText(find.byType(EditableText), 'ma');
      await tester.pump();
      final typed = words(tester);
      final caret = block(tester)!;
      expect(typed.right, closeTo(hint, 0.01));
      expect(caret.right, closeTo(typed.left, 0.01));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('blinks, and holds still under Reduce Motion', (tester) async {
      await type(tester);
      expect(block(tester), isNotNull);
      await tester.pump(const Duration(milliseconds: 500));
      expect(block(tester), isNull);
      await tester.pump(const Duration(milliseconds: 500));
      expect(block(tester), isNotNull);
      // An edit shows it again from the start.
      await tester.pump(const Duration(milliseconds: 500));
      expect(block(tester), isNull);
      await tester.enterText(find.byType(EditableText), 'm');
      await tester.pump();
      expect(block(tester), isNotNull);

      await type(tester, still: true);
      await tester.pump();
      for (var i = 0; i < 4; i++) {
        expect(block(tester), isNotNull);
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("the keys' cursor on a chosen tab goes hollow, in the accent", (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TermTabBar(
          tabs: const ['log', 'diff'],
          selectedIndex: 0,
          onTap: (_) {},
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final cursors = [
      for (final paint in tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      ))
        if (paint.painter is TermCursorPainter)
          paint.painter! as TermCursorPainter,
    ];
    expect(cursors, hasLength(1));
    expect(cursors.single.hollow, isTrue);
    expect(cursors.single.color, TermThemeData.dark().accent);
    expect(cursors.single.knockout, TermThemeData.dark().onAccent);
  });

  testWidgets("right to left, a banner's Latin title stands first, by its "
      'glyph', (tester) async {
    const banner = SizedBox(
      width: 720,
      child: TermBanner(
        title: 'degraded',
        message: 'builds queue longer than usual',
        tone: TermTone.warning,
      ),
    );
    await tester.pumpWidget(_host(banner, direction: TextDirection.rtl));
    final words = tester.renderObject<RenderParagraph>(
      find.textContaining('degraded', findRichText: true),
    );
    final text = words.text.toPlainText();
    Rect of(String part) {
      final at = text.indexOf(part);
      final boxes = words.getBoxesForSelection(
        TextSelection(baseOffset: at, extentOffset: at + part.length),
      );
      return boxes
          .map((b) => b.toRect())
          .reduce((a, b) => a.expandToInclude(b));
    }

    final title = of('degraded');
    final message = of('builds queue longer than usual');
    expect(title.left, greaterThan(message.right));
    final glyph = tester.getRect(find.text(TermTone.warning.glyph));
    final titleRight = words.localToGlobal(title.topRight).dx;
    expect(glyph.left - titleRight, closeTo(glyph.width, 0.01));
    // Left to right the words are as they were given.
    await tester.pumpWidget(_host(banner));
    expect(
      find.textContaining('degraded  builds', findRichText: true),
      findsOneWidget,
    );
  });

  for (final direction in TextDirection.values) {
    testWidgets("a phone's window list stands on the character grid "
        '${direction.name}', (tester) async {
      _size(tester, 390, 844);
      await tester.pumpWidget(
        _host(
          direction: direction,
          alignment: Alignment.bottomCenter,
          TermNavigationBar(
            destinations: const [
              TermNavigationDestination(label: 'runs'),
              TermNavigationDestination(label: 'deploys'),
              TermNavigationDestination(label: 'config'),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
        ),
      );
      final cw = tester
          .element(find.byType(TermNavigationBar))
          .termGrid
          .cellWidth;
      final names = ['1:runs*', '2:deploys ', '3:config '];
      final starts = <double>[];
      for (final name in names) {
        final rect = tester.getRect(find.text(name));
        final start = direction == TextDirection.ltr
            ? rect.left
            : 390 - rect.right;
        starts.add(start);
        expect(
          (start / cw - (start / cw).round()).abs(),
          lessThan(0.001),
          reason: '$name starts at $start',
        );
      }
      // Evenly apart, to a cell.
      final gaps = [
        starts[0] - cw,
        starts[1] - starts[0] - cw * (names[0].length + 2),
        starts[2] - starts[1] - cw * (names[1].length + 2),
      ];
      final least = gaps.reduce((a, b) => a < b ? a : b);
      final most = gaps.reduce((a, b) => a > b ? a : b);
      expect(most - least, lessThanOrEqualTo(cw + 0.001), reason: '$gaps');
    });
  }

  testWidgets("a phone's window list keeps a cell at each end when it has "
      'three to spare', (tester) async {
    _size(tester, 390, 844);
    await tester.pumpWidget(
      _host(
        alignment: Alignment.bottomCenter,
        TermNavigationBar(
          destinations: const [
            TermNavigationDestination(label: 'home'),
            TermNavigationDestination(label: 'runs'),
            TermNavigationDestination(label: 'deploy'),
            TermNavigationDestination(label: 'config'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
    );
    final cw = tester
        .element(find.byType(TermNavigationBar))
        .termGrid
        .cellWidth;
    // 40 cells of names in 43: a cell before the first, one in the middle
    // and one (and the odd pixels) after the last. A name's words stand a
    // cell inside its inverse cell.
    expect(tester.getRect(find.text('1:home*')).left, cw * 2);
    expect(tester.getRect(find.text('2:runs ')).left, cw * 11);
    expect(tester.getRect(find.text('3:deploy ')).left, cw * 21);
    expect(tester.getRect(find.text('4:config ')).left, cw * 32);
    expect(
      390 - tester.getRect(find.text('4:config ')).right,
      closeTo(cw * 2 + 3, 0.01),
    );
  });

  testWidgets("the inventory says 'on' only of what Terminal builds on", (
    tester,
  ) async {
    _size(tester, 1440, 900);
    await tester.pumpWidget(_host(const TermInventoryGallery()));
    await tester.pump();
    Future<void> row(String id, String said) async {
      final at = find.byKey(ValueKey<String>('inventory-$id'));
      await tester.scrollUntilVisible(
        at,
        600,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.descendant(of: at, matching: find.text(said)),
        findsOneWidget,
        reason: id,
      );
    }

    await row('NumberField', 'NumberField');
    await row('Rating', 'on DesignRating');
    await row('TimePicker', 'TimePicker');
    await row('WheelPicker', 'WheelPicker');
    await row('TabBar', 'on DesignTabBar');
    // A part left out that ui_core has long had a behaviour for says so
    // still.
    await row('CarouselView', 'on DesignCarousel');
    await row('BottomSheet', 'BottomSheet');
    await row('BarChart', 'BarChart');
    await row('LineChart', 'on DesignChart');
    await tester.pumpWidget(const SizedBox.shrink());
  }, experimentalLeakTesting: LeakTesting.settings.withIgnoredAll());

  testWidgets("a double frame's lines are whole pixels, sides and all", (
    tester,
  ) async {
    final theme = TermThemeData.dark();
    final grid = theme.grid;
    final size = Size(grid.cols(10), grid.lines(3));
    final recorder = ui.PictureRecorder();
    TermFramePainter(
      grid: grid,
      color: const Color(0xFFFFFFFF),
      stroke: theme.strokeWidth,
      doubled: 1,
    ).paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = (await tester.runAsync(
      () => picture.toImage(size.width.round(), size.height.round()),
    ))!;
    final rgba = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    int alpha(int x, int y) => rgba.getUint8((y * image.width + x) * 4 + 3);
    // Across the left and right sides, and down the top and bottom.
    final midY = image.height ~/ 2;
    final midX = image.width ~/ 2;
    final cw = grid.cellWidth.round();
    final lh = grid.lineHeight.round();
    final cuts = {
      'left': [for (var x = 0; x < cw; x++) alpha(x, midY)],
      'right': [
        for (var x = image.width - cw; x < image.width; x++) alpha(x, midY),
      ],
      'top': [for (var y = 0; y < lh; y++) alpha(midX, y)],
      'bottom': [
        for (var y = image.height - lh; y < image.height; y++) alpha(midX, y),
      ],
    };
    image.dispose();
    picture.dispose();
    for (final MapEntry(key: side, value: cut) in cuts.entries) {
      expect(
        cut.where((a) => a != 0 && a != 255),
        isEmpty,
        reason: '$side: $cut',
      );
      expect(cut.where((a) => a == 255), hasLength(2), reason: '$side: $cut');
    }
    // The pair stands evenly round the cell's middle on both sides.
    expect(cuts['right'], cuts['left']!.reversed.toList());
  });
}
