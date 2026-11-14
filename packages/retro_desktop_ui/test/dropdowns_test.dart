// Dropdowns (design6, 11-11 16:34): from 600 up a select and a combobox
// stand at their column's start, at most 320 wide, closed; a
// select's open list is at least as wide as its field and starts on its
// leading edge. At 600, 1024, 1440 and 1920, in both appearances.
// And (design6, 11-11 night) at 390 and 1440: a select's, a combobox's and a
// menu's open list, opened from a card, floats over it in
// the window's overlay, whole on the screen; a field's options start their
// words on one x, the field's value's.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

const _options = [
  RetroDesktopOption('here', 'This computer'),
  RetroDesktopOption('cloud', 'A shared folder online, kept in step'),
];

void main() {
  setUpAll(() async {
    await loadRetroDesktopFonts();
    await loadRetroDesktopGlyphFace();
  });

  for (final appearance in RetroDesktopAppearance.values) {
    testWidgets('${appearance.name}: dropdowns hug from 600 up; a select\'s '
        'list is at least its field\'s width, on its leading edge', (
      tester,
    ) async {
      final faults = <String>[];
      for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey(width),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, page) => RetroDesktopTheme(
                data: RetroDesktopThemeData.preset(
                  'classic',
                  Brightness.light,
                ).copyWith(appearance: appearance).atWidth(width),
                child: page!,
              ),
              home: Builder(
                builder: (context) => ColoredBox(
                  color: RetroDesktopTheme.of(context).colors.platinum,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        key: const ValueKey('column'),
                        width: 520,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            RetroDesktopSelect<String>(
                              label: 'Save new documents to',
                              value: 'here',
                              options: _options,
                              onChanged: (_) {},
                            ),
                            const SizedBox(height: 16),
                            RetroDesktopCombobox<String>(
                              label: 'Country',
                              options: const ['Austria', 'Belgium', 'Chile'],
                              onSelected: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final column = tester.getRect(find.byKey(const ValueKey('column')));
        Rect closed(Finder part) => tester.getRect(
          find
              .descendant(
                of: part,
                matching: find.byType(RetroDesktopPressable),
              )
              .first,
        );
        final select = closed(find.byType(RetroDesktopSelect<String>));
        final parts = <String, Rect>{
          'select': select,
          'combobox': tester.getRect(
            find
                .descendant(
                  of: find.byType(RetroDesktopCombobox<String>),
                  matching: find.byType(EditableText),
                )
                .first,
          ),
        };
        for (final MapEntry(key: name, value: r) in parts.entries) {
          if (r.right - column.left > 320.5) {
            faults.add(
              '$width: the $name reaches ${r.right - column.left} into its '
              'column, past 320',
            );
          }
        }
        if ((select.left - column.left).abs() > .5) {
          faults.add(
            '$width: the select starts ${select.left - column.left} in',
          );
        }
        await tester.tap(find.text('This computer'));
        await tester.pumpAndSettle();
        final list = tester.getRect(find.byType(RetroDesktopMenu<String>));
        if (list.width < select.width - .5) {
          faults.add(
            '$width: the select\'s list is ${list.width} wide, its field '
            '${select.width}',
          );
        }
        if ((list.left - select.left).abs() > .5) {
          faults.add(
            '$width: the select\'s list starts at ${list.left}, its field at '
            '${select.left}',
          );
        }
        if (find
            .text('A shared folder online, kept in step')
            .evaluate()
            .isEmpty) {
          faults.add('$width: the list does not show the longest option');
        }
        await tester.tapAt(Offset(width - 10, 880));
        await tester.pumpAndSettle();
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });

    testWidgets('${appearance.name}: an open list in a card floats over it '
        'whole, its options\' words on one x, the field\'s', (tester) async {
      final faults = <String>[];
      for (final width in const [390.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          KeyedSubtree(
            key: ValueKey('card $width'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              builder: (context, page) => RetroDesktopTheme(
                data: RetroDesktopThemeData.preset(
                  'classic',
                  Brightness.light,
                ).copyWith(appearance: appearance).atWidth(width),
                child: page!,
              ),
              home: Builder(
                builder: (context) => ColoredBox(
                  color: RetroDesktopTheme.of(context).colors.platinum,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: 320,
                        child: RetroDesktopCard(
                          title: 'Where to keep it',
                          children: [
                            RetroDesktopSelect<String>(
                              label: 'Save new documents to',
                              value: 'here',
                              options: _options,
                              onChanged: (_) {},
                            ),
                            RetroDesktopCombobox<String>(
                              label: 'Country',
                              hint: 'Choose a country',
                              options: const ['Austria', 'Belgium', 'Chile'],
                              onSelected: (_) {},
                            ),
                            RetroDesktopMenuAnchor<String>(
                              items: const [
                                RetroDesktopMenuItem('open', 'Open'),
                                RetroDesktopMenuItem('rename', 'Rename'),
                              ],
                              builder: (context, open) =>
                                  RetroDesktopButton('More', onPressed: open),
                              onSelected: (_) {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = tester.renderObject(find.byType(RetroDesktopCard));
        final screen = Offset.zero & Size(width, 900);
        // Opens [name] by [opener], then reads each of [options]' words in the
        // list: on one x, and on [field]'s x when given; outside the card's
        // paint (no clip of the card reaches it), on the screen whole.
        Future<void> open(
          String name,
          Finder opener,
          List<String> options, {
          double? field,
        }) async {
          await tester.tap(opener);
          await tester.pumpAndSettle();
          final at = '$width $name';
          final xs = <double>[];
          for (final words in options) {
            final shown = find.text(words);
            if (shown.evaluate().isEmpty) {
              faults.add('$at: "$words" is not in the open list');
              continue;
            }
            final rect = tester.getRect(shown.last);
            xs.add(rect.left);
            if (!screen.contains(rect.topLeft) ||
                !screen.contains(rect.bottomRight - const Offset(.1, .1))) {
              faults.add('$at: "$words" stands off the screen at $rect');
            }
            RenderObject? up = tester.renderObject(shown.last);
            while (up != null && !identical(up, card)) {
              up = up.parent;
            }
            if (up != null) {
              faults.add(
                '$at: the list paints inside its card, under its clip',
              );
            }
          }
          if (xs.isNotEmpty) {
            for (final x in xs) {
              if ((x - xs.first).abs() > .5) {
                faults.add('$at: options\' words start at $xs, not one x');
                break;
              }
            }
            if (field != null && (xs.first - field).abs() > 1) {
              faults.add(
                '$at: options\' words start at ${xs.first}, the field\'s '
                'at $field',
              );
            }
          }
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          FocusManager.instance.primaryFocus?.unfocus();
          await tester.pumpAndSettle();
        }

        double leftOf(Finder f) => tester.getRect(f).left;
        await open('select', find.text('This computer'), [
          'This computer',
          'A shared folder online, kept in step',
        ], field: leftOf(find.text('This computer')));
        await open('combobox', find.text('Choose a country'), [
          'Austria',
          'Belgium',
          'Chile',
        ], field: leftOf(find.text('Choose a country')));
        await open('menu', find.text('More'), ['Open', 'Rename']);
      }
      expect(faults, isEmpty, reason: faults.join('\n'));
    });
  }
}
