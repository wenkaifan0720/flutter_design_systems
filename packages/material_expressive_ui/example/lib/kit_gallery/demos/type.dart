/// The type group's demo: the 30 styles of the type scale in Roboto Flex,
/// one section per role (display, headline, title, body, label), each size
/// in its baseline and its emphasized form, with its size and line height.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The type group's demo, in [brightness].
Widget kitTypeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Type',
  sections: <Widget>[for (final role in _Role.values) _RoleSection(role)],
  // Live only: a test's fonts have none of these glyphs, a browser's do.
  liveSections: <Widget>[
    for (final role in _Role.values) _RoleSection(role),
    const _ScriptsSection(),
  ],
);

/// Words in six other scripts in a field, buttons and list rows: the
/// bundled faces fall back to the platform's fonts (Noto on the web), and
/// no line clips their tall marks. Type any script into the field.
class _ScriptsSection extends StatelessWidget {
  const _ScriptsSection();

  static const _samples = <(String, String)>[
    ('Arabic', 'مرحبا بالعالم'),
    ('Hebrew', 'שלום עולם'),
    ('Chinese', '你好，世界'),
    ('Japanese', 'こんにちは世界'),
    ('Hindi', 'नमस्ते दुनिया'),
    ('Thai', 'สวัสดีชาวโลก'),
  ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Other scripts',
    children: <Widget>[
      const ExpressiveTextField(label: 'Type in any script'),
      Wrap(
        spacing: ExpressiveSpacing.s8,
        runSpacing: ExpressiveSpacing.s8,
        children: <Widget>[
          for (final (_, words) in _samples)
            ExpressiveFilledButton(words, onPressed: () {}),
        ],
      ),
      for (final (script, words) in _samples)
        ExpressiveListTile(
          title: Text(words),
          subtitle: Text(script),
          onTap: () {},
        ),
    ],
  );
}

enum _Role { display, headline, title, body, label }

/// [role]'s three sizes in [t], large to small: (size, baseline,
/// emphasized).
List<(String, TextStyle, TextStyle)> _sizes(
  ExpressiveTextTheme t,
  _Role role,
) => switch (role) {
  _Role.display => [
    ('Large', t.displayLarge, t.displayLargeEmphasized),
    ('Medium', t.displayMedium, t.displayMediumEmphasized),
    ('Small', t.displaySmall, t.displaySmallEmphasized),
  ],
  _Role.headline => [
    ('Large', t.headlineLarge, t.headlineLargeEmphasized),
    ('Medium', t.headlineMedium, t.headlineMediumEmphasized),
    ('Small', t.headlineSmall, t.headlineSmallEmphasized),
  ],
  _Role.title => [
    ('Large', t.titleLarge, t.titleLargeEmphasized),
    ('Medium', t.titleMedium, t.titleMediumEmphasized),
    ('Small', t.titleSmall, t.titleSmallEmphasized),
  ],
  _Role.body => [
    ('Large', t.bodyLarge, t.bodyLargeEmphasized),
    ('Medium', t.bodyMedium, t.bodyMediumEmphasized),
    ('Small', t.bodySmall, t.bodySmallEmphasized),
  ],
  _Role.label => [
    ('Large', t.labelLarge, t.labelLargeEmphasized),
    ('Medium', t.labelMedium, t.labelMediumEmphasized),
    ('Small', t.labelSmall, t.labelSmallEmphasized),
  ],
};

class _RoleSection extends StatelessWidget {
  const _RoleSection(this.role);

  final _Role role;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final c = theme.colors;
    final name = '${role.name[0].toUpperCase()}${role.name.substring(1)}';
    return kitSection(
      name,
      children: <Widget>[
        for (final (size, baseline, emphasized) in _sizes(theme.type, role))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '$name ${size.toLowerCase()} · ${_metrics(baseline)}',
                style: theme.type.labelSmall.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
              Text('Roboto Flex', style: baseline.copyWith(color: c.onSurface)),
              Text(
                'Emphasized',
                style: emphasized.copyWith(color: c.onSurface),
              ),
            ],
          ),
      ],
    );
  }
}

/// `size/line height` in sp, as the tokens state them.
String _metrics(TextStyle style) {
  final size = style.fontSize!;
  return '${_sp(size)}/${_sp(size * style.height!)}';
}

/// A metric as a label: float noise from `size * height` (51.99999999999999)
/// rounded away, at most two decimals, no trailing zeros.
String _sp(double value) {
  final rounded = (value * 100).round() / 100;
  if (rounded == rounded.roundToDouble()) return '${rounded.round()}';
  return rounded
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
