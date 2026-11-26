// A control's field label reads as a text field's label: the same size,
// weight and ink, on and off (a switch's label stood larger and grey).
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final enabled in [true, false]) {
    for (final brightness in Brightness.values) {
      testWidgets('labels match, enabled $enabled, $brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, app) => GlossHost(
              theme: GlossThemeData.light(),
              darkTheme: GlossThemeData.dark(),
              brightness: brightness,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: app!,
              ),
            ),
            home: SingleChildScrollView(
              child: Column(
                children: [
                  GlossTextField(labelText: 'Recipe name', enabled: enabled),
                  GlossFormField(
                    labelText: 'Reminders',
                    enabled: enabled,
                    child: GlossSwitch(
                      value: true,
                      onChanged: enabled ? (_) {} : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        TextStyle style(String words) {
          final p = tester.renderObject<RenderParagraph>(
            find.text(words, findRichText: true).first,
          );
          return p.text.style!;
        }

        final field = style('Recipe name'), control = style('Reminders');
        expect(control.fontSize, field.fontSize);
        expect(control.height, field.height);
        expect(control.fontWeight, field.fontWeight);
        expect(control.color, field.color);
      });
    }
  }
}
