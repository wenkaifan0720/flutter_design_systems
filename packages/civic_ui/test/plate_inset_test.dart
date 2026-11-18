// ignore_for_file: avoid_relative_lib_imports
import 'dart:ui' as ui;

import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

const _screen = ValueKey('plate screen');

Future<Color Function(double, double)> _picture(WidgetTester t) async {
  final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(_screen));
  final (width, data) = (await t.runAsync(() async {
    final im = await boundary.toImage(pixelRatio: 2);
    final rgba = (await im.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final width = im.width;
    im.dispose();
    return (width, rgba);
  }))!;
  return (double x, double y) {
    final i = 4 * ((y * 2).floor() * width + (x * 2).floor());
    return Color.fromARGB(
      data.getUint8(i + 3),
      data.getUint8(i),
      data.getUint8(i + 1),
      data.getUint8(i + 2),
    );
  };
}

void main() {
  setUpAll(loadScreenFonts);
  for (final width in [390.0, 1440.0]) {
    for (final dir in TextDirection.values) {
      bool rtl = dir == TextDirection.rtl;
      Future<void> show(WidgetTester t, Widget child) async {
        t.view.devicePixelRatio = 2;
        t.view.physicalSize = Size(width, 700) * 2;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          RepaintBoundary(
            key: _screen,
            child: kitApp(
              brightness: Brightness.light,
              direction: dir,
              home: ColoredBox(
                color: const Color(0xffeeeeee),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(width: 320, child: child),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      testWidgets(
        'square switch, round radio and edge-to-edge list at $width in ${dir.name}',
        (t) async {
          await show(
            t,
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CivicSwitch(value: true, onChanged: (_) {}),
                ),
                CivicRadioGroup<String>(
                  groupValue: 'one',
                  onChanged: (_) {},
                  children: const [CivicRadio(value: 'one', labelText: 'One')],
                ),
                CivicListGroup(
                  children: [
                    CivicListRow(
                      title: const Text('First'),
                      selected: true,
                      onTap: () {},
                    ),
                    CivicListRow(title: const Text('Last'), onTap: () {}),
                  ],
                ),
                CivicNavigationBar(
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  destinations: const [
                    CivicNavigationDestination(
                      icon: LucideIcons.house,
                      label: 'Home',
                      key: ValueKey('home'),
                    ),
                    CivicNavigationDestination(
                      icon: LucideIcons.user,
                      label: 'Account',
                    ),
                  ],
                ),
              ],
            ),
          );
          final color = await _picture(t);
          final theme = t.element(find.byType(CivicSwitch)).civicTheme;
          Rect face(Finder part, Size size) => t.getRect(
            find
                .descendant(
                  of: part,
                  matching: find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.size == size,
                  ),
                )
                .first,
          );
          final track = face(find.byType(CivicSwitch), CivicSwitch.trackSize);
          final x = track.left + (rtl ? 8.0 : 32.0);
          final y = track.top + 8;
          for (final dx in [.25, 19.75]) {
            for (final dy in [.25, 19.75]) {
              expect(color(x + dx, y + dy), theme.onAction);
            }
          }
          expect(color(x - .75, y + .5), theme.action);
          expect(color(x + .5, y - .75), theme.action);
          expect(color(x + 20.75, y + 19.5), theme.action);
          expect(color(x + 19.5, y + 20.75), theme.action);
          final well = face(
            find.byType(CivicRadio<String>),
            const Size.square(40),
          );
          final c = well.center;
          for (final direction in [
            const Offset(1, 0),
            const Offset(-1, 0),
            const Offset(0, 1),
            const Offset(0, -1),
          ]) {
            final inDot = c + direction * 9, gap = c + direction * 11;
            expect(color(inDot.dx, inDot.dy), theme.textPrimary);
            expect(color(gap.dx, gap.dy), theme.background);
          }
          final card = t.getRect(find.byType(CivicListGroup));
          double start(double d) => rtl ? card.right - d : card.left + d;
          // The selected rule follows the card's outer eight-pixel corner.
          expect(color(start(.25), card.top + .25), isNot(theme.action));
          expect(color(start(2.25), card.top + 1.25), isNot(theme.action));
          expect(color(start(2.25), card.top + 5.25), theme.action);
          expect(color(start(.25), card.top + 9), theme.action);
          final cell = t.getRect(find.byKey(const ValueKey('home')));
          final mid = cell.center.dx;
          final level = cell.top + 2;
          expect(color(mid, level), theme.action);
          for (final sign in [-1, 1]) {
            expect(
              color(mid + sign * (cell.width * .3 - 1), level),
              theme.action,
            );
            expect(
              color(mid + sign * (cell.width * .3 + 1), level),
              isNot(theme.action),
            );
          }
        },
      );
      for (final combo in [false, true]) {
        testWidgets(
          'the ${combo ? 'combobox' : 'select'} menu clips its first option inside the rim at $width in ${dir.name}',
          (t) async {
            await show(
              t,
              combo
                  ? CivicCombobox<String>(
                      labelText: 'Paper size',
                      options: const ['A4', 'A3'],
                      value: 'A4',
                      onSelected: (_) {},
                    )
                  : CivicSelect<String>(
                      labelText: 'Paper size',
                      items: const [
                        CivicSelectItem(value: 'A4', label: 'A4'),
                        CivicSelectItem(value: 'A3', label: 'A3'),
                      ],
                      value: 'A4',
                      onChanged: (_) {},
                    ),
            );
            await t.tap(combo ? find.byType(EditableText) : find.text('A4'));
            await t.pumpAndSettle();
            final menu = find
                .ancestor(
                  of: find.text('A3'),
                  matching: find.byWidgetPredicate(
                    (w) =>
                        w is DecoratedBox &&
                        w.decoration is BoxDecoration &&
                        (w.decoration as BoxDecoration).boxShadow?.isNotEmpty ==
                            true,
                  ),
                )
                .first;
            final box = t.getRect(menu);
            final color = await _picture(t);
            double start(double d) => rtl ? box.right - d : box.left + d;
            final inset = color(start(1.25), box.top + 9.25);
            expect(color(start(1.25), box.top + 1.25), isNot(inset));
            expect(color(start(2.75), box.top + 2.75), inset);
            expect(color(start(0.25), box.top + 9.25), isNot(inset));
          },
        );
      }
    }
  }
}
