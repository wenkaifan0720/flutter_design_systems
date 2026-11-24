/// Reference scenes for filled and outlined dropdown anchors in empty,
/// selected, disabled and error states. The menus scenes capture the popup
/// separately.
library;

import 'package:material_ui/material_ui.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../harness/oracle.dart';

/// The select states, by key segment.
enum _State { empty, chosen, error, disabled }

void _none(String _) {}

const List<ExpressiveSelectOption<String>> _options =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption<String>('s', 'Small'),
      ExpressiveSelectOption<String>('m', 'Medium'),
    ];

/// One select, as the oracle's `SelectField` builds it: "Size", "Medium"
/// chosen (but when empty), a supporting line ("Error message" in error).
Widget _select(ExpressiveTextFieldKind style, _State state) {
  final error = state == _State.error;
  return OracleTag(
    'field',
    child: ExpressiveSelect<String>(
      options: _options,
      value: state == _State.empty ? null : 'm',
      onChanged: state == _State.disabled ? null : _none,
      kind: style,
      labelText: 'Size',
      helperText: error ? null : 'Supporting text',
      errorText: error ? 'Error message' : null,
    ),
  );
}

final OracleGroup selectScenes = OracleGroup(
  id: 'select',
  // What a text field needs above it: the host's thin Material theme, the
  // localizations and an overlay.
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<Object>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: ExpressiveHost(
        theme: theme,
        darkTheme: theme,
        brightness: theme.brightness,
        child: Overlay(
          initialEntries: <OverlayEntry>[
            OverlayEntry(builder: (context) => scene),
          ],
        ),
      ),
    );
  },
  scenes: [
    for (final style in ExpressiveTextFieldKind.values)
      for (final state in _State.values)
        OracleScene(
          key: 'select/${style.name}/${state.name}',
          size: const Size(312, 104),
          build: (context) => _select(style, state),
        ),
  ],
);

void main() => runOracleGroup(selectScenes);
