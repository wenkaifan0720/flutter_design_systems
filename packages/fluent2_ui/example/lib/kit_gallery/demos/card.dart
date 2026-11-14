/// Fluent 2's card: its four appearances and three sizes, a preview
/// reaching the edges over its header and footer, the horizontal card
/// with a thumbnail, and the selectable card with its check.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

/// Holds a live value for a specimen: [builder] draws the control with the
/// value and the setter it hands the control.
class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Widget kitCardDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Card',
  sections: [
    kitSection(
      'A file, its preview and acts',
      children: [kitSpecimenCardFile()],
    ),
    kitSection(
      'Appearances',
      children: [
        for (final appearance in Fluent2CardAppearance.values)
          Fluent2Card(
            appearance: appearance,
            onPressed: () {},
            children: [
              Fluent2CardHeader(
                image: const Icon(Fluent2Icons.documentText),
                header: 'Brand guidelines.pdf',
                description: '${kitSay(appearance)} · Mara Okafor · 5m ago',
              ),
            ],
          ),
      ],
    ),
    kitSection(
      'Sizes',
      children: [
        for (final size in Fluent2CardSize.values)
          Fluent2Card(
            size: size,
            children: [
              Fluent2CardHeader(
                image: const Fluent2Avatar(
                  name: 'Kai Tanaka',
                  color: Fluent2AvatarColor.colorful,
                ),
                header: 'Kai Tanaka shared Q3 plan.docx',
                description: '${kitSay(size)} · Planning',
              ),
            ],
          ),
      ],
    ),
    kitSection('Horizontal', children: [kitSpecimenCardHorizontal()]),
    kitSection('Selectable', children: [kitSpecimenCardSelectable()]),
  ],
);

/// A quiet picture for a preview: the brand's tint under one glyph (the
/// gallery ships no photographs).
Widget _picture(IconData glyph) => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return ColoredBox(
      color: t.colors.brandBackground2,
      child: Center(
        child: Icon(glyph, size: 40, color: t.colors.brandForeground2),
      ),
    );
  },
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenCardFile() => Fluent2Card(
  onPressed: () {},
  children: [
    Fluent2CardHeader(
      image: const Fluent2Avatar(
        name: 'Mara Okafor',
        color: Fluent2AvatarColor.colorful,
      ),
      header: 'Mara Okafor mentioned you',
      description: 'Brand guidelines.pdf · 5m ago',
      action: Fluent2IconButton(
        Fluent2Icons.moreHorizontal,
        label: 'More options',
        onPressed: () {},
      ),
    ),
    Fluent2CardPreview(
      aspectRatio: 16 / 9,
      child: _picture(Fluent2Icons.documentText),
    ),
    Fluent2CardFooter(
      children: [
        Fluent2Button('Open', icon: Fluent2Icons.open, onPressed: () {}),
        Fluent2Button('Share', icon: Fluent2Icons.share, onPressed: () {}),
      ],
    ),
  ],
);

Widget kitSpecimenCardHorizontal() => Fluent2Card(
  orientation: Fluent2CardOrientation.horizontal,
  onPressed: () {},
  children: [
    Fluent2CardPreview(width: 64, child: _picture(Fluent2Icons.calendarLtr)),
    const Fluent2CardHeader(
      header: 'Roadmap review',
      description: 'Today 14:00 · Video call · 6 people',
    ),
  ],
);

Widget kitSpecimenCardSelectable() => _Live<Set<int>>(
  const {0},
  (on, set) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Fluent2Spacing.m,
    children: [
      for (final (i, (name, meta)) in _picks.indexed)
        Fluent2Card(
          selected: on.contains(i),
          onSelected: (v) => set(v ? {...on, i} : {...on.where((j) => j != i)}),
          children: [
            Fluent2CardHeader(
              image: Icon(i == 0 ? Fluent2Icons.document : Fluent2Icons.folder),
              header: name,
              description: meta,
            ),
          ],
        ),
    ],
  ),
);

const List<(String, String)> _picks = [
  ('Q3 plan.docx', 'Kai Tanaka · 2h ago'),
  ('Offsite photos', '24 items · Noor Haddad'),
];
