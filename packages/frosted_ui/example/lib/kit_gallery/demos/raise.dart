/// The raised surfaces' show functions ([showFrostedDialog],
/// [showFrostedActionSheet], [showFrostedMenu], [showFrostedSnackBar]) and
/// [FrostedTooltip], each opened from a button, with the action sheet's
/// card drawn in place.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitRaiseDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Raised surfaces',
  sections: [
    kitSection(
      'Opened from a button',
      children: [
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              'Dialog',
              onPressed: () => showFrostedDialog<void>(
                context,
                builder: (dialog) => FrostedDialog(
                  title: 'Archive this project?',
                  message: 'You can restore it from Archived at any time.',
                  actions: [
                    FrostedButton.glass(
                      'Cancel',
                      onPressed: () => Navigator.of(dialog).pop(),
                    ),
                    FrostedButton(
                      'Archive',
                      onPressed: () => Navigator.of(dialog).pop(),
                    ),
                  ],
                ),
              ),
            ),
            FrostedButton.glass(
              'Action sheet',
              onPressed: () => showFrostedActionSheet<String>(
                context,
                builder: (_) => _sheet,
              ),
            ),
            Builder(
              builder: (anchor) => FrostedButton.glass(
                'Menu',
                onPressed: () => showFrostedMenu<String>(
                  anchor,
                  items: const [
                    FrostedMenuItem('rename', 'Rename'),
                    FrostedMenuItem('move', 'Move to…'),
                    FrostedMenuItem('delete', 'Delete', enabled: false),
                  ],
                ),
              ),
            ),
            FrostedButton.glass(
              'Snack bar',
              onPressed: () => showFrostedSnackBar(
                context,
                'Saved to Drafts',
                actionLabel: 'Undo',
                onAction: () {},
              ),
            ),
          ]),
        ),
      ],
    ),
    kitSection(
      'Tooltip: rest a pointer on Share, or hold it',
      children: [
        kitRow([
          FrostedTooltip(
            message: 'Share with your team',
            child: FrostedIconButton(
              FrostedGlyphs.share,
              label: 'Share',
              onPressed: () {},
            ),
          ),
        ]),
      ],
    ),
    kitSection('Action sheet, in place', children: [_sheet]),
    kitSection(
      'Snack bar tones, in place',
      children: const [
        FrostedSnackBar('Your changes are saved'),
        FrostedSnackBar(
          'Check your connection and try again.',
          title: 'Upload paused',
          tone: FrostedTone.warning,
        ),
        FrostedSnackBar(
          'The file could not be opened',
          tone: FrostedTone.danger,
        ),
      ],
    ),
  ],
);

const _sheet = FrostedActionSheet<String>(
  title: 'Photo',
  message: 'Choose what to do with this photo.',
  actions: [
    FrostedActionSheetAction('Share', value: 'share'),
    FrostedActionSheetAction('Duplicate', value: 'duplicate'),
    FrostedActionSheetAction('Delete', value: 'delete', destructive: true),
  ],
);
