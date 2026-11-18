/// Fields: [TermTextField], its label in the top line and its help or
/// error in the bottom one, and [TermSelect], whose menu is as wide as it;
/// then both on one line, as a config file writes them.
library;

import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'fields',
  sections: [
    kitSection(
      'text',
      children: [
        const TermTextField(
          labelText: 'branch',
          hintText: 'main',
          prompt: '\u{E0A0}',
        ),
        const TermTextField(
          labelText: 'timeout',
          hintText: '30m',
          helperText: 'how long a step may run',
        ),
        const TermTextField(
          labelText: 'webhook',
          errorText: 'starts with https://',
        ),
        const TermTextField(
          labelText: 'token',
          obscureText: true,
          hintText: '••••',
        ),
        const TermTextField(
          labelText: 'region',
          hintText: 'eu-north (fixed)',
          enabled: false,
        ),
        const TermTextField(
          labelText: 'name',
          helperText: 'a short name, made of lower-case letters, digits and dashes, unique in the team',
        ),
      ],
    ),
    kitSection('select', children: [const _Select()]),
    kitSection(
      'on one line',
      children: [
        const TermTextField.inline(labelText: 'name', labelCols: 10),
        const TermTextField.inline(
          labelText: 'timeout',
          labelCols: 10,
          hintText: '30m',
          errorText: 'a number and s, m or h',
        ),
        const _Select(inline: true),
      ],
    ),
  ],
);

class _Select extends StatefulWidget {
  const _Select({this.inline = false});

  final bool inline;

  @override
  State<_Select> createState() => _SelectState();
}

class _SelectState extends State<_Select> {
  String? _env;

  @override
  Widget build(BuildContext context) {
    if (widget.inline) {
      return TermSelect<String>.inline(
        labelText: 'env',
        labelCols: 10,
        hintText: 'choose one',
        value: _env,
        items: const [
          TermSelectItem(value: 'preview', label: 'preview'),
          TermSelectItem(value: 'staging', label: 'staging'),
          TermSelectItem(value: 'production', label: 'production'),
        ],
        onChanged: (v) => setState(() => _env = v),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TermSelect<String>(
          labelText: 'environment',
          hintText: 'choose one',
          value: _env,
          helperText: _env == 'production' ? 'asks y/N before it goes' : null,
          items: const [
            TermSelectItem(
              value: 'preview',
              label: 'preview',
              detail: 'per branch',
            ),
            TermSelectItem(value: 'staging', label: 'staging'),
            TermSelectItem(value: 'production', label: 'production'),
          ],
          onChanged: (v) => setState(() => _env = v),
        ),
        SizedBox(height: context.termGrid.lineHeight),
        const TermSelect<String>(
          labelText: 'region',
          value: 'eu-north',
          items: [TermSelectItem(value: 'eu-north', label: 'eu-north')],
          onChanged: null,
        ),
      ],
    );
  }
}
