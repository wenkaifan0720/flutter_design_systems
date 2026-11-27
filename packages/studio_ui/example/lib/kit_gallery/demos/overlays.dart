import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

/// A dialog rising toward the light, a drawer sliding out, a toast.
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialogs, sheets and toasts',
  sections: [
    KitSection(
      title: 'Dialog',
      note: 'A panel module rising toward the light as the room dims.',
      children: [
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StudioButton(
              'Discard take…',
              onPressed: () => showStudioDialog<void>(
                context: context,
                isAlert: true,
                builder: (context) => StudioDialog(
                  title: 'Discard this take?',
                  content: const Text(
                    'The 7 minutes you recorded will be gone.',
                  ),
                  actions: [
                    StudioButton(
                      'Keep',
                      onPressed: () => Navigator.pop(context),
                    ),
                    StudioButton.lit(
                      'Discard',
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Sheet',
      note: 'A drawer of metal with a finger slot.',
      children: [
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StudioButton(
              'Export…',
              onPressed: () => showStudioBottomSheet<void>(
                context: context,
                title: 'Export',
                builder: (context) => StudioListGroup(
                  children: [
                    StudioListTile(
                      title: 'MP3, 128 kbps',
                      onTap: () => Navigator.pop(context),
                    ),
                    StudioListTile(
                      title: 'WAV, 48 kHz',
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Toast',
      note: 'A strip of readout glass with its lamp lit.',
      children: [
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StudioButton(
              'Add marker',
              onPressed: () => showStudioToast(
                context,
                'Marker added at 7:14',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Menus',
      note: 'A list under glass opened by a key; a destructive row reads red.',
      children: [
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: StudioMenu(
              semanticLabel: 'Episode',
              items: [
                StudioMenuItem(
                  label: 'Rename',
                  onPressed: () => kitFeedback(context, 'Rename'),
                ),
                StudioMenuItem(
                  label: 'Download',
                  onPressed: () => kitFeedback(context, 'Downloading'),
                ),
                StudioMenuItem(
                  label: 'Delete',
                  isDestructiveAction: true,
                  onPressed: () => kitFeedback(context, 'Deleted'),
                ),
              ],
              builder: (context, toggle, open) =>
                  StudioButton('More', onPressed: toggle),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Popover, hover card and tooltip',
      note: 'A raised panel a key opens; one the pointer opens; a name in a small readout.',
      children: [
        KitRow(
          children: [
            StudioPopover(
              semanticLabel: 'Speed',
              builder: (context, toggle, open) =>
                  StudioButton('Speed', onPressed: toggle),
              content: (context, close) => kitState<double>(
                1,
                (context, v, set) => StudioSegmentedButton<double>(
                  semanticLabel: 'Speed',
                  segments: const [
                    StudioSegment(value: 1, label: '1×'),
                    StudioSegment(value: 1.5, label: '1.5×'),
                    StudioSegment(value: 2, label: '2×'),
                  ],
                  value: v,
                  onChanged: set,
                ),
              ),
            ),
            StudioHoverCard(
              content: (context) =>
                  const Text('Noor Haddad has hosted Night Desk since 2024.'),
              child: Builder(
                builder: (context) => StudioLink(
                  'Noor Haddad',
                  onPressed: () => kitFeedback(context, 'Noor Haddad'),
                ),
              ),
            ),
            Builder(
              builder: (context) => StudioTooltip(
                message: 'Skip back 15 seconds',
                child: StudioIconButton(
                  icon: const Icon(LucideIcons.rotateCcw),
                  tooltip: 'Skip back',
                  onPressed: () => kitFeedback(context, 'Back 15 s'),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Side and action sheets',
      note: 'A panel slid in from the side; a bank of keys up from the bottom.',
      children: [
        Builder(
          builder: (context) => KitRow(
            children: [
              StudioButton(
                'Filters',
                onPressed: () => showStudioSideSheet<void>(
                  context: context,
                  title: 'Filters',
                  builder: (context) => const Text('Unplayed only'),
                ),
              ),
              StudioButton(
                'This take…',
                onPressed: () => showStudioActionSheet<String>(
                  context: context,
                  title: 'This take',
                  message: 'Take 3, 7 min 12 s.',
                  actions: const [
                    StudioSheetAction(label: 'Keep', value: 'keep'),
                    StudioSheetAction(label: 'Rename', value: 'rename'),
                    StudioSheetAction(
                      label: 'Discard',
                      value: 'discard',
                      isDestructiveAction: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Command palette',
      note: 'Type to find a command; Enter runs the lit one and the search keeps typing.',
      children: [
        Builder(
          builder: (context) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 480,
              height: 360,
              child: StudioCommandPalette(
                commands: [
                  StudioCommand(
                    label: 'New episode',
                    group: 'Episodes',
                    shortcut: 'Ctrl N',
                    onPressed: () => kitFeedback(context, 'New episode'),
                  ),
                  StudioCommand(
                    label: 'Start recording',
                    group: 'Record',
                    shortcut: 'R',
                    onPressed: () => kitFeedback(context, 'Recording'),
                  ),
                  StudioCommand(
                    label: 'Export mix',
                    group: 'Record',
                    onPressed: () => kitFeedback(context, 'Exported'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);
