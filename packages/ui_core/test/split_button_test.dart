import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

final List<String> _ran = [];
final Map<String, Set<WidgetState>> _states = {};

// The bare reference painter: "Save" and "v" side by side; a grey menu.
Widget _button({TextDirection direction = TextDirection.ltr}) => harness(
  Center(
    child: DesignSplitButton(
      label: 'Save',
      onPressed: () => _ran.add('save'),
      actions: [
        DesignSplitAction(label: 'Save as', onPressed: () => _ran.add('as')),
        DesignSplitAction(label: 'Save all', onPressed: () => _ran.add('all')),
      ],
      buttonBuilder: (context, part, states, open) {
        _states[part.name] = states;
        return Text(part == DesignSplitPart.main ? 'Save' : (open ? '^' : 'v'));
      },
      itemBuilder: (context, action, states) {
        _states[action.label] = states;
        return SizedBox(width: 120, height: 44, child: Text(action.label));
      },
      surfaceBuilder: (context, info, items) => ColoredBox(
        color: const Color(0xFFEEEEEE),
        child: Column(mainAxisSize: MainAxisSize.min, children: items),
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
    'DesignSplitButton',
    build: (c) => Center(
      child: DesignSplitButton(
        label: 'Save',
        onPressed: c.enabled ? () => _ran.add('save') : null,
        actions: [
          DesignSplitAction(label: 'Save as', onPressed: () => _ran.add('as')),
        ],
        buttonBuilder: (context, part, states, open) =>
            Text(part == DesignSplitPart.main ? 'Save' : (open ? '^' : 'v')),
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

  testWidgets('two tab stops; the main half runs; the toggle opens the menu; '
      'an item runs after it closes', (tester) async {
    await tester.pumpWidget(_button());
    await tester.tap(find.text('Save'));
    expect(_ran, ['save']);
    expect(
      tester.getSize(find.byType(DesignSplitButton)),
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
