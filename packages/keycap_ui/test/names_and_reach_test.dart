// Keycap's names and reach: a select and a date key read their label once; a row's menu at its end keeps a node of its
// own, and on a phone it opens inside the page margin; tags', segments' and keys' glyphs and a person's monogram grow
// with text; the host moves between palettes.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(1440, 900),
  double scale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: KeycapHost(brightness: Brightness.light, child: page!),
      ),
      home: KeycapScreen(body: child),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

List<String> _words(WidgetTester tester) {
  final out = <String>[];
  void visit(SemanticsNode node) {
    final d = node.getSemanticsData();
    out.add([d.label, d.value, d.hint].join(' '));
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

int _count(List<String> words, String word) => words.fold(
  0,
  (n, w) => n + RegExp(RegExp.escape(word)).allMatches(w).length,
);

void main() {
  testWidgets('a select and a date key read their label once', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(
      tester,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeycapSelect<String>(
            labelText: 'Status',
            value: 'reading',
            items: const [KeycapSelectItem(value: 'reading', label: 'Reading')],
            onChanged: (_) {},
          ),
          KeycapDatePicker(
            labelText: 'Started',
            value: DateTime(2026, 1, 4),
            firstDate: DateTime(2000),
            lastDate: DateTime(2030),
            onChanged: (_) {},
          ),
        ],
      ),
    );
    final words = _words(tester);
    expect(_count(words, 'Status'), 1, reason: words.join(' | '));
    expect(_count(words, 'Started'), 1, reason: words.join(' | '));
    semantics.dispose();
  });

  Widget row() => KeycapListTile(
    title: 'Piranesi',
    onTap: () {},
    trailing: KeycapMenu(
      entries: [RawMenuEntry(label: 'Rename', onPressed: () {})],
      builder: (context, anchor) => KeycapIconButton(
        icon: const Icon(LucideIcons.ellipsis),
        semanticLabel: 'More',
        onPressed: anchor.toggle,
      ),
    ),
  );

  testWidgets("a row's menu at its end keeps a node of its own", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, row());
    final words = _words(tester);
    expect(
      words.where((w) => w.contains('More') && !w.contains('Piranesi')),
      hasLength(1),
      reason: words.join(' | '),
    );
    expect(
      words.where((w) => w.contains('Piranesi') && !w.contains('More')),
      hasLength(1),
      reason: words.join(' | '),
    );
    semantics.dispose();
  });

  testWidgets("on a phone a row's menu opens inside the page margin", (
    tester,
  ) async {
    await _pump(tester, row(), size: const Size(390, 844));
    await tester.tap(find.bySemanticsLabel('More'));
    await tester.pumpAndSettle();
    final panel = tester.getRect(find.byType(KeycapMenuPanel));
    expect(panel.right, lessThanOrEqualTo(390 - 16 + 0.5));
    expect(panel.left, greaterThanOrEqualTo(16 - 0.5));
  });

  Future<Map<String, double>> glyphs(WidgetTester tester, double scale) async {
    await _pump(
      tester,
      Column(
        children: [
          const KeycapTag('Draft', icon: LucideIcons.pencil),
          KeycapSegmentedButton<String>(
            segments: const [
              KeycapSegment(
                value: 'a',
                label: 'All',
                icon: Icon(LucideIcons.list),
              ),
              KeycapSegment(
                value: 'b',
                label: 'Read',
                icon: Icon(LucideIcons.bookOpen),
              ),
            ],
            selected: const {'a'},
            onSelectionChanged: (_) {},
          ),
          KeycapButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.plus),
            child: const Text('Add'),
          ),
          const KeycapAvatar(name: 'Rosa Vidal'),
        ],
      ),
      size: const Size(1440, 1400),
      scale: scale,
    );
    return {
      'tag': tester.getSize(find.byIcon(LucideIcons.pencil)).height,
      'segment': tester.getSize(find.byIcon(LucideIcons.list)).height,
      'key': tester.getSize(find.byIcon(LucideIcons.plus)).height,
      'monogram': tester.getSize(find.byType(KeycapAvatar)).height,
    };
  }

  testWidgets(
    "tags', segments' and keys' glyphs and a person's monogram grow with text",
    (tester) async {
      final one = await glyphs(tester, 1);
      final two = await glyphs(tester, 2);
      final three = await glyphs(tester, 3);
      for (final part in one.keys) {
        expect(two[part], closeTo(one[part]! * 2, 0.5), reason: part);
      }
      expect(
        three['monogram'],
        closeTo(one['monogram']! * 2, 0.5),
        reason: 'a monogram grows to 2x',
      );
    },
  );

  testWidgets('the host moves between palettes', (tester) async {
    late KeycapThemeData shown;
    Widget host(String id) => Directionality(
      textDirection: TextDirection.ltr,
      child: KeycapHost(
        palette: KeycapThemeData.palettes.firstWhere((p) => p.id == id),
        brightness: Brightness.light,
        child: Builder(
          builder: (context) {
            shown = KeycapTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpWidget(host('classic'));
    await tester.pump(const Duration(seconds: 2));
    final from = shown.colors.ground;
    await tester.pumpWidget(host('rose'));
    await tester.pump(const Duration(milliseconds: 60));
    final to = KeycapThemeData.preset('rose', Brightness.light).colors.ground;
    expect(shown.colors.ground, isNot(from));
    expect(shown.colors.ground, isNot(to));
    await tester.pump(const Duration(seconds: 3));
    expect(shown.colors.ground, to);
  });
}
