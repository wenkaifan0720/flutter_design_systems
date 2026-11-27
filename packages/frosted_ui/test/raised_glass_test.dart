// What Frosted raises over the page reads as its own glass, and what fails
// reads as failed: a combobox's list dropping from a field on a card frosts
// the card and the words under it (law 3: what lies under a raised slab
// softens), by day and by night; a dialog raised with showFrostedDialog dims
// and softens the page as FrostedDialog.show's does; a menu's loss is set in
// the over ink, as the action sheet sets one; the error state stands on the
// empty state's glass tile with the over ink along its top edge; and pages
// standing side by side stand on one light, with no seam where they meet.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/src/frosted/internal/face.dart';
import 'package:frosted_ui/src/frosted/internal/panel.dart';

Widget _host(FrostedThemeData t, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => FrostedHost(
    theme: t,
    darkTheme: t,
    brightness: t.isDark ? Brightness.dark : Brightness.light,
    child: page!,
  ),
  home: ColoredBox(
    color: t.colorScheme.background,
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: SizedBox(width: 400, child: child),
      ),
    ),
  ),
);

void _noop() {}

/// The face [text] stands on, of [material].
Finder _faceOf(Finder text, FrostedMaterial material) => find.ancestor(
  of: text,
  matching: find.byWidgetPredicate(
    (w) => w is FrostedFace && w.material == material,
  ),
);

void main() {
  for (final brightness in Brightness.values) {
    final t = FrostedThemeData.preset('opal', brightness);

    testWidgets('a combobox list over a card frosts what lies under it '
        '(${brightness.name})', (tester) async {
      await tester.pumpWidget(
        _host(
          t,
          FrostedCard(
            child: FrostedCombobox<String>(
              labelText: 'Assignee',
              options: const ['Maya Reed', 'Sam Okafor', 'Noor Haddad'],
              value: 'Maya Reed',
              onSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(find.byType(FrostedPanel), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FrostedPanel),
          matching: find.byType(BackdropFilter),
        ),
        findsWidgets,
        reason: 'the open list reads the page behind it, not the card',
      );
      // Its rows still stand on the list's glass: one blur, the list's
      // own; no row blurs a second time.
      final blurs = tester
          .widgetList<BackdropFilter>(
            find.descendant(
              of: find.byType(FrostedPanel),
              matching: find.byType(BackdropFilter),
            ),
          )
          .where((f) => '${f.filter}'.contains('blur'));
      expect(blurs, hasLength(1));
    });

    testWidgets('showFrostedDialog dims and softens the page under it '
        '(${brightness.name})', (tester) async {
      await tester.pumpWidget(
        _host(
          t,
          Builder(
            builder: (context) => FrostedButton(
              'Leave',
              onPressed: () => showFrostedDialog<void>(
                context,
                builder: (context) => const FrostedDialog(
                  title: 'Unsaved changes',
                  message: 'Save your changes before leaving this task?',
                  confirmLabel: 'Save changes',
                  cancelLabel: 'Cancel',
                  onConfirm: _noop,
                  onCancel: _noop,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      final soft = find.byWidgetPredicate(
        (w) => w is BackdropFilter && w.child is ColoredBox,
      );
      expect(soft, findsOneWidget, reason: 'the scrim softens the page');
      expect(
        (tester.widget<BackdropFilter>(soft).child! as ColoredBox).color,
        t.materials.scrim,
      );
    });

    testWidgets('a menu sets its loss in the over ink (${brightness.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          t,
          Builder(
            builder: (anchor) => FrostedButton.glass(
              'Actions',
              onPressed: () => FrostedMenu.show<String>(
                anchor,
                items: const [
                  FrostedMenuItem('done', 'Mark done'),
                  FrostedMenuItem(
                    'delete',
                    'Delete',
                    isDestructiveAction: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Actions'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('Delete')).style?.color,
        t.colorScheme.over,
      );
      expect(
        tester.widget<Text>(find.text('Mark done')).style?.color,
        isNot(t.colorScheme.over),
      );
    });

    testWidgets(
      'the error state stands on the empty state\'s tile, its top edge lit in '
      'the over hue (${brightness.name})',
      (tester) async {
        await tester.pumpWidget(
          _host(
            t,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FrostedEmptyState(title: 'No tasks'),
                SizedBox(
                  height: 300,
                  child: FrostedErrorState(
                    title: 'Couldn’t load the workspace',
                    message: 'Try again to load the team’s latest work.',
                    onRetry: _noop,
                  ),
                ),
              ],
            ),
          ),
        );
        final empty = tester.widget<FrostedFace>(
          _faceOf(find.text('No tasks'), FrostedMaterial.pane),
        );
        final tile = _faceOf(
          find.text('Couldn’t load the workspace'),
          FrostedMaterial.pane,
        );
        expect(tile, findsOneWidget, reason: 'the failed list is a tile too');
        final error = tester.widget<FrostedFace>(tile);
        expect(error.radius, empty.radius);
        expect(error.shadows, empty.shadows);
        // Along its top edge the spectrum's band in the over hue, fading in
        // and out as the spectrum does, and lighter than the over ink: light
        // caught in the glass, never a dark line by day.
        final rim = tester
            .widgetList<DecoratedBox>(
              find.descendant(of: tile, matching: find.byType(DecoratedBox)),
            )
            .map((w) => w.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.gradient)
            .whereType<LinearGradient>()
            .single;
        expect(rim.colors.first.a, 0);
        expect(rim.colors.last.a, 0);
        final band = rim.colors.sublist(1, rim.colors.length - 1);
        expect(band, isNotEmpty);
        double hue(Color c) => HSLColor.fromColor(c).hue;
        for (final c in band) {
          final apart = (hue(c) - hue(t.colorScheme.over)).abs() % 360;
          expect(
            apart < 180 ? apart : 360 - apart,
            lessThan(20),
            reason: 'the band is in the over hue',
          );
        }
        if (brightness == Brightness.light) {
          expect(
            band.first.computeLuminance(),
            greaterThan(t.colorScheme.over.computeLuminance()),
            reason: 'by day no edge is a dark line',
          );
        }
      },
    );

    testWidgets('pages side by side stand on one light (${brightness.name})', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final frame = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, page) => FrostedHost(
            theme: t,
            darkTheme: t,
            brightness: brightness,
            child: page!,
          ),
          home: RepaintBoundary(
            key: frame,
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 480,
                  child: FrostedScaffold(
                    topBar: FrostedAppBar.none,
                    scroll: false,
                    body: SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: FrostedScaffold(
                    topBar: FrostedAppBar.none,
                    scroll: false,
                    body: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary =
          frame.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!;
      }))!;
      final width = boundary.size.width.round();
      List<int> at(int x, int y) {
        final i = (y * width + x) * 4;
        return [
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        ];
      }

      int step(int x, int y) {
        final a = at(x, y), b = at(x + 1, y);
        return [for (var c = 0; c < 3; c++) (a[c] - b[c]).abs()]
            .reduce((p, q) => p > q ? p : q);
      }

      for (final y in [40, 160, 320, 480, 640]) {
        // Across the seam the light steps no more than it does a pixel
        // either side of it.
        final across = step(479, y);
        final beside = [
          step(476, y),
          step(477, y),
          step(481, y),
          step(482, y),
        ].reduce((p, q) => p > q ? p : q);
        expect(
          across,
          lessThanOrEqualTo(beside + 2),
          reason: 'row $y: ${at(479, y)} | ${at(480, y)}',
        );
      }
    });
  }
}
