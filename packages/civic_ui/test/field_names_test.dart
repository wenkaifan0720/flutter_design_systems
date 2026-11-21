// A field's question is read once, and each control in it says its own
// name: the time input's hour, minute and AM or PM; a date's month, day and
// year; a range's From and To under the one question; a number field's
// stepper with its value and its next ones. On every gallery page, left to
// right and right to left (in Arabic), no field's question is read twice.
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'screens_matrix.dart';

/// Every node shown under [root] (merged nodes as their parent says them).
List<SemanticsData> _nodes(SemanticsNode root) {
  final out = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (node.isMergedIntoParent) return;
    out.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return out;
}

/// How many nodes under [root] say [words], alone or before a comma.
int _heard(SemanticsNode root, String words) => [
  for (final node in _nodes(root))
    for (final line in node.label.split('\n'))
      if (line.trim() == words || line.trim().startsWith('$words,')) line,
].length;

/// The root of the semantics tree [tester] shows.
SemanticsNode _root(WidgetTester tester) {
  var node = tester.getSemantics(find.byType(Directionality).first);
  while (node.parent != null) {
    node = node.parent!;
  }
  return node;
}

SemanticsData _named(SemanticsNode root, String label) =>
    _nodes(root).singleWhere((n) => n.label == label);

void main() {
  setUpAll(loadScreenFonts);

  testWidgets('each control names itself and the question is read once', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1440, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      kitApp(
        brightness: Brightness.light,
        direction: TextDirection.ltr,
        home: ListView(
          padding: const EdgeInsets.all(CivicSpacing.s20),
          children: [
            CivicNumberField(
              labelText: 'Estimate (hours)',
              value: 3,
              onChanged: (_) {},
            ),
            CivicTimeInput(
              labelText: 'Start time',
              value: const RawTimeOfDay(hour: 9, minute: 30),
              onChanged: (_) {},
            ),
            CivicDatePicker(
              labelText: 'Permit start',
              value: DateTime(2026, 11, 24),
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              onChanged: (_) {},
            ),
            CivicDateRangePicker(
              labelText: 'Visitor stay',
              value: null,
              firstDate: DateTime(2026),
              lastDate: DateTime(2026, 12, 31),
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = _root(tester);

    for (final question in [
      'Estimate (hours)',
      'Start time',
      'Permit start',
      'Visitor stay',
    ]) {
      expect(_heard(root, question), 1, reason: '"$question" read');
    }

    // The number field's stepper: the value and the next ones, stepping.
    final stepper = _named(root, 'Estimate (hours)');
    expect(stepper.value, '3');
    expect(stepper.increasedValue, '4');
    expect(stepper.hasAction(SemanticsAction.increase), isTrue);
    expect(stepper.hasAction(SemanticsAction.decrease), isTrue);

    // The time: its parts named as such, under the question with the time.
    // Its words as the locale writes them (a narrow space before AM).
    expect(
      _named(root, 'Start time').value.replaceAll('\u202f', ' '),
      '9:30 AM',
    );
    for (final (part, value) in [('Hour', '9'), ('Minute', '30')]) {
      final node = _nodes(root)
          .singleWhere((n) => n.label == part && n.value == value);
      expect(node.hasAction(SemanticsAction.increase), isTrue);
    }
    expect(_heard(root, 'AM/PM'), 1);

    // A date's parts; a range's two ends by their own names.
    expect(_heard(root, 'Month'), 3);
    expect(_heard(root, 'Day'), 3);
    expect(_heard(root, 'Year'), 3);
    expect(_named(root, 'From').label, 'From');
    expect(_named(root, 'To').label, 'To');
    semantics.dispose();
  });

  for (final page in galleryPages) {
    for (final direction in TextDirection.values) {
      testWidgets('${page.id}: no question read twice, ${direction.name}', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await showScreen(
          tester,
          Directionality(
            textDirection: direction,
            child: page.build(Brightness.light),
          ),
          width: 1440,
          height: 6000,
        );
        final root = _root(tester);
        final fields = find.byType(RawInputDecorator, skipOffstage: false);
        for (final field in fields.evaluate()) {
          final question = (field.widget as RawInputDecorator).labelText
              ?.trim();
          if (question == null || question.isEmpty) continue;
          // The nodes over this field's box.
          final box = field.renderObject! as RenderBox;
          final area = (box.localToGlobal(Offset.zero) & box.size).inflate(1);
          var heard = 0;
          void visit(SemanticsNode node, Matrix4 transform) {
            final at = node.transform == null
                ? transform
                : (transform.clone()..multiply(node.transform!));
            // A search field's button may say the word its question does:
            // that names the button, not the field.
            final data = node.getSemanticsData();
            if (!node.isMergedIntoParent && !data.flagsCollection.isButton) {
              final rect = MatrixUtils.transformRect(at, node.rect);
              if (area.contains(rect.center)) {
                for (final line in data.label.split('\n')) {
                  final l = line.trim();
                  if (l == question || l.startsWith('$question,')) heard++;
                }
              }
            }
            node.visitChildren((child) {
              visit(child, at);
              return true;
            });
          }

          visit(root, Matrix4.identity());
          expect(
            heard,
            lessThanOrEqualTo(1),
            reason: '${page.id}: "$question" read $heard times',
          );
        }
        semantics.dispose();
      });
    }
  }
}
