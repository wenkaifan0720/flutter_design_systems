// Buttons and links: the page's one action, the actions beside it, the
// start of a service, the destructive one, and links in words.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitActionsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Buttons & links',
  intro:
      'A button says what happens next. Its face stands on a solid edge, '
      'which a press sinks onto; there is no other shadow anywhere.',
  sections: const [_Buttons(), _Group(), _IconButtons(), _Links()],
);

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Buttons',
    children: [
      CivicButton.start(onPressed: () {}, child: const Text('Start now')),
      CivicButton(onPressed: () {}, child: const Text('Continue')),
      CivicButton.secondary(
        onPressed: () {},
        child: const Text('Save and come back later'),
      ),
      CivicButton(
        onPressed: () {},
        isDestructiveAction: true,
        child: const Text('Cancel application'),
      ),
      const CivicButton(onPressed: null, child: Text('Send application')),
      KitFocused(
        builder: (c) => CivicButton(
          onPressed: () {},
          statesController: c,
          child: const Text('Continue (focused)'),
        ),
      ),
      Wrap(
        spacing: CivicSpacing.s16,
        runSpacing: CivicSpacing.s16,
        children: [
          CivicButton(
            onPressed: () {},
            expand: false,
            child: const Text('Accept and send'),
          ),
          CivicButton.secondary(
            onPressed: () {},
            expand: false,
            child: const Text('Cancel'),
          ),
        ],
      ),
    ],
  );
}

class _IconButtons extends StatelessWidget {
  const _IconButtons();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Icon buttons',
    caption: 'Each says what it does to a screen reader.',
    children: [
      Wrap(
        spacing: CivicSpacing.s8,
        children: [
          CivicIconButton(
            icon: LucideIcons.menu,
            semanticLabel: 'Menu',
            onPressed: () {},
          ),
          CivicIconButton(
            icon: LucideIcons.printer,
            semanticLabel: 'Print this page',
            onPressed: () {},
          ),
          KitFocused(
            builder: (c) => CivicIconButton(
              icon: LucideIcons.x,
              semanticLabel: 'Close',
              statesController: c,
              onPressed: () {},
            ),
          ),
          const CivicIconButton(
            icon: LucideIcons.trash2,
            semanticLabel: 'Remove',
            onPressed: null,
          ),
        ],
      ),
    ],
  );
}

class _Links extends StatelessWidget {
  const _Links();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Links',
    children: [
      CivicBackLink(onPressed: () {}),
      CivicLink(
        onPressed: () {},
        child: const Text('Read the guidance on permit zones'),
      ),
      KitFocused(
        builder: (c) => CivicLink(
          onPressed: () {},
          statesController: c,
          child: const Text('Change your address'),
        ),
      ),
      CivicLink.quiet(
        onPressed: () {},
        child: const Text('Accessibility statement'),
      ),
    ],
  );
}

class _Group extends StatelessWidget {
  const _Group();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Button group',
    caption: 'The acts that end a page: they stack on a phone.',
    children: [
      CivicButtonGroup(
        children: [
          CivicButton(onPressed: () {}, child: const Text('Save and continue')),
          CivicLink(
            onPressed: () {},
            child: const Text('Save and come back later'),
          ),
        ],
      ),
    ],
  );
}
