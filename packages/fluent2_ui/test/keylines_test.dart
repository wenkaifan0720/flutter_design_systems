// Keylines (design6 P): an ordinary screen's sections, cards and rows start on one line and end on another, read by
// ui_core's keyline check over the look's own regions (the screen's content, a form section, a list section, a list's
// card, a card) at a phone's 390 and a desktop's 1440, in both directions. A checkbox's, radio's or switch's room round
// its indicator hangs outside the keyline (the indicator's ink stands on it) and still answers a tap.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:fluent2_ui/fluent2_ui.dart';
import 'package:fluent2_ui/fluent2_host.dart';

void _none() {}

/// Settings as an app has it: a form section of a field and its choices, a
/// list section of rows, and a card.
class _Settings extends StatelessWidget {
  const _Settings();

  @override
  Widget build(BuildContext context) => Fluent2Scaffold(
    topBar: const Fluent2AppBar(title: 'Settings'),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Fluent2Spacing.xxl,
      children: [
        Fluent2FormSection(
          title: 'Notifications',
          description: 'How Northwind reaches you.',
          footnote: 'You can change these at any time.',
          children: [
            Fluent2FormField(
              label: 'Email',
              child: Fluent2TextField(
                value: 'kai@northwind.example',
                onChanged: (_) {},
              ),
            ),
            Fluent2Checkbox(
              value: true,
              onChanged: (_) {},
              label: 'Email me a digest',
            ),
            Fluent2Checkbox(
              value: false,
              onChanged: (_) {},
              label: 'Mentions only',
              labelPosition: Fluent2LabelPosition.before,
            ),
            Fluent2Switch(
              value: true,
              onChanged: (_) {},
              label: 'Push notifications',
            ),
            Fluent2Switch(
              value: false,
              onChanged: (_) {},
              label: 'Sounds',
              labelPosition: Fluent2LabelPosition.above,
            ),
            Fluent2RadioGroup<String>(
              label: 'Digest',
              options: const [
                Fluent2Radio('daily', 'Daily'),
                Fluent2Radio('weekly', 'Weekly'),
              ],
              value: 'weekly',
              onChanged: (_) {},
            ),
          ],
        ),
        const Fluent2ListSection(
          title: 'Account',
          rows: [
            Fluent2ListItem(
              icon: Fluent2Icons.person,
              title: 'Profile',
              chevron: true,
              onTap: _none,
            ),
            Fluent2ListItem(
              icon: Fluent2Icons.lockClosed,
              title: 'Sign-in and security',
              value: 'On',
              chevron: true,
              onTap: _none,
            ),
            Fluent2ListItem(
              icon: Fluent2Icons.signOut,
              title: 'Sign out',
              onTap: _none,
            ),
          ],
        ),
        const Fluent2Card(
          children: [
            Fluent2CardHeader(
              header: 'Storage',
              description: '62 GB of 100 GB used',
            ),
            Text('Files you share count against the owner\'s storage.'),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Fluent2Button('Manage', onPressed: _none),
            ),
          ],
        ),
      ],
    ),
  );
}

Future<void> _pump(
  WidgetTester t,
  Widget page,
  Size size,
  TextDirection direction,
) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) => Directionality(
        textDirection: direction,
        child: Fluent2Host(brightness: Brightness.light, child: child!),
      ),
      home: page,
    ),
  );
  await t.pumpAndSettle();
}

Finder _named(String type) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == type);

void main() {
  for (final direction in TextDirection.values) {
    final rtl = direction == TextDirection.rtl;
    double edge(Rect r) => rtl ? r.right : r.left;

    for (final size in const [Size(390, 1500), Size(1440, 1200)]) {
      testWidgets(
        '${direction.name}, ${size.width.round()} wide: Settings holds its keylines',
        (t) async {
          await _pump(t, const _Settings(), size, direction);
          final report = await const DesignKeylineCheck(look: 'Fluent 2')
              .check(t.element(find.byType(_Settings)), runAsync: t.runAsync);
          report.verify();
        },
        // ui_core's check reads drawn pixels (the rasterizer's, as a
        // golden's): run where the goldens run.
        tags: const ['goldens'],
      );
    }

    // The look's own measure, beside ui_core's check:
    // the form's head, its field, every choice control's indicator and the
    // list section and the card stand on one leading keyline.
    testWidgets(
      '${direction.name}, 390 wide: the screen\'s parts start on one keyline',
      (t) async {
        await _pump(t, const _Settings(), const Size(390, 1500), direction);
        final line = edge(t.getRect(find.text('Notifications')));
        final radio = find
            .descendant(
              of: find.byType(Fluent2Radio<String>).first,
              matching: find.byType(Container),
            )
            .first;
        final parts = <String, Finder>{
          'the field\'s label': find.text('Email'),
          'the field': find.byType(Fluent2TextField),
          'a checkbox': _named('_Indicator').first,
          'a label before its checkbox': find.text('Mentions only'),
          'a switch': _named('_Track').first,
          'a label above its switch': find.text('Sounds'),
          'a radio': radio,
          'the list\'s head': find.text('Account'),
          'the list\'s card': find.byType(Fluent2ListGroup),
          'the card': find.byType(Fluent2Card),
        };
        for (final MapEntry(key: name, value: part) in parts.entries) {
          expect(edge(t.getRect(part)), closeTo(line, 0.5), reason: name);
        }
      },
    );

    testWidgets(
      '${direction.name}: a choice control\'s room outside the keyline still answers a tap',
      (t) async {
        var taps = 0;
        await _pump(
          t,
          Fluent2Scaffold(
            body: Fluent2FormSection(
              title: 'Notifications',
              children: [
                Fluent2Checkbox(
                  value: false,
                  onChanged: (_) => taps++,
                  label: 'Email me a digest',
                ),
              ],
            ),
          ),
          const Size(390, 600),
          direction,
        );
        final box = t.getRect(_named('_Indicator'));
        final line = t.getRect(find.text('Notifications'));
        // The indicator's ink stands on the title's keyline; its room hangs past it.
        expect(edge(box), closeTo(edge(line), 0.5));
        await t.tapAt(box.center);
        await t.tapAt(t.getCenter(find.text('Email me a digest')));
        expect(taps, 2);
      },
    );
  }
}
