/// The screen and its bars, the picture and the states a page can be in.
library;

import 'package:flutter/material.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
// The demo art is the example's; a test or page that draws it reads it from there.
// ignore: avoid_relative_lib_imports
import '../../demo_art.dart';

Widget kitChromeDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Screen, bars and pictures',
  sections: [
    kitSection('The top bar', children: [kitSpecimenTopBar()]),
    kitSection('The strip of places', children: [kitSpecimenTabBar()]),
    kitSection('A strip on the desk', children: [kitSpecimenDeskStrip()]),
    kitSection('Marks on the desk', children: [kitSpecimenDeskMarks()]),
    kitSection('The mark', children: [kitSpecimenMark()]),
    kitSection('A picture, in its fallback', children: [kitSpecimenPhoto()]),
    kitSection('A picture card', children: [kitSpecimenPictureCard()]),
    kitSection('Loading', children: [kitSpecimenLoadingState()]),
    kitSection('An error', children: [kitSpecimenErrorState()]),
    kitSection('The plain button', children: [kitSpecimenButton()]),
    kitSection('The plain input', children: [kitSpecimenInput()]),
  ],
);

Widget kitSpecimenTopBar() => const RetroDesktopAppBar(
  title: 'A page',
  subtitle: 'A line under the title',
);

Widget kitSpecimenTabBar() => kitValue(
  0,
  (value, change) => RetroDesktopNavigationBar(
    items: kitTabs,
    selectedIndex: value,
    onDestinationSelected: change,
  ),
);

Widget kitSpecimenDeskStrip() => const RetroDesktopDeskStrip(
  items: [
    RetroDesktopStripItem(
      'Saved 08:18',
      icon: LucideIcons.cloudCheck,
      highlighted: true,
    ),
    RetroDesktopStripItem('Laptop', icon: LucideIcons.laptop),
    RetroDesktopStripItem('Phone', icon: LucideIcons.smartphone),
  ],
);

Widget kitSpecimenDeskMarks() => const KitDesk(
  child: RetroDesktopDeskMarks(
    marks: [
      (RetroDesktopDeskMark.disk, 'Your files'),
      (RetroDesktopDeskMark.floppy, 'Backups'),
      (RetroDesktopDeskMark.bin, 'Bin'),
    ],
  ),
);

Widget kitSpecimenMark() => const RetroDesktopSystemMark();

Widget kitSpecimenPhoto() => const RetroDesktopMedia(
  slotId: 'kit-picture',
  aspect: 16 / 9,
  label: 'A picture',
);

Widget kitSpecimenPictureCard() => const RetroDesktopGridOf(
  columns: 2,
  gap: 12,
  runGap: 12,
  children: [
    // Both with their pictures: an empty slot's fallback, shown here, read as a picture that failed to load (the
    // fallback has its own section).
    RetroDesktopPictureCard(
      art: RetroDesktopObjectArt(RetroDesktopObject.letter),
      title: 'One thing',
      subtitle: 'A kind',
      figure: '42',
    ),
    RetroDesktopPictureCard(
      art: RetroDesktopObjectArt(RetroDesktopObject.folder),
      title: 'Another',
      subtitle: 'A kind',
      figure: '38',
    ),
  ],
);

Widget kitSpecimenLoadingState() =>
    const SizedBox(height: 180, child: RetroDesktopLoadingState());

Widget kitSpecimenErrorState() => const RetroDesktopErrorState(
  title: 'That did not load',
  message: 'Check the line and try again.',
);

Widget kitSpecimenButton() => kitAction(
  'Button pressed',
  (press) => RetroDesktopButton('A plain button', wide: true, onPressed: press),
);

Widget kitSpecimenInput() => const RetroDesktopInput(hint: 'A plain input');

Widget kitSpecimenScreen() => const RetroDesktopScaffold(
  topBar: RetroDesktopAppBar(title: 'A page'),
  body: RetroDesktopDesktop(
    tiles: [
      RetroDesktopWindowColumn(
        span: 12,
        windows: [
          RetroDesktopWindow(
            title: 'A page',
            child: RetroDesktopDescriptionList([
              RetroDesktopFact('A label', 'A value'),
            ]),
          ),
        ],
      ),
    ],
  ),
);
