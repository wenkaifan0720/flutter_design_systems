// Menu and field overrides take precedence over theme defaults. An opaque
// acrylic surface also works when backdrop blur is disabled.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/src/fluent2_design/components/input/field_core.dart'
    show Fluent2FieldFrame;

const _green = Color(0xFF00AA00);
const _blue = Color(0xFF0000FF);
const _menuLook = Fluent2Style(fill: WidgetStatePropertyAll<Color?>(_green));

Widget _app(Widget child, {Fluent2ThemeData? theme}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      Fluent2Theme(data: theme ?? Fluent2ThemeData.lapis(), child: page!),
  home: Scaffold(body: Center(child: child)),
);

/// The colours the boxes under [of] are filled with.
Set<Color?> _fills(WidgetTester t, Finder of) => {
  for (final box in t.widgetList<DecoratedBox>(
    find.descendant(of: of, matching: find.byType(DecoratedBox)),
  ))
    switch (box.decoration) {
      final BoxDecoration d => d.color,
      final ShapeDecoration d => d.color,
      _ => null,
    },
};

void main() {
  final themed = Fluent2ThemeData.lapis().copyWith(menuTheme: _menuLook);
  final items = [
    const Fluent2MenuItem<String>('open', 'Open'),
    const Fluent2MenuItem<String>('share', 'Share'),
  ];

  group('the menu theme', () {
    testWidgets('reaches the public menu', (t) async {
      await t.pumpWidget(
        _app(
          Fluent2Menu<String>(items: items, onSelected: (_) {}),
          theme: themed,
        ),
      );
      expect(_fills(t, find.byType(Fluent2Menu<String>)), contains(_green));
    });

    testWidgets("a menu's own style wins over it", (t) async {
      await t.pumpWidget(
        _app(
          Fluent2Menu<String>(
            items: items,
            onSelected: (_) {},
            style: const Fluent2Style(
              fill: WidgetStatePropertyAll<Color?>(_blue),
            ),
          ),
          theme: themed,
        ),
      );
      final fills = _fills(t, find.byType(Fluent2Menu<String>));
      expect(fills, contains(_blue));
      expect(fills, isNot(contains(_green)));
    });

    testWidgets('without it the menu keeps Fluent\'s first layer', (t) async {
      await t.pumpWidget(
        _app(Fluent2Menu<String>(items: items, onSelected: (_) {})),
      );
      expect(
        _fills(t, find.byType(Fluent2Menu<String>)),
        contains(Fluent2ThemeData.lapis().colors.neutralBackground1),
      );
    });

    testWidgets('reaches a neutral popover, not a brand one', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Fluent2Flyout(key: Key('neutral'), child: Text('Shared')),
              Fluent2Flyout(
                key: Key('brand'),
                appearance: Fluent2FlyoutAppearance.brand,
                child: Text('New'),
              ),
            ],
          ),
          theme: themed,
        ),
      );
      expect(_fills(t, find.byKey(const Key('neutral'))), contains(_green));
      expect(
        _fills(t, find.byKey(const Key('brand'))),
        isNot(contains(_green)),
      );
    });

    testWidgets('reaches a popover its trigger opens', (t) async {
      await t.pumpWidget(
        _app(
          Fluent2Popover(
            semanticLabel: 'Sharing',
            trigger: (context, toggle) =>
                Fluent2Button('Share', onPressed: toggle),
            content: const Text('Shared with 4 people'),
          ),
          theme: themed,
        ),
      );
      await t.tap(find.text('Share'));
      await t.pumpAndSettle();
      expect(find.text('Shared with 4 people'), findsOneWidget);
      expect(_fills(t, find.byType(Fluent2Flyout)), contains(_green));
    });
  });

  group('every field kind takes a style', () {
    const look = Fluent2Style(fill: WidgetStatePropertyAll<Color?>(_blue));
    final fields = <String, Widget>{
      'text field': Fluent2TextField(
        semanticLabel: 'Name',
        value: '',
        onChanged: (_) {},
        style: look,
      ),
      'text area': Fluent2TextArea(
        semanticLabel: 'Notes',
        value: '',
        onChanged: (_) {},
        style: look,
      ),
      'search box': Fluent2SearchBox(
        semanticLabel: 'Search',
        value: '',
        onChanged: (_) {},
        style: look,
      ),
      'select': Fluent2Select<String>(
        semanticLabel: 'Size',
        value: 'm',
        options: const [
          Fluent2Option('s', 'Small'),
          Fluent2Option('m', 'Medium'),
        ],
        onChanged: (_) {},
        style: look,
      ),
      'combobox': Fluent2Combobox<String>(
        semanticLabel: 'Owner',
        value: null,
        options: const [Fluent2Option('ana', 'Ana')],
        onChanged: (_) {},
        style: look,
      ),
      'spin button': Fluent2SpinButton(
        semanticLabel: 'Copies',
        value: 1,
        onChanged: (_) {},
        style: look,
      ),
      'date picker': Fluent2DatePicker(
        semanticLabel: 'Due',
        value: DateTime(2026, 3, 10),
        onChanged: (_) {},
        style: look,
      ),
      'tag picker': Fluent2MultiSelect<String>(
        semanticLabel: 'Invite',
        options: const [Fluent2Option('ana', 'Ana')],
        selected: const [],
        onChanged: (_) {},
        style: look,
      ),
    };
    for (final MapEntry(key: kind, value: field) in fields.entries) {
      testWidgets('the $kind hands it to its frame', (t) async {
        await t.pumpWidget(_app(SizedBox(width: 320, child: field)));
        final frames = t.widgetList<Fluent2FieldFrame>(
          find.byType(Fluent2FieldFrame),
        );
        expect(frames, isNotEmpty);
        expect(frames.every((f) => identical(f.style, look)), isTrue);
      });
    }
  });

  group('solid acrylic', () {
    Widget acrylic() => const SizedBox(
      width: 80,
      height: 40,
      child: Fluent2Acrylic(child: SizedBox.expand()),
    );

    testWidgets('by default the acrylic blurs what lies behind', (t) async {
      await t.pumpWidget(_app(acrylic()));
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('solidAcrylic stands the opaque fallback in', (t) async {
      final theme = Fluent2ThemeData.lapis().copyWith(solidAcrylic: true);
      await t.pumpWidget(_app(acrylic(), theme: theme));
      expect(find.byType(BackdropFilter), findsNothing);
      expect(
        t
            .widgetList<ColoredBox>(
              find.descendant(
                of: find.byType(Fluent2Acrylic),
                matching: find.byType(ColoredBox),
              ),
            )
            .map((b) => b.color),
        contains(theme.acrylic.fallback),
      );
    });

    test('is part of the theme, kept by copyWith and lerp', () {
      final plain = Fluent2ThemeData.lapis();
      final solid = plain.copyWith(solidAcrylic: true);
      expect(solid.solidAcrylic, isTrue);
      expect(solid, isNot(plain));
      expect(
        solid.copyWith(density: Fluent2Density.compact).solidAcrylic,
        isTrue,
      );
      expect(plain.lerp(solid, .25).solidAcrylic, isFalse);
      expect(plain.lerp(solid, .75).solidAcrylic, isTrue);
    });
  });
}
