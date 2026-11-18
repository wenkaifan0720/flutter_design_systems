// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/demos/history.dart';
import '../example/lib/kit_gallery/demos/permits.dart';
import '../example/lib/kit_gallery/demos/tables.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

const _stage = ValueKey('painted stage');
const _places = [
  CivicNavItem(LucideIcons.house, 'Home'),
  CivicNavItem(LucideIcons.fileText, 'Applications'),
  CivicNavItem(LucideIcons.circleUser, 'Account'),
];

Future<void> _show(
  WidgetTester t,
  Widget app, {
  double width = 390,
  double scale = 2,
}) async {
  t.view.physicalSize = Size(width, 1000) * 2;
  t.view.devicePixelRatio = 2;
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.view.reset);
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  await t.pumpWidget(RepaintBoundary(key: _stage, child: app));
  await t.pumpAndSettle();
}

double _baseline(RenderParagraph paragraph) {
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    locale: paragraph.locale,
    textHeightBehavior: paragraph.textHeightBehavior,
  )..layout(maxWidth: paragraph.size.width);
  final baseline = painter.computeLineMetrics().first.baseline;
  painter.dispose();
  return paragraph.localToGlobal(Offset(0, baseline)).dy;
}

Future<Color Function(Offset)> _pixels(WidgetTester t) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_stage));
  final (width, bytes) = (await t.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final width = image.width;
    image.dispose();
    return (width, data);
  }))!;
  return (Offset point) {
    final local = boundary.globalToLocal(point) * 2;
    final i = (local.dy.floor() * width + local.dx.floor()) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  };
}

void main() {
  setUpAll(loadScreenFonts);
  for (final direction in TextDirection.values) {
    testWidgets(
      'large attached filenames and sortable headings keep whole words in ${direction.name}',
      (t) async {
        const name = 'tenancy-agreement.pdf';
        await _show(
          t,
          kitApp(
            brightness: Brightness.light,
            direction: direction,
            home: Align(
              alignment: AlignmentDirectional.topStart,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CivicFileUpload(
                  chooseLabel: 'Choose file',
                  emptyLabel: 'No file chosen',
                  fileName: name,
                  removeLabel: 'Remove',
                  onChoose: () {},
                  onRemoved: () {},
                ),
              ),
            ),
          ),
        );
        final file = t.renderObject<RenderParagraph>(find.text(name));
        final extension = file.getBoxesForSelection(
          const TextSelection(
            baseOffset: name.length - 4,
            extentOffset: name.length,
          ),
        );
        for (final box in extension) {
          final rect = box.toRect().shift(file.localToGlobal(Offset.zero));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(390));
        }
        expect(t.takeException(), isNull);
        await _show(
          t,
          Directionality(
            textDirection: direction,
            child: kitTablesDemo(Brightness.light),
          ),
        );
        for (final heading in ['Vehicle', 'Zone', 'Days left']) {
          final p = t.renderObject<RenderParagraph>(find.text(heading));
          expect(
            p.getMinIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(p.size.width + 0.1),
            reason: heading,
          );
          expect(p.didExceedMaxLines, isFalse, reason: heading);
        }
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'destination type follows the requested size in ${direction.name}',
      (t) async {
        for (final width in [390.0, 768.0]) {
          final widget = CivicNavigationBar(
            destinations: _places,
            selectedIndex: 1,
            onDestinationSelected: (_) {},
          );
          await _show(
            t,
            kitApp(
              brightness: Brightness.light,
              direction: direction,
              home: CivicScaffold(
                body: const SizedBox(),
                navigationBar: widget,
              ),
            ),
            width: width,
          );
          final p = t.renderObject<RenderParagraph>(find.text('Applications'));
          expect(p.textScaler.scale(15), 30);
          expect(
            p.getMinIntrinsicWidth(double.infinity),
            lessThanOrEqualTo(p.size.width + 0.5),
          );
          expect(
            p.localToGlobal(const Offset(0, 1)).dy -
                p.localToGlobal(Offset.zero).dy,
            closeTo(1, 0.01),
          );
          expect(t.takeException(), isNull);
        }
      },
    );

    testWidgets(
      'the scroll cue preserves the entire selected tab marker in ${direction.name}',
      (t) async {
        var index = 0;
        await _show(
          t,
          kitApp(
            brightness: Brightness.light,
            direction: direction,
            home: Align(
              alignment: Alignment.topCenter,
              child: StatefulBuilder(
                builder: (context, set) => CivicTabBar(
                  tabs: const ['Details', 'Documents', 'History', 'Renewals'],
                  selectedIndex: index,
                  onTap: (i) => set(() => index = i),
                ),
              ),
            ),
          ),
        );
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.sendKeyEvent(
          direction == TextDirection.ltr
              ? LogicalKeyboardKey.arrowRight
              : LogicalKeyboardKey.arrowLeft,
        );
        await t.pumpAndSettle();
        expect(index, 1);
        // Clear the yellow keyboard focus to expose the selected blue bar.
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        final paint = find
            .ancestor(
              of: find.text('Documents'),
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.foregroundPainter != null,
              ),
            )
            .first;
        final rect = t.getRect(paint);
        final sample = await _pixels(t);
        final ink = t.element(paint).civicTheme.action;
        final y = rect.bottom - 2;
        for (final x in [rect.left + 1, rect.center.dx, rect.right - 1]) {
          expect(sample(Offset(x, y)), ink, reason: 'marker at $x / $rect');
        }
      },
    );
  }

  testWidgets(
    'underlining keeps the same text baseline and paints just one back glyph',
    (t) async {
      final heights = <double>[];
      for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
        await _show(
          t,
          kitApp(
            brightness: Brightness.light,
            direction: dir,
            home: Column(
              children: [
                CivicTabBar(
                  tabs: const ['Active', 'Baseline'],
                  selectedIndex: 0,
                  onTap: (_) {},
                ),
                CivicBackLink(label: 'Back', onPressed: () {}),
              ],
            ),
          ),
        );
        final p = t.renderObject<RenderParagraph>(find.text('Baseline').last);
        heights.add(_baseline(p));
        expect(find.byIcon(LucideIcons.chevronLeft), findsOneWidget);
        final icon = t.getRect(find.byIcon(LucideIcons.chevronLeft));
        final pixels = await _pixels(t);
        // The two arms meet on one horizontal row at the tip.
        final x = dir == TextDirection.ltr
            ? icon.left + icon.width * 0.34
            : icon.right - icon.width * 0.34;
        final bands = <int>[];
        var previous = false;
        for (var i = 0; i < (icon.height * 2).round(); i++) {
          final color = pixels(Offset(x, icon.top + (i + .5) / 2));
          final ink = color.computeLuminance() < 0.3;
          if (ink && !previous) bands.add(i);
          previous = ink;
        }
        expect(bands, hasLength(1));
      }
      expect(heights.first, closeTo(heights.last, 0.5));
    },
  );

  testWidgets(
    'header titles align with the service name and grow with the text',
    (t) async {
      for (final scale in [1.0, 2.0]) {
        await _show(
          t,
          const CivicPreview(
            tabs: _places,
            activeIndex: 0,
            brand: 'Brindlemere parking permits',
            child: CivicScreen(
              topBar: CivicTopBar(title: 'Applications'),
              body: SizedBox(),
            ),
          ),
          width: 1440,
          scale: scale,
        );
        final brand = t.renderObject<RenderParagraph>(
          find.text('Brindlemere parking permits'),
        );
        final title = t.renderObject<RenderParagraph>(
          find.descendant(
            of: find.byType(CivicTopBar),
            matching: find.text('Applications'),
          ),
        );
        expect(_baseline(brand), closeTo(_baseline(title), 1));
        if (scale == 2) {
          expect(
            t.getSize(find.byType(CivicTopBar)).height,
            greaterThan(CivicTopBar.height + CivicTopBar.ruleHeight + 8),
          );
        }
      }
      await _show(
        t,
        kitApp(
          brightness: Brightness.light,
          home: Align(
            alignment: Alignment.topCenter,
            child: CivicTopBar(
              title: 'Brindlemere parking permits',
              emblem: const KitEmblem(),
              onTitlePressed: () {},
              actions: [
                CivicIconButton(
                  semanticLabel: 'Account',
                  icon: LucideIcons.user,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final long = t.renderObject<RenderParagraph>(
        find.text('Brindlemere parking permits'),
      );
      expect(long.didExceedMaxLines, isFalse);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'the embedded service and timeline use Arabic in the RTL gallery',
    (t) async {
      await _show(
        t,
        Directionality(
          textDirection: TextDirection.rtl,
          child: kitPermitsDemo(Brightness.dark),
        ),
      );
      final label = find.text('Brindlemere parking permits');
      expect(label, findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Text && (w.data ?? '').contains('تصريح'),
        ),
        findsWidgets,
      );
      await _show(
        t,
        Directionality(
          textDirection: TextDirection.rtl,
          child: kitHistoryDemo(Brightness.dark),
        ),
      );
      expect(find.text('تمت الموافقة على التصريح'), findsOneWidget);
      final p = t.renderObject<RenderParagraph>(find.text('٧ نوفمبر ٢٠٢٦'));
      final day = p
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single;
      final year = p
          .getBoxesForSelection(
            const TextSelection(baseOffset: 8, extentOffset: 9),
          )
          .single;
      expect(day.left, greaterThan(year.left));
    },
  );
}
