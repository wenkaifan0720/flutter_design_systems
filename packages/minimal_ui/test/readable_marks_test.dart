// What a reader needs to see reads: an upcoming step's number at 4.5:1, the
// marks that are a control's only sign (a tree's chevron, a grip, a clear
// button's cross) at 3:1, a field's glyph at 3:1 where nothing else names
// the field, and a selected row's caption at 4.5:1 on the selection wash,
// in every preset and a brand's colours, by day and by night. A glyph
// beside the words that name it stays quiet on purpose.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shows [part] by day in a phone (or [view]), under a declared [touch]
/// floor (ui_core's own when null), in [theme] (the standard preset).
Future<void> _show(
  WidgetTester tester,
  Widget part, {
  double? touch,
  double width = 342,
  Size view = const Size(390, 900),
  MinimalThemeData? theme,
}) async {
  tester.view
    ..physicalSize = view
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MinimalTheme(
        data: theme ?? MinimalThemeData.standard(),
        child: touch == null
            ? app!
            : RawTapTargetScope(
                targets: RawTapTargets(touch: Size.square(touch)),
                child: app!,
              ),
      ),
      home: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: width, child: part),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

final _themes = <String, MinimalThemeData>{
  for (final b in Brightness.values) ...{
    'standard ${b.name}': MinimalThemeData.standard(b),
    'graphite ${b.name}': MinimalThemeData.graphite(b),
    'ember ${b.name}': MinimalThemeData.ember(b),
    for (final (name, accent) in const [
      ('navy', Color(0xFF1F3A68)),
      ('green', Color(0xFF2E7D32)),
      ('gold', Color(0xFFC9A227)),
      ('purple', Color(0xFF6D28D9)),
      ('pastel', Color(0xFFF4A7B9)),
    ])
      '$name ${b.name}': MinimalThemeData.from(primary: accent, brightness: b),
  },
};

Color _colorOf(WidgetTester tester, IconData icon) => tester
    .widget<MinimalIcon>(
      find.byWidgetPredicate((w) => w is MinimalIcon && w.icon == icon),
    )
    .color!;

/// [ink]'s contrast on the worse of the two grounds a part stands on.
double _onGrounds(Color ink, MinimalThemeData t) => [
  RawPalette.contrastRatio(ink, t.background),
  RawPalette.contrastRatio(ink, t.card),
].reduce((a, b) => a < b ? a : b);

void main() {
  for (final MapEntry(key: name, value: t) in _themes.entries) {
    testWidgets("$name: an upcoming step's number reads at 4.5:1", (
      tester,
    ) async {
      await _show(
        tester,
        const MinimalStepProgress(
          steps: ['Plan', 'Build', 'Ship', 'Review'],
          current: 1,
        ),
        theme: t,
        view: const Size(800, 600),
        width: 700,
      );
      for (final n in ['3', '4']) {
        final ink = tester.widget<Text>(find.text(n)).style!.color!;
        expect(
          RawPalette.contrastRatio(ink, t.background),
          greaterThanOrEqualTo(4.5),
          reason: 'step $n',
        );
      }
    });

    testWidgets("$name: a selected row's caption reads at 4.5:1 on the wash", (
      tester,
    ) async {
      await _show(
        tester,
        const MinimalListTile(
          title: 'Open studio',
          subtitle: 'Nov 20',
          selected: true,
        ),
        theme: t,
      );
      final ink = tester.widget<Text>(find.text('Nov 20')).style!.color!;
      expect(
        RawPalette.contrastRatio(ink, t.selection),
        greaterThanOrEqualTo(4.5),
      );
    });
  }

  for (final b in Brightness.values) {
    final t = MinimalThemeData.standard(b);

    testWidgets("${b.name}: a tree's chevron is a control and reads at 3:1", (
      tester,
    ) async {
      await _show(
        tester,
        MinimalTreeView<String>(
          roots: const ['Projects'],
          childrenOf: (n) => n == 'Projects' ? const ['Atlas'] : const [],
          labelOf: (n) => n,
        ),
        theme: t,
      );
      final chevron = _colorOf(tester, LucideIcons.chevronRight);
      expect(_onGrounds(chevron, t), greaterThanOrEqualTo(3));
    });

    testWidgets('${b.name}: a reorderable row\'s grip reads at 3:1', (
      tester,
    ) async {
      await _show(
        tester,
        MinimalReorderableListView<String>(
          items: const ['Inbox'],
          onReorder: (_, _) {},
          labelOf: (s) => s,
          itemBuilder: (context, item) => Text(item),
        ),
        theme: t,
      );
      final grip = _colorOf(tester, LucideIcons.gripVertical);
      expect(_onGrounds(grip, t), greaterThanOrEqualTo(3));
    });

    testWidgets("${b.name}: a resizable's grip reads at 3:1 on its knob", (
      tester,
    ) async {
      await _show(
        tester,
        const SizedBox(
          height: 200,
          child: MinimalResizable(
            first: SizedBox.expand(),
            second: SizedBox.expand(),
            handle: true,
          ),
        ),
        theme: t,
      );
      final grip = _colorOf(tester, LucideIcons.gripVertical);
      expect(RawPalette.contrastRatio(grip, t.card), greaterThanOrEqualTo(3));
    });

    testWidgets("${b.name}: a clear button's cross reads at 3:1", (
      tester,
    ) async {
      final name = TextEditingController(text: 'Ada');
      final query = TextEditingController(text: 'atlas');
      addTearDown(name.dispose);
      addTearDown(query.dispose);
      await _show(
        tester,
        Column(
          children: [
            MinimalTextField(
              labelText: 'Name',
              clearable: true,
              controller: name,
            ),
            MinimalSearchField(clearable: true, controller: query),
          ],
        ),
        theme: t,
      );
      final crosses = tester.widgetList<MinimalIcon>(
        find.byWidgetPredicate(
          (w) => w is MinimalIcon && w.icon == LucideIcons.circleX,
        ),
      );
      expect(crosses, hasLength(2));
      for (final cross in crosses) {
        expect(_onGrounds(cross.color!, t), greaterThanOrEqualTo(3));
      }
    });

    testWidgets("${b.name}: a field's glyph names it at 3:1 when nothing else "
        'does, and stays quiet beside its label or hint', (tester) async {
      await _show(
        tester,
        const Column(
          children: [
            MinimalTextField(icon: LucideIcons.mail),
            MinimalTextField(icon: LucideIcons.user, labelText: 'Name'),
            MinimalTextField(icon: LucideIcons.phone, hintText: 'Phone'),
          ],
        ),
        theme: t,
      );
      expect(
        _onGrounds(_colorOf(tester, LucideIcons.mail), t),
        greaterThanOrEqualTo(3),
      );
      expect(_colorOf(tester, LucideIcons.user), t.textTertiary);
      expect(_colorOf(tester, LucideIcons.phone), t.textTertiary);
    });
  }
}
