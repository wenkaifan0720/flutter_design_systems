// A field out of use says so in its hint too: the hint fades to the
// disabled ink with the label and the well, so "Not now" in a disabled field
// doesn't read like a live field's placeholder.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets("a disabled field's hint is in the disabled ink, "
        '${brightness.name}', (tester) async {
      late KeycapColors c;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              KeycapHost(brightness: brightness, child: app!),
          home: Builder(
            builder: (context) {
              c = KeycapTheme.of(context).colors;
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    KeycapTextField(label: 'Live', hint: 'Garden'),
                    KeycapTextField(
                      label: 'Disabled',
                      hint: 'Not now',
                      enabled: false,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      Color? inkOf(String text) => tester
          .renderObject<RenderParagraph>(find.text(text))
          .text
          .style
          ?.color;
      expect(inkOf('Not now'), c.inkDisabled);
      expect(inkOf('Garden'), c.inkMuted);
    });
  }
}
