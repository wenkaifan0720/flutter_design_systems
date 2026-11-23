import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2PopoverSurface;

Future<void> _pump(
  WidgetTester t,
  Widget child, {
  double scale = 1,
  Brightness brightness = Brightness.light,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: ThemeData(platform: TargetPlatform.macOS),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Fluent2Host(brightness: brightness, child: page!),
      ),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: Alignment.topLeft, child: child),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Tab, Space and Enter operate the password visibility button', (
    t,
  ) async {
    final editor = TextEditingController(text: 'One password');
    addTearDown(editor.dispose);
    await _pump(t, Fluent2PasswordField(label: 'Password', controller: editor));
    await t.tap(find.byType(EditableText));
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.space);
    await t.pumpAndSettle();
    expect(
      t.widget<EditableText>(find.byType(EditableText)).obscureText,
      isFalse,
    );
    expect(find.byIcon(Fluent2Icons.eyeOff), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(
      t.widget<EditableText>(find.byType(EditableText)).obscureText,
      isTrue,
    );
    expect(editor.text, 'One password');
  });

  testWidgets('the full month heading and day numbers follow text scaling', (
    t,
  ) async {
    final date = DateTime(2026, 11, 4);
    double? firstHeight;
    for (final scale in [1.0, 2.0]) {
      await _pump(
        t,
        SizedBox(
          width: 260,
          child: Fluent2Calendar(
            value: date,
            today: date,
            showAdjacent: false,
            onChanged: (_) {},
          ),
        ),
        scale: scale,
      );
      final title = t.renderObject<RenderParagraph>(find.text('November 2026'));
      expect(title.didExceedMaxLines, isFalse);
      final day = t.renderObject<RenderParagraph>(find.text('4'));
      final glyph = day
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 1),
          )
          .single;
      final height = glyph.bottom - glyph.top;
      if (firstHeight == null) {
        firstHeight = height;
      } else {
        expect(height, greaterThan(firstHeight * 1.8));
      }
    }
  });

  testWidgets(
    'Escape closes a pointer-opened date picker and restores the field',
    (t) async {
      final trigger = FocusNode();
      addTearDown(trigger.dispose);
      await _pump(
        t,
        Fluent2DatePicker(
          focusNode: trigger,
          value: DateTime(2026, 11, 4),
          label: 'Due date',
          onChanged: (_) {},
        ),
        scale: 2,
      );
      await t.tap(find.byType(Fluent2DatePicker));
      await t.pumpAndSettle();
      expect(find.byType(Fluent2PopoverSurface), findsOneWidget);
      expect(find.byType(Fluent2Calendar), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(Fluent2Calendar), findsNothing);
      expect(trigger.hasFocus, isTrue);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'a chart point shows the full series name and value at twice the text size',
    (t) async {
      await _pump(
        t,
        const Fluent2LineChart(
          labels: ['Mon', 'Tue', 'Wed', 'Thu'],
          series: [
            Fluent2ChartSeries('Balance', [98, 102, 104, 106]),
          ],
        ),
        scale: 2,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.end);
      await t.pumpAndSettle();
      final name = t.renderObject<RenderParagraph>(find.text('Balance'));
      expect(name.didExceedMaxLines, isFalse);
      expect(find.text('106'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'large-text data grid headings and cell values can be read in full',
    (t) async {
      final controller = RawDataTableController<List<String>>(
        rows: const [
          ['Launch plan', 'Ana Ruiz', '21'],
        ],
        columns: [
          RawDataColumn(id: '0', label: 'Name', sortKey: (row) => row[0]),
          RawDataColumn(id: '1', label: 'Owner', sortKey: (row) => row[1]),
          RawDataColumn(
            id: '2',
            label: 'Pages',
            numeric: true,
            sortKey: (row) => row[2],
          ),
        ],
      );
      addTearDown(controller.dispose);
      await _pump(
        t,
        Fluent2DataGrid<List<String>>(
          controller: controller,
          cell: (row, column) => row[int.parse(column.id)],
        ),
        scale: 2,
      );
      for (final label in ['Launch plan', 'Ana Ruiz', 'Pages']) {
        final text = find.text(label);
        await t.ensureVisible(text);
        await t.pumpAndSettle();
        expect(
          t.renderObject<RenderParagraph>(text).didExceedMaxLines,
          isFalse,
          reason: label,
        );
        expect(t.getCenter(text).dx, inInclusiveRange(16, 374));
      }
    },
  );

  testWidgets('a disabled composer explanation wraps and keeps text contrast', (
    t,
  ) async {
    const reason = "You can't reply in this channel";
    for (final brightness in Brightness.values) {
      await _pump(
        t,
        const Fluent2Composer(onSend: null, hintText: reason),
        scale: 2,
        brightness: brightness,
      );
      final field = find.byType(TextField);
      final ink = t
          .widget<TextField>(field)
          .decoration!
          .hintStyle!
          .color!
          .computeLuminance();
      final ground = t
          .element(field)
          .fluent2Theme
          .background
          .computeLuminance();
      final ratio = ink > ground
          ? (ink + .05) / (ground + .05)
          : (ground + .05) / (ink + .05);
      expect(ratio, greaterThanOrEqualTo(4.5));
      expect(
        t.renderObject<RenderParagraph>(find.text(reason)).didExceedMaxLines,
        isFalse,
      );
    }
  });
}
