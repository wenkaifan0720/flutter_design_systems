import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final Map<int, Set<WidgetState>> _thumbs = {};

class _Host extends StatefulWidget {
  const _Host({this.divisions, this.enabled = true});

  final int? divisions;

  final bool enabled;

  @override
  State<_Host> createState() => _HostState();
}

late _HostState _host;

class _HostState extends State<_Host> {
  RawRangeValues values = const RawRangeValues(20, 80);

  @override
  Widget build(BuildContext context) {
    _host = this;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 440,
        child: RawRangeSlider(
          values: values,
          max: 100,
          minGap: 10,
          divisions: widget.divisions,
          step: widget.divisions == null ? 1 : null,
          semanticFormatterCallback: (v) => '${v.round()}',
          onChanged: widget.enabled
              ? (next) => setState(() => values = next)
              : null,
          // The bare reference painter: a grey rail and square thumbs.
          trackBuilder: (context, track) => const SizedBox(
            height: 4,
            child: ColoredBox(color: Color(0xFFCCCCCC)),
          ),
          thumbBuilder: (context, index, states) {
            _thumbs[index] = states;
            return SizedBox(
              key: ValueKey('thumb $index'),
              width: 20,
              height: 20,
              child: const ColoredBox(color: Color(0xFF333333)),
            );
          },
        ),
      ),
    );
  }
}

double _handle = 0.5;

Future<void> _press(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyEvent(key);
  await tester.pump();
}

void main() {
  setUp(() {
    _thumbs.clear();
    _handle = 0.5;
  });

  behaviourContract(
    'RawRangeSlider',
    build: (c) => _Host(enabled: c.enabled),
    node: () => find.bySemanticsLabel('Minimum'),
    root: () => find.byType(RawRangeSlider),
    semantics: isSemantics(
      label: 'Minimum',
      value: '20',
      isSlider: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Minimum',
      value: '20',
      isSlider: true,
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    keyboard: (p) async {
      final t = p.tester;
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(p.data.value, '21');
      await p.key(LogicalKeyboardKey.end);
      expect(_host.values.start, 70, reason: 'a gap below the upper end');
      await p.tab();
      expect(
        semanticsOf(t, find.bySemanticsLabel('Maximum')),
        isSemantics(isFocused: true, value: '80'),
      );
      await p.key(LogicalKeyboardKey.home);
      expect(_host.values.end, 80, reason: 'a gap above the lower end');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_host.values.start, 21, reason: 'Left is up, right to left');
    },
    motion: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
    },
  );

  behaviourContract(
    'RawValueHandle',
    build: (c) => StatefulBuilder(
      builder: (context, setState) => Center(
        child: RawValueHandle(
          value: _handle,
          step: 0.1,
          semanticLabel: 'Volume',
          onChanged: c.enabled ? (v) => setState(() => _handle = v) : null,
          builder: (context, states) => const SizedBox(width: 8, height: 8),
        ),
      ),
    ),
    node: () => find.bySemanticsLabel('Volume'),
    semantics: isSemantics(
      label: 'Volume',
      value: '50%',
      increasedValue: '60%',
      decreasedValue: '40%',
      isSlider: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Volume',
      isSlider: true,
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    keyboard: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(p.data.value, '60%');
      await p.key(LogicalKeyboardKey.home);
      expect(p.data.value, '0%');
      await p.key(LogicalKeyboardKey.end);
      expect(p.data.value, '100%');
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(p.data.value, '60%', reason: 'Left is up, right to left');
    },
  );

  testWidgets('a handle speaks the current locale for each adjustment', (
    tester,
  ) async {
    for (final (locale, lower, value, higher) in [
      ('tr', '%30', '%40', '%50'),
      ('ar', '٣٠٪\u061c', '٤٠٪\u061c', '٥٠٪\u061c'),
    ]) {
      await tester.pumpWidget(
        harness(
          Localizations(
            locale: Locale(locale),
            delegates: const [
              RawWidgetsLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
            child: RawValueHandle(
              semanticLabel: 'Gain',
              value: 14,
              min: 10,
              max: 20,
              step: 1,
              onChanged: (_) {},
              builder: (_, _) => const SizedBox.square(dimension: 24),
            ),
          ),
        ),
      );
      final data = tester
          .getSemantics(find.bySemanticsLabel('Gain'))
          .getSemanticsData();
      expect(data.value, value);
      expect(data.increasedValue, higher);
      expect(data.decreasedValue, lower);
    }
  });

  testWidgets('thumbs sit at their values; a press moves the nearer one; a '
      'drag cannot cross the other', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    // 400 px of travel from x = 20: 20 at 100, 80 at 340.
    expect(tester.getCenter(find.byKey(const ValueKey('thumb 0'))).dx, 100);
    expect(tester.getCenter(find.byKey(const ValueKey('thumb 1'))).dx, 340);
    await tester.tapAt(const Offset(20 + 300, 20));
    await tester.pump();
    expect(_host.values, const RawRangeValues(20, 75));

    await tester.drag(
      find.byKey(const ValueKey('thumb 0')),
      const Offset(400, 0),
    );
    await tester.pump();
    expect(_host.values, const RawRangeValues(65, 75), reason: 'a gap of 10');
  });

  testWidgets('the thumb moved last is drawn on top, mid-drag and after, '
      'and keeps its focus as the order changes', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(harness(const _Host()));
    final thumbs = find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && '${w.key}'.contains('thumb '),
    );
    // Drawn in tree order: the last is on top.
    String top() =>
        (tester.widgetList(thumbs).last.key! as ValueKey<String>).value;
    expect(top(), 'thumb 1');

    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('thumb 0'))),
    );
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    await drag.moveBy(const Offset(30, 0));
    await tester.pump();
    expect(top(), 'thumb 0', reason: 'the dragged thumb, mid-drag');
    await drag.up();
    await tester.pump();
    expect(top(), 'thumb 0', reason: 'the last dragged stays on top');

    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.tab);
    expect(_thumbs[1], contains(WidgetState.focused));
    await _press(tester, LogicalKeyboardKey.arrowLeft);
    expect(top(), 'thumb 1', reason: 'moved by its keys');
    expect(_thumbs[1], contains(WidgetState.focused));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await _press(tester, LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    expect(_thumbs[0], contains(WidgetState.focused));
    await _press(tester, LogicalKeyboardKey.arrowRight);
    expect(top(), 'thumb 0');
    expect(_thumbs[0], contains(WidgetState.focused));
    expect(_thumbs[1], isNot(contains(WidgetState.focused)));
  });

  testWidgets('each thumb is a tab stop with keys; right to left mirrors '
      'them and the track', (tester) async {
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.pumpWidget(
      harness(const _Host(), textDirection: TextDirection.rtl),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('thumb 0'))).dx,
      440 - 100,
      reason: 'the lower end is on the right',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_thumbs[0], contains(WidgetState.focused));
    await _press(tester, LogicalKeyboardKey.arrowLeft);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(_host.values.start, 22);
    await _press(tester, LogicalKeyboardKey.pageUp);
    expect(_host.values.start, 32);
    await _press(tester, LogicalKeyboardKey.home);
    expect(_host.values.start, 0);
    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.end);
    expect(_host.values.end, 100);
    await _press(tester, LogicalKeyboardKey.home);
    expect(_host.values.end, 10, reason: 'stops a gap above the lower end');
  });

  testWidgets('a screen reader hears two sliders and can step them', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Host(divisions: 10)));
    final upper = find.bySemanticsLabel('Maximum');
    expect(
      tester.getSemantics(upper),
      isSemantics(
        isSlider: true,
        value: '80',
        increasedValue: '90',
        decreasedValue: '70',
        hasIncreaseAction: true,
      ),
    );
    final owner = semanticsOwner();
    owner.performAction(
      tester.getSemantics(upper).id,
      SemanticsAction.decrease,
    );
    await tester.pump();
    expect(_host.values.end, 70);
    expect(find.bySemanticsLabel('Minimum'), findsOneWidget);
    await expectLater(
      tester,
      meetsGuideline(labeledTapTargetGuideline),
      reason: 'the track is the pointer\'s; it adds no unlabelled node',
    );
    semantics.dispose();
  });

  testWidgets('a thumb announces only the adjustments its gap permits', (
    tester,
  ) async {
    var values = const RawRangeValues(60, 80);
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (_, setState) => RawRangeSlider(
            values: values,
            max: 100,
            divisions: 10,
            minGap: 16,
            onChanged: (next) => setState(() => values = next),
            trackBuilder: (_, _) => const SizedBox.shrink(),
            thumbBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
        ),
      ),
    );

    final lower = find.bySemanticsLabel('Minimum');
    final upper = find.bySemanticsLabel('Maximum');
    SemanticsData data(Finder thumb) =>
        semanticsOf(tester, thumb).getSemanticsData();
    Future<void> adjust(Finder thumb, SemanticsAction action) async {
      semanticsOwner().performAction(tester.getSemantics(thumb).id, action);
      await tester.pump();
    }

    // The nearest permitted values are between ticks. Keep their positions
    // and percentages relative to the whole track.
    expect(data(lower).increasedValue, '64%');
    expect(data(upper).decreasedValue, '76%');
    await adjust(lower, SemanticsAction.increase);
    expect(data(lower).value, '64%');
    expect(data(lower).hasAction(SemanticsAction.increase), isFalse);
    expect(data(lower).increasedValue, isEmpty);
    expect(data(upper).hasAction(SemanticsAction.decrease), isFalse);
    expect(data(upper).decreasedValue, isEmpty);
    expect(data(lower).decreasedValue, '50%');
    expect(data(upper).increasedValue, '90%');

    await adjust(lower, SemanticsAction.decrease);
    expect(data(lower).value, '50%');
    await adjust(upper, SemanticsAction.decrease);
    expect(data(upper).value, '70%');
    expect(data(upper).decreasedValue, '66%');
    await adjust(upper, SemanticsAction.decrease);
    expect(data(upper).value, '66%');
    expect(data(upper).hasAction(SemanticsAction.decrease), isFalse);
    expect(data(lower).hasAction(SemanticsAction.increase), isFalse);
    expect(data(upper).increasedValue, '80%');
  });

  testWidgets('a fixed range with divisions offers no adjustments', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        RawRangeSlider(
          values: const RawRangeValues(4, 4),
          min: 4,
          max: 4,
          divisions: 4,
          onChanged: (_) => fail('a fixed range cannot change'),
          trackBuilder: (_, _) => const SizedBox.shrink(),
          thumbBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    );
    for (final label in ['Minimum', 'Maximum']) {
      final data = semanticsOf(
        tester,
        find.bySemanticsLabel(label),
      ).getSemanticsData();
      expect(data.value, '0%');
      expect(data.hasAction(SemanticsAction.increase), isFalse);
      expect(data.hasAction(SemanticsAction.decrease), isFalse);
    }
    await _press(tester, LogicalKeyboardKey.tab);
    await _press(tester, LogicalKeyboardKey.end);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a handle alone: vertical, growing down, as a divider', (
    tester,
  ) async {
    var value = 0.5;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: RawValueHandle(
              value: value,
              axis: Axis.vertical,
              growsToward: VerticalDirection.down,
              step: 0.1,
              autofocus: true,
              onChanged: (v) => setState(() => value = v),
              builder: (context, states) => const SizedBox(width: 8, height: 8),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await _press(tester, LogicalKeyboardKey.arrowDown);
    expect(value, closeTo(0.6, 1e-9));
    await _press(tester, LogicalKeyboardKey.arrowUp);
    await _press(tester, LogicalKeyboardKey.arrowUp);
    expect(value, closeTo(0.4, 1e-9));
    expect(tester.getSize(find.byType(RawValueHandle)), const Size(40, 40));
  });

  for (final turnedOff in [false, true]) {
    testWidgets('a drag cancelled${turnedOff ? ' while turned off' : ''} '
        'lets the thumb go: not pressed, the click cursor', (tester) async {
      var enabled = true;
      var values = const RawRangeValues(0.2, 0.8);
      var pressed = false;
      var ended = 0;
      late StateSetter host;
      await tester.pumpWidget(
        harness(
          Center(
            child: SizedBox(
              width: 350,
              child: StatefulBuilder(
                builder: (_, setState) {
                  host = setState;
                  return RawRangeSlider(
                    values: values,
                    onChanged: enabled
                        ? (next) => setState(() => values = next)
                        : null,
                    onChangeEnd: (_) => ended++,
                    trackBuilder: (_, _) => const SizedBox.shrink(),
                    thumbBuilder: (_, index, states) {
                      if (index == 0) {
                        pressed = states.contains(WidgetState.pressed);
                      }
                      return SizedBox.square(
                        key: ValueKey('face $index'),
                        dimension: 32,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('face 0'))),
      );
      await finger.moveBy(const Offset(35, 0));
      await tester.pump();
      expect(pressed, isTrue);
      if (turnedOff) {
        host(() => enabled = false);
        await tester.pump();
      }
      await finger.cancel();
      await tester.pump();
      if (turnedOff) {
        host(() => enabled = true);
        await tester.pump();
      }
      final mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        pointer: 42,
      );
      await mouse.addPointer(
        location: tester.getCenter(find.byType(RawRangeSlider)),
      );
      await tester.pump();
      final cursor = RendererBinding.instance.mouseTracker
          .debugDeviceActiveCursor(1);
      await mouse.removePointer();
      expect(pressed, isFalse);
      expect(cursor, SystemMouseCursors.click);
      expect(ended, turnedOff ? 0 : 1, reason: 'a cancelled drag ends');
    });
  }
}
