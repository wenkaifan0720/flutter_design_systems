// A row's name: its words, a tag at its end among them, said once (an
// avatar at its start, picturing what the title names, stays out); a row
// without a press of its own is one node with its switch, the title naming
// it, as Flutter's SwitchListTile is.
// A radio group's choice shows what stands after its words (a palette's
// swatches) and is heard by its words alone.
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

SemanticsData _node(WidgetTester t, Finder f) =>
    t.getSemantics(f).getSemanticsData();

Future<void> _show(WidgetTester t, Widget child) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (context, _) => GlossHost(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GlossScreen(body: child),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets("a row's words name it once, its tag among them", (t) async {
    final h = t.ensureSemantics();
    await _show(
      t,
      GlossWell(
        children: [
          GlossListTile(
            leading: const GlossAvatar(name: 'Dune', size: 40),
            title: 'Dune',
            subtitle: 'Frank Herbert',
            trailing: const GlossTag('Reading'),
            onTap: () {},
          ),
        ],
      ),
    );
    expect(
      _node(t, find.byType(GlossListTile)).label,
      'Dune\nFrank Herbert\nReading',
    );
    h.dispose();
  });

  testWidgets("a row's switch is named by the row", (t) async {
    final h = t.ensureSemantics();
    var on = false;
    await _show(
      t,
      StatefulBuilder(
        builder: (context, set) => GlossWell(
          children: [
            GlossListTile(
              title: 'Favourite',
              trailing: GlossSwitch(
                value: on,
                onChanged: (v) => set(() => on = v),
              ),
            ),
          ],
        ),
      ),
    );
    final node = _node(t, find.byType(GlossSwitch));
    expect(node.label, 'Favourite');
    expect(node.flagsCollection.isToggled, Tristate.isFalse);
    expect(node.hasAction(SemanticsAction.tap), isTrue);
    h.dispose();
  });

  testWidgets('a choice shows its swatches, heard by its words', (t) async {
    final h = t.ensureSemantics();
    await _show(
      t,
      GlossRadioGroup<String>(
        options: const ['jade', 'teal'],
        groupValue: 'jade',
        labelOf: (v) => v == 'jade' ? 'Jade' : 'Teal',
        trailingOf: (v) =>
            SizedBox.square(key: ValueKey('swatch-$v'), dimension: 12),
        onChanged: (_) {},
      ),
    );
    expect(find.byKey(const ValueKey('swatch-teal')), findsOneWidget);
    final words = t.getRect(find.text('Teal'));
    final swatch = t.getRect(find.byKey(const ValueKey('swatch-teal')));
    expect(swatch.left, greaterThanOrEqualTo(words.right));
    expect(_node(t, find.text('Teal')).label, 'Teal');
    h.dispose();
  });
}
