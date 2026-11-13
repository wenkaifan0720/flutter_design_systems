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
  DesignRangeValues values = const DesignRangeValues(20, 80);

  @override
  Widget build(BuildContext context) {
    _host = this;
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 444,
        child: DesignRangeSlider(
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
    'DesignRangeSlider',
    build: (c) => _Host(enabled: c.enabled),
    node: () => find.bySemanticsLabel('Minimum'),
    root: () => find.byType(DesignRangeSlider),
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
    'DesignValueHandle',
    build: (c) => StatefulBuilder(
      builder: (context, setState) => Center(
        child: DesignValueHandle(
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

  testWidgets('thumbs sit at their values; a press moves the nearer one; a '
      'drag cannot cross the other', (tester) async {
    await tester.pumpWidget(harness(const _Host()));
    // 400 px of travel from x = 22: 20 at 102, 80 at 342.
    expect(tester.getCenter(find.byKey(const ValueKey('thumb 0'))).dx, 102);
    expect(tester.getCenter(find.byKey(const ValueKey('thumb 1'))).dx, 342);
    await tester.tapAt(const Offset(22 + 300, 22));
    await tester.pump();
    expect(_host.values, const DesignRangeValues(20, 75));

    await tester.drag(
      find.byKey(const ValueKey('thumb 0')),
      const Offset(400, 0),
    );
    await tester.pump();
    expect(
      _host.values,
      const DesignRangeValues(65, 75),
      reason: 'a gap of 10',
    );
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
      444 - 102,
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

  testWidgets('a handle alone: vertical, growing down, as a divider', (
    tester,
  ) async {
    var value = 0.5;
    await tester.pumpWidget(
      harness(
        StatefulBuilder(
          builder: (context, setState) => Center(
            child: DesignValueHandle(
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
    expect(tester.getSize(find.byType(DesignValueHandle)), const Size(44, 44));
  });
}
