/// Soft surfaces above the page, with working launchers below their specimens.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitRaisedDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialogs, sheets, menus and notices',
  sections: [
    kitSection('A decision', children: [kitSpecimenDialog()]),
    kitSection('A longer task', children: [kitSpecimenSheet()]),
    kitSection('A choice beside its control', children: [kitSpecimenMenu()]),
    kitSection('A little help', children: [kitSpecimenTooltip()]),
    kitSection('A confirmation', children: [kitSpecimenSnackBar()]),
    kitSection('Open them', children: [const _Launchers()]),
  ],
);

Widget _raised(
  Widget child, {
  required double height,
  bool bottom = false,
  bool scrim = true,
}) => SizedBox(
  height: height,
  child: ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        const ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: NeumorphicColumn(
              children: [
                NeumorphicSectionHeader(title: 'Today'),
                NeumorphicKvRow('The reading room', '09:00'),
                NeumorphicKvRow('An afternoon walk', '14:00'),
              ],
            ),
          ),
        ),
        if (scrim) const ColoredBox(color: Color(0x66000000)),
        Align(
          alignment: bottom ? Alignment.bottomCenter : Alignment.center,
          child: child,
        ),
      ],
    ),
  ),
);

Widget kitSpecimenDialog() => _raised(
  NeumorphicDialog(
    title: 'Keep this time?',
    message: 'Your reminder will be ready tomorrow morning.',
    actions: [
      NeumorphicButton('Not now', onPressed: () {}),
      NeumorphicButton.filled('Keep it', onPressed: () {}),
    ],
  ),
  height: 360,
);

Widget kitSpecimenSheet() => _raised(
  NeumorphicBottomSheet(
    title: 'Choose a space',
    onClose: () {},
    actions: [NeumorphicButton.filled('Choose', onPressed: () {})],
    child: NeumorphicColumn(
      gap: 12,
      children: [
        NeumorphicChoiceBox(
          onPressed: () {},
          child: const Text('The reading room'),
        ),
        NeumorphicChoiceBox(
          selected: true,
          onPressed: () {},
          child: const Text('Beside the window'),
        ),
        NeumorphicChoiceBox(
          onPressed: () {},
          child: const Text('The courtyard'),
        ),
      ],
    ),
  ),
  height: 520,
  bottom: true,
);

const _choices = <NeumorphicMenuItem<String>>[
  NeumorphicMenuItem(
    'read',
    'The reading room',
    icon: NeumorphicGlyphs.armchair,
  ),
  NeumorphicMenuItem('window', 'Beside the window', selected: true),
  NeumorphicMenuItem('court', 'The courtyard', note: 'Closed', enabled: false),
  NeumorphicMenuItem.divider(),
  NeumorphicMenuItem('clear', 'Clear the choice', danger: true),
];

Widget kitSpecimenMenu() => SizedBox(
  height: 390,
  child: Stack(
    children: [
      const NeumorphicSelectField(value: 'Beside the window'),
      Positioned(
        top: 60,
        left: 0,
        right: 0,
        bottom: 0,
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: NeumorphicMenu<String>(
            autofocus: false,
            items: _choices,
            onSelected: (_) {},
          ),
        ),
      ),
    ],
  ),
);

Widget kitSpecimenTooltip() => const SizedBox(
  height: 128,
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NeumorphicTooltipFace(message: 'About this space'),
        SizedBox(height: 12),
        NeumorphicRoundButton(NeumorphicGlyphs.info, label: 'About this space'),
      ],
    ),
  ),
);

Widget kitSpecimenSnackBar() => _raised(
  Padding(
    padding: const EdgeInsets.all(12),
    child: NeumorphicSnackBar(
      'Your time is kept',
      tone: NeumorphicTone.success,
      actionLabel: 'Undo',
      onAction: () {},
      onDismiss: () {},
    ),
  ),
  height: 260,
  bottom: true,
  scrim: false,
);

class _Launchers extends StatelessWidget {
  const _Launchers();
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      NeumorphicButton(
        'Dialog',
        onPressed: () => showNeumorphicDialog<void>(
          context,
          builder: (context) => NeumorphicDialog(
            title: 'Keep this time?',
            message: 'A reminder for tomorrow morning.',
            actions: [
              NeumorphicButton(
                'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
              NeumorphicButton(
                'Keep',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
      NeumorphicButton(
        'Sheet',
        onPressed: () => showNeumorphicBottomSheet<void>(
          context,
          builder: (context) => NeumorphicBottomSheet(
            title: 'Choose a space',
            actions: [
              NeumorphicButton(
                'Choose',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            child: const Text('Choose somewhere quiet for tomorrow morning.'),
          ),
        ),
      ),
      Builder(
        builder: (anchorContext) => NeumorphicButton(
          'Menu',
          onPressed: () {
            final box = anchorContext.findRenderObject()! as RenderBox;
            showNeumorphicMenu<String>(
              anchorContext,
              anchor: box.localToGlobal(Offset.zero) & box.size,
              items: _choices,
            );
          },
        ),
      ),
      NeumorphicTooltip(
        message: 'Help is here',
        child: NeumorphicRoundButton(
          NeumorphicGlyphs.info,
          label: 'Help',
          onPressed: () {},
        ),
      ),
      NeumorphicButton(
        'Notice',
        onPressed: () => showNeumorphicSnackBar(
          context,
          message: 'Your time is kept',
          tone: NeumorphicTone.success,
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
    ],
  );
}
