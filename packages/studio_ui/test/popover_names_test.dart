// A date field's, a range field's and a select's open surface is named for
// what it is for, not by the field's label: the field is heard once, open
// or closed ("Started", not "Started Started"). The calendars' surface says
// Select date in the app's language; a select's leaves its name to the list.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

/// Every label line under the semantics root.
List<String> _labels(WidgetTester tester) {
  final lines = <String>[];
  void walk(SemanticsNode node) {
    final label = node.getSemanticsData().label;
    if (label.isNotEmpty) lines.addAll(label.split('\n'));
    node.visitChildren((child) {
      walk(child);
      return true;
    });
  }

  walk(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return lines;
}

Future<void> _show(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => StudioHost(child: child!),
      home: Center(child: SizedBox(width: 358, child: field)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final fields = <String, (Type, Widget, String?)>{
    'date field': (
      StudioDatePicker,
      StudioDatePicker(
        labelText: 'Started',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        onChanged: (_) {},
      ),
      'Select date',
    ),
    'range field': (
      StudioDateRangePicker,
      StudioDateRangePicker(
        labelText: 'Started',
        value: null,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        onChanged: (_) {},
      ),
      'Select date',
    ),
    'select': (
      StudioSelect<String>,
      StudioSelect<String>(
        labelText: 'Started',
        value: 'hi',
        items: const [
          StudioSelectItem(value: 'hi', label: 'High'),
          StudioSelectItem(value: 'lo', label: 'Low'),
        ],
        onChanged: (_) {},
      ),
      null,
    ),
  };
  for (final MapEntry(key: name, value: (type, field, purpose))
      in fields.entries) {
    testWidgets('a $name is heard once, open or closed', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _show(tester, field);
        expect(_labels(tester).where((l) => l == 'Started'), hasLength(1));

        await tester.tap(find.byType(type));
        await tester.pumpAndSettle();
        final open = _labels(tester);
        expect(
          open.where((l) => l == 'Started'),
          hasLength(1),
          reason: '$open',
        );
        if (purpose != null) expect(open, contains(purpose));
      } finally {
        semantics.dispose();
      }
    });
  }
}
