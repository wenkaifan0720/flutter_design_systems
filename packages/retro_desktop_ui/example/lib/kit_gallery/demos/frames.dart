/// The one frame: every section a window on a desktop, one of them active, with heads and marks inside them.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitFramesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Windows, alerts and the desktop',
  bare: true,
  sections: [
    kitSection(
      'A desktop, one window active',
      children: [kitSpecimenDesktop()],
    ),
    kitSection('A window', children: [kitSpecimenWindow()]),
    kitSection('A window that closes', children: [kitSpecimenWindowClosing()]),
    kitSection('A well', children: [kitSpecimenWell()]),
    kitSection('A toolbar', children: [kitSpecimenToolbar()]),
    kitSection('A folded window', children: [kitSpecimenShade()]),
    kitSection('An alert', children: [kitSpecimenAlert()]),
    kitSection('An eyebrow', children: [kitSpecimenEyebrow()]),
    kitSection('A head', children: [kitSpecimenHead()]),
    kitSection('A sub head', children: [kitSpecimenSubHead()]),
    kitSection('A part head', children: [kitSpecimenPartHead()]),
    kitSection('A label', children: [kitSpecimenLabel()]),
    kitSection('A labelled field', children: [kitSpecimenLabelled()]),
    kitSection('A monogram', children: [kitSpecimenMonogram()]),
  ],
);

Widget kitSpecimenDesktop() => const KitDesk(
  child: RetroDesktopDesktop(
    active: 'The active one',
    tiles: [
      RetroDesktopWindowColumn(
        span: 7,
        windows: [
          RetroDesktopWindow(
            title: 'The active one',
            icon: LucideIcons.calendarCheck,
            status: ['3 open', '2 done'],
            child: RetroDesktopDescriptionList([
              RetroDesktopFact('Open', '3'),
              RetroDesktopFact('Done', '2'),
            ], leaders: true),
          ),
        ],
      ),
      RetroDesktopWindowColumn(
        span: 5,
        windows: [
          RetroDesktopWindow(
            title: 'Another',
            child: Text('Flat and quieter.'),
          ),
          RetroDesktopWindowShade(title: 'A third, folded'),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenWindow() => const KitDesk(
  child: RetroDesktopDesktop(
    tiles: [
      RetroDesktopWindowColumn(
        span: 12,
        windows: [
          RetroDesktopWindow(
            title: 'A window',
            icon: LucideIcons.fileText,
            info: '6 of 40',
            infoEnd: 'By date',
            status: ['Synced', '6 shown'],
            child: Text('Every section of a page is one of these.'),
          ),
        ],
      ),
    ],
  ),
);

Widget kitSpecimenWindowClosing() => kitDismissible(
  'window',
  (close) => KitDesk(
    child: RetroDesktopDesktop(
      tiles: [
        RetroDesktopWindowColumn(
          span: 12,
          windows: [
            RetroDesktopWindow(
              title: 'A window that closes',
              icon: LucideIcons.fileText,
              onClose: close,
              child: const Text(
                'Press the box at the bar\'s start to close it. On a touch screen the bar stands taller, so the box reaches a finger.',
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);

Widget kitSpecimenWell() => RetroDesktopWell(
  child: RetroDesktopList(
    share: true,
    children: const [
      RetroDesktopListTile(title: 'One row', subtitle: 'On paper'),
      RetroDesktopListTile(title: 'Another', subtitle: 'On paper'),
    ],
  ),
);

Widget kitSpecimenToolbar() => kitAction(
  'Toolbar action completed',
  (press) => RetroDesktopToolbar(
    // Out of a window's toolbar slot, on the column's edge: the 12 at its start lines it up with a window's content.
    padding: const EdgeInsets.symmetric(vertical: 6),
    children: [
      kitPopup('First folder', icon: LucideIcons.folder),
      const RetroDesktopToolRule(),
      RetroDesktopIconButton(LucideIcons.tag, label: 'Tag', onPressed: press),
      RetroDesktopIconButton(
        LucideIcons.paperclip,
        label: 'Attach',
        onPressed: press,
      ),
      const RetroDesktopToolNote('Saved', icon: LucideIcons.cloudCheck),
    ],
  ),
);

Widget kitSpecimenShade() => const KitDesk(
  child: RetroDesktopWindowShade(
    title: 'Inbox, 4 new',
    icon: LucideIcons.inbox,
  ),
);

Widget kitSpecimenAlert() => kitAction(
  'Reminder handled',
  (press) => KitDesk(
    child: RetroDesktopAlert(
      icon: LucideIcons.alarmClock,
      title: 'Due today at 14:00',
      body: 'The step to take next is due this afternoon.',
      meta: 'in 4 h',
      actions: [
        RetroDesktopButton('Snooze', onPressed: press),
        RetroDesktopButton('Open it', isDefaultAction: true, onPressed: press),
      ],
    ),
  ),
);

Widget kitSpecimenEyebrow() => const RetroDesktopEyebrow('A few words');

Widget kitSpecimenHead() => const RetroDesktopHeadline('3 left today');

Widget kitSpecimenSubHead() => kitAction(
  'Storage settings opened',
  (press) => RetroDesktopSectionHeader(
    'Storage',
    note: 'All saved',
    trailing: RetroDesktopButton(
      'Manage',
      size: RetroDesktopButtonSize.small,
      onPressed: press,
    ),
  ),
);

// Over the part it names, as it stands in an app (alone, it headed nothing: an empty strip). No triangle: this part
// doesn't fold.
Widget kitSpecimenPartHead() => const RetroDesktopColumn(
  gap: 6,
  children: [
    RetroDesktopPartHead('Next 4 hours', note: 'sky, °C, rain %'),
    RetroDesktopHourStrip(
      hours: [
        RetroDesktopHour(
          label: 'Now',
          icon: LucideIcons.cloudRain,
          value: 8,
          reading: '8°',
          kind: RetroDesktopSkyCondition.rain,
          share: .6,
        ),
        RetroDesktopHour(
          label: '10',
          icon: LucideIcons.cloudDrizzle,
          value: 9,
          reading: '9°',
          kind: RetroDesktopSkyCondition.drizzle,
          share: .4,
        ),
        RetroDesktopHour(
          label: '11',
          icon: LucideIcons.cloud,
          value: 10,
          reading: '10°',
          kind: RetroDesktopSkyCondition.cloud,
          share: .1,
        ),
        RetroDesktopHour(
          label: '12',
          icon: LucideIcons.sun,
          value: 11,
          reading: '11°',
          kind: RetroDesktopSkyCondition.sun,
        ),
      ],
    ),
  ],
);

Widget kitSpecimenLabel() => const RetroDesktopLabel('Folder');

Widget kitSpecimenLabelled() => const RetroDesktopFormField(
  label: 'Name',
  help: 'Only for your receipts',
  child: RetroDesktopTextField(hint: 'Your name'),
);

Widget kitSpecimenMonogram() => const RetroDesktopMonogram('AB');
