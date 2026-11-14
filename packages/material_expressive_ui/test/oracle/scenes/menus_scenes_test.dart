/// The `menus` oracle group (Compose twin: `MenusScenes.kt`): the segmented
/// Expressive menu inline (standard with a label, a disabled item and
/// supporting text; selectable; vibrant), the alert dialog, and the plain
/// and rich tooltips.
///
/// The oracle app bundles no symbol font, so no scene carries an icon but
/// the selectable menu's check, which Compose holds as an empty 20 dp slot:
/// its glyph is the one expected pixel difference. The dialog and the
/// tooltips render without their window (Compose's `AlertDialogContent` is
/// internal and `TooltipScope` sealed; the Compose side recreates them from
/// their public defaults).
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../harness/oracle.dart';

void _none() {}

final OracleGroup menusScenes = OracleGroup(
  id: 'menus',
  scenes: [
    OracleScene(
      key: 'menus/menu/standard',
      size: const Size(152, 224),
      build: (context) => OracleTag(
        'menu',
        child: ExpressiveMenuSurface(
          groups: <ExpressiveMenuGroup>[
            const ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              ExpressiveMenuItem(
                'Copy',
                trailingText: 'Ctrl+C',
                onPressed: _none,
              ),
              ExpressiveMenuItem('Paste', trailingText: 'Ctrl+V'),
            ], label: 'Edit'),
            const ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              ExpressiveMenuItem(
                'Share',
                supportingText: 'Send a link',
                onPressed: _none,
              ),
            ]),
          ],
        ),
      ),
    ),
    OracleScene(
      key: 'menus/menu/selectable',
      size: const Size(152, 168),
      build: (context) => OracleTag(
        'menu',
        child: ExpressiveMenuSurface(
          groups: <ExpressiveMenuGroup>[
            ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              for (final name in <String>['Date', 'Name', 'Size'])
                ExpressiveMenuRadioItem(
                  name,
                  selected: name == 'Date',
                  onSelected: _none,
                ),
            ]),
          ],
        ),
      ),
    ),
    OracleScene(
      key: 'menus/menu/vibrant',
      size: const Size(152, 128),
      build: (context) => OracleTag(
        'menu',
        child: const ExpressiveHeroMoment(
          label: 'oracle',
          child: ExpressiveMenuSurface(
            vibrant: true,
            groups: <ExpressiveMenuGroup>[
              ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                ExpressiveMenuItem('Favourite', onPressed: _none),
              ]),
              ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                ExpressiveMenuItem('Delete', onPressed: _none),
              ]),
            ],
          ),
        ),
      ),
    ),
    OracleScene(
      key: 'menus/dialog/basic',
      size: const Size(400, 208),
      build: (context) => const OracleTag(
        'dialog',
        child: ExpressiveDialog(
          title: 'Discard draft?',
          text: 'Your changes to this message will be lost for good.',
          actions: <ExpressiveDialogAction>[
            ExpressiveDialogAction('Cancel'),
            ExpressiveDialogAction('Discard'),
          ],
        ),
      ),
    ),
    OracleScene(
      key: 'menus/tooltip/plain',
      size: const Size(136, 40),
      build: (context) => const OracleTag(
        'tooltip',
        child: ExpressivePlainTooltip('Add to favourites'),
      ),
    ),
    OracleScene(
      key: 'menus/tooltip/rich',
      size: const Size(344, 176),
      build: (context) => OracleTag(
        'tooltip',
        child: ExpressiveRichTooltip(
          title: 'Offline mode',
          text: 'Saved pages stay readable when you lose your connection.',
          actionLabel: 'Learn more',
          onAction: _none,
        ),
      ),
    ),
  ],
);

void main() => runOracleGroup(menusScenes);
