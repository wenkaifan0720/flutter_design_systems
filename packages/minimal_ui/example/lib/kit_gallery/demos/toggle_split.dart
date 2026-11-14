/// Toggle groups (one on, several on, glyphs only, quiet) and split
/// buttons in each variant, live.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitToggleSplitDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Toggle group & split button',
  sections: [
    kitSection(
      'One on',
      children: [
        const _View(),
        kitNote('Arrow keys move along the group; Space turns one on.'),
      ],
    ),
    kitSection('Several on', children: const [_Marks()]),
    kitSection(
      'Quiet',
      children: [
        _Static(
          (value, set) => MinimalToggleGroup<String>(
            label: 'Density',
            outlined: false,
            small: true,
            selected: {value},
            onChanged: (s) => set(s.single),
            items: const [
              MinimalToggleItem('compact', label: 'Compact'),
              MinimalToggleItem('comfortable', label: 'Comfortable'),
              MinimalToggleItem('spacious', label: 'Spacious', enabled: false),
            ],
          ),
          initial: 'compact',
        ),
        kitNote('Spacious is disabled: an option not on offer stays, dimmed.'),
      ],
    ),
    kitSection(
      'Split button',
      children: [
        Builder(
          builder: (context) => kitRow([
            MinimalSplitButton(
              'Publish',
              icon: LucideIcons.sendDir,
              onPressed: () => showMinimalSnackBar(context, 'Published'),
              actions: _publish(context),
            ),
            MinimalSplitButton(
              'Export',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => showMinimalSnackBar(context, 'Exported'),
              actions: _publish(context),
            ),
            MinimalSplitButton(
              'Save',
              variant: MinimalButtonVariant.ghost,
              size: MinimalButtonSize.small,
              onPressed: () {},
              actions: _publish(context),
            ),
          ]),
        ),
        kitNote(
          'The chevron opens the other ways to do it; Down opens it from the '
          'keyboard.',
        ),
      ],
    ),
  ],
);

List<MinimalMenuItem> _publish(BuildContext context) => [
  MinimalMenuItem(
    'Schedule…',
    icon: LucideIcons.calendarClock,
    onPressed: () => showMinimalSnackBar(context, 'Scheduled'),
  ),
  MinimalMenuItem(
    'Save as draft',
    icon: LucideIcons.fileText,
    shortcut: '⌘ S',
    onPressed: () => showMinimalSnackBar(context, 'Saved'),
  ),
  MinimalMenuItem(
    'Discard',
    icon: LucideIcons.trash2,
    destructive: true,
    startsGroup: true,
    onPressed: () {},
  ),
];

const List<MinimalToggleItem<String>> _views = [
  MinimalToggleItem('list', label: 'List', icon: LucideIcons.list),
  MinimalToggleItem('board', label: 'Board', icon: LucideIcons.columns3),
  MinimalToggleItem('calendar', label: 'Calendar', icon: LucideIcons.calendar),
];

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  String _view = 'board';

  @override
  Widget build(BuildContext context) => MinimalToggleGroup<String>(
    label: 'View',
    selected: {_view},
    onChanged: (s) => setState(() => _view = s.single),
    items: _views,
  );
}

class _Marks extends StatefulWidget {
  const _Marks();

  @override
  State<_Marks> createState() => _MarksState();
}

class _MarksState extends State<_Marks> {
  Set<String> _on = {'bold', 'underline'};

  @override
  Widget build(BuildContext context) => MinimalToggleGroup<String>(
    label: 'Text style',
    multiple: true,
    allowEmpty: true,
    selected: _on,
    onChanged: (s) => setState(() => _on = s),
    items: const [
      MinimalToggleItem('bold', icon: LucideIcons.bold, semanticLabel: 'Bold'),
      MinimalToggleItem(
        'italic',
        icon: LucideIcons.italic,
        semanticLabel: 'Italic',
      ),
      MinimalToggleItem(
        'underline',
        icon: LucideIcons.underline,
        semanticLabel: 'Underline',
      ),
    ],
  );
}

class _Static<T> extends StatefulWidget {
  const _Static(this.builder, {required this.initial});

  final Widget Function(T value, ValueChanged<T> set) builder;
  final T initial;

  @override
  State<_Static<T>> createState() => _StaticState<T>();
}

class _StaticState<T> extends State<_Static<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

// --- catalog specimens -------------------------------------------------------

/// A view switch, one on.
Widget kitSpecimenToggleGroup() => Center(
  child: MinimalToggleGroup<String>(
    label: 'View',
    selected: const {'board'},
    onChanged: (_) {},
    items: _views,
  ),
);

/// A split button, its menu closed.
Widget kitSpecimenSplitButton() => Builder(
  builder: (context) => Center(
    child: MinimalSplitButton(
      'Publish',
      icon: LucideIcons.sendDir,
      onPressed: () {},
      actions: _publish(context),
    ),
  ),
);
