/// A field's `hint` widget, as `InputDecoration.hint`: drawn where
/// [ExpressiveTextField.hintText] is, in its style, while the field is empty
/// and its label minimized.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

final ExpressiveThemeData _theme = ExpressiveThemeData.preset(
  'baseline',
  Brightness.light,
);

Future<void> _pump(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xff000000),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      builder: (context, child) => ExpressiveHost(
        theme: _theme,
        brightness: Brightness.light,
        child: child!,
      ),
      home: Center(child: SizedBox(width: 320, child: field)),
    ),
  );
  await tester.showKeyboard(find.byType(EditableText));
  await tester.pumpAndSettle();
}

TextStyle? _drawn(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  return paragraph.text.style;
}

void main() {
  setUpAll(expressiveLoadFonts);

  testWidgets('a hint widget is drawn in the hint text\'s style', (
    tester,
  ) async {
    await _pump(
      tester,
      const ExpressiveTextField(
        labelText: 'Email',
        hintText: 'name@example.com',
      ),
    );
    final asText = _drawn(tester, 'name@example.com');
    await _pump(
      tester,
      const ExpressiveTextField(
        key: ValueKey('widget'),
        labelText: 'Email',
        hint: Text('name@example.com'),
      ),
    );
    final asWidget = tester
        .renderObject<RenderParagraph>(find.text('name@example.com'))
        .text
        .style;
    expect(asWidget?.color, asText?.color);
    expect(asWidget?.fontSize, asText?.fontSize);
  });

  testWidgets('a hint widget is read only as its own semantics say', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const ExpressiveTextField(
        labelText: 'Email',
        hint: ExcludeSemantics(child: Text('name@example.com')),
      ),
    );
    expect(find.text('name@example.com'), findsOneWidget);
    expect(tester.getSemantics(find.byType(EditableText)).label, 'Email');
    handle.dispose();
  });

  testWidgets('the hint goes once the field holds text', (tester) async {
    final text = TextEditingController();
    addTearDown(text.dispose);
    await _pump(
      tester,
      ExpressiveTextField(
        controller: text,
        labelText: 'Email',
        hint: const Text('name@example.com'),
      ),
    );
    expect(find.text('name@example.com'), findsOneWidget);
    await tester.enterText(find.byType(EditableText), 'ada@example.com');
    await tester.pumpAndSettle();
    expect(find.text('name@example.com'), findsNothing);
  });

  testWidgets('a text area takes a hint widget too', (tester) async {
    await _pump(
      tester,
      const ExpressiveTextArea(
        labelText: 'Notes',
        hint: Text('Anything we should know'),
      ),
    );
    expect(find.text('Anything we should know'), findsOneWidget);
  });
}
