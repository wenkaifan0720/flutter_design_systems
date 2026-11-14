/// Every part reserves space for what it paints, at each density.
library;

import 'dart:ui' show BoxHeightStyle;

import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

final _theme = ExpressiveThemeData.preset('baseline', Brightness.light);
const _densities = [
  ExpressiveDensity.standard,
  ExpressiveDensity.comfortable,
  ExpressiveDensity.compact,
];

// Ignore pixels outside a scroll viewport, but never the surface's shape clip:
// that clip must not conceal an incorrect content inset from this test.
Rect? _visibleRect(WidgetTester tester, Element element, {Rect? localBounds}) {
  // Icon's outer box can be stretched by its parent; its RichText is the
  // painted glyph. Include ancestor transforms (FittedBox, rotating chevrons).
  final painted = element.widget is Icon
      ? find
            .descendant(
              of: find.byElementPredicate((e) => e == element),
              matching: find.byType(RichText),
            )
            .evaluate()
            .single
      : element;
  final box = painted.findRenderObject()! as RenderBox;
  var rect = MatrixUtils.transformRect(
    box.getTransformTo(null),
    localBounds ?? box.paintBounds,
  );
  if (element.widget case Text(:final data)
      when data?.trim().isEmpty ?? false) {
    return null;
  }
  RenderObject? ancestor = box.parent;
  while (ancestor != null) {
    if (ancestor is RenderOpacity && ancestor.opacity == 0) return null;
    if (ancestor is RenderOffstage && ancestor.offstage) return null;
    // A frame that clips its children square (a carousel's): what lies past
    // it is never painted, so no part's shape needs to hold it.
    if (ancestor is RenderClipRect && ancestor.clipper == null) {
      rect = rect.intersect(
        ancestor.localToGlobal(Offset.zero) & ancestor.size,
      );
      if (rect.isEmpty) return null;
    }
    if (ancestor is RenderBox && ancestor is RenderAbstractViewport) {
      final dynamic viewport = ancestor;
      if (viewport.clipBehavior != Clip.none) {
        rect = rect.intersect(
          ancestor.localToGlobal(Offset.zero) & ancestor.size,
        );
        if (rect.isEmpty) return null;
      }
    }
    ancestor = ancestor.parent;
  }
  return rect;
}

// The loading morph draws a smaller path inside its 48dp canvas. Measure the
// actual painted glyph, including its rotation, rather than the canvas's box.
Path _loadingPaintPath(CustomPainter painter, Size size) {
  var transform = Matrix4.identity();
  final stack = <Matrix4>[];
  Path? painted;
  expect(
    (Canvas canvas) => painter.paint(canvas, size),
    paints..everything((method, arguments) {
      switch (method) {
        case #save:
          stack.add(transform.clone());
        case #restore:
          transform = stack.removeLast();
        case #translate:
          transform.translateByDouble(
            (arguments[0] as num).toDouble(),
            (arguments[1] as num).toDouble(),
            0,
            1,
          );
        case #rotate:
          transform.rotateZ((arguments[0] as num).toDouble());
        case #drawPath:
          final drawn = (arguments[0] as Path).transform(transform.storage);
          painted = painted == null
              ? drawn
              : Path.combine(PathOperation.union, painted!, drawn);
        default:
          fail('Unmeasured loading-painter operation: $method');
      }
      return true;
    }),
  );
  expect(painted, isNotNull);
  expect(stack, isEmpty);
  return painted!;
}

void _inside(Path path, Rect content, String reason) {
  expect(content.isEmpty, isFalse, reason: '$reason has no visible content');
  final rect = content.deflate(1);
  if (rect.isEmpty) return;
  for (final point in [
    rect.topLeft,
    rect.topCenter,
    rect.topRight,
    rect.centerLeft,
    rect.centerRight,
    rect.bottomLeft,
    rect.bottomCenter,
    rect.bottomRight,
  ]) {
    expect(path.contains(point), isTrue, reason: '$reason at $point');
  }
}

void main() {
  for (final area in [false, true]) {
    testWidgets(
      '${area ? "area" : "field"} contains editing content under every offered setting',
      (tester) async {
        final controller = TextEditingController(
          text: 'A longer line of words for a narrow field',
        );
        for (final density in _densities) {
          for (final width in [120.0, 240.0, 390.0]) {
            for (final scale in [1.0, 1.3]) {
              await tester.pumpWidget(
                MaterialApp(
                  home: ExpressiveHost(
                    light: _theme.copyWith(density: density),
                    brightness: Brightness.light,
                    child: MediaQuery(
                      data: MediaQueryData(
                        textScaler: TextScaler.linear(scale),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: width,
                          child: area
                              ? ExpressiveTextArea(controller: controller)
                              : ExpressiveTextField(controller: controller),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final faceFinder = find.byWidgetPredicate(
                (w) => w.runtimeType.toString() == '_FieldLayout',
              );
              final face = tester.getRect(faceFinder);
              final dynamic layout = tester.widget(faceFinder);
              final shape = layout.shape as OutlinedBorder;
              _inside(
                shape.getOuterPath(Offset.zero & face.size),
                tester.getRect(find.byType(EditableText)).shift(-face.topLeft),
                '$density $width $scale',
              );
              expect(tester.takeException(), isNull);
            }
          }
        }
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      },
    );
  }

  testWidgets('code cells contain their digits at narrow widths', (
    tester,
  ) async {
    final controller = TextEditingController(text: '123456');
    for (final density in _densities) {
      for (final width in [120.0, 240.0, 390.0]) {
        for (final scale in [1.0, 1.3]) {
          await tester.pumpWidget(
            MaterialApp(
              home: ExpressiveHost(
                light: _theme.copyWith(density: density),
                brightness: Brightness.light,
                child: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Center(
                    child: SizedBox(
                      width: width,
                      child: ExpressiveInputOtp(controller: controller),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final cells = find.byWidgetPredicate(
            (w) =>
                w is CustomPaint &&
                w.painter.runtimeType.toString() == '_CellPainter',
          );
          expect(cells, findsNWidgets(6));
          for (final element in cells.evaluate()) {
            final finder = find.byElementPredicate((e) => e == element);
            final face = tester.getRect(finder);
            final dynamic painter = (element.widget as CustomPaint).painter;
            final shape = painter.shape as OutlinedBorder;
            final digit = find.descendant(
              of: finder,
              matching: find.byType(Text),
            );
            _inside(
              shape.getOuterPath(Offset.zero & face.size),
              _visibleRect(
                tester,
                digit.evaluate().single,
              )!.shift(-face.topLeft),
              '$width $scale $density',
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  final destinations = [
    const ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
    const ExpressiveNavItem(ExpressiveSymbols.explore, 'Explore'),
    const ExpressiveNavItem(ExpressiveSymbols.person, 'Profile'),
  ];
  final controls = <String, Widget Function()>{
    for (final interactive in [false, true])
      'carousel interactive=$interactive': () =>
          ExpressiveCarouselView.uncontained(
            itemCount: 3,
            itemWidth: 160,
            height: 120,
            onItemTap: interactive ? (_) {} : null,
            itemBuilder: (context, index) {
              final info = ExpressiveCarouselItemInfo.of(context);
              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: info.contentRect.deflate(12),
                    child: Center(
                      child: Text(
                        'Place',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
    'page dots': () =>
        ExpressivePageDots(count: 8, selectedIndex: 2, onChanged: (_) {}),

    'bar chart': () => const ExpressiveChart.bar(
      points: [
        ExpressiveChartPoint('Mon', 2),
        ExpressiveChartPoint('Tue', 5),
        ExpressiveChartPoint('Wed', 3),
      ],
    ),
    'scaled chart': () => const ExpressiveChart.line(
      points: [
        ExpressiveChartPoint('Mon', 72),
        ExpressiveChartPoint('Tue', 76),
        ExpressiveChartPoint('Wed', 74),
      ],
      domain: ExpressiveChartDomain.fixed(60, 90, step: 10),
      labels: ExpressiveChartLabels.sparse,
    ),

    'linear progress': () => const ExpressiveLinearProgressIndicator(value: .4),
    'circular progress': () =>
        const ExpressiveCircularProgressIndicator(value: .4),
    'wavy linear progress': () => const ExpressiveHeroMoment(
      child: ExpressiveLinearProgressIndicator(value: .4, wavy: true),
    ),
    'wavy circular progress': () => const ExpressiveHeroMoment(
      child: ExpressiveCircularProgressIndicator(value: .4, wavy: true),
    ),
    'meter': () => const ExpressiveMeter(
      label: 'Storage',
      value: 148,
      limit: 200,
      note: '52 GB left',
    ),
    for (final kind in ExpressiveStepProgressKind.values)
      'steps $kind': () => ExpressiveStepProgress(
        count: 3,
        currentStep: 1,
        labels: const ['Prepare', 'Review', 'Complete'],
        kind: kind,
      ),
    'loading state': () => const SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveLoadingState(),
    ),
    'placeholder frame': () =>
        const SizedBox(height: 72, child: ExpressiveImagePlaceholder()),
    'skeleton circle': () => const ExpressiveSkeleton.circle(size: 48),
    'skeleton text': () => const ExpressiveSkeleton.text(),

    'loading container': () =>
        const ExpressiveLoadingIndicator(contained: true, progress: .5),
    'empty state': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveEmptyState(
        icon: ExpressiveSymbols.inbox,
        title: 'Nothing here',
        body: 'Add a first item',
        actionLabel: 'Add',
        onAction: () {},
      ),
    ),
    'success state': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveSuccessState(
        title: 'Saved',
        message: 'Your item is ready',
        actionLabel: 'Done',
        onAction: () {},
      ),
    ),
    'error state': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveErrorState(
        title: 'Try again',
        message: 'Please try again',
        onRetry: () {},
      ),
    ),
    'image frame': () =>
        const ExpressiveMedia(slotId: 'containment-image', aspectRatio: 16 / 9),
    'skeleton frame': () => const ExpressiveSkeleton(height: 48),

    for (final position in ExpressiveNavItemPosition.values)
      'navigation bar $position': () => ExpressiveNavigationBar(
        destinations: destinations,
        selectedIndex: 0,
        itemPosition: position,
        onDestinationSelected: (_) {},
      ),
    'navigation rail': () => SizedBox(
      height: 400,
      child: ExpressiveNavigationRail(
        destinations: destinations,
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    ),
    for (final scrollable in [false, true])
      'tabs scroll=$scrollable': () => ExpressiveTabBar(
        tabs: const [
          ExpressiveTab(label: 'Home', icon: ExpressiveSymbols.home),
          ExpressiveTab(label: 'Explore', icon: ExpressiveSymbols.explore),
          ExpressiveTab(label: 'Profile', icon: ExpressiveSymbols.person),
        ],
        selectedIndex: 0,
        scrollable: scrollable,
        onChanged: (_) {},
      ),
    'interactive rating': () => ExpressiveRating(value: 3.5, onChanged: (_) {}),
    'read-only rating': () => const ExpressiveRating(value: 3.5),
    for (final ruled in [false, true])
      '${ruled ? 'ruled' : 'stacked'} table': () => SingleChildScrollView(
        clipBehavior: Clip.none,
        child: ExpressiveTable(
          stackBelow: ruled
              ? ExpressiveWindowSizeClass.compact
              : ExpressiveWindowSizeClass.medium,
          columns: const [
            ExpressiveTableColumn('Plant'),
            ExpressiveTableColumn('Water'),
          ],
          rows: [
            ExpressiveTableRow(
              const ['A longer plant name', '200 millilitres'],
              selected: true,
              onPressed: () {},
            ),
            const ExpressiveTableRow(['A static plant', '50 millilitres']),
          ],
        ),
      ),
    'time dial': () => const _TimeCase(ExpressiveTimePickerMode.dial),
    'vibrant time dial': () =>
        const _TimeCase(ExpressiveTimePickerMode.dial, vibrant: true),
    'horizontal time dial': () =>
        const _TimeCase(ExpressiveTimePickerMode.dial, horizontal: true),
    'time input': () => const _TimeCase(ExpressiveTimePickerMode.input),
    'vibrant time input': () =>
        const _TimeCase(ExpressiveTimePickerMode.input, vibrant: true),
    'time scroll': () => const _TimeCase(ExpressiveTimePickerMode.scroll),
    'number scroll': () =>
        ExpressiveScrollField(itemCount: 60, value: 15, onChanged: (_) {}),
    'time dialog': () => ExpressiveTimePickerDialog(
      title: 'Select time',
      confirm: ExpressiveTextButton('OK', onPressed: () {}),
      dismiss: ExpressiveTextButton('Cancel', onPressed: () {}),
      modeToggle: ExpressiveTimePickerModeToggle(
        mode: ExpressiveTimePickerMode.dial,
        onChanged: (_) {},
      ),
      child: const _TimeCase(ExpressiveTimePickerMode.dial),
    ),
    'date dialog': () => ExpressiveDatePickerDialog(
      confirm: ExpressiveTextButton('OK', onPressed: () {}),
      dismiss: ExpressiveTextButton('Cancel', onPressed: () {}),
      child: ExpressiveDatePicker(
        selected: DateTime(2026, 6, 15),
        currentDate: DateTime(2026, 6, 15),
        firstYear: 2026,
        lastYear: 2026,
        onChanged: (_) {},
      ),
    ),
    'date picker': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveDatePicker(
        selected: DateTime(2026, 6, 15),
        currentDate: DateTime(2026, 6, 15),
        firstYear: 2026,
        lastYear: 2026,
        onChanged: (_) {},
      ),
    ),
    'date range picker': () => SizedBox(
      height: 500,
      child: ExpressiveDateRangePicker(
        start: DateTime(2026, 6, 15),
        end: DateTime(2026, 6, 20),
        currentDate: DateTime(2026, 6, 15),
        firstYear: 2026,
        lastYear: 2026,
        onChanged: (_, _) {},
      ),
    ),
    'date input': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveDatePicker(
        selected: DateTime(2026, 6, 15),
        currentDate: DateTime(2026, 6, 15),
        initialMode: ExpressiveDatePickerMode.input,
        onChanged: (_) {},
      ),
    ),
    'app bar': () =>
        const ExpressiveAppBar(title: 'A longer title', subtitle: 'Subtitle'),
    'search bar': () => const ExpressiveSearchBar(hintText: 'A longer label'),
    'filled search field': () => const _FilledSearch(),
    'search field': () =>
        const ExpressiveSearchField(hintText: 'A longer label'),
    'slider': () => ExpressiveSlider(
      value: .5,
      size: ExpressiveSliderSize.medium,
      icon: ExpressiveSymbols.add,
      valueLabel: (value) => '50',
      autofocus: true,
      onChanged: (_) {},
    ),
    'range slider': () =>
        ExpressiveRangeSlider(start: .25, end: .75, onChanged: (_, _) {}),
    'vertical slider': () => SizedBox(
      height: 200,
      child: ExpressiveVerticalSlider(value: .5, onChanged: (_) {}),
    ),
    'split button': () => ExpressiveSplitButton(
      'A longer label',
      icon: ExpressiveSymbols.add,
      onPressed: () {},
    ),
    'quantity stepper': () =>
        ExpressiveNumberField(value: 12, onChanged: (_) {}),
    'floating toolbar': () => ExpressiveFloatingToolbar(
      children: [
        ExpressiveIconButton(
          ExpressiveSymbols.add,
          semanticLabel: 'Add',
          onPressed: () {},
        ),
        ExpressiveIconButton(
          ExpressiveSymbols.edit,
          semanticLabel: 'Edit',
          onPressed: () {},
        ),
      ],
    ),
    'toolbar with fab': () => ExpressiveFloatingToolbar(
      floatingActionButton: ExpressiveToolbarFab(
        icon: ExpressiveSymbols.add,
        semanticLabel: 'Add',
        onPressed: () {},
      ),
      children: [
        ExpressiveIconButton(
          ExpressiveSymbols.edit,
          semanticLabel: 'Edit',
          onPressed: () {},
        ),
      ],
    ),
    'docked toolbar': () => ExpressiveDockedToolbar(
      children: [
        ExpressiveIconButton(
          ExpressiveSymbols.add,
          semanticLabel: 'Add',
          onPressed: () {},
        ),
      ],
    ),
    'bottom sheet': () => const SizedBox(
      height: 300,
      child: ExpressiveBottomSheet(
        initialValue: ExpressiveSheetValue.expanded,
        skipPartiallyExpanded: true,
        child: Text('A longer label'),
      ),
    ),
    'choice': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveChoiceTile(
        title: 'A longer label',
        supportingText: 'More words',
        icon: ExpressiveSymbols.add,
        selected: true,
        onPressed: () {},
      ),
    ),
    'face pile': () => const ExpressiveAvatarGroup(
      faces: [
        ExpressiveFace('Ada Kim'),
        ExpressiveFace('Noor Ali'),
        ExpressiveFace('Sam Reed'),
        ExpressiveFace('Jo Wu'),
      ],
      total: 9,
    ),
    for (final size in ExpressiveAvatarSize.values) ...{
      'avatar ${size.name}': () =>
          ExpressiveAvatar(name: 'Mara Quist', size: size),
      'avatar icon ${size.name}': () => ExpressiveAvatar(
        name: 'Person',
        icon: ExpressiveSymbols.person,
        size: size,
      ),
    },
    'message': () => const ExpressiveMessageBubble(
      text: 'More words in this message',
      side: ExpressiveMessageSide.outgoing,
    ),
    'banner': () => SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveBanner(
        message: 'More words in this message',
        title: 'Details',
        icon: ExpressiveSymbols.add,
        actions: [ExpressiveBannerAction('Read', onPressed: () {})],
      ),
    ),
    // At 120dp an expanded panel can be taller than the test window. Give
    // it a scrolling page, with no clip that could conceal any painted text.
    'disclosure': () => const SingleChildScrollView(
      clipBehavior: Clip.none,
      child: ExpressiveDisclosure(
        title: Text('A longer label'),
        initiallyExpanded: true,
        child: Text('More words in the expanded panel'),
      ),
    ),
    'snackbar': () => ExpressiveSnackBar(
      'A longer message',
      actionLabel: 'Undo',
      onAction: () {},
      withDismissAction: true,
      onDismiss: () {},
    ),
    'badge': () => ExpressiveBadge.count(999),
    'tag': () =>
        const ExpressiveTag('A longer label', icon: ExpressiveSymbols.add),
    'checkbox row': () => ExpressiveCheckboxRow(
      label: 'A longer label',
      value: true,
      onChanged: (_) {},
    ),
    'radio row': () => ExpressiveRadioRow(
      label: 'A longer label',
      selected: true,
      onPressed: () {},
    ),
    'switch row': () => ExpressiveSwitchRow(
      label: 'A longer label',
      value: true,
      checkedIcon: const Icon(ExpressiveSymbols.check),
      onChanged: (_) {},
    ),
    'static list tile': () => const ExpressiveListTile(
      title: Text('A longer label'),
      subtitle: Text('Supporting words'),
      leading: Icon(ExpressiveSymbols.add),
    ),
    'interactive list tile': () => ExpressiveListTile(
      title: const Text('A longer label'),
      subtitle: const Text('Supporting words'),
      onTap: () {},
    ),
    'dialog': () => const ExpressiveDialog(
      title: 'A longer label',
      text: 'Supporting words for the dialog',
    ),
    'plain tooltip': () => const ExpressivePlainTooltip('A longer label'),
    'rich tooltip': () =>
        const ExpressiveRichTooltip(title: 'Details', text: 'A longer label'),
    'popover': () =>
        const ExpressivePopoverSurface(child: Text('A longer label')),
    'menu': () => ExpressiveMenuSurface(
      groups: [
        ExpressiveMenuGroup([
          ExpressiveMenuItem(
            'A longer label',
            icon: ExpressiveSymbols.add,
            onPressed: () {},
          ),
          ExpressiveMenuCheckItem(
            'Another choice',
            value: true,
            onChanged: (_) {},
          ),
        ]),
      ],
    ),
    'chip': () => ExpressiveChip('A longer label', onPressed: () {}),
    'toggle': () => ExpressiveToggleButton(
      label: 'A longer label',
      value: true,
      onChanged: (_) {},
    ),
    'dialog text action': () =>
        ExpressiveTextButton('A longer action', onPressed: () {}),
    for (final open in [false, true])
      'fab menu open=$open': () => ExpressiveHeroMoment(
        child: ExpressiveFabMenu(
          icon: ExpressiveSymbols.add,
          expanded: open,
          padded: false,
          items: [
            ExpressiveFabMenuItem(
              icon: ExpressiveSymbols.add,
              label: 'A longer action',
              onPressed: (_) {},
            ),
            ExpressiveFabMenuItem(
              icon: ExpressiveSymbols.edit,
              label: 'Another action',
              onPressed: (_) {},
            ),
          ],
        ),
      ),
    'fab': () => ExpressiveFloatingActionButton(
      icon: ExpressiveSymbols.add,
      onPressed: () {},
    ),
    'extended fab': () => ExpressiveFloatingActionButton.extended(
      icon: ExpressiveSymbols.add,
      label: 'A longer label',
      onPressed: () {},
    ),
  };
  for (final entry in controls.entries) {
    testWidgets('${entry.key} contains its label and glyph '
        'under every offered setting', (tester) async {
      for (final density in _densities) {
        for (final width in [120.0, 240.0, 390.0]) {
          for (final scale in [1.0, 1.3]) {
            await tester.pumpWidget(
              MaterialApp(
                home: ExpressiveHost(
                  light: _theme.copyWith(density: density),
                  brightness: Brightness.light,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Center(
                      child: SizedBox(
                        width: width,
                        child: Center(child: entry.value()),
                      ),
                    ),
                  ),
                ),
              ),
            );
            if (entry.key.startsWith('wavy ') ||
                entry.key.startsWith('skeleton') ||
                entry.key == 'loading state') {
              await tester.pump(const Duration(milliseconds: 100));
            } else {
              await tester.pumpAndSettle();
            }
            for (final surface in find.byType(ExpressiveSurface).evaluate()) {
              final faceFinder = find.byElementPredicate((e) => e == surface);
              final paintedFinder = find
                  .descendant(
                    of: faceFinder,
                    matching: find.byWidgetPredicate(
                      (w) => w.runtimeType.toString() == '_SurfacePaint',
                    ),
                  )
                  .first;
              final dynamic painted = tester.widget(paintedFinder);
              final shape = painted.shape as ShapeBorder;
              final face = tester.getRect(paintedFinder);
              for (final finder in [
                find.byType(Text),
                find.byType(Icon),
                find.byType(EditableText),
                find.byWidgetPredicate(
                  (w) =>
                      w is CustomPaint &&
                      const [
                        '_LoadingPainter',
                        '_LinearPainter',
                        '_LinearWavyPainter',
                        '_CircularPainter',
                        '_CircularWavyPainter',
                      ].contains(w.painter.runtimeType.toString()),
                ),
              ]) {
                for (final element
                    in find
                        .descendant(of: faceFinder, matching: finder)
                        .evaluate()) {
                  Rect? localBounds;
                  if (element.widget case CustomPaint(:final painter)
                      when painter.runtimeType.toString() ==
                          '_LoadingPainter') {
                    final box = element.findRenderObject()! as RenderBox;
                    final path = _loadingPaintPath(painter!, box.size);
                    localBounds = path.getBounds();
                    // This native vector is the shape itself, not content
                    // in a rectangular box. Its rotated path fits the
                    // circle even where empty bounds corners do not.
                    final glyph = path
                        .transform(box.getTransformTo(null).storage)
                        .shift(-face.topLeft);
                    final outside = Path.combine(
                      PathOperation.difference,
                      glyph,
                      shape.getOuterPath(Offset.zero & face.size),
                    );
                    expect(
                      outside.getBounds().isEmpty,
                      isTrue,
                      reason:
                          '${entry.key} native painted path $density $width $scale',
                    );
                    continue;
                  }
                  // A text by what its font can paint: its glyph run's
                  // ascent to descent, not the line height's leading, which
                  // paints nothing (a label drawn by its capitals on its
                  // face's middle carries its line box a pixel or two off).
                  final paragraph = element.widget is Text
                      ? element.findRenderObject()
                      : null;
                  if (paragraph case final RenderParagraph p) {
                    final text = p.text.toPlainText();
                    final boxes = p.getBoxesForSelection(
                      TextSelection(baseOffset: 0, extentOffset: text.length),
                      boxHeightStyle: BoxHeightStyle.tight,
                    );
                    if (boxes.isNotEmpty) {
                      // Across the paragraph's own width: a wrapped line's
                      // trailing space hangs past it and paints nothing.
                      final run = boxes
                          .map((b) => b.toRect())
                          .reduce((a, b) => a.expandToInclude(b));
                      localBounds = Rect.fromLTRB(
                        run.left.clamp(0.0, p.size.width),
                        run.top,
                        run.right.clamp(0.0, p.size.width),
                        run.bottom,
                      );
                    }
                  }
                  final visible = _visibleRect(
                    tester,
                    element,
                    localBounds: localBounds,
                  );
                  if (visible == null) continue;
                  _inside(
                    shape.getOuterPath(Offset.zero & face.size),
                    visible.shift(-face.topLeft),
                    '${entry.key} $density $width $scale content=${element.widget} face=$face shape=$shape',
                  );
                }
              }
            }
            for (final element in find.byType(DecoratedBox).evaluate()) {
              final decoration = (element.widget as DecoratedBox).decoration;
              if (decoration is! ShapeDecoration) continue;
              final finder = find.byElementPredicate((e) => e == element);
              final face = tester.getRect(finder);
              // Native loading retains its original ShapeDecoration paint.
              // Keep the approved vector-containment proof on that plate.
              for (final glyph
                  in find
                      .descendant(
                        of: finder,
                        matching: find.byWidgetPredicate(
                          (w) =>
                              w is CustomPaint &&
                              w.painter.runtimeType.toString() ==
                                  '_LoadingPainter',
                        ),
                      )
                      .evaluate()) {
                final box = glyph.findRenderObject()! as RenderBox;
                final painter = (glyph.widget as CustomPaint).painter!;
                final path = _loadingPaintPath(painter, box.size)
                    .transform(box.getTransformTo(null).storage)
                    .shift(-face.topLeft);
                expect(
                  Path.combine(
                    PathOperation.difference,
                    path,
                    decoration.shape.getOuterPath(Offset.zero & face.size),
                  ).getBounds().isEmpty,
                  isTrue,
                  reason:
                      '${entry.key} native decorated vector $density $width $scale',
                );
              }
              for (final glyph
                  in find
                      .descendant(
                        of: finder,
                        matching: find.byWidgetPredicate(
                          (w) => w is Icon || w is Text || w is EditableText,
                        ),
                      )
                      .evaluate()) {
                final visible = _visibleRect(tester, glyph);
                if (visible == null) continue;
                _inside(
                  decoration.shape.getOuterPath(Offset.zero & face.size),
                  visible.shift(-face.topLeft),
                  '${entry.key} decoration $density $width $scale',
                );
              }
            }
            // Navigation's icon and label are siblings of its ripple plate.
            for (final item
                in find
                    .byWidgetPredicate(
                      (w) => w.runtimeType.toString() == '_NavItemLayout',
                    )
                    .evaluate()) {
              final finder = find.byElementPredicate((e) => e == item);
              final painted = find
                  .descendant(
                    of: finder,
                    matching: find.byWidgetPredicate(
                      (w) => w.runtimeType.toString() == '_SurfacePaint',
                    ),
                  )
                  .first;
              final dynamic surface = tester.widget(painted);
              final face = tester.getRect(painted);
              final shape = surface.shape as ShapeBorder;
              final dynamic layout = item.widget;
              final includeLabel =
                  layout.geometry.position == ExpressiveNavItemPosition.start;
              final content = find.descendant(
                of: finder,
                matching: find.byWidgetPredicate(
                  (w) => w is Icon || (includeLabel && w is Text),
                ),
              );
              for (final child in content.evaluate()) {
                final visible = _visibleRect(tester, child);
                if (visible == null) continue;
                _inside(
                  shape.getOuterPath(Offset.zero & face.size),
                  visible.shift(-face.topLeft),
                  '${entry.key} indicator $density $width $scale',
                );
              }
            }
            for (final element in find.byType(CustomPaint).evaluate()) {
              final painter = (element.widget as CustomPaint).painter;
              if (painter.runtimeType.toString() == '_ScaledChartPainter') {
                final finder = find.byElementPredicate((e) => e == element);
                final size = tester.getSize(finder);
                final path = Path()..addRect(Offset.zero & size);
                expect(
                  (Canvas canvas) => painter!.paint(canvas, size),
                  paints..everything((method, arguments) {
                    if (method == #drawParagraph) {
                      final dynamic paragraph = arguments[0];
                      final at = arguments[1] as Offset;
                      _inside(
                        path,
                        at &
                            Size(
                              paragraph.width as double,
                              paragraph.height as double,
                            ),
                        '${entry.key} canvas label $density $width $scale',
                      );
                    }
                    return true;
                  }),
                );
              }
              if (painter.runtimeType.toString() == '_BodyPainter') {
                final dynamic body = painter;
                final finder = find.byElementPredicate((e) => e == element);
                final face = tester.getRect(finder);
                for (final glyph
                    in find
                        .descendant(
                          of: finder,
                          matching: find.byWidgetPredicate(
                            (w) => w is Icon || w is Text,
                          ),
                        )
                        .evaluate()) {
                  final visible = _visibleRect(tester, glyph);
                  if (visible != null) {
                    _inside(
                      (body.shape as ShapeBorder).getOuterPath(
                        Offset.zero & face.size,
                      ),
                      visible.shift(-face.topLeft),
                      '${entry.key} body $density $width $scale',
                    );
                  }
                }
              }
              if (![
                '_CheckboxPainter',
                '_RadioPainter',
              ].contains(painter.runtimeType.toString())) {
                continue;
              }
              final dynamic mark = painter;
              final shape = mark.shape as OutlinedBorder?;
              if (shape == null) continue;
              final finder = find.byElementPredicate((e) => e == element);
              final size = tester.getSize(finder);
              final inset = mark.inset as EdgeInsets;
              _inside(
                shape.getOuterPath(Offset.zero & size),
                inset.deflateRect(Offset.zero & size),
                '${entry.key} mark $density $width $scale',
              );
            }
            final exception = tester.takeException();
            expect(
              exception,
              isNull,
              reason:
                  '${entry.key} $density $width $scale '
                  '${exception is FlutterError ? exception.diagnostics.map((d) => d.toStringDeep()).join() : exception}',
            );
          }
        }
      }
    });
  }
}

class _FilledSearch extends StatefulWidget {
  const _FilledSearch();
  @override
  State<_FilledSearch> createState() => _FilledSearchState();
}

class _FilledSearchState extends State<_FilledSearch> {
  final controller = TextEditingController(text: 'A longer query');
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ExpressiveSearchField(controller: controller);
}

class _TimeCase extends StatefulWidget {
  const _TimeCase(this.mode, {this.vibrant = false, this.horizontal = false});
  final ExpressiveTimePickerMode mode;
  final bool vibrant;
  final bool horizontal;
  @override
  State<_TimeCase> createState() => _TimeCaseState();
}

class _TimeCaseState extends State<_TimeCase> {
  final controller = ExpressiveTimePickerController(
    hour: 10,
    minute: 15,
    is24Hour: false,
  );
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => switch (widget.mode) {
    ExpressiveTimePickerMode.dial => ExpressiveTimePicker(
      controller: controller,
      vibrant: widget.vibrant,
      layout: widget.horizontal
          ? ExpressiveTimePickerLayout.horizontal
          : ExpressiveTimePickerLayout.vertical,
    ),
    ExpressiveTimePickerMode.input => ExpressiveTimeInput(
      controller: controller,
      vibrant: widget.vibrant,
    ),
    ExpressiveTimePickerMode.scroll => ExpressiveTimeScroll(
      controller: controller,
    ),
  };
}
