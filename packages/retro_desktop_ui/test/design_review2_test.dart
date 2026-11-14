// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import '../example/lib/kit_gallery/demos/ordinary.dart';
import '../example/lib/kit_gallery/kit.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);
  for (final dark in [false, true]) {
    for (final position in [0, 1, 2]) {
      testWidgets(
        'empty group rows preserve height and gap at $position dark=$dark',
        (tester) async {
          const first = ValueKey('group-first');
          const last = ValueKey('group-last');
          const group = ValueKey('measured-group');
          const rows = [
            SizedBox(key: first, height: 30),
            SizedBox(key: last, height: 40),
          ];
          Widget host(List<Widget> children) => retroDesktopApp(
            Center(
              child: SizedBox(
                width: 300,
                child: RetroDesktopListSection(key: group, children: children),
              ),
            ),
            dark: dark,
          );
          double gap() =>
              tester.getTopLeft(find.byKey(last)).dy -
              tester.getBottomLeft(find.byKey(first)).dy;
          await tester.pumpWidget(host(rows));
          final naturalHeight = tester.getSize(find.byKey(group)).height;
          final naturalGap = gap();
          for (final empty in [
            const SizedBox.shrink(),
            Builder(builder: (_) => const SizedBox.shrink()),
            const Visibility(visible: false, child: SizedBox(height: 25)),
          ]) {
            await tester.pumpWidget(
              host([...rows.take(position), empty, ...rows.skip(position)]),
            );
            expect(gap(), naturalGap);
            expect(tester.getSize(find.byKey(group)).height, naturalHeight);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
    testWidgets(
      'group separators preserve keyed field state on reorder dark=$dark',
      (tester) async {
        var reversed = false;
        await tester.pumpWidget(
          retroDesktopApp(
            Center(
              child: SizedBox(
                width: 360,
                child: StatefulBuilder(
                  builder: (context, change) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RetroDesktopButton(
                        'Reverse rows',
                        onPressed: () => change(() => reversed = !reversed),
                      ),
                      RetroDesktopListSection(
                        children: [
                          for (final name in reversed ? ['B', 'A'] : ['A', 'B'])
                            RetroDesktopTextField(
                              key: ValueKey(name),
                              label: name,
                              initial: name,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        final field = find.descendant(
          of: find.byKey(const ValueKey('A')),
          matching: find.byType(EditableText),
        );
        await tester.enterText(field, 'Edited A');
        await tester.tap(find.text('Reverse rows'));
        await tester.pumpAndSettle();
        expect(tester.widget<EditableText>(field).controller.text, 'Edited A');
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'an empty tab list keeps its panel inside its bounds dark=$dark',
      (tester) async {
        await tester.pumpWidget(
          retroDesktopApp(
            const Center(
              child: SizedBox(
                width: 300,
                child: RetroDesktopTabBar(
                  tabs: [],
                  child: Text('Panel contents'),
                ),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        final bounds = tester.getRect(find.byType(RetroDesktopTabBar));
        final panel = tester.getRect(
          find.descendant(
            of: find.byType(RetroDesktopTabBar),
            matching: find.byType(ClipPath),
          ),
        );
        expect(panel.top, greaterThanOrEqualTo(bounds.top));
        expect(panel.bottom, lessThanOrEqualTo(bounds.bottom));
        expect(tester.takeException(), isNull);
      },
    );
    for (final width in [390.0, 1440.0]) {
      testWidgets(
        'group rows keep their inset and separator $width dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          // Papers' settings are checkboxes in group boxes now; the grouped
          // rows a settings page of switches uses are pumped as such a page
          // has them.
          await tester.pumpWidget(
            kitScreen(
              brightness: dark ? Brightness.dark : Brightness.light,
              title: 'Settings',
              maxWindowWidth: 720,
              sections: [
                RetroDesktopListSection(
                  title: 'Documents',
                  children: [
                    RetroDesktopSwitchRow(
                      label: 'Save automatically',
                      note: 'Keep your work as you make changes.',
                      value: true,
                      onChanged: (_) {},
                    ),
                    RetroDesktopSwitchRow(
                      label: 'Keep an offline copy',
                      note: 'Open your documents without a connection.',
                      value: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          );
          await tester.pumpAndSettle();
          final group = find.byType(RetroDesktopListSection).first;
          final panel = find
              .descendant(of: group, matching: find.byType(RetroDesktopSurface))
              .first;
          final bounds = tester.getRect(panel);
          final label = tester.getRect(find.text('Save automatically'));
          expect(label.left - bounds.left, inInclusiveRange(12, 16));
          expect(label.top - bounds.top, inInclusiveRange(8, 12));
          final row = find.byType(RetroDesktopSwitchRow).first;
          final track = find
              .descendant(
                of: row,
                matching: find.byWidgetPredicate(
                  (w) => w.runtimeType.toString() == '_Face',
                ),
              )
              .first;
          expect(
            bounds.right - tester.getRect(track).right,
            inInclusiveRange(12, 16),
          );
          final divider = find.descendant(
            of: group,
            matching: find.byType(RetroDesktopDivider),
          );
          expect(divider, findsOneWidget);
          expect(tester.getSize(divider).height, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'all ordinary desktop windows share centre and top inset dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final screen in kitOrdinaryScreens) {
          await tester.pumpWidget(
            KeyedSubtree(
              key: ValueKey(screen),
              child: kitOrdinaryScreen(
                screen,
                dark ? Brightness.dark : Brightness.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final rect = tester.getRect(find.byType(RetroDesktopWindow));
          expect(rect.center.dx, 720, reason: screen);
          // The menu bar includes its target height and one pixel rule.
          final barHeight =
              RetroDesktopChromeMetrics.targetOf(
                tester.element(find.byType(RetroDesktopWindow)),
              ) +
              1;
          expect(rect.top - barHeight, 24, reason: screen);
          // A window is as wide as what it holds (Papers' windows).
          expect(rect.width, switch (screen) {
            'form' => 400,
            'settings' => 440,
            'checkout' => 480,
            'list' => 600,
            'dialog' => 720,
            'cards' => 1040,
            _ => 960,
          }, reason: screen);
          if (screen == 'tabs') {
            final panel = tester.getRect(find.byType(RetroDesktopTabBar));
            final leftInset = panel.left - rect.left;
            final rightInset = rect.right - panel.right;
            expect(leftInset, closeTo(rightInset, .01));
            expect(leftInset, inInclusiveRange(8, 24));
            expect(
              find.descendant(
                of: find.byType(RetroDesktopTabBar),
                matching: find.byType(RetroDesktopWell),
              ),
              findsNothing,
            );
          }
          expect(tester.takeException(), isNull, reason: screen);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      },
    );

    for (final direction in TextDirection.values) {
      for (final ratio in [1.0, 1.25, 1.5, 2.0]) {
        testWidgets(
          'selected folder tab opens the panel rule dark=$dark $direction @$ratio',
          (tester) async {
            tester.view.physicalSize = Size(390 * ratio, 900 * ratio);
            tester.view.devicePixelRatio = ratio;
            addTearDown(tester.view.reset);
            final boundaryKey = GlobalKey();
            var selected = 0;
            await tester.pumpWidget(
              retroDesktopApp(
                Center(
                  child: RepaintBoundary(
                    key: boundaryKey,
                    child: SizedBox(
                      width: 360,
                      child: StatefulBuilder(
                        builder: (context, change) => RetroDesktopTabBar(
                          tabs: const ['Recent', 'Shared'],
                          selectedIndex: selected,
                          onChanged: (value) => change(() => selected = value),
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Panel contents'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                dark: dark,
                direction: direction,
              ),
            );
            await tester.pumpAndSettle();
            Finder face(String label) => find
                .descendant(
                  of: find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byType(RetroDesktopPressable),
                      )
                      .first,
                  matching: find.byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_Face',
                  ),
                )
                .first;
            final panel = find
                .descendant(
                  of: find.byType(RetroDesktopTabBar),
                  matching: find.byWidgetPredicate(
                    (w) => w.runtimeType.toString() == '_Face',
                  ),
                )
                .last;
            for (final label in ['Recent', 'Shared']) {
              if (label == 'Shared') {
                await tester.tap(find.text(label));
                FocusManager.instance.primaryFocus?.unfocus();
                await tester.pumpAndSettle();
              }
              final selectedRect = tester.getRect(face(label));
              final otherRect = tester.getRect(
                face(label == 'Recent' ? 'Shared' : 'Recent'),
              );
              final panelRect = tester.getRect(panel);
              expect(selectedRect.top, lessThan(otherRect.top - 2));
              expect(selectedRect.bottom, greaterThan(panelRect.top));
              final boundary =
                  boundaryKey.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final point = boundary.globalToLocal(
                Offset(selectedRect.center.dx, panelRect.top + 1),
              );
              final expected = RetroDesktopTheme.of(tester.element(panel))
                  .colors
                  .platinumLight
                  .toARGB32();
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: ratio);
                try {
                  final bytes = (await image.toByteData(
                    format: ui.ImageByteFormat.rawRgba,
                  ))!;
                  final x = (point.dx * ratio).floor(),
                      y = (point.dy * ratio).floor();
                  for (final dx in [-1, 0, 1]) {
                    final offset = (y * image.width + x + dx) * 4;
                    final actual = Color.fromARGB(
                      bytes.getUint8(offset + 3),
                      bytes.getUint8(offset),
                      bytes.getUint8(offset + 1),
                      bytes.getUint8(offset + 2),
                    ).toARGB32();
                    expect(
                      actual,
                      expected,
                      reason: '$label panel join @$ratio',
                    );
                  }
                } finally {
                  image.dispose();
                }
              });
            }
            expect(selected, 1);
            expect(tester.takeException(), isNull);
          },
          tags: const ['goldens'],
        );
      }
    }
  }
}
