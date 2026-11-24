import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_contract.dart';
import 'behaviour_harness.dart';

const _fieldKey = ValueKey('field');

final List<String> _ran = [];

// What the field last heard: its list shows (a palette's always does).
bool? _open;
final Map<String, Set<WidgetState>> _items = {};

List<RawCommand> _commands() => [
  RawCommand(
    label: 'New file',
    group: 'File',
    onPressed: () => _ran.add('new'),
  ),
  RawCommand(
    label: 'Open recent',
    group: 'File',
    keywords: const ['history'],
    onPressed: () => _ran.add('recent'),
  ),
  const RawCommand(label: 'Save all', group: 'File', enabled: false),
  RawCommand(
    label: 'Toggle theme',
    group: 'View',
    onPressed: () => _ran.add('theme'),
  ),
  RawCommand(
    label: 'Zoom in',
    group: 'View',
    onPressed: () => _ran.add('zoom'),
  ),
];

// The bare reference painter: a field and labelled rows.
RawCommandPalette _palette({
  ValueChanged<RawCommand>? onSelected,
  bool autofocus = true,
}) => RawCommandPalette(
  commands: _commands(),
  onSelected: onSelected,
  autofocus: autofocus,
  fieldBuilder: (context, field) {
    _open = field.isOpen;
    return plainField(
      key: _fieldKey,
      controller: field.controller,
      focusNode: field.focusNode,
      onSubmitted: field.submit,
    );
  },
  groupBuilder: (context, group) => Text('# $group'),
  emptyBuilder: (context) => const Text('Nothing found'),
  itemBuilder: (context, command, states) {
    _items[command.label] = states;
    return SizedBox(height: 44, child: Text(command.label));
  },
);

bool _lit(String label) => _items[label]!.contains(WidgetState.focused);

void main() {
  testWidgets('RawCommandShortcut keeps the nodes of the app under it: a '
      'heading and the text under it stay two', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(RawCommandShortcut(onOpen: () {}, child: headingAndText())),
    );
    expectHeadingAndTextApart(tester);
    semantics.dispose();
  });

  testWidgets('words beside the palette\'s field name its text field, on '
      'its one node, and are read once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        RawCommandPalette(
          commands: _commands(),
          fieldBuilder: (context, field) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Search'),
              plainField(
                controller: field.controller,
                focusNode: field.focusNode,
                onSubmitted: field.submit,
              ),
            ],
          ),
          itemBuilder: (context, command, states) =>
              SizedBox(height: 44, child: Text(command.label)),
        ),
      ),
    );
    expect(textFieldNode().label, 'Search');
    var said = 0;
    void visit(SemanticsNode n) {
      if (!n.isMergedIntoParent && n.label.contains('Search')) said++;
      n.visitChildren((c) {
        visit(c);
        return true;
      });
    }

    visit(semanticsOwner().rootSemanticsNode!);
    expect(said, 1, reason: 'no node of its own beside the field says it');
    semantics.dispose();
  });

  testWidgets('the field hears that its list shows: a palette\'s always '
      'does', (tester) async {
    _open = null;
    await tester.pumpWidget(harness(_palette()));
    await tester.pumpAndSettle();
    expect(_open, isTrue);
  });

  setUp(() {
    _ran.clear();
    _items.clear();
  });

  behaviourContract(
    'RawCommandPalette',
    build: (c) => _palette(),
    node: () => find.byKey(_fieldKey),
    semantics: isSemantics(
      isTextField: true,
      isFocusable: true,
      isFocused: true,
    ),
    noDisabledState:
        'the field is the look\'s; a command disables itself '
        '(RawCommand.enabled)',
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
        showRawCommandPalette(
          context: p.tester.element(p.node),
          palette: (run) => _palette(onSelected: run),
        ),
      );
      await p.tester.pump();
    },
  );

  test('a prefix beats a word start, which beats a substring, which beats '
      'letters in order', () {
    final prefix = rawMatchScore('Theme', 'the')!;
    final word = rawMatchScore('Toggle theme', 'the')!;
    final inside = rawMatchScore('Aesthetic', 'the')!;
    final spread = rawMatchScore('Tab here', 'the')!;
    expect(prefix, greaterThan(word));
    expect(word, greaterThan(inside));
    expect(inside, greaterThan(spread));
    expect(rawMatchScore('Zoom', 'the'), isNull);
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

  testWidgets('in a long list, every move keeps the highlighted row in view, '
      'round the ends too', (tester) async {
    final many = [
      for (var i = 0; i < 30; i++)
        RawCommand(label: 'Command $i', onPressed: () {}),
    ];
    await tester.pumpWidget(
      harness(
        RawCommandPalette(
          commands: many,
          maxHeight: 200,
          fieldBuilder: (context, field) => plainField(
            key: _fieldKey,
            controller: field.controller,
            focusNode: field.focusNode,
            onSubmitted: field.submit,
          ),
          itemBuilder: (context, command, states) {
            _items[command.label] = states;
            return SizedBox(
              key: ValueKey(command.label),
              height: command.label.endsWith('9') ? 64 : 44,
              child: Text(command.label),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    void inView(String label) {
      final row = find.text(label);
      expect(row, findsOneWidget, reason: '$label is built');
      final list = tester.getRect(find.byType(ListView));
      final rect = tester.getRect(find.byKey(ValueKey(label)));
      expect(
        rect.top >= list.top - 0.5 && rect.bottom <= list.bottom + 0.5,
        isTrue,
        reason: '$label ($rect) lies wholly in the list ($list)',
      );
    }

    expect(_lit('Command 0'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(_lit('Command 29'), isTrue);
    inView('Command 29');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(_lit('Command 0'), isTrue);
    inView('Command 0');
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

  testWidgets('modal: a barrier builder paints the barrier in place of its '
      'colour, which still closes it on a tap and says its label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    late BuildContext app;
    Widget dots(BuildContext context, Animation<double> animation) =>
        FadeTransition(
          opacity: animation,
          child: const ColoredBox(
            key: ValueKey('dots'),
            color: Color(0x330000FF),
            child: Text('dots'),
          ),
        );
    final RawBarrierBuilder builder = dots;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            app = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showRawCommandPalette(
        context: app,
        palette: (run) => _palette(onSelected: run),
        barrierBuilder: builder,
        surfaceBuilder: (context, palette) =>
            SizedBox(width: 400, child: palette),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('New file'), findsOneWidget);
    expect(find.byKey(const ValueKey('dots')), findsOneWidget);
    final route = ModalRoute.of(tester.element(find.text('New file')))!;
    expect(route.barrierColor, isNull, reason: 'the builder paints it');
    expect(find.bySemanticsLabel('Close commands'), findsOneWidget);
    expect(find.bySemanticsLabel('dots'), findsNothing);
    await tester.tapAt(const Offset(20, 580));
    await tester.pumpAndSettle();
    expect(find.text('New file'), findsNothing);
    expect(find.byKey(const ValueKey('dots')), findsNothing);
    semantics.dispose();
  });

  // Android's and the web's flag, then iOS's alone.
  for (final ios in [false, true]) {
    testWidgets('modal under Reduce Motion${ios ? ', iOS\'s alone' : ''}: '
        'it shows at once, no fade', (tester) async {
      if (ios) iosReduceMotion(tester);
      late BuildContext app;
      await tester.pumpWidget(
        harness(
          Builder(
            builder: (context) {
              app = context;
              return const SizedBox.expand();
            },
          ),
          reduceMotion: !ios,
        ),
      );
      unawaited(
        showRawCommandPalette(
          context: app,
          palette: (run) => _palette(onSelected: run),
          surfaceBuilder: (context, palette) =>
              SizedBox(width: 400, child: palette),
        ),
      );
      await tester.pump();
      final fades = tester.widgetList<FadeTransition>(
        find.ancestor(
          of: find.text('New file'),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fades, isNotEmpty);
      for (final fade in fades) {
        expect(fade.opacity.value, 1, reason: 'shown at once');
      }
    });
  }

  testWidgets('modal: Escape closes it with nothing in it focused, the '
      "focus on the route's own scope", (tester) async {
    late BuildContext app;
    await tester.pumpWidget(
      harness(
        Builder(
          builder: (context) {
            app = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    unawaited(
      showRawCommandPalette(
        context: app,
        palette: (run) => _palette(onSelected: run),
        surfaceBuilder: (context, palette) =>
            SizedBox(width: 400, child: palette),
      ),
    );
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();
    final focus = FocusManager.instance.primaryFocus;
    expect(focus, isA<FocusScopeNode>());
    expect(focus!.debugLabel, contains('ModalScopeState'));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('New file'), findsNothing);
  });

  testWidgets('modal: Ctrl+K opens it, Escape closes it and focus returns; '
      'a chosen command runs after it closed', (tester) async {
    late BuildContext app;
    final opener = FocusNode();
    addTearDown(opener.dispose);
    Future<void> open() => showRawCommandPalette(
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
            return RawCommandShortcut(
              onOpen: open,
              child: Center(
                child: RawButton(
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
