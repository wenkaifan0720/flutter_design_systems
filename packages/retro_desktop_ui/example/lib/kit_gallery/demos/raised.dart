/// The surfaces that rise above a desktop and their working launchers.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import '../kit.dart';

Widget kitRaisedDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialogs, sheets and menus',
  sections: [
    kitSection('A dialog window', children: [kitSpecimenDialog()]),
    kitSection('A sheet at the foot', children: [kitSpecimenBottomSheet()]),
    kitSection('A menu', children: [kitSpecimenMenu()]),
    kitSection('A tooltip', children: [kitSpecimenTooltip()]),
    kitSection('A snack bar', children: [kitSpecimenSnackBar()]),
    kitSection('Open each surface', children: [kitRaiseLaunchers()]),
  ],
);

const _firstRow = RetroDesktopListTile(
  title: 'Project notes',
  subtitle: 'Edited today',
);
const _secondRow = RetroDesktopListTile(
  title: 'Archive',
  subtitle: '12 documents',
);

Widget _raised(Widget child, {double height = 360, bool bottom = false}) =>
    Builder(
      builder: (context) => SizedBox(
        // The stage grows with the reader's text, so a raised window at twice the size stands whole in it.
        height: MediaQuery.textScalerOf(context).scale(height) < height
            ? height
            : MediaQuery.textScalerOf(context).scale(height),
        // Nothing behind is dimmed (the stacking law): the window in front
        // stands over the page as the period's did, its shadow hard.
        child: bottom
            ? Stack(
                fit: StackFit.expand,
                children: [
                  const ExcludeSemantics(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(children: [_firstRow, _secondRow]),
                    ),
                  ),
                  Align(alignment: Alignment.bottomCenter, child: child),
                ],
              )
            // A dialog stands from the top of the page's second row: centred,
            // its top edge cut a row's letters wherever it fell, and at twice
            // the text size left their tips, a pixel, standing over it.
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const ExcludeSemantics(child: _firstRow),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const ExcludeSemantics(child: _secondRow),
                          Align(alignment: Alignment.topCenter, child: child),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );

Widget kitSpecimenDialog() => kitDismissible(
  'dialog',
  (close) => _raised(
    RetroDesktopDialog(
      title: 'Keep your changes?',
      message: 'Save this document before closing its window.',
      tone: RetroDesktopTone.warning,
      actions: [
        RetroDesktopButton('Discard', onPressed: close),
        RetroDesktopButton('Save', isDefaultAction: true, onPressed: close),
      ],
    ),
  ),
);
Widget kitSpecimenBottomSheet() => kitDismissible(
  'sheet',
  (close) => _raised(
    RetroDesktopBottomSheet(
      title: 'Choose a destination',
      onClose: close,
      actions: [
        RetroDesktopButton(
          'Move here',
          isDefaultAction: true,
          onPressed: close,
        ),
      ],
      // Rows stand in a well, as a list's do.
      child: RetroDesktopWell(
        child: RetroDesktopList(
          children: [
            RetroDesktopListTile(
              title: 'Documents',
              leading: const Icon(RetroDesktopGlyphs.inbox),
              onPressed: close,
            ),
            RetroDesktopListTile(
              title: 'Archive',
              leading: const Icon(RetroDesktopGlyphs.inbox),
              onPressed: close,
            ),
          ],
        ),
      ),
    ),
    height: 440,
    bottom: true,
  ),
);
const _menu = [
  RetroDesktopMenuItem('open', 'Open', icon: RetroDesktopGlyphs.fileText),
  RetroDesktopMenuItem('rename', 'Rename'),
  RetroDesktopMenuItem('locked', 'Locked', enabled: false),
];
// A menu as it opens: as wide as its longest command, at most a menu's 280.
Widget kitSpecimenMenu() => kitAction(
  'Command selected',
  (press) => Align(
    alignment: AlignmentDirectional.topStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: IntrinsicWidth(
        child: RetroDesktopMenu<String>(
          label: 'Document commands',
          items: _menu,
          onSelected: (_) => press(),
        ),
      ),
    ),
  ),
);
Widget kitSpecimenTooltip() => kitAction(
  'Search opened',
  (press) => RetroDesktopTooltip(
    message: 'Search every document',
    child: RetroDesktopIconButton(
      RetroDesktopGlyphs.search,
      label: 'Search',
      onPressed: press,
    ),
  ),
);
Widget kitTooltipFace() =>
    const RetroDesktopTooltipFace(message: 'Search every document');
Widget kitSpecimenSnackBar() => kitDismissible(
  'snack bar',
  (close) => RetroDesktopSnackBar(
    'Moved to Archive',
    actionLabel: 'Undo',
    onAction: close,
    onDismissed: close,
  ),
);
Widget kitSpecimenMenuAnchor() => kitAction(
  'Command selected',
  (press) => RetroDesktopMenuAnchor<String>(
    items: _menu,
    builder: (context, open) =>
        RetroDesktopButton('Document commands', onPressed: open),
    onSelected: (_) => press(),
  ),
);
Widget kitRaiseLaunchers() => Builder(
  builder: (context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      // The dialog the page shows in place, raised: one dialog, one look,
      // its actions at the trailing end, the confirming one last and filled.
      RetroDesktopButton(
        'Dialog',
        onPressed: () => showRetroDesktopDialog<void>(
          context,
          builder: (context) => RetroDesktopDialog(
            title: 'Keep your changes?',
            message: 'Save this document before closing its window.',
            tone: RetroDesktopTone.warning,
            actions: [
              RetroDesktopDialogAction<void>('Discard'),
              RetroDesktopDialogAction<void>('Save', isDefaultAction: true),
            ],
          ),
        ),
      ),
      RetroDesktopButton(
        'Sheet',
        onPressed: () => showRetroDesktopBottomSheet<void>(
          context,
          builder: (context) => RetroDesktopBottomSheet(
            title: 'Folders',
            onClose: () => Navigator.pop(context),
            child: const RetroDesktopListTile(title: 'Documents'),
          ),
        ),
      ),
      kitSpecimenMenuAnchor(),
      RetroDesktopButton(
        'Snack bar',
        onPressed: () => showRetroDesktopSnackBar(context, 'Document saved'),
      ),
      kitSpecimenTooltip(),
    ],
  ),
);
