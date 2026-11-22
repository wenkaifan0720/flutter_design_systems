// A key that can't be pressed no longer stands proud of the metal: its cap,
// its lift and its shadow show at a fraction (StudioFace.presence below 1),
// so it never looks pressable. Every kind of key does it the same way, and a
// lit key with no power is an ordinary disabled key, its graphite and lamp
// gone. The legend keeps its disabled ink.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:studio_ui/studio_ui.dart';

void _none() {}

final _keys = <String, Widget Function(bool enabled)>{
  'key': (on) => StudioButton('Save', onPressed: on ? _none : null),
  'lit key': (on) => StudioButton.lit('Publish', onPressed: on ? _none : null),
  'destructive key': (on) => StudioButton(
    'Delete',
    isDestructiveAction: true,
    onPressed: on ? _none : null,
  ),
  'icon key': (on) => StudioIconButton(
    icon: const Icon(LucideIcons.search),
    tooltip: 'Search',
    onPressed: on ? _none : null,
  ),
  'transport key': (on) => StudioTransportKey(
    icon: const Icon(LucideIcons.play),
    tooltip: 'Play',
    onPressed: on ? _none : null,
  ),
  'floating key': (on) => StudioFloatingKey(
    icon: const Icon(LucideIcons.mic),
    tooltip: 'Record',
    onPressed: on ? _none : null,
  ),
  'checkbox': (on) => StudioCheckbox(
    value: true,
    semanticLabel: 'Explicit',
    onChanged: on ? (_) {} : null,
  ),
  'radio': (on) => StudioRadio<int>(
    value: 1,
    groupValue: 1,
    semanticLabel: 'One',
    onChanged: on ? (_) {} : null,
  ),
};

Future<StudioFace> _face(
  WidgetTester tester,
  Widget key,
  Brightness brightness,
) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, page) => StudioTheme(
        data: brightness == Brightness.dark
            ? StudioThemeData.dark()
            : StudioThemeData.light(),
        child: page!,
      ),
      home: Center(child: key),
    ),
  );
  await tester.pumpAndSettle();
  return tester
      .widget<AnimatedStudioSurface>(find.byType(AnimatedStudioSurface).first)
      .face;
}

void main() {
  for (final brightness in Brightness.values) {
    for (final MapEntry(key: name, value: build) in _keys.entries) {
      testWidgets(
        'by ${brightness.name} a $name that can\'t be pressed shows no lift',
        (tester) async {
          final on = await _face(tester, build(true), brightness);
          final off = await _face(tester, build(false), brightness);
          expect(on.presence, 1);
          expect(off.presence, lessThan(0.5));
          expect(off.depth, on.depth);
        },
      );
    }
    testWidgets(
      'by ${brightness.name} a lit key that can\'t be pressed is an ordinary '
      'disabled key',
      (tester) async {
        final plain = await _face(
          tester,
          const StudioButton('Publish', onPressed: null),
          brightness,
        );
        final lit = await _face(
          tester,
          const StudioButton.lit('Publish', onPressed: null),
          brightness,
        );
        expect(lit, plain);
      },
    );
  }
}
