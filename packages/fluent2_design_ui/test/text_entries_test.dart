// ui_core's text entry check: every
// one-line entry the look draws (a field, a search, a password) holds the
// typed text's capitals on its box's middle (DesignCapCenter round the bare
// TextField, internal/cap_label.dart), its hint on the typed text's
// baseline, and nothing in its editable's decoration but the hint, under
// each density and under a host theme that pads and sizes decorations
// unevenly, as each platform.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/alignment.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

DesignAlignmentTheme _under(Fluent2Density density, {ThemeData? host}) =>
    (context, child) {
      final theme = Fluent2ThemeData.preset(
        'lapis',
        Brightness.light,
      ).copyWith(density: density);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: host,
        builder: (context, route) => Fluent2Host(
          light: theme,
          darkData: theme,
          brightness: Brightness.light,
          child: route!,
        ),
        home: Material(
          type: MaterialType.transparency,
          child: Center(child: child),
        ),
      );
    };

void _drop(Object? _) {}

/// The two registers: an entry stands the 48 target under a finger and
/// Fluent's own height with a pointer, so each is held
/// across its own platforms.
const _registers = {
  'under a finger': [TargetPlatform.android, TargetPlatform.iOS],
  'with a pointer': [
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
  ],
};

void main() {
  for (final MapEntry(key: register, value: platforms) in _registers.entries) {
    testWidgets('every one-line entry holds its capitals on its middle, '
        '$register', (t) async {
      final report = await DesignTextEntryCheck(
        look: 'Fluent 2',
        themes: {
          'standard': _under(Fluent2Density.standard),
          'comfortable': _under(Fluent2Density.comfortable),
          'compact': _under(Fluent2Density.compact),
          // A host theme that pads a decoration unevenly and gives it a
          // minimum height: the bare editable must leave neither to it.
          'uneven host': _under(
            Fluent2Density.standard,
            host: ThemeData(
              inputDecorationTheme: const InputDecorationTheme(
                contentPadding: EdgeInsets.fromLTRB(4, 20, 4, 2),
                constraints: BoxConstraints(minHeight: 80),
              ),
            ),
          ),
        },
        entries: {
          for (final size in Fluent2InputSize.values) ...{
            'text field, ${size.name}': (context, controller, hint) =>
                Fluent2TextField(
                  controller: controller,
                  hint: hint,
                  size: size,
                  onChanged: _drop,
                ),
          },
          'search': (context, controller, hint) =>
              Fluent2SearchBox(controller: controller, hint: hint),
          'password': (context, controller, hint) => Fluent2PasswordField(
            controller: controller,
            hint: hint,
            onChanged: _drop,
          ),
        },
      ).check(pump: t.pumpWidget, platforms: platforms);
      report.verify();
    });
  }
}
