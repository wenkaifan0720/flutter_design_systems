// A row's control at its end keeps its own node, so a screen reader reaches
// the row's menu apart from the row; the end is bounded (a control at most
// three fifths of the row) so a long control never pushes the title out, yet
// a control takes its own width (a stepper keeps its well); and the rules
// between rows run under the end's column to the well's wall.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _show(WidgetTester t, Widget body, {double width = 390}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 700);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF0E7652),
      builder: (context, _) => GlossTheme(
        data: GlossThemeData.preset('jade', Brightness.light),
        child: Padding(padding: const EdgeInsets.all(16), child: body),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets("a row's menu is its own node, apart from the row", (t) async {
    final handle = t.ensureSemantics();
    var menu = 0, row = 0;
    await _show(
      t,
      GlossWell(
        children: [
          GlossListTile(
            title: 'Dune',
            subtitle: 'Frank Herbert',
            onTap: () => row++,
            trailing: GlossIconButton(
              icon: const Icon(LucideIcons.ellipsis),
              tooltip: 'More',
              onPressed: () => menu++,
            ),
          ),
        ],
      ),
    );
    final more = t.getSemantics(find.byType(GlossIconButton));
    final d = more.getSemanticsData();
    expect('${d.label} ${d.tooltip}', contains('More'));
    expect(d.hasAction(SemanticsAction.tap), isTrue);
    final tile = t.getSemantics(find.byType(GlossListTile));
    expect(tile.id, isNot(more.id));
    expect(tile.label, contains('Dune'));
    expect(tile.label, isNot(contains('More')));
    await t.tap(find.byType(GlossIconButton));
    expect((menu, row), (1, 0));
    handle.dispose();
  });

  testWidgets("a row's end is bounded: a long control leaves the title room", (
    t,
  ) async {
    await _show(
      t,
      const GlossWell(
        children: [
          GlossListTile(
            title: 'Palette',
            trailing: Text(
              'A long chosen value that runs on and on past any row',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    expect(t.takeException(), isNull);
    final row = t.getRect(find.byType(GlossListTile));
    final end = t.getRect(find.textContaining('A long chosen value'));
    expect(end.width, lessThanOrEqualTo(row.width * 0.6 + .5));
    expect(t.getRect(find.text('Palette')).width, greaterThan(40));
  });

  testWidgets("a stepper at a row's end keeps its own width at 390", (t) async {
    Widget stepper() =>
        GlossStepper(value: 2, min: 1, max: 12, onChanged: (_) {});
    await _show(t, Center(child: stepper()));
    final alone = t.getSize(find.byType(GlossStepper)).width;
    await _show(
      t,
      GlossWell(
        children: [
          GlossListTile(
            title: 'Cooking for',
            subtitle: 'Scales every recipe',
            trailing: stepper(),
          ),
        ],
      ),
    );
    expect(t.takeException(), isNull);
    expect(
      t.getSize(find.byType(GlossStepper)).width,
      moreOrLessEquals(alone, epsilon: .5),
    );
  });

  testWidgets('the rule between rows runs under the end column', (t) async {
    await _show(
      t,
      const GlossWell(
        children: [
          GlossListTile(title: 'One', trailingText: '12'),
          GlossListTile(title: 'Two', trailingText: '34'),
        ],
      ),
    );
    final rule = t.getRect(find.byType(GlossEngravedLine));
    final value = t.getRect(find.text('34'));
    expect(rule.right, greaterThanOrEqualTo(value.right));
  });
}
