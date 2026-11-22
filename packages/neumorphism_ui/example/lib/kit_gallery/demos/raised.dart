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

/// A small phone screen with a raised layer on it, as an app shows one: the page (dimmed under a dialog or a sheet),
/// and the layer in the screen's own overlay. The screen's corners are the ones a sheet has, so a sheet standing on the
/// screen's foot meets them exactly and its cast ends where the screen does. A layer that floats keeps a slab's cast
/// room ([kitCastRoom]) from every edge, so nothing of it is cut by the screen's box. On a specimen stage the screen
/// spans the band's room: it casts nothing itself.
class _RaisedScreen extends StatelessWidget {
  const _RaisedScreen({
    required this.height,
    required this.child,
    this.bottom = false,
    this.scrim = true,
  });
  final double height;
  final Widget child;
  final bool bottom, scrim;

  @override
  Widget build(BuildContext context) {
    final room = kitStageRoom(context);
    final screen = SizedBox(
      height: height,
      child: ClipPath(
        clipper: ShapeBorderClipper(
          shape: context.neumorphicTheme.shapes.corner(NeumorphicRadii.slab),
          textDirection: Directionality.of(context),
        ),
        child: Overlay.wrap(
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
              // The look's own veil over the page (its routes lay the bare wall at 72%), not a grey: a grey would dirty
              // the wall and turn a layer's light cast into a halo on every side.
              if (scrim)
                ColoredBox(
                  color: context.neumorphicTheme.colors.ground.withValues(
                    alpha: .72,
                  ),
                ),
              Align(
                alignment: bottom ? Alignment.bottomCenter : Alignment.center,
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
    if (room == 0) return screen;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, box) => OverflowBox(
          minWidth: box.maxWidth + 2 * room,
          maxWidth: box.maxWidth + 2 * room,
          child: screen,
        ),
      ),
    );
  }
}

Widget _raised(
  Widget child, {
  required double height,
  bool bottom = false,
  bool scrim = true,
}) => _RaisedScreen(height: height, bottom: bottom, scrim: scrim, child: child);

/// What a dialog keeps between itself and a phone's edge on its own (NeumorphicDialog's inset).
const double _dialogInset = 20;

Widget kitSpecimenDialog() => _raised(
  // The dialog keeps its own 20 from the screen's edge; the screen adds the rest of a slab's cast room.
  Padding(
    padding: const EdgeInsets.all(kitCastRoom - _dialogInset),
    child: NeumorphicDialog(
      title: 'Keep this time?',
      message: 'Your reminder will be ready tomorrow morning.',
      actions: [
        NeumorphicButton('Not now', onPressed: () {}),
        NeumorphicButton.filled('Keep it', onPressed: () {}),
      ],
    ),
  ),
  height: 420,
);

/// The width the look's sheet route gives a sheet on a window wider than a phone: on a wide stage the sheet stands at
/// it, as an app's would, rather than spanning the whole band.
const double _sheetWidth = 560;

Widget kitSpecimenSheet() => _raised(
  ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _sheetWidth),
    child: NeumorphicBottomSheet(
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

// The band's 390 less a cast's room above and below: the field and the open menu show whole.
Widget kitSpecimenMenu() => SizedBox(
  height: 390 - 2 * kitCastRoom,
  child: Stack(
    clipBehavior: Clip.none,
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
    // A snack bar's own margin on its small screen: the screen's edge is the display's, which ends its cast.
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
