// Clay's toggle buttons stay buttons: a selected ClayIconButton and an on
// filter ClayChip say what Flutter's IconButton(isSelected: true) says, a
// button that is selected, not a switch that is toggled; off, they say not
// selected.
import 'package:material_ui/material_ui.dart'
    show IconButton, Material, MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';

/// The flags a screen reader reads off the one node [label] names (or, with
/// none, the one button).
String _flags(WidgetTester tester, {String? label}) {
  final node = find.semantics
      .byPredicate((node) {
        if (node.isMergedIntoParent) return false;
        final data = node.getSemanticsData();
        return label == null
            ? data.flagsCollection.isButton
            : data.label == label;
      })
      .evaluate()
      .single;
  final f = node.getSemanticsData().flagsCollection;
  return 'button ${f.isButton}, selected ${f.isSelected}, '
      'toggled ${f.isToggled}, checked ${f.isChecked}';
}

Future<String> _iconButtonFlags(WidgetTester tester, bool selected) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Material(
        child: Center(
          child: IconButton(
            isSelected: selected,
            onPressed: () {},
            icon: const SizedBox.square(dimension: 24),
          ),
        ),
      ),
    ),
  );
  return _flags(tester);
}

void main() {
  for (final selected in const [true, false]) {
    testWidgets('a ClayIconButton ${selected ? 'on' : 'off'} reads as '
        "IconButton(isSelected: $selected) does", (tester) async {
      final semantics = tester.ensureSemantics();
      final flutter = await _iconButtonFlags(tester, selected);
      await tester.pumpWidget(
        ClayPreview(
          child: Center(
            child: ClayIconButton(
              onPressed: () {},
              icon: const Icon(IconData(0x41)),
              tooltip: 'Pin',
              selected: selected,
            ),
          ),
        ),
      );
      expect(_flags(tester, label: 'Pin'), flutter);
      expect(flutter, contains('button true'));
      semantics.dispose();
    });

    testWidgets('a filter ClayChip ${selected ? 'on' : 'off'} reads as '
        "IconButton(isSelected: $selected) does", (tester) async {
      final semantics = tester.ensureSemantics();
      final flutter = await _iconButtonFlags(tester, selected);
      await tester.pumpWidget(
        ClayPreview(
          child: Center(
            child: ClayChip(
              label: 'Walks',
              selected: selected,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(_flags(tester, label: 'Walks'), flutter);
      semantics.dispose();
    });
  }
}
