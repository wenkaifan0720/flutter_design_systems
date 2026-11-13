import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');

final List<String> _ran = [];
final Map<String, Set<WidgetState>> _items = {};

List<DesignCommand> _commands() => [
  DesignCommand(
    label: 'New file',
    group: 'File',
    onPressed: () => _ran.add('new'),
  ),
  DesignCommand(
    label: 'Open recent',
    group: 'File',
    keywords: const ['history'],
    onPressed: () => _ran.add('recent'),
  ),
  const DesignCommand(label: 'Save all', group: 'File', enabled: false),
  DesignCommand(
    label: 'Toggle theme',
    group: 'View',
    onPressed: () => _ran.add('theme'),
  ),
  DesignCommand(
    label: 'Zoom in',
    group: 'View',
    onPressed: () => _ran.add('zoom'),
  ),
];

// The bare reference painter: a field and labelled rows.
DesignCommandPalette _palette({
  ValueChanged<DesignCommand>? onSelected,
  bool autofocus = true,
}) => DesignCommandPalette(
  commands: _commands(),
  onSelected: onSelected,
  autofocus: autofocus,
  fieldBuilder: (context, field) => plainField(
    key: _fieldKey,
    controller: field.controller,
    focusNode: field.focusNode,
    onSubmitted: field.submit,
  ),
  groupBuilder: (context, group) => Text('# $group'),
  emptyBuilder: (context) => const Text('Nothing found'),
  itemBuilder: (context, command, states) {
    _items[command.label] = states;
    return SizedBox(height: 44, child: Text(command.label));
  },
);

bool _lit(String label) => _items[label]!.contains(WidgetState.focused);

void main() {
  setUp(() {
    _ran.clear();
    _items.clear();
  });

  behaviourContract(
    'DesignCommandPalette',
    build: (c) => _palette(),
    node: () => find.byKey(_fieldKey),
    semantics: isSemantics(
      isTextField: true,
      isFocusable: true,
      isFocused: true,
    ),
    noDisabledState:
        'the field is the look\'s; a command disables itself '
        '(DesignCommand.enabled)',
    keyboard: (p) async {
      final t = p.tester;
      expect(
        t.getSemantics(find.bySemanticsLabel('Commands')),
        isSemantics(label: 'Commands'),
        reason: 'the results carry their name',
      );
      expect(
        t.getSemantics(find.text('Save all')),
        isSemantics(label: 'Save all', hasEnabledState: true),
        reason: 'a disabled command says so',
      );
      expect(
        t
            .getSemantics(find.text('Save all'))
            .getSemanticsData()
            .flagsCollection
            .isEnabled,
        Tristate.isFalse,
      );
      t.takeAnnouncements();
      await p.key(LogicalKeyboardKey.arrowDown);
      await p.key(LogicalKeyboardKey.arrowDown);
      expect(t.takeAnnouncements().map((a) => a.message), [
        'Open recent',
        'Toggle theme',
      ], reason: 'the highlight is told as it moves, past a disabled command');
      expect(
        t.getSemantics(find.text('Toggle theme')),
        isSemantics(label: 'Toggle theme', isSelected: true),
        reason: 'and the lit row says it is selected',
      );
      expect(p.focused, isTrue, reason: 'focus stays in the field');
      await t.enterText(p.node, 'zzz');
      await t.pumpAndSettle();
      expect(
        t.takeAnnouncements().map((a) => a.message),
        contains('No results'),
      );
      await t.enterText(p.node, 'zoom');
      await t.pumpAndSettle();
      await p.key(LogicalKeyboardKey.enter);
      expect(_ran, ['zoom'], reason: 'Enter runs the lit command');
    },
    motion: (p) async {
      unawaited(
        showDesignCommandPalette(
          context: p.tester.element(p.node),
          palette: (run) => _palette(onSelected: run),
        ),
      );
      await p.tester.pump();
    },
  );

  test('a prefix beats a word start, which beats a substring, which beats '
      'letters in order', () {
    final prefix = designMatchScore('Theme', 'the')!;
    final word = designMatchScore('Toggle theme', 'the')!;
    final inside = designMatchScore('Aesthetic', 'the')!;
    final spread = designMatchScore('Tab here', 'the')!;
    expect(prefix, greaterThan(word));
    expect(word, greaterThan(inside));
    expect(inside, greaterThan(spread));
    expect(designMatchScore('Zoom', 'the'), isNull);
  });

  testWidgets('focus stays in the field; arrows move the highlight past a '
      'disabled command and wrap; Enter runs it', (tester) async {
    await tester.pumpWidget(harness(_palette()));
    await tester.pump();
    expect(find.text('# File'), findsOneWidget);
    expect(_lit('New file'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(_lit('Toggle theme'), isTrue, reason: 'Save all is disabled');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(_lit('Zoom in'), isTrue, reason: 'wrapped');
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(_ran, ['zoom']);
  });

  testWidgets('inline (autofocus false) it waits to be reached: no focus '
      'taken on build, Tab reaches its field', (tester) async {
    await tester.pumpWidget(harness(_palette(autofocus: false)));
    await tester.pump();
    await tester.pump();
    final field = tester.widget<EditableText>(find.byType(EditableText));
    expect(field.focusNode.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(field.focusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets('inline below the fold, it leaves its page where it is', (
    tester,
  ) async {
    final page = ScrollController();
    addTearDown(page.dispose);
    await tester.pumpWidget(
      harness(
        SingleChildScrollView(
          controller: page,
          child: Column(
            children: [
              const SizedBox(height: 2000),
              SizedBox(height: 400, child: _palette(autofocus: false)),
              const SizedBox(height: 600),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_lit('New file'), isTrue);
    expect(
      page.offset,
      0,
      reason:
          'the first row is lit, and only the results list may move to show it',
    );
  });

  testWidgets('a query ranks within groups and finds keywords; no match '
      'shows the empty state', (tester) async {
    await tester.pumpWidget(harness(_palette()));
    await tester.enterText(find.byType(EditableText), 'hist');
    await tester.pump();
    expect(find.text('Open recent'), findsOneWidget);
    expect(find.text('New file'), findsNothing);
    expect(_lit('Open recent'), isTrue);
    await tester.enterText(find.byType(EditableText), 'zzz');
    await tester.pump();
    expect(find.text('Nothing found'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'the');
    await tester.pump();
    expect(find.text('# View'), findsOneWidget);
    expect(find.text('# File'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(_ran, ['theme']);
  });

  testWidgets('modal: Ctrl+K opens it, Escape closes it and focus returns; '
      'a chosen command runs after it closed', (tester) async {
    late BuildContext app;
    final opener = FocusNode();
    addTearDown(opener.dispose);
    Future<void> open() => showDesignCommandPalette(
      context: app,
      palette: (run) => _palette(onSelected: run),
      surfaceBuilder: (context, palette) =>
          SizedBox(width: 400, child: palette),
    );
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            app = context;
            return DesignCommandShortcut(
              onOpen: open,
              child: Center(
                child: DesignPressable(
                  focusNode: opener,
                  onPressed: () {},
                  builder: (context, states, _) => const Text('opener'),
                ),
              ),
            );
          },
        ),
      ),
    );
    opener.requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('New file'), findsOneWidget);
    expect(opener.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('New file'), findsNothing);
    expect(opener.hasFocus, isTrue);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'zoom');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('New file'), findsNothing);
    expect(_ran, ['zoom']);
    expect(opener.hasFocus, isTrue);
  });
}
