// At a large text size a row's words come first: its subtitle runs on to as
// many lines as it needs, as its title does, rather than being cut after two
// (a settings page's About line lost its end at 200%). At the regular size it
// keeps to two lines, and a one-word subtitle (a path) keeps to one.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

const _about =
    'A shared task list and timesheet for Fieldwork Studio, kept in step '
    'on every device the team signs in on.';

Future<RenderParagraph> _subtitle(
  WidgetTester t, {
  required double scale,
  String subtitle = _about,
}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(390, 844);
  addTearDown(t.view.reset);
  final theme = Fluent2ThemeData.lapis(Brightness.light);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, route) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Fluent2Theme(data: theme, child: route!),
      ),
      home: ColoredBox(
        color: theme.background,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Fluent2ListGroup(
            children: [
              Fluent2ListItem(
                icon: Fluent2Icons.info,
                title: 'Stint',
                subtitle: subtitle,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
  return t.renderObject<RenderParagraph>(find.text(subtitle));
}

void main() {
  testWidgets('at 200% a long subtitle shows every word', (t) async {
    final words = await _subtitle(t, scale: 2);
    expect(words.didExceedMaxLines, isFalse);
    // Every word is laid out: more lines than two, none cut.
    final line = words.text.style!.fontSize! * 2;
    expect(words.size.height, greaterThan(line * 2.5));
  });

  testWidgets('at 100% a long subtitle keeps to two lines', (t) async {
    final words = await _subtitle(t, scale: 1);
    expect(words.maxLines, 2);
  });

  testWidgets('a one-word subtitle keeps to one line at 200%', (t) async {
    final words = await _subtitle(
      t,
      scale: 2,
      subtitle: 'fieldwork-studio/shared/timesheets/2026',
    );
    expect(words.maxLines, 1);
  });
}
