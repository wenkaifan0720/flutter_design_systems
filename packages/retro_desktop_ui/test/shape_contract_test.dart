import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

// The package reads the gallery from its example (a relative import); the demo art's import gets its own ignore.
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';

import 'shape_fit_test.dart' show shapeSpecimens;
import 'support.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../example/lib/demo_art.dart';

/// The look's two appearances; each brings its own corners and edges.
const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

/// Each appearance's shapes, by the appearance's name.
final families = <String, RetroDesktopShapes>{
  for (final f in appearances.entries) f.key: RetroDesktopShapes.of(f.value),
};

// The source barrel is scanned, rather than a gallery-only inventory. A newly
// exported widget fails until an actual specimen builds it in every family.
Set<String> exportedWidgets() {
  final barrel = [
    File('lib/src/retro_desktop.dart'),
    File('lib/src/retro_desktop.dart'),
  ].firstWhere((file) => file.existsSync());
  final classes = <String, String>{};
  final hidden = <String>{};
  for (final export in RegExp(
    r"export '([^']+)'([^;]*);",
    dotAll: true,
  ).allMatches(barrel.readAsStringSync())) {
    final uri = export[1]!;
    if (uri.contains(':')) continue;
    if (export[2]!.contains('hide')) {
      hidden.addAll(
        export[2]!.split('hide').last.split(',').map((s) => s.trim()),
      );
    }
    final file = File('${barrel.parent.path}/$uri');
    final source = file.readAsStringSync();
    for (final item in RegExp(
      r'^class ((?:Animated)?RetroDesktop\w+)(?:<[^\n]+?>)?\s+extends\s+(\w+)',
      multiLine: true,
    ).allMatches(source)) {
      classes[item[1]!] = item[2]!;
    }
  }
  bool widget(String type) =>
      type.endsWith('Widget') ||
      (classes.containsKey(type) && widget(classes[type]!));
  return {
    for (final entry in classes.entries)
      if (!hidden.contains(entry.key) && widget(entry.value)) entry.key,
  };
}

OutlinedBorder plain(ShapeBorder shape) =>
    (shape as OutlinedBorder).copyWith(side: BorderSide.none);

void checkOutline(ShapeBorder outline, RetroDesktopShapes shapes, String why) {
  final value = plain(outline);
  final allowed = [
    shapes.small,
    shapes.medium,
    shapes.large,
    shapes.full,
    shapes.radio,
    shapes.button,
  ];
  // Inset faces may reach zero radius/cut: that is the concentric result,
  // rather than an independent hard-coded square.
  const insets = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
  for (final inset in insets) {
    if (allowed.any(
      (shape) => plain(RetroDesktopShapes.inset(shape, inset)) == value,
    )) {
      return;
    }
  }
  // Content flush with an edge of its face takes the face's inner corners on
  // that edge and is square on the others (a picture's top, a first row).
  if (value is RoundedRectangleBorder) {
    final radii = {
      0.0,
      for (final inset in insets)
        for (final shape in allowed)
          if (RetroDesktopShapes.inset(shape, inset)
              case RoundedRectangleBorder(:final borderRadius))
            borderRadius.resolve(TextDirection.ltr).topLeft.x,
    };
    final r = value.borderRadius.resolve(TextDirection.ltr);
    if ([
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ].every((c) => c.x == c.y && radii.contains(c.x))) {
      return;
    }
  }
  fail('$why has $value outside its appearance\'s outlines');
}

// Flutter's own Material clips to its shape (a transparent Material hosts a
// field's editing overlays); that clip is the framework's, not the look's.
bool materialOwned(Element element) {
  var owned = false;
  var depth = 0;
  element.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString();
    if (ancestor.widget is Material || name.startsWith('_Material')) {
      owned = true;
      return false;
    }
    return ++depth < 4;
  });
  return owned;
}

// A box decoration may draw rules (one to three sides), a fill or a shadow
// in a family-shaped parent; it may never carry its own corner radius or a
// closed four-sided frame, which would be a shape outside the family.
void checkBox(BoxDecoration box, String why) {
  expect(box.borderRadius, isNull, reason: '$why hard-codes a corner radius');
  expect(box.shape, BoxShape.rectangle, reason: '$why hard-codes a circle');
  final border = box.border;
  if (border is Border) {
    final closed = [
      border.top,
      border.right,
      border.bottom,
      border.left,
    ].every((side) => side.style != BorderStyle.none && side.width > 0);
    expect(closed, isFalse, reason: '$why draws a closed square frame');
  }
}

// The look's painters that draw an outline carry it as a field; each must be
// one of the family's (or concentric with one).
int checkPainter(Object? painter, RetroDesktopShapes shapes, String why) {
  if (painter == null) return 0;
  final dynamic p = painter;
  switch (painter.runtimeType.toString()) {
    case '_SliderPainter':
      expect(plain(p.shapeDefault as OutlinedBorder), plain(shapes.small));
      expect(plain(p.trackShape as OutlinedBorder), plain(shapes.full));
      return 2;
    case '_GaugePainter':
    case '_BoxPainter':
    case '_CellPainter':
    case '_TilePainter':
    case '_NextPainter':
      checkOutline(
        p.shape as OutlinedBorder,
        shapes,
        '$why ${painter.runtimeType}',
      );
      return 1;
    case '_HatchTrack':
    case '_SpanPainter':
      expect(plain(p.track as OutlinedBorder), plain(shapes.full), reason: why);
      return 1;
    case '_ScalePainter':
      checkOutline(p.shape as OutlinedBorder, shapes, '$why knob');
      expect(plain(p.track as OutlinedBorder), plain(shapes.full), reason: why);
      return 2;
    case '_ProgressPainter':
      if (why == 'kitSpecimenCircularProgressIndicator') {
        checkOutline(p.shape as OutlinedBorder, shapes, why);
      } else if (why == 'kitSpecimenProgress') {
        expect((p.theme as RetroDesktopThemeData).shapes, shapes);
      }
      return 1;
  }
  return 0;
}

final helpers = <String, Widget Function(BuildContext)>{
  'inventory': (context) =>
      const SizedBox(height: 800, child: RetroDesktopInventoryGallery()),
  'stem charts': (context) => RetroDesktopColumn(
    children: [
      RetroDesktopLineChart(
        label: 'Visits',
        series: [
          RetroDesktopChartSeries('Visits', const [1, 2, 3]),
        ],
      ),
      RetroDesktopBarChart(
        label: 'Visits',
        series: [
          RetroDesktopChartSeries('Visits', const [1, 2, 3]),
        ],
      ),
      RetroDesktopAreaChart(
        label: 'Visits',
        series: [
          RetroDesktopChartSeries('Visits', const [1, 2, 3]),
        ],
      ),
      RetroDesktopPieChart(
        label: 'Visits',
        series: [
          RetroDesktopChartSeries('Visits', const [1, 2, 3]),
        ],
      ),
    ],
  ),
  // The catalog exports its demo art (the package keeps it in its example),
  // so each drawing needs a specimen of its own here.
  'demo art': (context) =>
      const SizedBox(width: 96, height: 96, child: RetroDesktopBeaconArt()),
  // The desk's own icons stand on the Papers desk, which no specimen shows.
  'desk icons': (context) => Row(
    children: [
      RetroDesktopDeskIcon(
        'Documents',
        art: const RetroDesktopSystemMark(size: 40),
        selected: true,
        onPressed: () {},
        onOpen: () {},
      ),
      const RetroDesktopDeskIcon('Bin', art: RetroDesktopSystemMark(size: 40)),
    ],
  ),
  'layout and type': (context) => RetroDesktopColumn(
    children: [
      RetroDesktopText(
        'Ordinary *text*',
        style: RetroDesktopTheme.of(context).type.body,
      ),
      RetroDesktopBalancedText(
        'Balanced heading',
        style: RetroDesktopTheme.of(context).type.head,
      ),
      const RetroDesktopEqualRow(
        flex: [1, 1],
        children: [Text('One'), Text('Two')],
      ),
      const RetroDesktopRow(
        spans: [6, 6],
        children: [Text('One'), Text('Two')],
      ),
      const RetroDesktopAutoRow(children: [Text('One'), Text('Two')]),
      const RetroDesktopGrow(child: Text('Growing text')),
      RetroDesktopPressable(
        label: 'Press',
        onPressed: () {},
        child: const Text('Press'),
      ),
      const RetroDesktopTriangleMark(AxisDirection.right),
      RetroDesktopDialogAction<bool>('Done', onPressed: () {}),
      SizedBox(
        height: 200,
        child: RetroDesktopTextContextMenu(
          anchors: const TextSelectionToolbarAnchors(
            primaryAnchor: Offset(150, 100),
          ),
          buttonItems: [ContextMenuButtonItem(label: 'Copy', onPressed: () {})],
        ),
      ),
      const RetroDesktopOnHighlight(child: Text('On highlight')),
      RetroDesktopBackButton(onPressed: () {}),
      const RetroDesktopSections(children: [Text('One'), Text('Two')]),
    ],
  ),
  'theme transition': (context) => AnimatedRetroDesktopTheme(
    data: RetroDesktopTheme.of(context),
    child: const Text('Theme'),
  ),
  'host': (context) => RetroDesktopHost(
    light: RetroDesktopTheme.of(context),
    dark: RetroDesktopTheme.of(context),
    child: const Text('Hosted'),
  ),
  'preview': (context) => SizedBox(
    height: 400,
    child: RetroDesktopPreview(
      light: RetroDesktopTheme.of(context),
      dark: RetroDesktopTheme.of(context),
      child: const RetroDesktopScaffold(body: Text('Preview')),
    ),
  ),
  'chrome scope': (context) => const RetroDesktopChromeScope(
    brand: 'Files',
    nav: [],
    active: 0,
    child: Text('Scoped'),
  ),
};

void main() {
  setUpAll(loadRetroDesktopFonts);
  test('nested rounded corners subtract the actual inset', () {
    const outer = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    );
    final inner = RetroDesktopShapes.inset(outer, 3) as RoundedRectangleBorder;
    expect(inner.borderRadius, const BorderRadius.all(Radius.circular(5)));
    expect(
      (RetroDesktopShapes.inset(
        outer,
        20,
      ) as RoundedRectangleBorder).borderRadius,
      BorderRadius.zero,
    );
  });
  for (final family in families.entries) {
    testWidgets('${family.key} nested controls keep their role and inset', (
      tester,
    ) async {
      final theme = RetroDesktopThemeData.classic().copyWith(
        appearance: appearances[family.key]!,
      );
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => RetroDesktopTheme(data: theme, child: child!),
          home: Center(
            child: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RetroDesktopSwitch(
                    value: true,
                    label: 'Sync',
                    onChanged: (_) {},
                  ),
                  RetroDesktopSegmentedButton<String>(
                    label: 'View',
                    value: 'list',
                    segments: const [
                      RetroDesktopButtonSegment('list', 'List'),
                      RetroDesktopButtonSegment('grid', 'Grid'),
                    ],
                    onChanged: (_) {},
                  ),
                  RetroDesktopRadioGroup<String>(
                    label: 'Save',
                    value: 'local',
                    options: const [
                      RetroDesktopRadio('local', 'Local'),
                      RetroDesktopRadio('cloud', 'Cloud'),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      List<OutlinedBorder> clips(Finder parent) => [
        for (final item
            in find
                .descendant(of: parent, matching: find.byType(ClipPath))
                .evaluate())
          if ((item.widget as ClipPath).clipper is ShapeBorderClipper)
            plain(
              ((item.widget as ClipPath).clipper! as ShapeBorderClipper).shape,
            ),
      ];
      // A face clips what it holds inside its rim, concentric with it.
      OutlinedBorder content(OutlinedBorder shape, double side) => plain(
        RetroDesktopShapes.inset(
          shape,
          side +
              (shape is RetroDesktopBorder ? shape.cut : 0) +
              theme.strokes.hairline,
        ),
      );
      expect(
        clips(find.byType(RetroDesktopSwitch)).first,
        content(family.value.full, theme.strokes.regular),
      );
      // The lever is a small raised face in the track: its bevel carries
      // the outline it draws.
      final dynamic lever = tester
          .widgetList<RetroDesktopPixelPaint>(
            find.descendant(
              of: find.byType(AnimatedAlign),
              matching: find.byType(RetroDesktopPixelPaint),
            ),
          )
          .map((paint) => paint.painter)
          .firstWhere((p) => p.runtimeType.toString() == '_BevelPainter');
      expect(
        plain(lever.shape as OutlinedBorder),
        plain(
          RetroDesktopShapes.inset(
            family.value.full,
            theme.strokes.regular + theme.strokes.hairline + 2,
          ),
        ),
      );
      final segmentClips = clips(
        find.byType(RetroDesktopSegmentedButton<String>),
      );
      // Cells: Platinum frames them in one outline of the button shape,
      // unbevelled, so its content is clipped a rim inside it; Chisel sets
      // its square buttons side by side with no frame.
      final frame = family.value.button;
      final rim = theme.chisel ? 0.0 : theme.strokes.regular;
      final inner = rim == 0 ? frame : RetroDesktopShapes.inset(frame, rim);
      // Each cell keeps the frame's inner corners on the ends it meets and
      // is square where it meets a neighbour.
      OutlinedBorder cell({required bool first, required bool last}) {
        if (inner is! RoundedRectangleBorder) {
          return first && last ? inner : const RetroDesktopBorder.square();
        }
        final r = inner.borderRadius.resolve(TextDirection.ltr);
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: first ? r.topLeft : Radius.zero,
            bottomLeft: first ? r.bottomLeft : Radius.zero,
            topRight: last ? r.topRight : Radius.zero,
            bottomRight: last ? r.bottomRight : Radius.zero,
          ),
        );
      }

      final cellClips = rim == 0 ? segmentClips : segmentClips.skip(1);
      if (rim > 0) {
        expect(
          segmentClips.first,
          plain(inner),
          reason: 'the frame clips its cells a rim inside it: $segmentClips',
        );
      }
      expect(cellClips, hasLength(2), reason: '$segmentClips');
      for (final (index, clip) in cellClips.indexed) {
        final shape = cell(first: index == 0, last: index == 1);
        expect(
          clip,
          anyOf(content(shape, theme.strokes.regular), content(shape, 0)),
          reason: 'cell $index of $segmentClips',
        );
      }
      expect(
        clips(find.byType(RetroDesktopRadioGroup<String>)),
        everyElement(plain(family.value.radio)),
      );
      // The chosen radio's dot, in the face's ink: the one painted dot.
      final dots = find.descendant(
        of: find.byType(RetroDesktopRadioGroup<String>),
        matching: find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is ShapeDecoration &&
              ((w.decoration as ShapeDecoration).color?.a ?? 0) > 0,
        ),
      );
      expect(dots, findsOneWidget);
      expect(
        plain(
          (tester.widget<DecoratedBox>(dots).decoration as ShapeDecoration)
              .shape,
        ),
        plain(family.value.radio),
      );
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      '${family.key} open dropdown carries the family and field width',
      (tester) async {
        final theme = RetroDesktopThemeData.classic().copyWith(
          appearance: appearances[family.key]!,
        );
        // On a phone the select fills its field, and its list the field's
        // width; from 600 up the face hugs its value, as a popup does.
        tester.view.physicalSize = const Size(390, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            builder: (_, child) =>
                RetroDesktopTheme(data: theme, child: child!),
            home: Center(
              child: SizedBox(
                width: 320,
                child: RetroDesktopSelect<String>(
                  label: 'Storage',
                  value: 'local',
                  onChanged: (_) {},
                  options: const [
                    RetroDesktopOption('local', 'Local'),
                    RetroDesktopOption('cloud', 'Cloud'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Local'));
        await tester.pumpAndSettle();
        final field = find.byType(RetroDesktopSelect<String>);
        final menu = find.byType(RetroDesktopMenu<String>);
        expect(menu, findsOneWidget);
        expect(tester.getSize(menu).width, tester.getSize(field).width);
        final menuClip = tester.widget<ClipPath>(
          find.descendant(of: menu, matching: find.byType(ClipPath)).first,
        );
        expect(
          plain((menuClip.clipper! as ShapeBorderClipper).shape),
          plain(
            RetroDesktopShapes.inset(
              family.value.medium,
              theme.strokes.regular +
                  (family.value.medium is RetroDesktopBorder
                      ? (family.value.medium as RetroDesktopBorder).cut
                      : 0) +
                  theme.strokes.hairline,
            ),
          ),
        );
        for (final barrier in tester.widgetList<ModalBarrier>(
          find.byType(ModalBarrier),
        )) {
          expect(barrier.color, anyOf(isNull, const Color(0x00000000)));
        }
        expect(tester.takeException(), isNull);
      },
    );
    for (final brightness in Brightness.values) {
      testWidgets(
        '${family.key} $brightness covers every exported widget and face',
        (tester) async {
          tester.view.physicalSize = const Size(390, 1600);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final theme = RetroDesktopThemeData.classic(brightness)
              .copyWith(appearance: appearances[family.key]!);
          kitShownTheme = (b) =>
              RetroDesktopThemeData.classic(b)
                  .copyWith(appearance: appearances[family.key]!);
          addTearDown(() => kitShownTheme = null);
          final built = <String>{};
          var faces = 0;
          for (final specimen in <String, Widget Function(BuildContext)>{
            for (final entry in shapeSpecimens.entries)
              entry.key: (_) => entry.value(),
            ...helpers,
          }.entries) {
            await tester.pumpWidget(
              MaterialApp(
                builder: (context, child) =>
                    RetroDesktopTheme(data: theme, child: child!),
                home: Builder(
                  builder: (context) => KeyedSubtree(
                    key: ValueKey(specimen.key),
                    child: specimen.key == 'kitSpecimenScreen'
                        ? specimen.value(context)
                        : SingleChildScrollView(child: specimen.value(context)),
                  ),
                ),
              ),
            );
            await tester.pump();
            expect(tester.takeException(), isNull, reason: specimen.key);
            for (final element
                in find
                    .byWidgetPredicate((_) => true, skipOffstage: false)
                    .evaluate()) {
              built.add(element.widget.runtimeType.toString().split('<').first);
              final widget = element.widget;
              if (widget is ClipPath &&
                  widget.clipper is ShapeBorderClipper &&
                  !materialOwned(element)) {
                checkOutline(
                  (widget.clipper! as ShapeBorderClipper).shape,
                  family.value,
                  specimen.key,
                );
                faces++;
              }
              if (widget is DecoratedBox &&
                  widget.decoration is BoxDecoration) {
                checkBox(widget.decoration as BoxDecoration, specimen.key);
              }
              if (widget is Container && widget.decoration is BoxDecoration) {
                checkBox(widget.decoration! as BoxDecoration, specimen.key);
              }
              if (widget is DecoratedBox &&
                  widget.decoration is ShapeDecoration) {
                checkOutline(
                  (widget.decoration as ShapeDecoration).shape,
                  family.value,
                  specimen.key,
                );
                faces++;
              }
              if (widget is CustomPaint) {
                faces += checkPainter(
                  widget.painter,
                  family.value,
                  specimen.key,
                );
                faces += checkPainter(
                  widget.foregroundPainter,
                  family.value,
                  specimen.key,
                );
              }
              if (widget is RetroDesktopPixelPaint) {
                faces += checkPainter(
                  widget.painter,
                  family.value,
                  specimen.key,
                );
              }
            }
          }
          final expected = exportedWidgets();
          // The source-only router adapter is exercised by navigation_layout_test;
          // its dependency cannot appear in the standalone UI package.
          expected.remove('RetroDesktopShell');
          expect(
            expected.difference(built),
            isEmpty,
            reason: 'An exported component needs an actual specimen.',
          );
          expect(faces, greaterThan(180));
          debugPrint(
            'SHAPE CONTRACT ${family.key}/${brightness.name}: ${expected.length} exported widgets, $faces outlines',
          );
        },
      );
    }
  }
}
