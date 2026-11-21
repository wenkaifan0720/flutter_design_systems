import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<String> _ran = [];
final Map<String, Set<WidgetState>> _states = {};

// The bare reference painter: "Save" and "v" side by side; a grey menu.
Widget _button({
  TextDirection direction = TextDirection.ltr,
  AlignmentGeometry alignment = Alignment.center,
}) => harness(
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Align(
      alignment: alignment,
      child: RawSplitButton(
        label: 'Save',
        onPressed: () => _ran.add('save'),
        actions: [
          RawSplitAction(label: 'Save as', onPressed: () => _ran.add('as')),
          RawSplitAction(label: 'Save all', onPressed: () => _ran.add('all')),
        ],
        buttonBuilder: (context, part, states, open) {
          _states[part.name] = states;
          return Text(part == RawSplitPart.main ? 'Save' : (open ? '^' : 'v'));
        },
        itemBuilder: (context, action, states) {
          _states[action.label] = states;
          return SizedBox(width: 120, height: 44, child: Text(action.label));
        },
        surfaceBuilder: (context, info, items) => ColoredBox(
          key: const ValueKey('menu surface'),
          color: const Color(0xFFEEEEEE),
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ),
    ),
  ),
  textDirection: direction,
);

bool _lit(String key) => _states[key]?.contains(WidgetState.focused) ?? false;

Future<void> _key(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pumpAndSettle();
}

void main() {
  behaviourContract(
    'RawSplitButton',
    build: (c) => Center(
      child: RawSplitButton(
        label: 'Save',
        onPressed: c.enabled ? () => _ran.add('save') : null,
        actions: [
          RawSplitAction(label: 'Save as', onPressed: () => _ran.add('as')),
        ],
        buttonBuilder: (context, part, states, open) =>
            Text(part == RawSplitPart.main ? 'Save' : (open ? '^' : 'v')),
        itemBuilder: (context, action, states) =>
            SizedBox(width: 120, height: 44, child: Text(action.label)),
        surfaceBuilder: (context, info, items) => ColoredBox(
          color: const Color(0xFFEEEEEE),
          child: Column(mainAxisSize: MainAxisSize.min, children: items),
        ),
      ),
    ),
    node: () => find.text('Save'),
    semantics: isSemantics(
      label: 'Save',
      isButton: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
    ),
    disabled: isSemantics(
      isButton: true,
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasTapAction: false,
    ),
    keyboard: (p) async {
      await p.tabInto();
      await p.tab();
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('More options')),
        isSemantics(isFocused: true, isExpanded: false),
      );
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(find.text('Save as'), findsOneWidget, reason: 'Down opens');
      await p.key(LogicalKeyboardKey.escape);
      expect(find.text('Save as'), findsNothing, reason: 'Escape closes');
      expect(
        p.tester.getSemantics(find.bySemanticsLabel('More options')),
        isSemantics(isFocused: true),
        reason: 'focus returns to the toggle',
      );
    },
    rtl: (p) async {
      expect(
        p.tester.getCenter(find.text('v')).dx,
        lessThan(p.tester.getCenter(find.text('Save')).dx),
        reason: 'the toggle is at the end',
      );
    },
    motion: (p) async {
      await p.tester.tap(find.text('v'));
      await p.tester.pump();
    },
  );
  setUp(() {
    _ran.clear();
    _states.clear();
  });

  for (final direction in TextDirection.values) {
    testWidgets(
      'the default menu shifts to the screen margin in ${direction.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 600);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _button(
            direction: direction,
            alignment: AlignmentDirectional.centerStart,
          ),
        );
        final button = tester.getRect(find.byType(RawSplitButton));
        await tester.tap(find.text('v'));
        await tester.pumpAndSettle();
        final menu = tester.getRect(find.byKey(const ValueKey('menu surface')));
        const margin = 8.0;
        if (direction == TextDirection.ltr) {
          expect(button.right - menu.width, lessThan(margin));
          expect(menu.left, margin);
        } else {
          expect(button.left + menu.width, greaterThan(390 - margin));
          expect(menu.right, 390 - margin);
        }
      },
    );

    testWidgets(
      'the default menu meets the trailing edge in ${direction.name}',
      (tester) async {
        await tester.pumpWidget(_button(direction: direction));
        final button = tester.getRect(find.byType(RawSplitButton));
        await tester.tap(find.text('v'));
        await tester.pumpAndSettle();
        final menu = tester.getRect(find.byKey(const ValueKey('menu surface')));
        expect(menu.width, greaterThan(button.width));
        if (direction == TextDirection.ltr) {
          expect(menu.right, button.right);
        } else {
          expect(menu.left, button.left);
        }
      },
    );

    testWidgets(
      'the split menu meets the painted button edge in ${direction.name}',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(390, 600);
        addTearDown(tester.view.reset);
        const capture = ValueKey('split capture');
        const button = ValueKey('button outline');
        const panel = ValueKey('menu outline');
        const border = Color(0xffed2734);
        const decoration = BoxDecoration(
          color: Color(0xfffafafa),
          border: Border.fromBorderSide(BorderSide(color: border, width: 2)),
          boxShadow: [
            BoxShadow(
              color: Color(0x88444444),
              offset: Offset(5, 2),
              blurRadius: 4,
            ),
          ],
        );
        // A centred button has space on both sides. At the trailing margin a
        // wide list fits only if its trailing outline touches the button's.
        for (final (position, align, itemWidth, leading) in [
          (AlignmentDirectional.center, RawPopoverAlign.start, 174.0, true),
          (AlignmentDirectional.centerEnd, RawPopoverAlign.start, 174.0, false),
          (AlignmentDirectional.center, RawPopoverAlign.end, 174.0, false),
          (AlignmentDirectional.center, RawPopoverAlign.start, 35.0, true),
        ]) {
          await tester.pumpWidget(
            harness(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: position,
                  child: RawSplitButton(
                    label: 'Save',
                    onPressed: () {},
                    actions: [RawSplitAction(label: 'Copy', onPressed: () {})],
                    placement: RawPopoverPlacement(
                      align: align,
                      matchAnchorWidth: itemWidth >= 44,
                    ),
                    layoutBuilder: (_, main, toggle) => DecoratedBox(
                      key: button,
                      decoration: decoration,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [main, toggle],
                        ),
                      ),
                    ),
                    buttonBuilder: (_, part, states, open) =>
                        Text(part == RawSplitPart.main ? 'Save' : 'v'),
                    itemBuilder: (_, action, states) => SizedBox(
                      width: itemWidth,
                      height: 44,
                      child: Text(action.label),
                    ),
                    surfaceBuilder: (_, info, items) => DecoratedBox(
                      key: panel,
                      decoration: decoration,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: items,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              textDirection: direction,
              wrap: (_, nav) => RepaintBoundary(key: capture, child: nav),
            ),
          );
          await tester.tap(find.text('v'));
          await tester.pumpAndSettle();
          final anchor = tester.getRect(find.byKey(button));
          final menu = tester.getRect(find.byKey(panel));
          final left = (direction == TextDirection.ltr) == leading;
          final edge = left ? anchor.left : anchor.right;
          expect(left ? menu.left : menu.right, edge);
          expect(menu.width, greaterThanOrEqualTo(anchor.width));
          if (itemWidth < anchor.width) expect(menu.width, anchor.width);
          await tester.runAsync(() async {
            final image = await tester
                .renderObject<RenderRepaintBoundary>(find.byKey(capture))
                .toImage();
            final rgba = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final width = image.width;
            image.dispose();
            final x = edge.round() - (left ? 0 : 1);
            int pixel(int dx, int y) => rgba.getUint32((y * width + dx) * 4);
            for (final outline in [anchor, menu]) {
              final y = outline.top.round() + 5;
              expect(
                pixel(x, y),
                0xed2734ff,
                reason: '$position • $outline • $x, $y',
              );
              expect(pixel(x + (left ? -1 : 1), y), isNot(0xed2734ff));
            }
          });
          await _key(tester, LogicalKeyboardKey.escape);
        }
      },
    );
  }

  testWidgets('two tab stops; the main half runs; the toggle opens the menu; '
      'an item runs after it closes', (tester) async {
    await tester.pumpWidget(_button());
    await tester.tap(find.text('Save'));
    expect(_ran, ['save']);
    expect(
      tester.getSize(find.byType(RawSplitButton)),
      const Size(56 + 44, 44),
      reason: 'the toggle\'s one glyph still gets a 44 px target',
    );
    await tester.tap(find.text('v'));
    await tester.pumpAndSettle();
    expect(find.text('^'), findsOneWidget);
    await tester.tap(find.text('Save all'));
    await tester.pumpAndSettle();
    expect(_ran, ['save', 'all']);
    expect(find.text('Save all'), findsNothing);
  });

  testWidgets('keyboard: Down opens at the first item; arrows move; Escape '
      'closes and focus returns', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(_button());
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_lit('main'), isTrue);
    await _key(tester, LogicalKeyboardKey.tab);
    expect(_lit('toggle'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit('Save as'), isTrue);
    await _key(tester, LogicalKeyboardKey.arrowDown);
    expect(_lit('Save all'), isTrue);
    await _key(tester, LogicalKeyboardKey.escape);
    expect(find.text('Save all'), findsNothing);
    expect(_lit('toggle'), isTrue);
  });

  testWidgets('a screen reader hears the main action and an expandable '
      'toggle', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_button());
    expect(
      tester.getSemantics(find.text('v')),
      isSemantics(
        label: 'More options',
        isButton: true,
        hasExpandedState: true,
        isExpanded: false,
      ),
    );
    expect(
      tester.getSemantics(find.text('Save')),
      isSemantics(label: 'Save', isButton: true),
    );
    semantics.dispose();
  });
}
