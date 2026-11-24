/// Popovers, menus, palettes and toasts.
library;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Popovers, menus, palettes and toasts',
  sections: kitOverlaysSections(),
);

List<Widget> kitOverlaysSections() => [
  kitSection('A menu bar', children: [kitSpecimenMenuBar()]),
  kitSection(
    'A menu where you ask for it: right-click, long-press, or Shift+F10',
    children: [kitSpecimenContextMenu()],
  ),
  kitSection(
    'Something to read beside its trigger',
    children: [kitSpecimenPopover()],
  ),
  kitSection(
    'More about a name, on hover or focus',
    children: [kitSpecimenHoverCard()],
  ),
  kitSection('Find and run a command', children: [kitSpecimenCommand()]),
  kitSection('A panel from the side', children: [kitSpecimenSideSheet()]),
  kitSection(
    'Choices from the bottom edge',
    children: [kitSpecimenActionSheet()],
  ),
  kitSection('Messages that queue', children: [kitLiveToaster()]),
];

Widget kitSpecimenMenuBar() => kitValue<bool>(
  true,
  (context, roomsShown, change) => NeumorphicMenuBar(
    label: 'Scenes',
    menus: [
      RawMenuEntry(
        label: 'Scene',
        children: [
          RawMenuEntry(
            label: 'New scene',
            shortcut: _primaryKeys(context, LogicalKeyboardKey.keyN),
            onPressed: () =>
                showNeumorphicSnackBar(context, message: 'New scene'),
          ),
          RawMenuEntry(
            label: 'Export',
            children: [
              RawMenuEntry(
                label: 'As a file',
                onPressed: () =>
                    showNeumorphicSnackBar(context, message: 'Exported'),
              ),
            ],
          ),
          const RawMenuEntry(label: 'Print'),
        ],
      ),
      RawMenuEntry(
        label: 'View',
        children: [
          RawMenuEntry(
            label: 'Rooms',
            checked: roomsShown,
            onPressed: () => change(!roomsShown),
          ),
          RawMenuEntry(
            label: 'Lamps',
            checked: !roomsShown,
            onPressed: () => change(!roomsShown),
          ),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenPopover() => NeumorphicPopover(
  label: 'Lights out',
  trigger: (context, toggle) =>
      NeumorphicButton('Lights out', onPressed: toggle),
  content: Builder(
    builder: (context) {
      final t = context.neumorphicTheme;
      return NeumorphicColumn(
        gap: 8,
        children: [
          Text('Every night', style: t.textTheme.title),
          Text(
            'The hall dims first, the bedroom last.',
            style: t.textTheme.caption,
          ),
        ],
      );
    },
  ),
);

Widget kitSpecimenHoverCard() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: NeumorphicHoverCard(
    label: 'Marta Rossi',
    content: const Text('Asleep by eleven, most nights.'),
    child: NeumorphicLink('Marta Rossi', onPressed: () {}),
  ),
);

List<RawCommand> _commands(BuildContext context) => [
  RawCommand(
    label: 'New scene',
    group: 'Scenes',
    shortcut: _primaryKeys(context, LogicalKeyboardKey.keyN),
  ),
  const RawCommand(label: 'Dim every room', group: 'Scenes'),
  RawCommand(
    label: 'Find a room',
    group: 'Rooms',
    shortcut: _primaryKeys(context, LogicalKeyboardKey.keyK),
  ),
];

Widget kitSpecimenCommand() => Builder(
  builder: (context) =>
      NeumorphicCommand(commands: _commands(context), maxHeight: 240),
);

Widget kitSpecimenContextMenu() => kitValue<bool>(
  true,
  (context, lit, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: NeumorphicContextMenu(
      label: 'Hall lamp',
      menuChildren: [
        RawMenuEntry(label: 'On', checked: lit, onPressed: () => change(!lit)),
        RawMenuEntry(
          label: 'Rename',
          shortcut: _primaryKeys(context, LogicalKeyboardKey.keyR),
          onPressed: () => showNeumorphicSnackBar(context, message: 'Rename'),
        ),
        const RawMenuEntry.divider(),
        RawMenuEntry(
          label: 'Remove',
          isDestructiveAction: true,
          onPressed: () => showNeumorphicSnackBar(context, message: 'Removed'),
        ),
      ],
      child: SizedBox(
        width: 320,
        child: NeumorphicCard(
          title: 'Hall lamp',
          subtitle: lit ? 'On' : 'Off',
          trailing: NeumorphicSwitch(
            label: 'Hall lamp',
            value: lit,
            onChanged: change,
          ),
        ),
      ),
    ),
  ),
);

Widget kitSpecimenSideSheet() => Builder(
  builder: (context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: NeumorphicButton(
      'Filters',
      onPressed: () => showNeumorphicSheet<void>(
        context,
        builder: (context, close) => NeumorphicSheet(
          title: 'Filters',
          onClose: close,
          actions: [NeumorphicButton('Show 12 rooms', onPressed: close)],
          child: const NeumorphicCheckbox(
            value: true,
            label: 'Warm white',
            onChanged: _ignore,
          ),
        ),
      ),
    ),
  ),
);

void _ignore(Object? _) {}

Widget kitSpecimenActionSheet() => NeumorphicActionSheet<String>(
  title: 'Bedroom',
  message: 'Two lamps',
  onSelected: _ignore,
  onCancel: () {},
  actions: const [
    NeumorphicActionSheetAction(
      'share',
      'Share',
      icon: NeumorphicGlyphs.share2,
    ),
    // Every action with its glyph at the start, as Share and Cancel have: without one its words stood out of line.
    NeumorphicActionSheetAction(
      'remove',
      'Remove the room',
      icon: NeumorphicGlyphs.trash2,
      destructive: true,
    ),
  ],
);

Widget kitLiveToaster() => Builder(
  builder: (context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      NeumorphicButton(
        'Show one',
        onPressed: () => showNeumorphicToast(
          context,
          message: 'Scene saved',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
      NeumorphicButton(
        'Show a warning',
        onPressed: () => showNeumorphicToast(
          context,
          title: 'The hall lamp',
          message: 'It is changing.',
          tone: NeumorphicTone.warning,
        ),
      ),
    ],
  ),
);

// A shortcut on the platform's own modifier: Command on Apple's, Control elsewhere, spelled as its menus spell it.
String _primaryKeys(BuildContext context, LogicalKeyboardKey key) {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  return rawShortcutLabel(
    context,
    SingleActivator(key, meta: apple, control: !apple),
  );
}
