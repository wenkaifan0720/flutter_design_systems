/// Gloss's overlays: the dialog, the sheet and the toast.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The overlays page.
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Overlays',
  sections: const [
    KitSection(
      title: 'Open one',
      note: 'A dialog, a sheet from the foot or the side, an action sheet, a toast.',
      children: [_Open()],
    ),
    KitSection(
      title: 'A dialog, at rest',
      children: [
        // A picture of one: its safe key takes no focus from the page.
        ExcludeFocus(
          child: GlossDialog(
            title: 'Delete this week’s plan?',
            content: Text('The 7 dinners in it go back to your recipes.'),
            actions: [
              GlossDialogAction(label: 'Keep', onPressed: _none),
              GlossDialogAction(
                label: 'Delete',
                onPressed: _none,
                primary: true,
                destructive: true,
              ),
            ],
          ),
        ),
      ],
    ),
    KitSection(title: 'Menus, popovers and tips', children: [_Anchored()]),
  ],
);

void _none() {}

class _Open extends StatelessWidget {
  const _Open();

  @override
  Widget build(BuildContext context) => KitRow(
    children: [
      GlossButton(
        'Dialog',
        onPressed: () => showGlossDialog<void>(
          context: context,
          builder: (context) => GlossDialog(
            title: 'Delete this week’s plan?',
            content: const Text('The 7 dinners in it go back to your recipes.'),
            actions: [
              GlossDialogAction(
                label: 'Keep',
                onPressed: () => Navigator.of(context).pop(),
              ),
              GlossDialogAction(
                label: 'Delete',
                primary: true,
                destructive: true,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
      GlossButton(
        'Sheet',
        onPressed: () => showGlossSheet<void>(
          context: context,
          title: 'Filters',
          builder: (context) => const Text('Diets, time and cuisine.'),
        ),
      ),
      GlossButton(
        'Toast',
        onPressed: () => showGlossToast(
          context,
          'Added to Thursday',
          actionLabel: 'Undo',
          onAction: () {},
        ),
      ),
      GlossButton(
        'Side sheet',
        onPressed: () => showGlossSideSheet<void>(
          context: context,
          title: 'Filters',
          builder: (context) => const Text('Courses, time, diet'),
        ),
      ),
      GlossButton(
        'Action sheet',
        onPressed: () => showGlossActionSheet<String>(
          context: context,
          title: 'Lemon risotto',
          actions: const [
            GlossSheetAction(label: 'Add to plan', value: 'plan'),
            GlossSheetAction(label: 'Share', value: 'share'),
            GlossSheetAction(
              label: 'Delete',
              value: 'delete',
              isDestructiveAction: true,
            ),
          ],
        ),
      ),
    ],
  );
}

class _Anchored extends StatelessWidget {
  const _Anchored();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: GlossSpacing.medium,
    runSpacing: GlossSpacing.medium,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      GlossMenu(
        items: [
          GlossMenuItem(label: 'Share', onPressed: () {}),
          GlossMenuItem(label: 'Duplicate', onPressed: () {}),
          GlossMenuItem(
            label: 'Delete',
            isDestructiveAction: true,
            onPressed: () {},
          ),
        ],
        builder: (context, toggle, open) =>
            GlossButton('More', onPressed: toggle),
      ),
      GlossPopover(
        builder: (context, toggle, open) =>
            GlossButton('Servings', onPressed: toggle),
        content: (context, close) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How many are eating?'),
            const SizedBox(height: GlossSpacing.small),
            GlossStepper(
              value: 4,
              onChanged: (_) {},
              semanticLabel: 'Servings',
            ),
          ],
        ),
      ),
      // A hover card rides on a link in running words.
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Point at '),
          GlossHoverCard(
            content: (context) => const Text('35 min, serves 4. Keeps 3 days.'),
            child: GlossLink('Lemon risotto', onPressed: () {}),
          ),
          const Text(' for its card'),
        ],
      ),
      GlossTooltip(
        message: 'Save to your recipes',
        child: GlossIconButton(
          onPressed: () {},
          tooltip: 'Save',
          icon: const Icon(LucideIcons.heart),
        ),
      ),
    ],
  );
}
