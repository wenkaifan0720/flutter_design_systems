// Fluent 2's controls between their states (ui_core's moving_states.dart):
// each kind held halfway into a press, under a pointer and under the
// keyboard's focus, on a phone and on a desk, and at each moment no shadow,
// glow or focus ring near it is cut flat by a clip.
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import 'moving_states.dart';

/// [child] on a Fluent 2 page in a list, as a screen lays it.
Widget _page(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Fluent2Host(child: page!),
  home: Scaffold(
    body: ListView(
      key: const Key('page'),
      padding: const EdgeInsets.all(16),
      children: [child],
    ),
  ),
);

void main() {
  final controls = <String, (Widget, Type)>{
    'a primary button': (
      Fluent2Button(
        'Save',
        appearance: Fluent2ButtonAppearance.primary,
        onPressed: () {},
      ),
      Fluent2Button,
    ),
    'a subtle button': (
      Fluent2Button(
        'More',
        appearance: Fluent2ButtonAppearance.subtle,
        onPressed: () {},
      ),
      Fluent2Button,
    ),
    'an icon button': (
      Fluent2IconButton(
        Fluent2Icons.share,
        semanticLabel: 'Share',
        onPressed: () {},
      ),
      Fluent2IconButton,
    ),
    'a card': (
      Fluent2Card(
        onPressed: () {},
        children: const [Fluent2CardHeader(header: 'Q3 plan.docx')],
      ),
      Fluent2Card,
    ),
    'a list row': (
      Fluent2ListGroup(
        title: 'Files',
        children: [
          Fluent2ListItem(title: 'Q3 plan.docx', onTap: () {}),
          Fluent2ListItem(title: 'Notes', onTap: () {}),
        ],
      ),
      Fluent2ListItem,
    ),
    'a text field': (
      Fluent2TextField(value: '', semanticLabel: 'Name', onChanged: (_) {}),
      Fluent2TextField,
    ),
    'a switch': (
      Fluent2Switch(value: true, label: 'Away', onChanged: (_) {}),
      Fluent2Switch,
    ),
    'a checkbox': (
      Fluent2Checkbox(value: true, label: 'Notify me', onChanged: (_) {}),
      Fluent2Checkbox,
    ),
    'a tag': (
      Fluent2InteractionTag('Design', selected: true, onPressed: () {}),
      Fluent2InteractionTag,
    ),
    'a select': (
      Fluent2Select<String>(
        semanticLabel: 'Channel',
        value: 'general',
        options: const [Fluent2Option('general', 'General')],
        onChanged: (_) {},
      ),
      Fluent2Select<String>,
    ),
    'a tab': (
      Fluent2TabList(
        tabs: const ['Chat', 'Files'],
        selectedIndex: 0,
        onChanged: (_) {},
      ),
      Fluent2TabList,
    ),
  };

  for (final (where, size) in const [
    ('a phone', Size(390, 844)),
    ('a desk', Size(1280, 800)),
  ]) {
    for (final MapEntry(key: name, value: (control, type))
        in controls.entries) {
      testWidgets('$name on $where keeps its casts whole as it moves', (
        tester,
      ) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_page(control));
        await tester.pumpAndSettle();
        final target = find.byType(type).first;
        Future<void> look(String moment) async {
          final report = await const DesignShadowClipCheck(look: 'Fluent 2')
              .check(
                tester.element(find.byKey(const Key('page'))),
                runAsync: tester.runAsync,
                near: tester.getRect(target),
              );
          expect(report.problems, isEmpty, reason: '$name at $moment');
        }

        await atPressHalfway(tester, target, look);
        await atHover(tester, target, look);
        await atFocus(tester, target, look);
      });
    }
  }
}
