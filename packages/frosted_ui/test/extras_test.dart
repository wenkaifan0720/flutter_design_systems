// The parts every look carries beside Frosted's own, one test each: a slider,
// tabs, an action bar, a composer, a dialog, a picture, the sign-in buttons,
// swipe actions and a week strip. The page owns every value through `value`
// and `onChanged`, and a null callback leaves a control inert.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Pumps [child] across a phone's page, 20 in from each side, on Frosted's
/// canvas; nothing may throw. The text scale is set inside the host so the
/// host's own ceiling does not hold it.
Future<void> _pump(
  WidgetTester t,
  Widget child, {
  TextScaler scale = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
  double gutter = 20,
}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? page) => FrostedHost(
        brightness: Brightness.light,
        child: Directionality(
          textDirection: direction,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: scale),
            child: page!,
          ),
        ),
      ),
      home: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [child],
        ),
      ),
    ),
  );
  expect(t.takeException(), isNull);
}

/// The node a screen reader lands on for [label].
SemanticsNode _node(WidgetTester t, String label) =>
    t.getSemantics(find.bySemanticsLabel(label));

/// A control that keeps the value its callback hands back, as a page does.
class _Owner<T> extends StatefulWidget {
  const _Owner(this.initial, this.builder, {this.seen});

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;
  final List<T>? seen;

  @override
  State<_Owner<T>> createState() => _OwnerState<T>();
}

class _OwnerState<T> extends State<_Owner<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(_value, (v) {
    widget.seen?.add(v);
    setState(() => _value = v);
  });
}

/// A plain row for a swipe to carry: a white band 56 tall with a word.
Widget _row(String label) => SizedBox(
  height: 56,
  child: ColoredBox(
    color: const Color(0xFFFFFFFF),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(label),
      ),
    ),
  ),
);

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  group('FrostedSlider', () {
    testWidgets('reports where it is tapped and snaps to its steps', (t) async {
      final seen = <double>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<double>(
              0.2,
              (v, set) =>
                  FrostedSlider(value: v, label: 'Reach', onChanged: set),
              seen: seen,
            ),
            _Owner<double>(
              50,
              (v, set) => FrostedSlider(
                value: v,
                label: 'Limit',
                min: 0,
                max: 100,
                divisions: 4,
                onChanged: set,
              ),
              seen: seen,
            ),
          ],
        ),
      );
      final reach = t.getRect(find.byType(FrostedSlider).first);
      await t.tapAt(Offset(reach.left + reach.width / 2, reach.center.dy));
      await t.pump();
      expect(seen.last, closeTo(0.5, 0.04));
      final limit = t.getRect(find.byType(FrostedSlider).last);
      await t.tapAt(
        Offset(limit.left + 12 + (limit.width - 24) * 0.7, limit.center.dy),
      );
      await t.pump();
      expect(seen.last, 75);
    });

    testWidgets('brackets a tap, a drag and a key step with onChangeStart and '
        'onChangeEnd', (t) async {
      final log = <String>[];
      await _pump(
        t,
        _Owner<double>(
          0.2,
          (v, set) => FrostedSlider(
            value: v,
            label: 'Reach',
            onChanged: set,
            onChangeStart: (v) => log.add('start ${v.toStringAsFixed(2)}'),
            onChangeEnd: (v) => log.add('end ${v.toStringAsFixed(2)}'),
          ),
        ),
      );
      final rect = t.getRect(find.byType(FrostedSlider));
      final room = rect.width - 22;
      Offset at(double f) => Offset(rect.left + 11 + room * f, rect.center.dy);
      await t.tapAt(at(0.5));
      await t.pump();
      expect(log, ['start 0.20', 'end 0.50']);
      log.clear();
      final drag = await t.startGesture(at(0.5));
      await drag.moveTo(at(0.6));
      await t.pump();
      await drag.moveTo(at(0.8));
      await t.pump();
      await drag.up();
      await t.pump();
      expect(log.first, 'start 0.50');
      expect(log.last, 'end 0.80');
      expect(log, hasLength(2));
      log.clear();
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await t.pump();
      expect(log, ['start 0.80', 'end 0.85']);
    });

    testWidgets('answers the screen reader and goes inert without a callback', (
      t,
    ) async {
      final seen = <double>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<double>(
              40,
              (v, set) => FrostedSlider(
                value: v,
                label: 'Alert at',
                min: 0,
                max: 100,
                divisions: 10,
                semanticFormatterCallback: (v) => '${v.round()}% of budget',
                onChanged: set,
              ),
              seen: seen,
            ),
            const FrostedSlider(value: 0.5, label: 'Locked', onChanged: null),
          ],
        ),
      );
      expect(
        _node(t, 'Alert at'),
        isSemantics(
          value: '40% of budget',
          increasedValue: '50% of budget',
          decreasedValue: '30% of budget',
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      t.semantics.performAction(
        find.semantics.byLabel('Alert at'),
        SemanticsAction.increase,
      );
      await t.pump();
      expect(seen, [50]);
      expect(
        _node(t, 'Locked'),
        isSemantics(
          isEnabled: false,
          hasIncreaseAction: false,
          hasDecreaseAction: false,
        ),
      );
    });

    testWidgets('stops at its ends and runs the other way in a right to left '
        'page', (t) async {
      await _pump(
        t,
        const FrostedSlider(value: 1, label: 'Full', onChanged: _noop),
      );
      expect(
        _node(t, 'Full'),
        isSemantics(hasIncreaseAction: false, hasDecreaseAction: true),
      );
      final seen = <double>[];
      await _pump(
        t,
        _Owner<double>(
          0.5,
          (v, set) => FrostedSlider(value: v, label: 'Reach', onChanged: set),
          seen: seen,
        ),
        direction: TextDirection.rtl,
      );
      final rect = t.getRect(find.byType(FrostedSlider));
      await t.tapAt(Offset(rect.left + 12, rect.center.dy));
      await t.pump();
      expect(seen.last, closeTo(1, 0.04));
    });
  });

  testWidgets(
    'FrostedTabBar choose a section and read as one group; a long row '
    'scrolls and a short one shares the width',
    (t) async {
      final seen = <int>[];
      await _pump(
        t,
        Column(
          children: [
            _Owner<int>(
              0,
              (i, set) => FrostedTabBar(
                tabs: const ['Overview', 'Activity', 'Statements'],
                selectedIndex: i,
                expand: true,
                onChanged: set,
              ),
              seen: seen,
            ),
            FrostedTabBar(
              tabs: const [
                'Cards',
                'Budgets',
                'Goals',
                'Reports',
                'Alerts',
                'Limits',
                'Rewards',
              ],
              selectedIndex: 1,
              label: 'More sections',
              onChanged: (_) {},
            ),
          ],
        ),
      );
      expect(_node(t, 'Overview'), isSemantics(isSelected: true));
      expect(_node(t, 'Activity'), isSemantics(isSelected: false));
      expect(find.bySemanticsLabel('Sections'), findsOneWidget);
      expect(find.bySemanticsLabel('More sections'), findsOneWidget);
      final tabs = t.getRect(find.byType(FrostedTabBar).first);
      final statements = t.getRect(find.text('Statements'));
      expect(statements.right, lessThanOrEqualTo(tabs.right));
      expect(
        t.getSize(find.byType(FrostedTabBar).first).height,
        greaterThanOrEqualTo(FrostedChromeMetrics.tabHeight),
      );
      final row = t.getRect(find.byType(FrostedTabBar).last);
      expect(t.getRect(find.text('Rewards')).right, greaterThan(row.right));
      await t.tap(find.text('Activity'));
      await t.pump();
      expect(seen, [1]);
      expect(_node(t, 'Activity'), isSemantics(isSelected: true));
    },
  );

  group('FrostedActionBar', () {
    testWidgets('puts its summary beside the act, and the act alone across '
        'the width', (t) async {
      var taps = 0;
      await _pump(
        t,
        Column(
          children: [
            FrostedActionBar(
              summary: '\$500.00',
              detail: 'To Maren Holt',
              label: 'Transfer',
              onPressed: () => taps++,
            ),
            FrostedActionBar(label: 'Continue', onPressed: () {}),
          ],
        ),
        gutter: 0,
      );
      expect(find.text('\$500.00'), findsOneWidget);
      expect(find.text('To Maren Holt'), findsOneWidget);
      final summary = t.getRect(find.text('\$500.00'));
      final act = t.getRect(find.text('Transfer'));
      expect(summary.right, lessThan(act.left));
      await t.tap(find.text('Transfer'));
      expect(taps, 1);
      final alone = t.getRect(find.byType(FrostedButton).last);
      final bar = t.getRect(find.byType(FrostedActionBar).last);
      expect(
        alone.width,
        closeTo(bar.width - 2 * FrostedChromeMetrics.actionBarSide, 3),
      );
    });

    testWidgets('stands the summary over the act when the text is large, '
        'and reads Working while busy', (t) async {
      var taps = 0;
      await _pump(
        t,
        FrostedActionBar(
          summary: '\$500.00',
          label: 'Transfer',
          busy: true,
          onPressed: () => taps++,
        ),
        scale: const TextScaler.linear(1.6),
        gutter: 0,
      );
      expect(find.text('Working…'), findsOneWidget);
      expect(find.text('Transfer'), findsNothing);
      final summary = t.getRect(find.text('\$500.00'));
      final act = t.getRect(find.text('Working…'));
      expect(summary.bottom, lessThanOrEqualTo(act.top));
      await t.tap(find.text('Working…'));
      expect(taps, 0);
    });

    testWidgets('floating, it stands off the edges', (t) async {
      await _pump(
        t,
        FrostedActionBar(floating: true, label: 'Remind me', onPressed: () {}),
        gutter: 0,
      );
      final bar = t.getRect(find.byType(FrostedActionBar));
      final act = t.getRect(find.byType(FrostedButton));
      expect(
        act.left - bar.left,
        closeTo(
          FrostedChromeMetrics.tabBarSide + FrostedChromeMetrics.actionBarSide,
          3,
        ),
      );
    });
  });

  group('FrostedComposer', () {
    testWidgets('sends the trimmed text and empties; with nothing written it '
        'offers the voice seat', (t) async {
      final sent = <String>[];
      await _pump(
        t,
        FrostedComposer(
          hint: 'Message Maren',
          onSend: sent.add,
          onVoice: () {},
          onAttach: () {},
        ),
      );
      expect(find.bySemanticsLabel('Message Maren'), findsOneWidget);
      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowUp), findsNothing);
      await t.enterText(find.byType(TextField), '  Running late  ');
      await t.pump();
      expect(find.byIcon(LucideIcons.arrowUp), findsOneWidget);
      await t.tap(find.byIcon(LucideIcons.arrowUp));
      await t.pump();
      expect(sent, ['Running late']);
      expect(find.text('Running late'), findsNothing);
      expect(find.byIcon(LucideIcons.mic), findsOneWidget);
    });

    testWidgets('shows stop while a reply is being written and is inert when '
        'disabled', (t) async {
      var stops = 0;
      await _pump(
        t,
        Column(
          children: [
            FrostedComposer(
              variant: FrostedComposerVariant.assistant,
              busy: true,
              onStop: () => stops++,
            ),
            const FrostedComposer(enabled: false, onSend: _noopText),
          ],
        ),
      );
      expect(find.text('Ask anything'), findsOneWidget);
      await t.tap(find.byIcon(LucideIcons.square));
      expect(stops, 1);
      expect(t.widget<TextField>(find.byType(TextField).last).enabled, isFalse);
    });
  });

  testWidgets('FrostedDialog.show completes with the act chosen, and with null '
      'when it is dismissed', (t) async {
    late BuildContext context;
    await t.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? page) =>
            FrostedHost(brightness: Brightness.light, child: page!),
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    Future<bool?> ask({bool destructive = false}) => FrostedDialog.show(
      context,
      title: 'Freeze this card?',
      message: 'Payments stop.',
      confirmLabel: 'Freeze',
      cancelLabel: 'Cancel',
      destructive: destructive,
    );
    var answer = ask();
    await t.pumpAndSettle();
    expect(find.text('Freeze this card?'), findsOneWidget);
    expect(find.text('Payments stop.'), findsOneWidget);
    final card = t.getSize(find.byType(FrostedDialog));
    expect(card.width, lessThanOrEqualTo(FrostedChromeMetrics.dialogWidth));
    await t.tap(find.text('Freeze'));
    await t.pumpAndSettle();
    expect(await answer, isTrue);
    expect(find.byType(FrostedDialog), findsNothing);
    answer = ask(destructive: true);
    await t.pumpAndSettle();
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(await answer, isFalse);
    answer = ask();
    await t.pumpAndSettle();
    await t.tapAt(const Offset(4, 4));
    await t.pumpAndSettle();
    expect(await answer, isNull);
  });

  testWidgets('FrostedDialog sets its acts side by side while their words fit, '
      'and stacks them, the confirm first, when they do not', (t) async {
    // The test face is a box an em wide, so a six letter word at 14 is 84 of
    // the 91 each act has room for; at 1.3 it is 109 and no longer fits.
    Future<void> pumpDialog(
      String confirm, {
      TextScaler scale = TextScaler.noScaling,
    }) => _pump(
      t,
      Center(
        child: FrostedDialog(
          title: 'Freeze this card?',
          confirmLabel: confirm,
          cancelLabel: 'Cancel',
          destructive: true,
          onConfirm: () {},
          onCancel: () {},
        ),
      ),
      scale: scale,
    );
    await pumpDialog('Freeze');
    expect(
      t.getTopLeft(find.text('Cancel')).dy,
      t.getTopLeft(find.text('Freeze')).dy,
      reason: 'short words share the row',
    );
    await pumpDialog('Freeze this card for good');
    expect(
      t.getTopLeft(find.text('Freeze this card for good')).dy,
      lessThan(t.getTopLeft(find.text('Cancel')).dy),
      reason: 'long words stand one over the other, the confirm first',
    );
    await pumpDialog('Freeze', scale: const TextScaler.linear(1.3));
    expect(
      t.getTopLeft(find.text('Freeze')).dy,
      lessThan(t.getTopLeft(find.text('Cancel')).dy),
      reason: 'large text no longer fits two across',
    );
  });

  testWidgets('FrostedDialog with one act has nothing to decide', (t) async {
    var taps = 0;
    await _pump(
      t,
      FrostedDialog(
        title: 'Transfer sent',
        message: 'It arrives Thursday.',
        confirmLabel: 'Done',
        onConfirm: () => taps++,
      ),
    );
    expect(find.byType(FrostedButton), findsOneWidget);
    await t.tap(find.text('Done'));
    expect(taps, 1);
    expect(
      t.getSemantics(find.bySemanticsLabel('Transfer sent').first),
      isSemantics(namesRoute: true, scopesRoute: true),
    );
  });

  testWidgets('FrostedMedia keeps its aspect, draws the ground from its seed '
      'and says what it is', (t) async {
    await _pump(
      t,
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Expanded(
            child: FrostedMedia(
              seed: 'Lisbon in May',
              aspect: 2 / 3,
              label: 'Lisbon in May',
            ),
          ),
          Expanded(
            child: FrostedMedia(seed: 'Lisbon in May', aspect: 16 / 9),
          ),
          Expanded(child: FrostedMedia(seed: 'Harbor Transit', aspect: 1)),
        ],
      ),
    );
    final poster = t.getSize(find.byType(FrostedMedia).first);
    expect(poster.width / poster.height, moreOrLessEquals(2 / 3));
    final wide = t.getSize(find.byType(FrostedMedia).at(1));
    expect(wide.width / wide.height, moreOrLessEquals(16 / 9));
    final square = t.getSize(find.byType(FrostedMedia).last);
    expect(square.width, moreOrLessEquals(square.height));
    expect(find.bySemanticsLabel('Lisbon in May'), findsOneWidget);
  });

  group('sign-in', () {
    testWidgets('names its provider, hears its press and goes inert while a '
        'window is open', (t) async {
      final seen = <String>[];
      await _pump(
        t,
        Column(
          children: [
            FrostedSignInButton('apple', onPressed: () => seen.add('apple')),
            FrostedSignInButton('google', onPressed: () => seen.add('google')),
            FrostedSignInButton('email', onPressed: () => seen.add('email')),
            FrostedSignInButton(
              'sso',
              label: 'Use single sign-on',
              onPressed: () {},
            ),
            FrostedSignInButton('apple', busy: true, onPressed: () {}),
          ],
        ),
      );
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Use single sign-on'), findsOneWidget);
      expect(find.text('Working…'), findsOneWidget);
      await t.tap(find.text('Continue with Apple'));
      await t.tap(find.text('Continue with Google'));
      await t.tap(find.text('Continue with email'));
      expect(seen, ['apple', 'google', 'email']);
    });

    testWidgets('a stack hears which provider was chosen; without a callback '
        'every button is disabled', (t) async {
      final seen = <String>[];
      await _pump(
        t,
        Column(
          children: [
            FrostedSignInStack(
              const ['apple', 'google', 'email'],
              leadWithFirst: false,
              onPressed: seen.add,
            ),
            const FrostedSignInStack(['google']),
          ],
        ),
      );
      await t.tap(find.text('Continue with Google').first);
      expect(seen, ['google']);
      final buttons = find.byType(FrostedSignInButton);
      expect(buttons, findsNWidgets(4));
      expect(t.widget<FrostedSignInButton>(buttons.last).onPressed, isNull);
    });
  });

  group('FrostedSwipeActions', () {
    testWidgets('a drag uncovers the actions, the first nearest the edge; a '
        'press on one does it and closes the row', (t) async {
      final done = <String>[];
      await _pump(
        t,
        FrostedSwipeActions(
          trailing: [
            FrostedSwipeAction(
              label: 'Delete',
              icon: LucideIcons.trash2,
              tone: FrostedSwipeTone.destructive,
              onPressed: () => done.add('delete'),
            ),
            FrostedSwipeAction(
              label: 'Pin',
              icon: LucideIcons.pin,
              tone: FrostedSwipeTone.accent,
              onPressed: () => done.add('pin'),
            ),
          ],
          child: _row('Harbor Transit'),
        ),
      );
      final rest = t.getRect(find.text('Harbor Transit'));
      await t.drag(find.text('Harbor Transit'), const Offset(-200, 0));
      await t.pumpAndSettle();
      final open = t.getRect(find.text('Harbor Transit'));
      expect(
        rest.left - open.left,
        moreOrLessEquals(2 * FrostedChromeMetrics.swipeBlock),
      );
      final delete = t.getCenter(find.text('DELETE'));
      final pin = t.getCenter(find.text('PIN'));
      expect(delete.dx, greaterThan(pin.dx));
      await t.tap(find.text('DELETE'));
      await t.pumpAndSettle();
      expect(done, ['delete']);
      expect(t.getRect(find.text('Harbor Transit')), rest);
    });

    testWidgets('a full swipe does the first action; short of a third it '
        'settles shut', (t) async {
      final done = <String>[];
      await _pump(
        t,
        FrostedSwipeActions(
          fullSwipe: true,
          trailing: [
            FrostedSwipeAction(
              label: 'Delete',
              icon: LucideIcons.trash2,
              tone: FrostedSwipeTone.destructive,
              onPressed: () => done.add('delete'),
            ),
          ],
          child: _row('Cinema Lumen'),
        ),
      );
      final rest = t.getRect(find.text('Cinema Lumen'));
      await t.drag(find.text('Cinema Lumen'), const Offset(-20, 0));
      await t.pumpAndSettle();
      expect(t.getRect(find.text('Cinema Lumen')), rest);
      expect(done, isEmpty);
      await t.drag(find.text('Cinema Lumen'), const Offset(-340, 0));
      await t.pumpAndSettle();
      expect(done, ['delete']);
      // A destructive edge carries the row off; the page then removes it.
      expect(t.getRect(find.text('Cinema Lumen')).left, lessThan(rest.left));
    });

    testWidgets('stands open on its first frame for a preview', (t) async {
      await _pump(
        t,
        FrostedSwipeActions(
          initiallyOpen: true,
          leading: const [
            FrostedSwipeAction(
              label: 'Paid',
              icon: LucideIcons.check,
              onPressed: _noop0,
            ),
          ],
          child: _row('Bill'),
        ),
      );
      expect(find.text('PAID'), findsOneWidget);
      expect(
        t.getRect(find.text('Bill')).left,
        greaterThan(FrostedChromeMetrics.swipeBlock),
      );
    });
  });

  testWidgets('FrostedWeekStrip checks the kept days, prints the others, reads '
      'each day by its state and lets only the days that happened be '
      'pressed', (t) async {
    final seen = <DateTime>[];
    await _pump(
      t,
      FrostedWeekStrip(
        start: DateTime(2026, 10, 26),
        days: const [
          FrostedDayStatus.complete,
          FrostedDayStatus.complete,
          FrostedDayStatus.missed,
          FrostedDayStatus.complete,
          FrostedDayStatus.current,
          FrostedDayStatus.upcoming,
          FrostedDayStatus.upcoming,
        ],
        onChanged: seen.add,
      ),
    );
    expect(find.byIcon(LucideIcons.check), findsNWidgets(3));
    expect(find.text('26'), findsNothing);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('MON'), findsOneWidget);
    await t.tap(find.text('28'));
    await t.tap(find.text('30'));
    await t.tap(find.text('31'), warnIfMissed: false);
    expect(seen, [DateTime(2026, 10, 28), DateTime(2026, 10, 30)]);
    expect(find.bySemanticsLabel(RegExp('Wednesday .*missed')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('.*to come')), findsNWidgets(2));
    expect(find.bySemanticsLabel(RegExp('Monday .*kept')), findsOneWidget);
  });

  testWidgets('a keycap and a lone badge are as wide as their words, and a '
      "shortcut's modifier keys are glyphs read by name", (t) async {
    await _pump(
      t,
      const Wrap(
        spacing: 8,
        children: [
          FrostedKbd('Esc'),
          FrostedBadge(120, label: '120 new'),
          FrostedKbd.combo(['⇧', '⌘', 'Z']),
        ],
      ),
    );
    expect(t.getSize(find.byType(FrostedKbd).first).width, lessThan(60));
    expect(t.getSize(find.byType(FrostedBadge)).width, lessThan(50));
    // The look's typefaces carry no ⌘ or ⇧: as text they fall back.
    expect(find.byIcon(FrostedGlyphs.command), findsOneWidget);
    expect(find.byIcon(FrostedGlyphs.shift), findsOneWidget);
    expect(find.bySemanticsLabel('Shift Command Z'), findsOneWidget);
  });

  testWidgets('Tab reaches the navigation bar\'s destinations and Enter '
      'goes there; an inert bar takes no focus', (t) async {
    final went = <int>[];
    await _pump(
      t,
      FrostedNavigationBar(
        items: const [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
        onDestinationSelected: went.add,
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(went, [1]);
    await _pump(
      t,
      const FrostedNavigationBar(
        items: [
          FrostedNavItem(FrostedGlyphs.house, 'Home'),
          FrostedNavItem(FrostedGlyphs.person, 'You'),
        ],
      ),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    final held = FocusManager.instance.primaryFocus?.context;
    final inBar =
        held != null &&
        find
            .descendant(
              of: find.byType(FrostedNavigationBar),
              matching: find.byWidget(held.widget),
            )
            .evaluate()
            .isNotEmpty;
    expect(inBar, isFalse);
  });

  testWidgets('in a box of any height, a segmented strip, pages and a rating '
      'stay as tall as themselves', (t) async {
    for (final part in <Widget>[
      FrostedSegmentedButton<int>(
        segments: const [
          FrostedButtonSegment(0, 'Day'),
          FrostedButtonSegment(1, 'Week'),
        ],
        value: 0,
        label: 'Range',
        onChanged: (_) {},
      ),
      FrostedPagination(pageCount: 5, selectedIndex: 1, onChanged: (_) {}),
      FrostedRating(value: 3, label: 'Rating', onChanged: (_) {}),
    ]) {
      // Offered 0 to 300 tall, as a box of a set height offers it.
      await _pump(
        t,
        SizedBox(
          height: 300,
          child: Align(alignment: Alignment.topLeft, child: part),
        ),
      );
      final box = t.renderObject<RenderBox>(find.byWidget(part));
      expect(box.size.height, lessThan(60), reason: '${part.runtimeType}');
    }
  });

  testWidgets('in a field wider than itself, a toggle strip stands at the '
      'start, its wash as wide as its toggles', (t) async {
    final strip = FrostedToggleGroup<String>(
      segments: const [
        FrostedButtonSegment('l', 'Left'),
        FrostedButtonSegment('r', 'Right'),
      ],
      selected: const {'l'},
      onChanged: (_) {},
    );
    await _pump(t, SizedBox(width: 350, child: strip));
    // The strip's stack: its wash fills it.
    final wash = find
        .descendant(of: find.byWidget(strip), matching: find.byType(Stack))
        .first;
    expect(t.getSize(wash).width, lessThan(200));
    expect(t.getTopLeft(wash).dx, t.getTopLeft(find.byWidget(strip)).dx);
  });

  testWidgets('in a desktop column, a month stands at most 400 wide and the '
      'time wheels 360, at the start', (t) async {
    for (final (part, most) in <(Widget, double)>[
      (
        FrostedCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2026, 12, 31),
          value: DateTime(2026, 11, 10),
          currentDate: DateTime(2026, 11, 12),
          onChanged: (_) {},
        ),
        400,
      ),
      (FrostedDatePicker(currentDate: DateTime(2026, 11, 10)), 400),
      (const FrostedTimePicker(value: FrostedTime(hour: 9, minute: 30)), 360),
    ]) {
      final column = SizedBox(width: 1000, child: part);
      await _pump(
        t,
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: column),
      );
      final drawn = find.descendant(
        of: find.byWidget(column),
        matching: find.byType(ConstrainedBox),
      );
      final box = t.renderObject<RenderBox>(drawn.first);
      expect(box.size.width, most, reason: '${part.runtimeType}');
      expect(
        t.getTopLeft(drawn.first).dx,
        t.getTopLeft(find.byWidget(column)).dx,
        reason: '${part.runtimeType}',
      );
    }
  });
}

void _noop(double _) {}
void _noopText(String _) {}
void _noop0() {}
