/// What rises over the page past the dialog and the menu: the bottom sheet
/// (sharing a file), the action sheet (a file's actions, Delete in the danger
/// ink), a popover of filters on its button and a person's card on hover;
/// each drawn in place and raised from its button.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

Widget kitRaisedDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Bottom sheet, action sheet & popover',
  sections: [
    kitSection(
      'Bottom sheet',
      children: [kitSpecimenBottomSheet(), _raiseShare],
    ),
    kitSection(
      'Action sheet',
      children: [kitSpecimenActionSheet(), _raiseActions],
    ),
    kitSection('Popover', children: [kitSpecimenPopover()]),
  ],
);

Widget _sharePeople(BuildContext context) => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Fluent2ListItem(
      leading: Fluent2Avatar(name: 'Ana Ruiz'),
      title: 'Ana Ruiz',
      subtitle: 'Can edit',
    ),
    Fluent2ListItem(
      leading: Fluent2Avatar(name: 'Kai Ito'),
      title: 'Kai Ito',
      subtitle: 'Can view',
    ),
  ],
);

Widget kitSpecimenBottomSheet() => Builder(
  builder: (context) => Fluent2BottomSheet(
    title: 'Share "Budget"',
    onClose: () {},
    actions: [Fluent2Button('Copy link', onPressed: () {})],
    child: _sharePeople(context),
  ),
);

final _raiseShare = Builder(
  builder: (context) => Fluent2Button(
    'Share',
    icon: Fluent2Icons.share,
    onPressed: () => showFluent2BottomSheet<void>(
      context,
      builder: (sheet) => Fluent2BottomSheet(
        title: 'Share "Budget"',
        onClose: () => Navigator.of(sheet).pop(),
        actions: [
          Fluent2Button(
            'Copy link',
            appearance: Fluent2ButtonAppearance.primary,
            onPressed: () => Navigator.of(sheet).pop(),
          ),
        ],
        child: _sharePeople(sheet),
      ),
    ),
  ),
);

const _fileActions = [
  Fluent2ActionSheetAction('open', 'Open', icon: Fluent2Icons.open),
  Fluent2ActionSheetAction('share', 'Share', icon: Fluent2Icons.share),
  Fluent2ActionSheetAction('copy', 'Copy link', icon: Fluent2Icons.link),
  Fluent2ActionSheetAction(
    'delete',
    'Delete',
    icon: Fluent2Icons.delete,
    destructive: true,
  ),
];

Widget kitSpecimenActionSheet() => Fluent2ActionSheet<String>(
  title: 'Budget',
  message: 'Edited today by Ana Ruiz',
  actions: _fileActions,
  onSelected: (_) {},
  onCancel: () {},
);

final _raiseActions = Builder(
  builder: (context) => Fluent2Button(
    'More actions',
    icon: Fluent2Icons.moreHorizontal,
    onPressed: () => showFluent2ActionSheet<String>(
      context,
      title: 'Budget',
      actions: _fileActions,
    ),
  ),
);

Widget kitSpecimenPopover() => Fluent2Popover(
  label: 'Filters',
  width: 260,
  trigger: (context, toggle) =>
      Fluent2Button('Filters', icon: Fluent2Icons.filter, onPressed: toggle),
  content: Builder(
    builder: (context) {
      final t = context.fluent2Theme;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Fluent2Spacing.s,
        children: [
          Text('Show', style: t.body1Strong.c(t.textPrimary)),
          Fluent2Checkbox(
            value: true,
            label: 'Shared with me',
            onChanged: (_) {},
          ),
          Fluent2Checkbox(value: false, label: 'Archived', onChanged: (_) {}),
        ],
      );
    },
  ),
);
