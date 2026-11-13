import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final Map<String, Set<WidgetState>> _states = {};

class _Host extends StatefulWidget {
  const _Host({this.multiple = false, this.follow = false});

  final bool multiple;
  final bool follow;

  @override
  State<_Host> createState() => _HostState();
}

late _HostState _host;

class _HostState extends State<_Host> {
  late Set<String> selected = {'week'};

  @override
  Widget build(BuildContext context) {
    _host = this;
    return Column(
      children: [
        Focus(child: plainFace('before')),
        DesignToggleGroup<String>(
          options: const ['day', 'week', 'month', 'year'],
          selected: selected,
          multiSelectionEnabled: widget.multiple,
          selectFollowsFocus: widget.follow,
          isEnabled: (v) => v != 'month',
          semanticLabel: 'Range',
          onSelectionChanged: (next) => setState(() => selected = next),
          // The bare reference painter: the value's name in a box.
          itemBuilder: (context, value, states) {
            _states[value] = states;
            return plainFace(value);
          },
        ),
        Focus(child: plainFace('after')),
      ],
    );
  }
}

void _keyboard() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  setUp(_states.clear);

  var picked = <String>{};
  behaviourContract(
    'DesignToggleGroup',
    build: (c) {
      picked = {'week'};
      return StatefulBuilder(
        builder: (context, setState) => DesignToggleGroup<String>(
          options: const ['day', 'week', 'month'],
          selected: picked,
          semanticLabel: 'Range',
          onSelectionChanged: c.enabled
              ? (v) => setState(() => picked = v)
              : null,
          itemBuilder: (context, value, states) => plainFace(value),
        ),
      );
    },
    node: () => find.text('week'),
    root: () => find.byType(DesignToggleGroup<String>),
    // One choice: a radio group, the chosen item checked.
    semantics: isSemantics(
      label: 'week',
      hasCheckedState: true,
      isChecked: true,
      isInMutuallyExclusiveGroup: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
    ),
    disabled: isSemantics(
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasTapAction: false,
    ),
    keyboard: (p) async {
      await p.tabInto();
      expect(p.focused, isTrue, reason: 'Tab stops at the choice');
      await p.key(LogicalKeyboardKey.arrowRight);
      await p.key(LogicalKeyboardKey.space);
      expect(picked, {'month'}, reason: 'arrows move, Space chooses');
      await p.key(LogicalKeyboardKey.home);
      expect(
        p.tester.getSemantics(find.text('day')),
        isSemantics(isFocused: true),
        reason: 'Home goes to the first',
      );
    },
    rtl: (p) async {
      await p.tabInto();
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(
        p.tester.getSemantics(find.text('day')),
        isSemantics(isFocused: true),
        reason: 'right to left, Right goes back',
      );
    },
  );

  testWidgets('one tab stop at the chosen item; arrows skip the disabled '
      'item and wrap; a press chooses', (tester) async {
    _keyboard();
    await tester.pumpWidget(harness(const _Host()));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_states['week'], contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      _states['year'],
      contains(WidgetState.focused),
      reason: 'month skipped',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_states['day'], contains(WidgetState.focused), reason: 'wrapped');
    expect(_host.selected, {'week'}, reason: 'arrows only move');
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_host.selected, {'day'});
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_host.selected, {
      'day',
    }, reason: 'a one-choice group keeps its choice');
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pump();
    expect(_states['year'], contains(WidgetState.focused));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      _states.values.any((s) => s.contains(WidgetState.focused)),
      isFalse,
      reason: 'Tab leaves the group',
    );
  });

  testWidgets('selectFollowsFocus chooses as the arrows move; right to left '
      'mirrors them', (tester) async {
    _keyboard();
    await tester.pumpWidget(
      harness(const _Host(follow: true), textDirection: TextDirection.rtl),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(_host.selected, {'year'});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(_host.selected, {'week'});
  });

  testWidgets('many: each toggles; a screen reader hears toggles, or a radio '
      'group for one choice', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Host(multiple: true)));
    await tester.tap(find.text('day'));
    await tester.pump();
    await tester.tap(find.text('week'));
    await tester.pump();
    expect(_host.selected, {'day'});
    expect(
      tester.getSemantics(find.text('day')),
      isSemantics(hasToggledState: true, isToggled: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.text('month')),
      isSemantics(isEnabled: false),
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(harness(const _Host()));
    expect(
      tester.getSemantics(find.text('week')),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSize(find.byType(DesignToggleGroup<String>)).height,
      greaterThanOrEqualTo(44),
      reason: '44 px targets',
    );
    semantics.dispose();
  });
}
