import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

const _shot = ValueKey('feedback-shot');

Widget _host(ComicThemeData theme, Widget child) => MaterialApp(
  builder: (context, home) => ComicTheme(data: theme, child: home!),
  home: RepaintBoundary(
    key: _shot,
    child: ColoredBox(
      color: theme.colors.card,
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  ),
);

Future<Color> _pixel(WidgetTester tester, Finder face, Offset at) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_shot),
  );
  final box = tester.renderObject<RenderBox>(face);
  final point = box.localToGlobal(at) - boundary.localToGlobal(Offset.zero);
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    return bytes!;
  });
  final i =
      (point.dy.floor() * boundary.size.width.round() + point.dx.floor()) * 4;
  return Color.fromARGB(
    bytes!.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

void main() {
  setUpAll(loadComicFonts);

  for (final width in [390.0, 1440.0]) {
    for (final mode in Brightness.values) {
      for (final direction in TextDirection.values) {
        testWidgets(
          'select menu matches its field without dimming $width $mode $direction',
          (tester) async {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = Size(width, 844);
            addTearDown(tester.view.reset);
            String? selected;
            await tester.pumpWidget(
              _host(
                ComicThemeData.offset(mode),
                Directionality(
                  textDirection: direction,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: width == 390 ? 342 : 600,
                      child: ComicSelect<String>(
                        label: 'Delivery',
                        value: 'standard',
                        options: const [
                          ComicSelectOption('standard', 'Standard delivery'),
                          ComicSelectOption('express', 'Express delivery'),
                        ],
                        onChanged: (value) => selected = value,
                      ),
                    ),
                  ),
                ),
              ),
            );
            final field = tester.getRect(find.byType(ComicSelectField));
            await tester.tap(find.byType(ComicSelectField));
            await tester.pumpAndSettle();
            final menu = find.byType(ComicMenu<String>);
            final route = ModalRoute.of(tester.element(menu))! as PopupRoute;
            expect(
              route.barrierColor?.a ?? 0,
              0,
              reason: 'A dropdown leaves the page undimmed',
            );
            expect(tester.getRect(menu).width, closeTo(field.width, .01));
            expect(tester.getRect(menu).left, closeTo(field.left, .01));
            await tester.tap(find.text('Express delivery'));
            await tester.pumpAndSettle();
            expect(selected, 'express');
            await tester.tap(find.byType(ComicSelectField));
            await tester.pumpAndSettle();
            await tester.tapAt(const Offset(2, 2));
            await tester.pumpAndSettle();
            expect(menu, findsNothing);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  for (final sheet in [false, true]) {
    testWidgets('${sheet ? 'sheet' : 'dialog'} retains its modal scrim', (
      tester,
    ) async {
      final theme = ComicThemeData.offset(Brightness.dark);
      await tester.pumpWidget(
        _host(
          theme,
          Builder(
            builder: (context) => ComicButton.filled(
              'Open',
              onPressed: () {
                if (sheet) {
                  showComicBottomSheet<void>(
                    context,
                    builder: (_) => const ComicBottomSheet(
                      title: 'Details',
                      child: Text('The issue'),
                    ),
                  );
                } else {
                  showComicDialog<void>(
                    context,
                    builder: (_) => const ComicDialog(title: 'Details'),
                  );
                }
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('OPEN'));
      await tester.pumpAndSettle();
      final raised = sheet
          ? find.byType(ComicBottomSheet)
          : find.byType(ComicDialog);
      final route = ModalRoute.of(tester.element(raised))! as PopupRoute;
      expect(route.barrierColor, theme.colors.scrim);
    });
  }

  for (final preset in ComicThemeData.presets) {
    testWidgets('$preset dark routine controls keep a dark reading surface', (
      tester,
    ) async {
      final theme = ComicThemeData.preset(preset, Brightness.dark);
      final examples = <(Widget, Finder, Offset)>[
        (
          ComicIconButton(ComicGlyphs.more, label: 'More', onPressed: () {}),
          find.byType(ComicIconButton),
          const Offset(10, 10),
        ),
        (
          const ComicAvatar('AM', name: 'Alex Morgan'),
          find.byType(ComicAvatar),
          const Offset(20, 7),
        ),
        (
          const SizedBox(
            width: 240,
            child: ComicTextField(label: 'Name', initialValue: 'Alex'),
          ),
          find.byType(ComicTextField),
          const Offset(10, 40),
        ),
        (
          ComicSelectField(value: 'Standard delivery', onPressed: () {}),
          find.byType(ComicSelectField),
          const Offset(10, 10),
        ),
      ];
      for (final (widget, finder, sample) in examples) {
        await tester.pumpWidget(_host(theme, widget));
        await tester.pumpAndSettle();
        expect(await _pixel(tester, finder, sample), theme.colors.card);
        expect(tester.takeException(), isNull);
      }
      // Drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
    }, tags: 'goldens');
    testWidgets('$preset dark switch gives emphasis to the on state', (
      tester,
    ) async {
      final theme = ComicThemeData.preset(preset, Brightness.dark);
      final colors = <Color>[];
      for (final value in [false, true]) {
        await tester.pumpWidget(
          _host(
            theme,
            ComicSwitch(value: value, label: 'Updates', onChanged: (_) {}),
          ),
        );
        await tester.pumpAndSettle();
        colors.add(
          await _pixel(tester, find.byType(ComicSwitch), const Offset(24, 17)),
        );
      }
      expect(colors.first, theme.colors.card);
      expect(colors.last, theme.colors.caption);
      expect(
        colors.first.computeLuminance(),
        lessThan(colors.last.computeLuminance()),
      );
    }, tags: 'goldens'); // drawn pixels
  }
}
