/// Overlays: Compose's `AlertDialog` (layout, actions' flow, the spring
/// route, which leaves the system back to a menu held open in it first),
/// `PlainTooltip` / `RichTooltip` in a `TooltipBox` (long press, hover,
/// persistence), the rich tooltip's action slot, and the coach mark (its
/// caret; with a widget action, Back, Escape and a tap outside, Tab onto
/// its action and focus back on its anchor).
library;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/behavior.g.dart';

final ExpressiveThemeData bloom = ExpressiveThemeData.preset(
  'bloom',
  Brightness.light,
);

Widget host(WidgetBuilder builder, {bool nested = false}) {
  final app = MaterialApp(
    builder: (context, app) =>
        ExpressiveHost(light: bloom, brightness: Brightness.light, child: app!),
    home: Builder(
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(alignment: Alignment.topCenter, child: builder(context)),
        ),
      ),
    ),
  );
  return nested ? MaterialApp(home: app) : app;
}

Finder get dialog => find.byType(ExpressiveDialog);

void main() {
  group('dialog', () {
    testWidgets('a filled action is a filled button, confirm last', (
      tester,
    ) async {
      Object? closed;
      await tester.pumpWidget(
        host(
          (context) => Center(
            child: ExpressiveTextButton(
              'Open',
              onPressed: () async {
                closed = await showExpressiveDialog<Object>(
                  context: context,
                  builder: (_) => const ExpressiveDialog(
                    title: 'Empty trash?',
                    text: '2 notes will be deleted forever.',
                    actions: [
                      ExpressiveDialogAction('Cancel'),
                      ExpressiveDialogAction(
                        'Empty',
                        filled: true,
                        value: 'empty',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      // The label sits under its button's pressable, which takes the tap.
      await tester.tap(find.text('Open'), warnIfMissed: false);
      await tester.pumpAndSettle();
      final empty = find.ancestor(
        of: find.text('Empty'),
        matching: find.bySubtype<ExpressiveButton>(),
      );
      expect(empty, findsOneWidget);
      // The dismiss is the dialog's own text action, not an app button.
      expect(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.byType(ExpressivePressable),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Cancel'),
          matching: find.bySubtype<ExpressiveButton>(),
        ),
        findsNothing,
      );
      // The confirm ends the row.
      expect(
        tester.getCenter(find.text('Empty')).dx,
        greaterThan(tester.getCenter(find.text('Cancel')).dx),
      );
      await tester.tap(empty);
      await tester.pumpAndSettle();
      expect(closed, 'empty');
      expect(dialog, findsNothing);
    });

    testWidgets('lays out as AlertDialogContent', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => const ExpressiveDialog(
            icon: ExpressiveSymbols.delete,
            title: 'Delete this trip?',
            text: 'Its notes and photos go with it.',
            actions: [
              ExpressiveDialogAction('Cancel'),
              ExpressiveDialogAction('Delete'),
            ],
          ),
        ),
      );
      final box = tester.getRect(dialog);
      expect(box.width, greaterThanOrEqualTo(AlertDialogBehavior.minWidth));
      final surface = tester.widget<ExpressiveSurface>(
        find
            .descendant(of: dialog, matching: find.byType(ExpressiveSurface))
            .first,
      );
      expect(surface.color, bloom.colors.surfaceContainerHigh);
      expect(
        (surface.shape as ExpressiveCornerBorder).radiiOn(box).topLeft.x,
        28,
      );
      // The icon: 24dp in `secondary`, centred, 24dp from the top.
      final icon = tester.getRect(find.byIcon(ExpressiveSymbols.delete));
      expect(icon.top - box.top, AlertDialogBehavior.padding);
      expect(icon.center.dx, closeTo(box.center.dx, 0.01));
      // The headline centres under an icon, 16dp below it.
      final title = tester.getRect(find.text('Delete this trip?'));
      expect(title.top - icon.bottom, AlertDialogBehavior.iconPaddingBottom);
      expect(title.center.dx, closeTo(box.center.dx, 0.5));
      final style = tester.widget<Text>(find.text('Delete this trip?')).style!;
      expect(style.fontSize, bloom.type.headlineSmall.fontSize);
      expect(style.color, bloom.colors.onSurface);
      // Actions end-aligned, confirm last in the row, 8dp apart, 24dp in.
      final confirm = tester.getRect(find.text('Delete'));
      final dismiss = tester.getRect(find.text('Cancel'));
      expect(confirm.left, greaterThan(dismiss.right));
      final confirmButton = tester.getRect(
        find
            .ancestor(
              of: find.text('Delete'),
              matching: find.byType(ExpressiveSurface),
            )
            .first,
      );
      expect(box.right - confirmButton.right, AlertDialogBehavior.padding);
      expect(confirmButton.height, 40);
      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Delete'))
            .text
            .style!
            .color,
        bloom.colors.primary,
      );
    });

    testWidgets('stacked actions put the confirm action first', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => const ExpressiveDialog(
            title: 'Share your itinerary?',
            actions: [
              ExpressiveDialogAction('Keep it to myself for now'),
              ExpressiveDialogAction('Share with everyone on the trip'),
            ],
          ),
        ),
      );
      final confirm = tester.getRect(
        find.text('Share with everyone on the trip'),
      );
      final dismiss = tester.getRect(find.text('Keep it to myself for now'));
      expect(confirm.bottom, lessThan(dismiss.top));
      // The 48dp touch targets already hold the stack apart, so the 8dp
      // spacing drops to 0 (`buttonPaddingFromMICS`): label to label is the
      // labels' 10dp padding in their 40dp buttons plus the targets' 4dp.
      expect(dismiss.top - confirm.bottom, closeTo(10 + 4 + 4 + 10, 0.5));
    });

    testWidgets('showExpressiveDialog raises it on a spring and returns', (
      tester,
    ) async {
      Future<Object?>? result;
      var confirmed = 0;
      await tester.pumpWidget(
        host(
          nested: true,
          (context) => GestureDetector(
            onTap: () => result = showExpressiveDialog<Object?>(
              context: context,
              builder: (context) => ExpressiveDialog(
                title: 'Leave the group?',
                text: 'You can rejoin with a new invite.',
                actions: [
                  const ExpressiveDialogAction('Stay'),
                  ExpressiveDialogAction(
                    'Leave',
                    value: 'left',
                    onPressed: () => confirmed++,
                  ),
                ],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final fading = tester.widget<FadeTransition>(
        find.ancestor(of: dialog, matching: find.byType(FadeTransition)).first,
      );
      expect(fading.opacity.value, greaterThan(0));
      expect(fading.opacity.value, lessThan(1));
      await tester.pumpAndSettle();
      // The app's theme on the root navigator, outside the app's host.
      final surface = tester.widget<ExpressiveSurface>(
        find
            .descendant(of: dialog, matching: find.byType(ExpressiveSurface))
            .first,
      );
      expect(surface.color, bloom.colors.surfaceContainerHigh);
      final route = ModalRoute.of(tester.element(dialog))!;
      expect(route, isA<ExpressivePopupRoute<Object?>>());
      expect(
        route.transitionDuration,
        expressiveSettleTime(
          ExpressiveMotion(scheme: bloom.motion.scheme)
              .spring(ExpressiveMotionKey.defaultEffects),
        ),
      );
      await tester.tap(
        find
            .ancestor(
              of: find.text('Leave'),
              matching: find.byType(ExpressiveSurface),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(await result, 'left');
      expect(confirmed, 1);
      expect(dialog, findsNothing);
    });

    testWidgets('a menu open in the dialog takes the first back; the dialog '
        'stays up', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => GestureDetector(
            onTap: () => showExpressiveDialog<void>(
              context: context,
              builder: (context) => ExpressiveDialog(
                title: 'Move the trip',
                content: ExpressiveCombobox<String>(
                  label: 'City',
                  options: const <ExpressiveSelectOption<String>>[
                    ExpressiveSelectOption<String>('lisbon', 'Lisbon'),
                    ExpressiveSelectOption<String>('oslo', 'Oslo'),
                  ],
                  onSelected: (_) {},
                ),
                actions: const [ExpressiveDialogAction('Move')],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpressiveSelectTrailingIcon));
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveMenuSurface), findsOneWidget);
      final route = ModalRoute.of(tester.element(dialog))!;

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ExpressiveMenuSurface), findsNothing);
      expect(dialog, findsOneWidget);
      expect(route.isActive, isTrue);
      expect(route.animation!.value, 1);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    });

    testWidgets('long text scrolls inside the screen', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => GestureDetector(
            onTap: () => showExpressiveDialog<void>(
              context: context,
              builder: (context) => ExpressiveDialog(
                title: 'Terms',
                text: List.filled(
                  80,
                  'Every trip keeps its own notes.',
                ).join(' '),
                actions: const [ExpressiveDialogAction('Agree')],
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final box = tester.getRect(dialog);
      expect(box.bottom, lessThanOrEqualTo(600));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Agree'), findsOneWidget);
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
    });
  });

  group('tooltip', () {
    testWidgets('a plain tooltip keeps its text off its edges when dense', (
      tester,
    ) async {
      for (final density in const <ExpressiveDensity>[
        ExpressiveDensity.standard,
        ExpressiveDensity.comfortable,
        ExpressiveDensity.compact,
      ]) {
        await tester.pumpWidget(
          ExpressiveHost(
            light: bloom.copyWith(density: density),
            brightness: Brightness.light,
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: Center(child: ExpressivePlainTooltip('Add to favourites')),
            ),
          ),
        );
        final box = tester.getRect(find.byType(ExpressivePlainTooltip));
        final text = tester.getRect(find.text('Add to favourites'));
        expect(
          text.top - box.top,
          TooltipBehavior.plainVerticalPadding,
          reason: '$density',
        );
        expect(
          box.bottom - text.bottom,
          TooltipBehavior.plainVerticalPadding,
          reason: '$density',
        );
      }
    });

    testWidgets('a plain tooltip shows on long press and leaves after 1.5 s', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => const Padding(
            padding: EdgeInsets.only(top: 100),
            child: ExpressiveTooltip.plain(
              message: 'Add to favourites',
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      );
      final anchor = tester.getRect(find.byType(ExpressiveTooltip));
      await tester.longPress(find.byType(ExpressiveTooltip));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 400));
      final bubble = find.byType(ExpressivePlainTooltip);
      expect(bubble, findsOneWidget);
      final rect = tester.getRect(bubble);
      // Above the anchor, 4dp clear, centred on it.
      expect(
        anchor.top - rect.bottom,
        closeTo(TooltipBehavior.anchorSpacing, 0.01),
      );
      expect(rect.center.dx, closeTo(anchor.center.dx, 0.01));
      expect(rect.height, greaterThanOrEqualTo(TooltipBehavior.minHeight));
      final surface = tester.widget<ExpressiveSurface>(
        find.descendant(of: bubble, matching: find.byType(ExpressiveSurface)),
      );
      expect(surface.color, bloom.colors.inverseSurface);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(bubble, findsNothing);
    });

    testWidgets('a hovering mouse shows it until it leaves', (tester) async {
      await tester.pumpWidget(
        host(
          (context) => const Padding(
            padding: EdgeInsets.only(top: 100),
            child: ExpressiveTooltip.plain(
              message: 'Share',
              child: SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(ExpressiveTooltip)));
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsOneWidget);
      // No timeout while the mouse rests on it.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Share'), findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(find.text('Share'), findsNothing);
      await mouse.removePointer();
    });

    testWidgets('a rich tooltip with an action stays until a tap outside', (
      tester,
    ) async {
      var learned = 0;
      await tester.pumpWidget(
        host(
          (context) => Padding(
            padding: const EdgeInsets.only(top: 240),
            child: ExpressiveTooltip.rich(
              title: 'Shared budgets',
              text: 'Everyone on the trip sees what was spent.',
              actionLabel: 'Learn more',
              onAction: () => learned++,
              child: const SizedBox(width: 48, height: 48),
            ),
          ),
        ),
      );
      await tester.longPress(find.byType(ExpressiveTooltip));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      final bubble = find.byType(ExpressiveRichTooltip);
      expect(bubble, findsOneWidget);
      final rect = tester.getRect(bubble);
      expect(rect.width, lessThanOrEqualTo(TooltipBehavior.richMaxWidth));
      final surface = tester.widget<ExpressiveSurface>(
        find
            .descendant(of: bubble, matching: find.byType(ExpressiveSurface))
            .first,
      );
      expect(surface.color, bloom.colors.surfaceContainer);
      // The subhead's first baseline is 28dp from the top.
      final title = tester.getRect(find.text('Shared budgets'));
      expect(title.top - rect.top, greaterThan(0));
      await tester.tapAt(const Offset(2, 590));
      await tester.pumpAndSettle();
      expect(bubble, findsNothing);
      expect(learned, 0);

      await tester.longPress(find.byType(ExpressiveTooltip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn more'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(learned, 1);
      expect(find.byType(ExpressiveRichTooltip), findsNothing);
    });
  });

  testWidgets('a coach mark points at its feature with a caret', (
    tester,
  ) async {
    var visible = true;
    var tried = 0;
    await tester.pumpWidget(
      host(
        (context) => StatefulBuilder(
          builder: (context, update) => ExpressiveCoachMark(
            visible: visible,
            title: 'Split a bill',
            text: 'Tap the receipt to split it between travellers.',
            actionLabel: 'Try it',
            onAction: () => tried++,
            onDismissed: () => update(() => visible = false),
            child: const SizedBox(width: 56, height: 56),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final anchor = tester.getRect(find.byType(ExpressiveCoachMark));
    final bubble = find.byType(ExpressiveRichTooltip);
    expect(bubble, findsOneWidget);
    final rect = tester.getRect(bubble);
    // Below its feature (the preferred side), the caret's tip 4dp clear.
    expect(
      rect.top - anchor.bottom,
      closeTo(
        TooltipBehavior.anchorSpacing + TooltipBehavior.caretHeight,
        0.01,
      ),
    );
    final caret = tester.widget<ExpressiveRichTooltip>(bubble).caret;
    expect(caret, isNotNull);
    expect(caret!.below, isTrue);
    expect(rect.left + caret.x, closeTo(anchor.center.dx, 0.01));
    await tester.tap(find.text('Try it'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tried, 1);
    expect(visible, isFalse);
    expect(bubble, findsNothing);
  });

  // A caret placed by hand from the start edge stands at the right in
  // right-to-left, where the anchor's start is (11-13: it stayed at the left).
  for (final direction in TextDirection.values) {
    testWidgets('a start caret counts from the start edge ($direction)', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          (context) => Directionality(
            textDirection: direction,
            child: const SizedBox(
              width: 280,
              child: ExpressiveRichTooltip(
                title: 'New: filters',
                text: 'Narrow the list to what matters today.',
                caret: ExpressiveTooltipCaret.start(below: false, start: 24),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final surface = find
          .descendant(
            of: find.byType(ExpressiveRichTooltip),
            matching: find.byType(ExpressiveSurface),
          )
          .first;
      final rect = Offset.zero & tester.getSize(surface);
      final path = tester
          .widget<ExpressiveSurface>(surface)
          .shape
          .getOuterPath(rect, textDirection: direction);
      // Just under the bottom edge, inside the caret's triangle.
      final y = rect.bottom + TooltipBehavior.caretHeight / 2;
      final start = direction == TextDirection.ltr
          ? rect.left + 24
          : rect.right - 24;
      final end = direction == TextDirection.ltr
          ? rect.right - 24
          : rect.left + 24;
      expect(path.contains(Offset(start, y)), isTrue);
      expect(path.contains(Offset(end, y)), isFalse);
    });
  }

  testWidgets('a coach mark stays with the screen it teaches: on its '
      'anchor\'s nearest overlay, a frame\'s own; focus taken into it there '
      'comes back to the anchor', (tester) async {
    final coach = _Coach();
    addTearDown(coach.dispose);
    await tester.pumpWidget(
      host(
        (context) => SizedBox(
          width: 360,
          height: 320,
          child: Overlay.wrap(
            child: Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder<bool>(
                valueListenable: coach.visible,
                builder: (context, shown, _) => ExpressiveCoachMark(
                  visible: shown,
                  text: 'Narrow the list to what matters today.',
                  action: ExpressiveTextButton(
                    'Got it',
                    focusNode: coach.action,
                    onPressed: () => coach.visible.value = false,
                  ),
                  onDismissed: () {
                    coach.dismissed++;
                    coach.visible.value = false;
                  },
                  child: ExpressiveFilledButton.tonal(
                    'Filters',
                    focusNode: coach.anchor,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final bubble = find.byType(ExpressiveRichTooltip);
    expect(bubble, findsOneWidget);
    expect(
      find.ancestor(of: bubble, matching: find.byType(Overlay)),
      findsNWidgets(2),
      reason: 'the frame\'s overlay, inside the navigator\'s',
    );
    coach.anchor.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(coach.action.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(coach.anchor.hasFocus, isTrue, reason: 'at once, while it fades');
    await tester.pumpAndSettle();
    expect(coach.dismissed, 1);
    expect(coach.anchor.hasFocus, isTrue);
  });

  group('the action slot', () {
    Widget tooltip({String? actionLabel, Widget? action}) => MaterialApp(
      builder: (context, app) => ExpressiveHost(
        light: bloom,
        brightness: Brightness.light,
        child: app!,
      ),
      home: Center(
        child: ExpressiveRichTooltip(
          title: 'Offline mode',
          text: 'Saved pages stay readable when you lose your connection.',
          actionLabel: actionLabel,
          onAction: actionLabel == null ? null : () {},
          action: action,
        ),
      ),
    );

    testWidgets('a rich tooltip draws a widget action where its text action '
        'stands, in the action label\'s type and colour', (tester) async {
      // Where the row starts, from the bubble's top left (the bubbles are
      // centred, and differ in height by their actions).
      Offset fromBubble(Finder finder) =>
          tester.getTopLeft(finder) -
          tester.getTopLeft(find.byType(ExpressiveRichTooltip));
      await tester.pumpWidget(tooltip(actionLabel: 'Learn more'));
      final textAction = fromBubble(
        find
            .ancestor(
              of: find.text('Learn more'),
              matching: find.byType(ExpressivePressable),
            )
            .first,
      );
      final withText = tester.getSize(find.byType(ExpressiveRichTooltip));

      const slot = ValueKey<String>('slot');
      await tester.pumpWidget(
        tooltip(action: const Text('Learn more', key: slot)),
      );
      expect(
        find.ancestor(
          of: find.byKey(slot),
          matching: find.byType(ExpressivePressable),
        ),
        findsNothing,
      );
      expect(fromBubble(find.byKey(slot)), textAction);
      final bubble = tester.getRect(find.byType(ExpressiveRichTooltip));
      final drawn = tester.getRect(find.byKey(slot));
      // The row keeps its least height and its gap below.
      expect(
        bubble.bottom - drawn.top,
        greaterThanOrEqualTo(
          TooltipBehavior.actionMinHeight + TooltipBehavior.actionBottomPadding,
        ),
      );
      expect(bubble.height, lessThanOrEqualTo(withText.height));
      final style = tester
          .widget<RichText>(
            find.descendant(
              of: find.byKey(slot),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style!;
      expect(style.color, bloom.colors.primary);
      expect(style.fontSize, bloom.type.labelLarge.fontSize);
    });

    test('a caller passes a widget action or a text action, never both', () {
      expect(
        () => ExpressiveRichTooltip(
          text: 'Saved pages stay readable.',
          actionLabel: 'Learn more',
          action: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
      expect(
        () => ExpressiveCoachMark(
          visible: true,
          text: 'Narrow the list.',
          onAction: () {},
          action: const SizedBox.shrink(),
          child: const SizedBox.shrink(),
        ),
        throwsAssertionError,
      );
    });
  });

  group('a coach mark with a widget action', () {
    const anchorKey = ValueKey<String>('anchor');
    const actionKey = ValueKey<String>('action');

    /// A home page that opens a second page holding the coach mark, up,
    /// over its anchor; a back that leaves the page shows.
    Future<_Coach> open(WidgetTester tester) async {
      final coach = _Coach();
      addTearDown(coach.dispose);
      await tester.pumpWidget(
        host(
          (context) => ExpressiveTextButton(
            'Open',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: coach.visible,
                      builder: (context, shown, _) => ExpressiveCoachMark(
                        visible: shown,
                        title: 'Split a bill',
                        text: 'Tap the receipt to split it.',
                        action: ExpressiveTextButton(
                          'Try it',
                          key: actionKey,
                          focusNode: coach.action,
                          onPressed: () => coach.visible.value = false,
                        ),
                        onDismissed: () {
                          coach.dismissed++;
                          coach.visible.value = false;
                        },
                        child: ExpressiveFilledButton.tonal(
                          'Receipt',
                          key: anchorKey,
                          focusNode: coach.anchor,
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return coach;
    }

    testWidgets('draws it in the bubble, one node holding the words and the '
        'action its own', (tester) async {
      final semantics = tester.ensureSemantics();
      await open(tester);
      final bubble = tester.getRect(find.byType(ExpressiveRichTooltip));
      expect(bubble.contains(tester.getCenter(find.byKey(actionKey))), isTrue);
      // The bubble's own node, its size, holds the words and is live.
      final words = tester.getSemantics(find.byType(ExpressiveRichTooltip));
      expect(words.label, contains('Split a bill'));
      expect(words.label, contains('Tap the receipt to split it.'));
      expect(words.label, isNot(contains('Try it')));
      expect(words.rect.size, bubble.size);
      expect(words.getSemanticsData().flagsCollection.isLiveRegion, isTrue);
      expect(
        find.semantics.byPredicate(
          (node) =>
              node.label == 'Try it' &&
              node.getSemanticsData().flagsCollection.isButton,
        ),
        findsOne,
      );
      semantics.dispose();
    });

    testWidgets('the first back closes it and tells the app, and the next '
        'leaves the page', (tester) async {
      final coach = await open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(coach.dismissed, 1);
      expect(find.byType(ExpressiveRichTooltip), findsNothing);
      expect(find.byKey(anchorKey), findsOne, reason: 'the page stays');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(anchorKey), findsNothing, reason: 'the page left');
      expect(coach.dismissed, 1);
    });

    testWidgets('Escape on its anchor closes it and tells the app; down, '
        'Escape is no longer its own', (tester) async {
      final coach = await open(tester);
      coach.anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(coach.dismissed, 1);
      expect(find.byType(ExpressiveRichTooltip), findsNothing);
      expect(coach.anchor.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(coach.dismissed, 1);
    });

    testWidgets('Tab from its anchor moves keyboard focus onto its action, '
        'where Tab stays; Escape there closes it and focus is back on the '
        'anchor', (tester) async {
      final coach = await open(tester);
      coach.anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(coach.action.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(coach.action.hasFocus, isTrue, reason: 'Tab stays in the bubble');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(
        coach.anchor.hasFocus,
        isTrue,
        reason: 'back on the anchor at once, not after the bubble fades',
      );
      await tester.pumpAndSettle();
      expect(coach.dismissed, 1);
      expect(find.byType(ExpressiveRichTooltip), findsNothing);
      expect(coach.anchor.hasFocus, isTrue);
    });

    testWidgets('its own action closing it from inside puts focus back on '
        'the anchor, and tells no dismissal', (tester) async {
      final coach = await open(tester);
      coach.anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(coach.action.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.pump();
      expect(coach.anchor.hasFocus, isTrue, reason: 'at once');
      await tester.pumpAndSettle();
      expect(coach.visible.value, isFalse);
      expect(coach.dismissed, 0);
      expect(find.byType(ExpressiveRichTooltip), findsNothing);
      expect(coach.anchor.hasFocus, isTrue);
    });

    testWidgets('a tap outside closes it, tells the app and leaves the back '
        'to the page', (tester) async {
      final coach = await open(tester);
      await tester.tapAt(const Offset(2, 590));
      await tester.pumpAndSettle();
      expect(coach.dismissed, 1);
      expect(find.byType(ExpressiveRichTooltip), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(anchorKey), findsNothing, reason: 'the page left');
    });
  });

  testWidgets('a rich tooltip lays its rows out in whole device pixels, '
      'as paddingFromBaseline does', (tester) async {
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => ExpressiveHost(
          light: ExpressiveThemeData.preset('baseline', Brightness.light),
          brightness: Brightness.light,
          child: app!,
        ),
        home: const Center(
          child: ExpressiveRichTooltip(
            title: 'Offline mode',
            text: 'Saved pages stay readable when you lose your connection.',
            actionLabel: 'Learn more',
          ),
        ),
      ),
    );
    final height = tester.getSize(find.byType(ExpressiveRichTooltip)).height;
    final px = height * 2.625;
    expect(px, moreOrLessEquals(px.roundToDouble(), epsilon: 1e-6));
  });
}

/// A coach mark under test: whether the app shows it, how often it was
/// dismissed, and the focus nodes of its anchor and its action.
final class _Coach {
  final visible = ValueNotifier<bool>(true);
  final anchor = FocusNode(debugLabel: 'anchor');
  final action = FocusNode(debugLabel: 'action');
  int dismissed = 0;

  void dispose() {
    visible.dispose();
    anchor.dispose();
    action.dispose();
  }
}
