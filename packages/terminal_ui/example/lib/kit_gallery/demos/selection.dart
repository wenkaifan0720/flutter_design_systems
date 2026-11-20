/// Choosing: [TermCheckbox] `[x]`, [TermRadio] `(•)` and [TermSwitch]
/// `[ ■]`, each live.
library;

import 'package:material_ui/material_ui.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../kit.dart';

Widget kitSelectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'selection',
  sections: [
    kitSection('live', children: [const _Live()]),
  ],
);

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  bool _failure = true;
  bool _success = false;
  bool? _all;
  String _strategy = 'rolling';
  bool _migrate = true;
  bool _follow = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const TermSectionHeader(title: 'checkboxes'),
      TermCheckbox(
        value: _failure,
        label: 'on failure',
        onChanged: (v) => setState(() => _failure = v!),
      ),
      TermCheckbox(
        value: _success,
        label: 'on success',
        onChanged: (v) => setState(() => _success = v!),
      ),
      TermCheckbox(
        value: _all,
        tristate: true,
        label: 'every event (some)',
        onChanged: (v) => setState(() => _all = v),
      ),
      const TermCheckbox(
        value: true,
        label: 'locked by the admin',
        onChanged: null,
      ),
      const TermCheckbox(
        value: false,
        label: 'accept the terms',
        isError: true,
        onChanged: null,
      ),
      const TermSectionHeader(title: 'radios'),
      // One choice, one Tab stop: the arrows move and choose, past the one
      // turned off.
      DesignRadioGroup<String>(
        options: const ['rolling', 'blue-green', 'canary', 'recreate'],
        value: _strategy,
        isEnabled: (s) => s != 'recreate',
        onChanged: (v) => setState(() => _strategy = v),
        semanticLabel: 'strategy',
        layoutBuilder: (context, radios) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: radios,
        ),
        itemBuilder: (context, s, node, select) => TermRadio<String>(
          value: s,
          groupValue: _strategy,
          focusNode: node,
          label: s == 'recreate' ? 'recreate (not here)' : s,
          onChanged: select == null ? null : (_) => select(),
        ),
      ),
      const TermSectionHeader(title: 'switches'),
      TermSwitch(
        value: _migrate,
        label: 'run migrations first',
        onChanged: (v) => setState(() => _migrate = v),
      ),
      TermSwitch(
        value: _follow,
        label: 'follow the log',
        onChanged: (v) => setState(() => _follow = v),
      ),
      const TermSwitch(
        value: true,
        label: 'audit log (always on)',
        onChanged: null,
      ),
    ],
  );
}
