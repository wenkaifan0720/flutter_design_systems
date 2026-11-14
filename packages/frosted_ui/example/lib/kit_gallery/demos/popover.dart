/// [FrostedPopover]: a panel of controls opened from its trigger and
/// closed by Escape or a press outside; [FrostedHoverCard]: a preview
/// shown while the pointer rests on its trigger.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitPopoverDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Popover',
  sections: [
    kitSection(
      'Popover',
      children: [
        kitRow([
          KitHeld<bool>(
            false,
            (unread, set) => FrostedPopover(
              label: 'Filter',
              builder: (context, controller, _) => FrostedButton.glass(
                'Filter',
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: FrostedSpacing.s12,
                children: [
                  FrostedSwitchRow(
                    label: 'Only unread',
                    value: unread,
                    onChanged: set,
                  ),
                  const FrostedTextField(label: 'From'),
                ],
              ),
            ),
          ),
        ]),
      ],
    ),
    kitSection('Open, as it stands', children: [const _OpenPopover()]),
    kitSection(
      'Hover card: rest a pointer on @maya',
      children: [
        kitRow([
          FrostedHoverCard(
            label: 'Maya Chen',
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: FrostedSpacing.s4,
              children: [
                Text('Maya Chen'),
                Text('Design lead · joined March 2024'),
              ],
            ),
            child: FrostedLink('@maya', link: '@maya', onPressed: () {}),
          ),
        ]),
      ],
    ),
  ],
);

/// A popover opened as the page arrives, so the panel shows without a
/// press; a press outside or Escape closes it as any popover's.
class _OpenPopover extends StatefulWidget {
  const _OpenPopover();

  @override
  State<_OpenPopover> createState() => _OpenPopoverState();
}

class _OpenPopoverState extends State<_OpenPopover> {
  final _controller = MenuController();
  var _soon = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.open();
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    // Room under the trigger for the panel.
    height: 260,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: FrostedPopover(
        label: 'Reminders',
        controller: _controller,
        builder: (context, controller, _) => FrostedButton.glass(
          'Remind me',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
        content: FrostedSwitchRow(
          label: 'A day before it is due',
          value: _soon,
          onChanged: (v) => setState(() => _soon = v),
        ),
      ),
    ),
  );
}
