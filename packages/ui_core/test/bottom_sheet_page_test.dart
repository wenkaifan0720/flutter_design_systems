// RawBottomSheetPage (0.6.0): a bottom sheet in a navigator's page list. A
// barrier tap pops it out of the list; a new page under the same key
// repaints the panel, its words and whether the barrier closes it.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _recipe = RawPage<void>(
  key: ValueKey('recipe'),
  transitionsBuilder: FadeUpwardsPageTransitionsBuilder(),
  child: SizedBox.expand(),
);

RawBottomSheetPage<void> _sheet(
  String text, {
  bool barrierDismissible = true,
  String? semanticLabel,
}) => RawBottomSheetPage<void>(
  key: const ValueKey('share'),
  barrierDismissible: barrierDismissible,
  semanticLabel: semanticLabel,
  builder: (context, details) => SizedBox(height: 200, child: Text(text)),
);

Widget _navigator(
  List<Page<void>> pages,
  void Function(Page<Object?> page) removed,
) => harness(Navigator(pages: pages, onDidRemovePage: removed));

void main() {
  testWidgets('a barrier tap pops it out of the page list', (tester) async {
    final removed = <Page<Object?>>[];
    final sheet = _sheet('Share');
    await tester.pumpWidget(_navigator([_recipe, sheet], removed.add));
    await tester.pumpAndSettle();
    expect(find.text('Share'), findsOneWidget);
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(removed, [sheet]);
  });

  testWidgets('a new page under the same key repaints the panel', (
    tester,
  ) async {
    await tester.pumpWidget(_navigator([_recipe, _sheet('Share')], (page) {}));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_navigator([_recipe, _sheet('Send')], (page) {}));
    await tester.pump();
    expect(find.text('Send'), findsOneWidget);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('whether the barrier closes it follows the page it holds now', (
    tester,
  ) async {
    final removed = <Page<Object?>>[];
    await tester.pumpWidget(
      _navigator([
        _recipe,
        _sheet('Share', barrierDismissible: false),
      ], removed.add),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(removed, isEmpty);
    expect(find.text('Share'), findsOneWidget);
    final now = _sheet('Share');
    await tester.pumpWidget(_navigator([_recipe, now], removed.add));
    await tester.pump();
    await tester.tapAt(const Offset(400, 40));
    await tester.pumpAndSettle();
    expect(removed, [now]);
  });

  testWidgets('a screen reader hears the label of the page it holds now', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _navigator([_recipe, _sheet('Share', semanticLabel: 'Share')], (page) {}),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Share'), findsWidgets);
    await tester.pumpWidget(
      _navigator([
        _recipe,
        _sheet('Share', semanticLabel: 'Send to'),
      ], (page) {}),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Send to'), findsOneWidget);
    semantics.dispose();
  });
}
