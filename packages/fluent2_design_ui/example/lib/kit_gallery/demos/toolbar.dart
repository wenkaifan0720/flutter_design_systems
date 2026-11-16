/// Fluent 2's toolbar: a file's commands with a divider and toggles,
/// labelled commands, its groups (commands that belong together, toggles
/// of one choice and of any number), its three sizes, the overflow menu
/// when the row runs out, and standing vertical; and the divider in its
/// appearances, with a label at its three alignments and standing
/// vertical.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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

Widget kitToolbarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toolbar and divider',
  sections: [
    kitSection('A file\'s commands', children: [kitSpecimenToolbarFile()]),
    kitSection('Labelled', children: [kitSpecimenToolbarLabelled()]),
    kitSection('A group of commands', children: [kitSpecimenToolbarGroup()]),
    kitSection(
      'One choice of several',
      children: [kitSpecimenToolbarRadioGroup()],
    ),
    kitSection(
      'Toggles of any number',
      children: [kitSpecimenToolbarToggleGroup()],
    ),
    for (final size in Fluent2ToolbarSize.values)
      kitSection(
        'Size ${kitSay(size).toLowerCase()}',
        children: [_toolbar(size: size)],
      ),
    kitSection(
      'Overflowing into More',
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: 200, child: _toolbar(more: true)),
        ),
      ],
    ),
    kitSection(
      'Vertical',
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _toolbar(vertical: true),
        ),
      ],
    ),
    kitSection('Divider appearances', children: [kitSpecimenDividers()]),
    kitSection('Divider labels', children: [kitSpecimenDividerLabels()]),
    kitSection(
      'Vertical divider',
      children: [
        const SizedBox(
          height: 40,
          child: Row(
            spacing: Fluent2Spacing.m,
            children: [
              Text('Files'),
              Fluent2Divider(vertical: true),
              Text('Chat'),
              Fluent2Divider(
                vertical: true,
                appearance: Fluent2DividerAppearance.brand,
              ),
              Text('Calendar'),
            ],
          ),
        ),
      ],
    ),
  ],
);

/// Whether the file is pinned and whether it is a favourite.
typedef _Marks = ({bool pinned, bool starred});

const _Marks _start = (pinned: true, starred: false);

/// A document's commands: New and Upload, a divider, the Pin and
/// Favourite toggles over [marks], then (with [more]) Share, Download and
/// Delete. [labels] shows the commands' words.
List<Fluent2ToolbarItem> _commands(
  _Marks marks,
  ValueChanged<_Marks> set, {
  bool more = false,
  bool labels = false,
}) => [
  Fluent2ToolbarItem.button(
    icon: Fluent2Icons.add,
    label: 'New',
    showLabel: labels,
    onPressed: () {},
  ),
  Fluent2ToolbarItem.button(
    icon: Fluent2Icons.arrowUpload,
    label: 'Upload',
    showLabel: labels,
    onPressed: () {},
  ),
  const Fluent2ToolbarItem.divider(),
  Fluent2ToolbarItem.toggle(
    icon: Fluent2Icons.pin,
    checkedIcon: Fluent2Icons.pinFilled,
    label: 'Pin',
    checked: marks.pinned,
    onChanged: (v) => set((pinned: v, starred: marks.starred)),
  ),
  Fluent2ToolbarItem.toggle(
    icon: Fluent2Icons.star,
    checkedIcon: Fluent2Icons.starFilled,
    label: 'Favourite',
    checked: marks.starred,
    onChanged: (v) => set((pinned: marks.pinned, starred: v)),
  ),
  if (more) ...[
    Fluent2ToolbarItem.button(
      icon: Fluent2Icons.share,
      label: 'Share',
      onPressed: () {},
    ),
    Fluent2ToolbarItem.button(
      icon: Fluent2Icons.arrowDownload,
      label: 'Download',
      onPressed: () {},
    ),
    Fluent2ToolbarItem.button(
      icon: Fluent2Icons.delete,
      label: 'Delete',
      onPressed: () {},
    ),
  ],
];

/// A live toolbar over a document, for the demo's bands.
Widget _toolbar({
  Fluent2ToolbarSize size = Fluent2ToolbarSize.medium,
  bool vertical = false,
  bool more = false,
}) => _Live<_Marks>(
  _start,
  (marks, set) => Fluent2Toolbar(
    size: size,
    vertical: vertical,
    label: 'File commands',
    items: _commands(marks, set, more: more),
  ),
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenToolbarFile() => _Live<_Marks>(
  _start,
  (marks, set) => Fluent2Toolbar(
    label: 'File commands',
    items: _commands(marks, set, more: true),
  ),
);

Widget kitSpecimenToolbarLabelled() => _Live<_Marks>(
  _start,
  (marks, set) => Fluent2Toolbar(
    label: 'File commands',
    items: _commands(marks, set, labels: true),
  ),
);

Widget kitSpecimenToolbarGroup() => Wrap(
  spacing: Fluent2Spacing.m,
  runSpacing: Fluent2Spacing.s,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: [
    Fluent2ToolbarGroup(
      label: 'Share',
      items: [
        Fluent2ToolbarItem.button(
          icon: Fluent2Icons.link,
          label: 'Copy link',
          onPressed: () {},
        ),
        Fluent2ToolbarItem.button(
          icon: Fluent2Icons.mail,
          label: 'Email',
          onPressed: () {},
        ),
        Fluent2ToolbarItem.button(
          icon: Fluent2Icons.chat,
          label: 'Send in chat',
          onPressed: () {},
        ),
      ],
    ),
    Fluent2ToolbarGroup(
      label: 'Arrange',
      items: [
        Fluent2ToolbarItem.button(
          icon: Fluent2Icons.arrowSort,
          label: 'Sort',
          showLabel: true,
          onPressed: () {},
        ),
        Fluent2ToolbarItem.button(
          icon: Fluent2Icons.filter,
          label: 'Filter',
          showLabel: true,
          onPressed: () {},
        ),
      ],
    ),
  ],
);

Widget kitSpecimenToolbarRadioGroup() => _Live<Set<String>>(
  const {'list'},
  (layout, set) => Fluent2ToolbarToggleGroup<String>(
    label: 'Layout',
    toggles: const [
      Fluent2ToolbarToggle('list', icon: Fluent2Icons.list, label: 'List'),
      Fluent2ToolbarToggle('grid', icon: Fluent2Icons.grid, label: 'Tiles'),
      Fluent2ToolbarToggle('board', icon: Fluent2Icons.board, label: 'Board'),
    ],
    selected: layout,
    onSelectionChanged: set,
  ),
);

Widget kitSpecimenToolbarToggleGroup() => _Live<Set<String>>(
  const {'flagged'},
  (shown, set) => Fluent2ToolbarToggleGroup<String>(
    label: 'Show',
    multiSelectionEnabled: true,
    toggles: const [
      Fluent2ToolbarToggle(
        'flagged',
        icon: Fluent2Icons.flag,
        label: 'Flagged',
        showLabel: true,
      ),
      Fluent2ToolbarToggle(
        'mentions',
        icon: Fluent2Icons.mail,
        label: 'Mentions',
        showLabel: true,
      ),
      Fluent2ToolbarToggle(
        'files',
        icon: Fluent2Icons.attach,
        label: 'With files',
        showLabel: true,
      ),
    ],
    selected: shown,
    onSelectionChanged: set,
  ),
);

Widget kitSpecimenDividers() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.l,
  children: [
    for (final appearance in Fluent2DividerAppearance.values)
      Fluent2Divider(label: kitSay(appearance), appearance: appearance),
  ],
);

Widget kitSpecimenDividerLabels() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  spacing: Fluent2Spacing.l,
  children: [
    Fluent2Divider(label: 'Today', align: Fluent2DividerAlign.start),
    Fluent2Divider(label: 'Yesterday'),
    Fluent2Divider(label: 'Last week', align: Fluent2DividerAlign.end),
    Fluent2Divider(inset: true),
  ],
);
