// Languages: a long German label at 200% text wraps or ellipsizes on purpose (no overflow), and Arabic, Hebrew,
// Chinese, Japanese, Hindi and Thai lay out in a field, a button and a list row, right to left where they read so.
// Whether a glyph draws (not a box) is the web build's to show: the test fonts draw every glyph as a square.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

import 'world_checks.dart';

Widget _app(
  List<Widget> parts, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => Directionality(
    textDirection: direction,
    child: FrostedHost(child: page!),
  ),
  home: SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: parts,
    ),
  ),
);

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(390, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void _drop(Object? _) {}

void main() {
  setUp(
    () =>
        TestWidgetsFlutterBinding
            .instance
            .platformDispatcher
            .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        ),
  );
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  const german = 'Datenschutzeinstellungen';
  const long = 'Benachrichtigungseinstellungen für Kontobewegungen';
  testWidgets('long German labels at 200% text lay out without overflow', (
    t,
  ) async {
    _phone(t);
    // ui_core's shared check: nothing overflows or throws at 200% text.
    await expectNoOverflowAtTextScale(
      t,
      _app([
        FrostedButton(long, onPressed: () {}, expand: true),
        FrostedButton(german, icon: FrostedGlyphs.check, onPressed: () {}),
        FrostedListTile(
          title: long,
          meta: german,
          leading: const Icon(FrostedGlyphs.house),
          onPressed: () {},
        ),
        FrostedSwitchRow(
          label: long,
          note: german,
          value: true,
          onChanged: _drop,
        ),
        FrostedCheckRow(label: long, value: false, onChanged: _drop),
        FrostedTextField(label: long, hint: german, onChanged: _drop),
        FrostedSegmentedButton<int>(
          label: german,
          value: 0,
          onChanged: _drop,
          segments: const [
            FrostedButtonSegment(0, 'Kontoauszüge'),
            FrostedButtonSegment(1, 'Überweisungen'),
          ],
        ),
        FrostedTabBar(tabs: const ['Ausgaben', 'Einnahmen'], onChanged: _drop),
      ]),
    );
  });

  const scripts = {
    'Arabic': ('الإعدادات', TextDirection.rtl),
    'Hebrew': ('הגדרות החשבון', TextDirection.rtl),
    'Chinese': ('账户设置', TextDirection.ltr),
    'Japanese': ('アカウント設定', TextDirection.ltr),
    'Hindi': ('खाता सेटिंग्स', TextDirection.ltr),
    'Thai': ('การตั้งค่าบัญชี', TextDirection.ltr),
  };
  for (final MapEntry(key: name, value: (words, direction))
      in scripts.entries) {
    testWidgets('$name in a field, a button and a list row', (t) async {
      _phone(t);
      await t.pumpWidget(
        _app(direction: direction, [
          FrostedTextField(label: words, value: words, onChanged: _drop),
          FrostedButton(words, onPressed: () {}),
          FrostedListTile(title: words, meta: words, onPressed: () {}),
        ]),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.text(words), findsWidgets);
    });
  }
}
