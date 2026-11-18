import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final Map<int, DesignRatingItemDetails> _items = {};

// The bare reference painter: a 40-wide item whose face says its fill.
Widget _item(BuildContext context, DesignRatingItemDetails d) {
  _items[d.index] = d;
  return SizedBox(
    key: ValueKey('item ${d.index}'),
    width: 40,
    height: 44,
    child: Center(
      child: Text(
        d.fill >= 1
            ? '★'
            : d.fill > 0
            ? '⯪'
            : '☆',
      ),
    ),
  );
}

late _HostState _host;

class _Host extends StatefulWidget {
  const _Host({
    this.value = 0,
    this.enabled = true,
    this.allowHalf = false,
    this.readOnly = false,
    this.itemCount = 5,
    this.locale,
  });

  final double value;
  final bool enabled;
  final bool allowHalf;
  final bool readOnly;
  final int itemCount;
  final Locale? locale;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late double value = widget.value;
  final List<double> sent = [];
  final List<String> ends = [];

  @override
  Widget build(BuildContext context) {
    _host = this;
    final rating = Align(
      alignment: Alignment.topLeft,
      child: DesignRating(
        value: value,
        itemCount: widget.itemCount,
        allowHalf: widget.allowHalf,
        readOnly: widget.readOnly,
        onChangeStart: (v) => ends.add('start $v'),
        onChangeEnd: (v) => ends.add('end $v'),
        onChanged: widget.enabled
            ? (next) => setState(() {
                sent.add(next);
                value = next;
              })
            : null,
        itemBuilder: _item,
      ),
    );
    final locale = widget.locale;
    if (locale == null) return rating;
    final direction = Directionality.of(context);
    return Localizations(
      locale: locale,
      delegates: const [
        DesignLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: Directionality(textDirection: direction, child: rating),
    );
  }
}

Finder _itemAt(int i) => find.byKey(ValueKey('item $i'));

// A point [fraction] of the way across item [i], as drawn.
Offset _on(WidgetTester tester, int i, double fraction) {
  final rect = tester.getRect(_itemAt(i));
  return Offset(rect.left + rect.width * fraction, rect.center.dy);
}

void main() {
  setUp(_items.clear);

  behaviourContract(
    'DesignRating',
    build: (c) => _Host(value: 3, enabled: c.enabled),
    node: () => find.bySemanticsLabel('Rating'),
    root: () => find.byType(DesignRating),
    semantics: isSemantics(
      label: 'Rating',
      value: '3 of 5',
      increasedValue: '4 of 5',
      decreasedValue: '2 of 5',
      isSlider: true,
      isFocusable: true,
      hasEnabledState: true,
      isEnabled: true,
      hasIncreaseAction: true,
      hasDecreaseAction: true,
    ),
    disabled: isSemantics(
      label: 'Rating',
      value: '3 of 5',
      isSlider: true,
      hasEnabledState: true,
      isEnabled: false,
      isFocusable: false,
      hasIncreaseAction: false,
      hasDecreaseAction: false,
    ),
    // The stars are drawn; a screen reader hears the value.
    hidden: const ['★', '☆'],
    keyboard: (p) async {
      await p.tabInto();
      expect(_items[0]!.states, contains(WidgetState.focused));
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_host.value, 4);
      expect(_host.ends, ['start 3.0', 'end 4.0']);
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_host.value, 5);
      await p.key(LogicalKeyboardKey.arrowUp);
      expect(_host.sent, [4, 5], reason: 'nothing above all of them');
      await p.key(LogicalKeyboardKey.arrowLeft);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(_host.value, 3);
      await p.key(LogicalKeyboardKey.home);
      expect(_host.value, 0, reason: 'Home clears');
      await p.key(LogicalKeyboardKey.end);
      expect(_host.value, 5);
      await p.tester.sendKeyEvent(LogicalKeyboardKey.digit2, character: '2');
      await p.tester.pump();
      expect(_host.value, 2);
      await p.tester.sendKeyEvent(LogicalKeyboardKey.digit0, character: '0');
      await p.tester.pump();
      expect(_host.value, 0, reason: '0 clears');
      await p.tester.sendKeyEvent(LogicalKeyboardKey.digit9, character: '9');
      await p.tester.pump();
      expect(_host.value, 0, reason: 'more than five: nothing');
    },
    rtl: (p) async {
      await p.tabInto();
      // Drawn right to left: Left steps up, toward the far end.
      expect(
        p.tester.getCenter(_itemAt(0)).dx,
        greaterThan(p.tester.getCenter(_itemAt(4)).dx),
      );
      await p.key(LogicalKeyboardKey.arrowLeft);
      expect(_host.value, 4);
      await p.key(LogicalKeyboardKey.arrowRight);
      expect(_host.value, 3);
    },
  );

  group('a pointer', () {
    testWidgets('a tap sets the item tapped; the value already set, '
        'nothing', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 3)));
      await tester.tapAt(_on(tester, 1, 0.5));
      await tester.pump();
      expect(_host.value, 2);
      await tester.tapAt(_on(tester, 1, 0.8));
      await tester.pump();
      expect(_host.sent, [2], reason: 'a tap on the current rating');
      expect(_host.ends, ['start 3.0', 'end 2.0']);
    });

    testWidgets('half steps: the first half of an item is a half', (
      tester,
    ) async {
      await tester.pumpWidget(harness(const _Host(allowHalf: true)));
      await tester.tapAt(_on(tester, 2, 0.25));
      await tester.pump();
      expect(_host.value, 2.5);
      expect(_items[2]!.fill, 0.5);
      expect(find.text('⯪'), findsOneWidget);
      await tester.tapAt(_on(tester, 2, 0.75));
      await tester.pump();
      expect(_host.value, 3);
    });

    testWidgets('right to left, the first half is the right one', (
      tester,
    ) async {
      await tester.pumpWidget(
        harness(const _Host(allowHalf: true), textDirection: TextDirection.rtl),
      );
      await tester.tapAt(_on(tester, 0, 0.75));
      await tester.pump();
      expect(_host.value, 0.5);
    });

    testWidgets(
      'only the held item presses, including a half step in RTL; cancellation clears it',
      (tester) async {
        await tester.pumpWidget(
          harness(
            const _Host(allowHalf: true),
            textDirection: TextDirection.rtl,
          ),
        );
        final press = await tester.startGesture(_on(tester, 2, 0.75));
        await tester.pump();
        Iterable<int> held() => _items.values
            .where((d) => d.states.contains(WidgetState.pressed))
            .map((d) => d.index);
        expect(held(), [2]);
        expect(_host.sent, isEmpty);
        await press.cancel();
        await tester.pump();
        expect(held(), isEmpty);
        expect(_host.sent, isEmpty);
      },
    );

    testWidgets('hovering previews the value a tap would set', (tester) async {
      await tester.pumpWidget(harness(const _Host(value: 1)));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(_on(tester, 3, 0.5));
      await tester.pump();
      expect(_items[3]!.fill, 1);
      expect(_items[3]!.isPreview, isTrue);
      expect(_items[0]!.states, contains(WidgetState.hovered));
      expect(_host.sent, isEmpty, reason: 'a preview only');
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(_items[3]!.fill, 0);
      expect(_items[3]!.isPreview, isFalse);
      expect(_items[0]!.states, isNot(contains(WidgetState.hovered)));
      await mouse.removePointer();
    });

    testWidgets('a drag sweeps across, changing as it goes, a step played '
        'at each', (tester) async {
      final log = <String>[];
      await tester.pumpWidget(
        harness(
          DesignHapticsScope(
            haptics: DesignHaptics(selectionChanged: () => log.add('step')),
            child: const _Host(value: 1),
          ),
        ),
      );
      final drag = await tester.startGesture(_on(tester, 0, 0.5));
      await tester.pump();
      expect(_items[0]!.states, contains(WidgetState.pressed));
      await drag.moveTo(_on(tester, 1, 0.5));
      await tester.pump();
      expect(_items[0]!.states, isNot(contains(WidgetState.pressed)));
      expect(_items[1]!.states, contains(WidgetState.pressed));
      await drag.moveTo(_on(tester, 2, 0.5));
      await tester.pump();
      await drag.moveTo(_on(tester, 3, 0.5));
      await tester.pump();
      expect(_host.value, 4);
      // Past the end: all of them; before the start: the least step.
      await drag.moveTo(_on(tester, 4, 1.5));
      await tester.pump();
      expect(_host.value, 5);
      await drag.moveTo(_on(tester, 0, -0.5));
      await tester.pump();
      expect(_host.value, 1);
      await drag.up();
      await tester.pump();
      expect(_host.sent.first, 2);
      expect(_host.sent.last, 1);
      expect(log, hasLength(_host.sent.length));
      expect(_host.ends.first, 'start 1.0');
      expect(_host.ends.last, 'end 1.0');
      expect(_items[0]!.states, isNot(contains(WidgetState.pressed)));
    });
  });

  testWidgets('a screen reader steps it, in halves with allowHalf', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness(const _Host(value: 2, allowHalf: true)));
    final node = semanticsOf(tester, find.bySemanticsLabel('Rating'));
    expect(node.getSemanticsData().increasedValue, '2.5 of 5');
    semanticsOwner().performAction(node.id, SemanticsAction.increase);
    await tester.pump();
    expect(_host.value, 2.5);
    semanticsOwner().performAction(node.id, SemanticsAction.decrease);
    await tester.pump();
    semanticsOwner().performAction(node.id, SemanticsAction.decrease);
    await tester.pump();
    expect(_host.value, 1.5);
    handle.dispose();
  });

  testWidgets('read-only: a value, no stop, no input, not disabled', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Host(value: 3.7, readOnly: true)));
    expect(_items[3]!.fill, closeTo(0.7, 1e-9));
    expect(_items[0]!.states, isEmpty);
    expect(
      semanticsOf(tester, find.bySemanticsLabel('Rating')),
      isSemantics(
        label: 'Rating',
        value: '3.7 of 5',
        isSlider: false,
        isFocusable: false,
        hasEnabledState: false,
        hasIncreaseAction: false,
        hasDecreaseAction: false,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.tapAt(_on(tester, 1, 0.5));
    await tester.pump();
    expect(_host.sent, isEmpty);
  });

  testWidgets('a fraction shows as one, and the keys step from it', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const _Host(value: 4.3)));
    expect(_items[4]!.fill, closeTo(0.3, 1e-9));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_host.value, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_host.value, 5);
  });

  testWidgets('in the reader\'s words: Arabic counts in its digits', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const _Host(value: 3, locale: Locale('ar')),
        textDirection: TextDirection.rtl,
      ),
    );
    final l = DesignLocalizations.of(tester.element(find.byType(DesignRating)));
    final data = semanticsOf(
      tester,
      find.bySemanticsLabel(l.ratingLabel),
    ).getSemanticsData();
    expect(data.value, l.ratingValueLabel(3, 5));
    expect(data.value, contains('٣'));
  });

  testWidgets('a layout, a formatter and a cursor of the caller\'s', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        DesignRating(
          value: 2,
          onChanged: (_) {},
          itemBuilder: _item,
          semanticFormatterCallback: (v) => '${v.round()} stars',
          mouseCursor: SystemMouseCursors.grab,
          layoutBuilder: (context, items) => Column(children: items),
        ),
      ),
    );
    expect(
      tester.getCenter(_itemAt(1)).dy,
      greaterThan(tester.getCenter(_itemAt(0)).dy),
    );
    expect(
      semanticsOf(
        tester,
        find.bySemanticsLabel('Rating'),
      ).getSemanticsData().value,
      '2 stars',
    );
  });

  testWidgets('turned off: no preview, no input', (tester) async {
    await tester.pumpWidget(harness(const _Host(value: 2)));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(_on(tester, 4, 0.5));
    await tester.pump();
    expect(_items[4]!.fill, 1);
    await tester.pumpWidget(harness(const _Host(value: 2, enabled: false)));
    await tester.pump();
    expect(_items[4]!.fill, 0);
    expect(_items[0]!.states, contains(WidgetState.disabled));
    await mouse.moveTo(_on(tester, 3, 0.5));
    await tester.tapAt(_on(tester, 4, 0.5));
    await tester.pump();
    expect(_host.sent, isEmpty);
    await mouse.removePointer();
  });

  testWidgets('a different count rebuilds its items', (tester) async {
    await tester.pumpWidget(harness(const _Host(value: 2, itemCount: 3)));
    expect(_itemAt(2), findsOneWidget);
    expect(_itemAt(3), findsNothing);
    await tester.pumpWidget(harness(const _Host(value: 2, itemCount: 10)));
    await tester.pump();
    expect(_itemAt(9), findsOneWidget);
  });

  test('diagnostics name what it was given', () {
    const rating = DesignRating(
      value: 1,
      onChanged: null,
      itemBuilder: _item,
      allowHalf: true,
      readOnly: true,
      autofocus: true,
      semanticLabel: 'Food',
    );
    expect(
      rating.toDiagnosticsNode().getProperties().map((p) => p.name),
      containsAll(['value', 'onChanged', 'allowHalf', 'readOnly', 'autofocus']),
    );
  });
}
