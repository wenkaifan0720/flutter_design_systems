import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

final List<String?> _told = [];

// A list-detail whose choice the host keeps.
class _Host extends StatefulWidget {
  const _Host({this.sideBySide, this.divider = false});

  final bool? sideBySide;
  final bool divider;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? selected;

  void choose(String? item) => setState(() => selected = item);

  @override
  Widget build(BuildContext context) => RawListDetail<String>(
    selectedItem: selected,
    onSelectedItemChanged: (item) {
      _told.add(item);
      choose(item);
    },
    sideBySide: widget.sideBySide,
    dividerBuilder: widget.divider
        ? (context, states, axis) => const ColoredBox(
            key: ValueKey('divider'),
            color: Color(0xFF000000),
          )
        : null,
    listBuilder: (context) => Column(
      key: const ValueKey('list'),
      children: [
        for (final item in ['A', 'B', 'C'])
          Focus(
            debugLabel: 'row $item',
            child: GestureDetector(
              onTap: () {
                _told.add(item);
                choose(item);
              },
              child: SizedBox(height: 44, child: Text('Item $item')),
            ),
          ),
      ],
    ),
    detailBuilder: (context, item) => Column(
      key: const ValueKey('detail'),
      children: [
        Text('Detail $item'),
        const Focus(
          debugLabel: 'detail field',
          child: SizedBox(width: 44, height: 44),
        ),
      ],
    ),
    emptyDetailBuilder: (context) => const Text('Choose an item'),
    detailRouteBuilder: (builder) => PageRouteBuilder<void>(
      pageBuilder: (context, _, _) =>
          ColoredBox(color: const Color(0xFFFFFFFF), child: builder(context)),
    ),
  );
}

_HostState _host(WidgetTester tester) =>
    tester.state(find.byType(_Host, skipOffstage: false));

NavigatorState _navigator(WidgetTester tester) =>
    tester.state(find.byType(Navigator));

Future<void> _width(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 700);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpAndSettle();
}

String? get _focus => FocusManager.instance.primaryFocus?.debugLabel;

void main() {
  setUp(_told.clear);

  testWidgets('narrow: the list alone, a chosen item\'s detail pushed; its '
      'pop clears the choice', (tester) async {
    await _width(tester, 400);
    await tester.pumpWidget(harness(const _Host()));
    expect(find.text('Choose an item'), findsNothing);
    await tester.tap(find.text('Item B'));
    await tester.pumpAndSettle();
    expect(find.text('Detail B'), findsOneWidget);
    expect(_navigator(tester).canPop(), isTrue);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Detail B'), findsNothing);
    expect(_host(tester).selected, isNull);
    expect(_told, ['B', null]);
  });

  testWidgets('a heading and the text under it stay two nodes, in the list '
      'alone and side by side with the detail', (tester) async {
    final semantics = tester.ensureSemantics();
    for (final (width, item) in [(390.0, null), (1000.0, 'A')]) {
      await _width(tester, width);
      await tester.pumpWidget(
        harness(
          RawListDetail<String>(
            selectedItem: item,
            onSelectedItemChanged: (_) {},
            listBuilder: (context) => headingAndText(),
            detailBuilder: (context, item) => Text('Detail $item'),
            detailRouteBuilder: (builder) => PageRouteBuilder<void>(
              pageBuilder: (context, _, _) => builder(context),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expectHeadingAndTextApart(tester);
    }
    semantics.dispose();
  });

  testWidgets('wide: side by side, the list 360 wide, nothing pushed', (
    tester,
  ) async {
    await _width(tester, 1000);
    await tester.pumpWidget(harness(const _Host()));
    expect(tester.getRect(find.byKey(const ValueKey('list'))).width, 360);
    expect(find.text('Choose an item'), findsOneWidget);
    await tester.tap(find.text('Item A'));
    await tester.pumpAndSettle();
    expect(find.text('Detail A'), findsOneWidget);
    expect(tester.getRect(find.text('Detail A')).left, greaterThan(360));
    expect(_navigator(tester).canPop(), isFalse);
  });

  testWidgets('crossing the width keeps the reader where they were', (
    tester,
  ) async {
    await _width(tester, 400);
    await tester.pumpWidget(harness(const _Host()));
    final list = tester.state(
      find
          .ancestor(
            of: find.text('Item A', skipOffstage: false),
            matching: find.byType(Focus),
          )
          .first,
    );
    await tester.tap(find.text('Item C'));
    await tester.pumpAndSettle();
    expect(_navigator(tester).canPop(), isTrue);
    await _width(tester, 1000);
    expect(_navigator(tester).canPop(), isFalse, reason: 'the push left');
    expect(find.text('Detail C'), findsOneWidget, reason: 'beside the list');
    expect(_host(tester).selected, 'C', reason: 'still chosen');
    expect(
      tester.state(
        find
            .ancestor(
              of: find.text('Item A', skipOffstage: false),
              matching: find.byType(Focus),
            )
            .first,
      ),
      same(list),
      reason: 'the list kept its state',
    );
    await _width(tester, 400);
    expect(_navigator(tester).canPop(), isTrue, reason: 'pushed again');
    expect(find.text('Detail C'), findsOneWidget);
    expect(_told, ['C']);
  });

  testWidgets('a choice changed from outside replaces or drops the pushed '
      'detail', (tester) async {
    await _width(tester, 400);
    await tester.pumpWidget(harness(const _Host()));
    _host(tester).choose('A');
    await tester.pumpAndSettle();
    expect(find.text('Detail A'), findsOneWidget);
    _host(tester).choose('B');
    await tester.pumpAndSettle();
    expect(find.text('Detail A'), findsNothing);
    expect(find.text('Detail B'), findsOneWidget);
    _host(tester).choose(null);
    await tester.pumpAndSettle();
    expect(_navigator(tester).canPop(), isFalse);
    expect(_told, isEmpty, reason: 'the host chose; nothing to tell it');
  });

  testWidgets('sideBySide overrides the width; a divider makes a split the '
      'reader resizes', (tester) async {
    await _width(tester, 400);
    await tester.pumpWidget(harness(const _Host(sideBySide: true)));
    expect(find.text('Choose an item'), findsOneWidget);
    await tester.pumpWidget(
      harness(const _Host(sideBySide: true, divider: true)),
    );
    expect(find.byType(RawSplitView), findsOneWidget);
    expect(find.byKey(const ValueKey('divider')), findsOneWidget);
    await _width(tester, 1000);
    await tester.pumpWidget(harness(const _Host(sideBySide: false)));
    expect(find.text('Choose an item'), findsNothing);
  });

  testWidgets('F6 moves between the list and the detail, each where it was', (
    tester,
  ) async {
    await _width(tester, 1000);
    await tester.pumpWidget(harness(const _Host()));
    await tester.tap(find.text('Item A'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(_focus, 'row B');
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_focus, 'detail field');
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(_focus, 'row B', reason: 'where it was');
    await tester.sendKeyEvent(LogicalKeyboardKey.f6, platform: 'linux');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pumpAndSettle();
    expect(_focus, 'row B', reason: 'Shift+F6 back');
  });

  test('it describes itself', () {
    final text = RawListDetail<String>(
      selectedItem: 'A',
      onSelectedItemChanged: (_) {},
      listBuilder: (context) => const SizedBox(),
      detailBuilder: (context, item) => const SizedBox(),
      detailRouteBuilder: (builder) => PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => builder(context),
      ),
      sideBySide: false,
      listWidth: 320,
    ).toDiagnosticsNode().toStringDeep();
    for (final s in [
      'selectedItem: A',
      'has listBuilder',
      'list alone',
      'listWidth: 320.0',
    ]) {
      expect(text, contains(s));
    }
  });

  // The width × direction × text scale matrix.
  for (final width in [400.0, 1000.0]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${width.round()} wide, $direction, text ×$scale: an '
            'item chosen shows its detail', (tester) async {
          await _width(tester, width);
          await tester.pumpWidget(
            harness(const _Host(), textDirection: direction, textScale: scale),
          );
          await tester.tap(find.text('Item B'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.text('Detail B'), findsOneWidget);
          expect(_navigator(tester).canPop(), width < 840);
          if (width >= 840) {
            final list = tester.getRect(find.byKey(const ValueKey('list')));
            expect(
              direction == TextDirection.ltr ? list.left : list.right,
              direction == TextDirection.ltr ? 0 : width,
            );
          }
        }, tags: 'sweep');
      }
    }
  }
}
