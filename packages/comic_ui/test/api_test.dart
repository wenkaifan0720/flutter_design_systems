import 'dart:ui' show Tristate, SemanticsValidationResult;

// Public call shapes used by a generated app, including runtime adapters.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/comic_host.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  testWidgets('navigation selects by position, with one callback', (
    tester,
  ) async {
    final selected = <int>[];
    var itemPresses = 0;
    final items = [
      ComicNavItem(
        label: 'Home',
        short: 'Home',
        icon: Icons.home,
        onPressed: () => itemPresses++,
      ),
      ComicNavItem(
        label: 'Saved',
        short: 'Saved',
        icon: Icons.bookmark,
        onPressed: () => itemPresses++,
      ),
    ];
    await tester.pumpWidget(
      comicApp(
        ComicNavigationBar(
          destinations: items,
          selectedIndex: 1,
          onDestinationSelected: selected.add,
        ),
      ),
    );
    final presses = tester
        .widgetList<ComicPressable>(find.byType(ComicPressable))
        .toList();
    expect(presses.map((press) => press.selected), [false, true]);
    await tester.tap(find.text('HOME'));
    await tester.pump();
    expect(selected, [0]);
    expect(itemPresses, 0);

    await tester.pumpWidget(comicApp(ComicNavigationBar(destinations: items)));
    await tester.tap(find.text('SAVED'));
    await tester.pump();
    expect(itemPresses, 1);
  });

  testWidgets('choices return values and mark selected tiles', (tester) async {
    final changed = <String>[];
    await tester.pumpWidget(
      comicApp(
        ComicChoices(
          options: const [
            ComicChoice('Mild', value: 'm'),
            ComicChoice('Hot', value: 'h'),
          ],
          value: 'h',
          onChanged: changed.add,
        ),
      ),
    );
    expect(
      tester
          .widgetList<ComicChoiceBox>(find.byType(ComicChoiceBox))
          .map((box) => box.selected),
      [false, true],
    );
    await tester.tap(find.text('Mild'));
    await tester.pump();
    expect(changed, ['m']);
  });

  testWidgets('shell action adapts onPressed to the runtime', (tester) async {
    var calls = 0;
    final action = ComicShellAction(
      icon: Icons.add,
      label: 'New',
      onPressed: (_) => calls++,
    );
    const destinations = [
      ComicNavItem(label: 'Home', short: 'Home', icon: Icons.home),
      ComicNavItem(label: 'Saved', short: 'Saved', icon: Icons.bookmark),
    ];
    for (var count = 0; count <= destinations.length; count++) {
      await tester.pumpWidget(
        comicApp(
          ComicNavigationBar(
            destinations: destinations.take(count).toList(),
            action: action,
          ),
        ),
      );
      final button = find.byWidgetPredicate(
        (w) => w is ComicPressable && w.label == 'New',
      );
      expect(button, findsOneWidget, reason: '$count destinations');
      await tester.tap(button);
      await tester.pump();
      expect(calls, count + 1);
    }
  });
  testWidgets('checkbox error is named, announced and resolves error styling', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      var sawError = false;
      await tester.pumpWidget(
        comicApp(
          ComicCheckbox(
            label: 'Accept terms',
            value: false,
            isError: true,
            onChanged: (_) {},
            style: ComicStyle(
              side: WidgetStateProperty.resolveWith((states) {
                sawError |= states.contains(WidgetState.error);
                return const BorderSide(color: Color(0xff123456), width: 3);
              }),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.bySemanticsLabel('Accept terms'));
      expect(node.getSemanticsData().label, 'Accept terms');
      expect(
        node.getSemanticsData().validationResult,
        SemanticsValidationResult.invalid,
      );
      expect(sawError, isTrue);
      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(ComicCheckbox),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration;
      expect(
        (decoration.shape as OutlinedBorder).side.color,
        const Color(0xff123456),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'chip primary and delete actions are separate and respect enabled',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        var primary = 0, removed = 0;
        Widget chip(bool enabled) => ComicChip(
          'Issue 12',
          icon: ComicGlyphs.search,
          selected: true,
          onPressed: enabled ? () => primary++ : null,
          onDeleted: enabled ? () => removed++ : null,
          deleteButtonTooltipMessage: 'Remove issue',
        );
        await tester.pumpWidget(comicApp(Center(child: chip(true))));
        expect(find.byIcon(ComicGlyphs.search), findsOneWidget);
        final label = find.byWidgetPredicate(
          (w) => w is ComicPressable && w.label == 'Issue 12',
        );
        final remove = find.byWidgetPredicate(
          (w) => w is ComicPressable && w.label == 'Remove issue',
        );
        // The press's own node: getSemantics on the pressable starts at its reach box, which owns none, and walks up.
        expect(
          tester
              .getSemantics(find.bySemanticsLabel('Issue 12'))
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        await tester.tap(label);
        await tester.pump();
        expect([primary, removed], [1, 0]);
        await tester.tap(remove);
        await tester.pump();
        expect([primary, removed], [1, 1]);
        await tester.pumpWidget(comicApp(Center(child: chip(false))));
        await tester.tap(label);
        await tester.tap(remove);
        await tester.pump();
        expect([primary, removed], [1, 1]);
        for (final name in ['Issue 12', 'Remove issue']) {
          expect(
            tester
                .getSemantics(find.bySemanticsLabel(name))
                .getSemanticsData()
                .flagsCollection
                .isEnabled,
            Tristate.isFalse,
          );
        }
        expect(tester.takeException(), isNull);
      } finally {
        semantics.dispose();
      }
    },
  );

  testWidgets('snack helper carries each tone to its distinct mark', (
    tester,
  ) async {
    late BuildContext launch;
    await tester.pumpWidget(
      comicApp(
        Builder(
          builder: (context) {
            launch = context;
            return const SizedBox();
          },
        ),
      ),
    );
    for (final tone in ComicTone.values) {
      final handle = showComicSnackBar(launch, 'Saved issue', tone: tone);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ComicToneMark>(find.byType(ComicToneMark)).tone,
        tone,
      );
      expect(find.text('Saved issue'), findsOneWidget);
      handle.dismiss();
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
