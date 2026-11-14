/// Chips: the four kinds' geometry (32dp on the token shape inside the 48dp
/// target, Compose's paddings and 8dp arrangement), selection and the
/// filter chip's springing check, the input chip's remove target, the
/// morphing shapes, semantics, disabled chips, and chip rows that stay
/// overflow-safe (Cody v2's chip-row test, ported).
library;

import 'dart:ui' show CheckedState;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/chips_tokens.g.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/filter_chip_tokens.g.dart';

import 'support/pressable.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Widget _app(Widget child) => ExpressiveHost(
  light: _theme,
  brightness: Brightness.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(child: child),
    ),
  ),
);

/// The chip's drawn container: the surface inside its touch target.
Rect _container(WidgetTester tester, Finder chip) => tester.getRect(
  find.descendant(of: chip, matching: find.byType(ExpressiveSurface)).first,
);

void main() {
  testWidgets('32dp container in the 48dp target; label-only padding is '
      'content padding plus the arrangement', (tester) async {
    await tester.pumpWidget(
      _app(const ExpressiveChip.assist('Share', onPressed: _noop)),
    );
    final chip = find.byType(ExpressiveChip);
    expect(
      tester.getSize(chip).height,
      HostBehavior.minimumInteractiveComponentSize,
    );
    final box = _container(tester, chip);
    expect(box.height, ChipsTokens.height);
    final label = tester.getRect(find.text('Share'));
    // 8dp content padding + the empty leading slot's 8dp spacing.
    const inset = ChipBehavior.contentPadding + ChipBehavior.horizontalSpacing;
    expect(label.left - box.left, inset);
    expect(box.right - label.right, inset);
  });

  // A slot's content (the check, an avatar, the close glyph) must not grow
  // to a bounded parent's height: a row (loose) and a scrolling chip row
  // in a fixed-height bar (the scroll view gets a tight 64dp).
  for (final scrolling in [false, true]) {
    testWidgets('under a bounded 64dp height '
        '(${scrolling ? 'scrolling chip row' : 'row'}) chips with slot '
        'content keep their 32dp container', (tester) async {
      const chips = <Widget>[
        ExpressiveChip.filter('Soul', selected: true, onPressed: _noop),
        ExpressiveChip.filter(
          'Folk',
          selected: true,
          elevated: true,
          onPressed: _noop,
        ),
        ExpressiveChip.input(
          'Lisbon',
          avatar: SizedBox.expand(),
          onPressed: _noop,
          onDeleted: _noop,
        ),
      ];
      await tester.pumpWidget(
        _app(
          SizedBox(
            height: 64,
            width: 400,
            child: scrolling
                ? const ExpressiveChipRow(scrollable: true, children: chips)
                : const Row(children: chips),
          ),
        ),
      );
      final found = find.byType(ExpressiveChip);
      expect(found, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        expect(_container(tester, found.at(i)).height, ChipsTokens.height);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a scrolling chip row takes the page margin inside its scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 400,
          child: ExpressiveChipRow(
            scrollable: true,
            padding: EdgeInsets.symmetric(horizontal: 16),
            children: <Widget>[
              ExpressiveChip.filter(
                'Morning',
                selected: false,
                onPressed: _noop,
              ),
              ExpressiveChip.filter(
                'Evening',
                selected: false,
                onPressed: _noop,
              ),
            ],
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(ExpressiveChipRow));
    final first = tester.getRect(find.byType(ExpressiveChip).first);
    expect(first.left - row.left, moreOrLessEquals(16, epsilon: 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('input chip paddings follow InputChipDefaults.contentPadding', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const ExpressiveChip.input(
          'Lisbon',
          avatar: SizedBox.expand(),
          onPressed: _noop,
          onDeleted: _noop,
        ),
      ),
    );
    final chip = find.byType(ExpressiveChip);
    final box = _container(tester, chip);
    final label = tester.getRect(find.text('Lisbon'));
    // Avatar: 4dp start, 24dp avatar, 8dp; trailing: 8dp, 18dp close, 8dp.
    expect(
      label.left - box.left,
      InputChipBehavior.compactPadding +
          ChipsTokens.avatarSize +
          ChipBehavior.horizontalSpacing,
    );
    expect(
      box.right - label.right,
      ChipBehavior.horizontalSpacing +
          ChipsTokens.trailingIconSize +
          InputChipBehavior.iconPadding,
    );
  });

  testWidgets(
    'a compact input chip keeps its avatar 4dp clear of the outline',
    (tester) async {
      await tester.pumpWidget(
        ExpressiveHost(
          light: _theme.copyWith(density: ExpressiveDensity.compact),
          brightness: Brightness.light,
          child: const Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData(),
              child: Center(
                child: ExpressiveChip.input(
                  'Lisbon',
                  avatar: SizedBox.expand(key: Key('avatar')),
                  onPressed: _noop,
                  onDeleted: _noop,
                ),
              ),
            ),
          ),
        ),
      );
      final box = _container(tester, find.byType(ExpressiveChip));
      final avatar = tester.getRect(find.byKey(const Key('avatar')));
      expect(box.height, lessThan(ChipsTokens.height));
      expect(avatar.top - box.top, InputChipBehavior.compactPadding);
      expect(box.bottom - avatar.bottom, InputChipBehavior.compactPadding);
      expect(avatar.left - box.left, InputChipBehavior.compactPadding);
    },
  );

  testWidgets('a filter chip toggles, shows its check springing in, and '
      'announces checked', (tester) async {
    final semantics = tester.ensureSemantics();
    var selected = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, update) => ExpressiveChip.filter(
            'Open now',
            selected: selected,
            onPressed: () => update(() => selected = !selected),
          ),
        ),
      ),
    );
    expect(find.byIcon(ExpressiveSymbols.check), findsNothing);
    final before = tester.getSize(find.byType(ExpressiveChip)).width;
    await tester.tap(find.byType(ExpressiveChip));
    await tester.pump();
    expect(selected, isTrue);
    expect(find.byIcon(ExpressiveSymbols.check), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    // The check's 18dp opened in the leading slot.
    expect(
      tester.getSize(find.byType(ExpressiveChip)).width,
      closeTo(before + FilterChipTokens.iconSize, 0.01),
    );
    final data = tester
        .getSemantics(find.byType(ExpressiveChip))
        .getSemanticsData();
    expect(data.flagsCollection.isChecked, CheckedState.isTrue);

    await tester.tap(find.byType(ExpressiveChip));
    await tester.pumpAndSettle();
    expect(selected, isFalse);
    expect(find.byIcon(ExpressiveSymbols.check), findsNothing);
    expect(
      tester.getSize(find.byType(ExpressiveChip)).width,
      closeTo(before, 0.01),
    );
    semantics.dispose();
  });

  testWidgets('the morphing shapes: medium at rest, full selected, small '
      'pressed', (tester) async {
    await tester.pumpWidget(
      _app(
        const ExpressiveChip.filter(
          'Patio',
          selected: true,
          morph: true,
          onPressed: _noop,
        ),
      ),
    );
    final pressable = tester.widget<ExpressivePressable>(
      find.byType(ExpressivePressable),
    );
    expect(
      pressable.shapes.shape,
      _theme.shapes.of(ChipsTokens.unselectedShape),
    );
    expect(pressable.shapes.selected, _theme.shapes.full);
    expect(pressable.shapes.pressed, _theme.shapes.small);
    expect(pressable.motion, ChipBehavior.shapeMotion);

    await tester.pumpWidget(
      _app(
        const ExpressiveChip.filter('Patio', selected: true, onPressed: _noop),
      ),
    );
    final plain = tester.widget<ExpressivePressable>(
      find.byType(ExpressivePressable),
    );
    expect(
      plain.shapes.shape,
      _theme.shapes.of(FilterChipTokens.containerShape),
    );
    expect(plain.shapes.selected, isNull);
  });

  testWidgets('an input chip removes from its close glyph, activates from '
      'its body', (tester) async {
    var pressed = 0;
    var deleted = 0;
    await tester.pumpWidget(
      _app(
        ExpressiveChip.input(
          'Mara Quist',
          onPressed: () => pressed++,
          onDeleted: () => deleted++,
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Remove Mara Quist'));
    expect(deleted, 1);
    expect(pressed, 0);
    await tester.tap(pressableOf(find.text('Mara Quist')));
    expect(pressed, 1);
    expect(deleted, 1);

    // The pointer says the glyph presses, as it says over the body: the
    // glyph sets the body's adaptive clickable cursor (the hand on the web),
    // not the arrow of the page behind.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is MouseRegion &&
            w.cursor == WidgetStateMouseCursor.adaptiveClickable,
      ),
      findsOneWidget,
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final cursors = <MouseCursor?>[];
    for (final over in [
      find.bySemanticsLabel('Remove Mara Quist'),
      find.text('Mara Quist'),
    ]) {
      await mouse.moveTo(tester.getCenter(over));
      await tester.pump();
      cursors.add(
        RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      );
    }
    expect(cursors.first, cursors.last);
    expect(
      cursors.first,
      WidgetStateMouseCursor.adaptiveClickable.resolve(const {}),
    );
  });

  testWidgets('disabled chips never report', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExpressiveChip.assist(
              'Offline',
              enabled: false,
              onPressed: () => taps++,
            ),
            ExpressiveChip.filter(
              'Closed',
              selected: false,
              enabled: false,
              onPressed: () => taps++,
            ),
            ExpressiveChip.input(
              'Archived',
              enabled: false,
              onPressed: () => taps++,
              onDeleted: () => taps++,
            ),
          ],
        ),
      ),
    );
    await tester.tap(pressableOf(find.text('Offline')));
    await tester.tap(pressableOf(find.text('Closed')));
    await tester.tap(pressableOf(find.text('Archived')));
    await tester.tap(pressableOf(find.byIcon(ExpressiveSymbols.close)));
    expect(taps, 0);
  });

  testWidgets('elevated chips cast their token shadow; flat ones outline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExpressiveChip.assist('Flat', onPressed: _noop),
            ExpressiveChip.assist('Raised', elevated: true, onPressed: _noop),
          ],
        ),
      ),
    );
    final surfaces = tester
        .widgetList<ExpressiveSurface>(find.byType(ExpressiveSurface))
        .toList();
    expect(surfaces[0].side.width, 1);
    expect(surfaces[0].side.color, _theme.colors.outlineVariant);
    expect(surfaces[0].shadowElevation, ExpressiveElevationLevel.level0);
    expect(surfaces[1].side, BorderSide.none);
    expect(surfaces[1].color, _theme.colors.surfaceContainerLow);
    expect(surfaces[1].shadowElevation, ExpressiveElevationLevel.level1);
  });

  // Cody: 'meta row and chip row stay overflow-safe at narrow widths'.
  testWidgets('chip rows stay overflow-safe at narrow widths', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ExpressiveChipRow(
                children: <Widget>[
                  for (var index = 0; index < 12; index += 1)
                    ExpressiveChip.filter(
                      'Filter $index',
                      selected: index.isEven,
                      onPressed: _noop,
                    ),
                ],
              ),
              ExpressiveChip.assist(
                'An unreasonably verbose suggestion that cannot fit ' * 3,
                icon: ExpressiveSymbols.map,
                onPressed: _noop,
              ),
              const ExpressiveChipRow(
                scrollable: true,
                children: <Widget>[
                  ExpressiveChip.suggestion('One', onPressed: _noop),
                  ExpressiveChip.suggestion('Two', onPressed: _noop),
                  ExpressiveChip.suggestion('Three', onPressed: _noop),
                  ExpressiveChip.suggestion('Four', onPressed: _noop),
                  ExpressiveChip.suggestion('Five', onPressed: _noop),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Wrap)).height, greaterThan(80));
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
