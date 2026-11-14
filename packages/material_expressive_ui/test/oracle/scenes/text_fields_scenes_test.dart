/// The `text-fields` oracle group (Compose twin: `TextFieldsScenes.kt`):
/// filled and outlined fields empty, focused, filled, in error and
/// disabled (CONTRACT §7 "Input"), and Expressive's rounded + tonal form of
/// each, filled.
library;

import 'package:material_ui/material_ui.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../harness/oracle.dart';

/// Compose's field states, by key segment.
enum _State { empty, focused, filled, error, disabled }

/// One field, as the oracle's `Field` builds it: "Label", a supporting line
/// ("Error message" in error), "Input text" when filled. [expressive] is
/// the rounded shape, the tonal colours and the label inside.
class _Field extends StatefulWidget {
  const _Field(this.style, this.state, {this.expressive = false});

  final ExpressiveTextFieldKind style;
  final _State state;
  final bool expressive;

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late final TextEditingController _text = TextEditingController(
    text: switch (widget.state) {
      _State.filled || _State.error || _State.disabled => 'Input text',
      _State.empty || _State.focused => '',
    },
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.state == _State.error;
    return OracleTag(
      'field',
      child: ExpressiveTextField(
        controller: _text,
        kind: widget.style,
        rounded: widget.expressive,
        tonal: widget.expressive,
        labelPosition: widget.expressive
            ? ExpressiveLabelPosition.inside
            : null,
        enabled: widget.state != _State.disabled,
        label: 'Label',
        helperText: error ? null : 'Supporting text',
        errorText: error ? 'Error message' : null,
      ),
    );
  }
}

const Size _crop = Size(312, 104);

final OracleGroup textFieldsScenes = OracleGroup(
  id: 'text-fields',
  // What a text field needs above it: the host's thin Material theme, the
  // localizations and an overlay (the text handles' and edit menu's).
  frame: (context, scene) {
    final theme = context.expressiveTheme;
    return Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<Object>>[
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      child: ExpressiveHost(
        light: theme,
        dark: theme,
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
    for (final style in ExpressiveTextFieldKind.values) ...[
      for (final state in _State.values)
        OracleScene(
          key: 'text-fields/${style.name}/${state.name}',
          size: _crop,
          build: (context) => _Field(style, state),
          interaction: state == _State.focused
              ? const OracleFocus('field')
              : null,
        ),
      OracleScene(
        key: 'text-fields/${style.name}/rounded-tonal',
        size: _crop,
        build: (context) => _Field(style, _State.filled, expressive: true),
      ),
    ],
  ],
);

void main() => runOracleGroup(textFieldsScenes);
