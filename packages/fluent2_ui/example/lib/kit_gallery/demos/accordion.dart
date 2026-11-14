/// Fluent 2's accordion: one panel open at a time or several, its four
/// sizes, the chevron at the end, glyphs on the headers, a disabled item and
/// accordions of one section each; and the tree, a team's folders opening
/// level by level with the current file selected.
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

Widget kitAccordionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Accordion and tree',
  sections: [
    kitSection('A meeting\'s details', children: [kitSpecimenAccordion()]),
    kitSection('Several open', children: [kitSpecimenAccordionMultiple()]),
    kitSection('One section each', children: [kitSpecimenDisclosure()]),
    for (final size in Fluent2AccordionSize.values)
      kitSection(
        'Size ${kitSay(size).toLowerCase()}',
        children: [Fluent2Accordion(size: size, items: _items())],
      ),
    kitSection('Tree', children: [kitSpecimenTree()]),
    kitSection(
      'Tree, small',
      children: [
        Fluent2Tree<String>(
          size: Fluent2TreeSize.small,
          label: 'Folders',
          items: _folders,
        ),
      ],
    ),
  ],
);

List<Fluent2AccordionItem> _items({bool glyphs = false}) => [
  Fluent2AccordionItem(
    value: 'agenda',
    title: 'Agenda',
    icon: glyphs ? Fluent2Icons.textBulletListLtr : null,
    child: const _Words('Roadmap review, then questions from the team.'),
  ),
  Fluent2AccordionItem(
    value: 'people',
    title: 'Attendees',
    icon: glyphs ? Fluent2Icons.people : null,
    child: const _Words(
      'Ines Duarte, Kai Tanaka, Mara Okafor, Tomas Lindqvist.',
    ),
  ),
  Fluent2AccordionItem(
    value: 'notes',
    title: 'Notes',
    icon: glyphs ? Fluent2Icons.note : null,
    enabled: false,
    child: const _Words('Shared after the call.'),
  ),
];

/// A panel's body: a paragraph in the second ink.
class _Words extends StatelessWidget {
  const _Words(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Text(text, style: t.body1.c(t.textSecondary));
  }
}

const List<Fluent2TreeItem<String>> _folders = [
  Fluent2TreeItem(
    'design',
    'Design',
    icon: Fluent2Icons.folder,
    openIcon: Fluent2Icons.folderFilled,
    children: [
      Fluent2TreeItem(
        'brand',
        'Brand guidelines.pdf',
        icon: Fluent2Icons.documentText,
      ),
      Fluent2TreeItem(
        'logos',
        'Logos',
        icon: Fluent2Icons.folder,
        openIcon: Fluent2Icons.folderFilled,
        children: [
          Fluent2TreeItem('mark', 'Mark.svg', icon: Fluent2Icons.image),
        ],
      ),
    ],
  ),
  Fluent2TreeItem(
    'planning',
    'Planning',
    icon: Fluent2Icons.folder,
    openIcon: Fluent2Icons.folderFilled,
    aside: '3',
    children: [
      Fluent2TreeItem('q3', 'Q3 plan.docx', icon: Fluent2Icons.document),
    ],
  ),
  Fluent2TreeItem('photos', 'Offsite photos', icon: Fluent2Icons.imageMultiple),
];

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenAccordion() => Fluent2Accordion(
  items: _items(glyphs: true),
  initiallyExpanded: const {'agenda'},
);

Widget kitSpecimenAccordionMultiple() => Fluent2Accordion(
  multiple: true,
  expandIconPosition: Fluent2ExpandIconPosition.end,
  items: _items(),
  initiallyExpanded: const {'agenda', 'people'},
);

Widget kitSpecimenTree() => _Live<String>(
  'brand',
  (value, set) => Fluent2Tree<String>(
    label: 'Northwind files',
    items: _folders,
    value: value,
    initiallyExpanded: const {'design'},
    onChanged: set,
  ),
);

/// One section that opens in place: Fluent's Accordion with a single item
/// each, collapsible.
Widget kitSpecimenDisclosure() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    Widget one(
      String title, {
      IconData? icon,
      String? words,
      bool open = false,
      bool enabled = true,
    }) => Fluent2Accordion(
      items: [
        Fluent2AccordionItem(
          value: title,
          title: title,
          icon: icon,
          enabled: enabled,
          child: words == null
              ? const SizedBox.shrink()
              : Text(words, style: t.body1.c(t.textSecondary)),
        ),
      ],
      collapsible: true,
      initiallyExpanded: {if (open) title},
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        one(
          'Sharing',
          icon: Fluent2Icons.share,
          words: 'Anyone at Northwind with the link can view.',
          open: true,
        ),
        one(
          'Retention',
          icon: Fluent2Icons.archive,
          words: 'Kept for seven years, then deleted.',
        ),
        one('Audit log', enabled: false),
      ],
    );
  },
);
