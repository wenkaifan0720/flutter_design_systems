/// The menus group's demo: the segmented Expressive menu inline — standard
/// groups with labels, shortcuts, dividers, supporting text and a disabled
/// item, the selectable check and radio items, the vibrant menu on the
/// hero — then the live anchors: a tap menu with a submenu, a hold-for
/// context menu, a controlled menu and the popover.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The menus group's demo, in [brightness].
Widget kitMenusDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Menus',
  sections: const <Widget>[
    _Standard(),
    _Selectable(),
    _Vibrant(),
    _Live(),
    _Popover(),
    _MultiSelect(),
    _MenuBars(),
  ],
);

/// A menu surface at its own width, not stretched across the page.
Widget _inline(Widget menu) =>
    Align(alignment: AlignmentDirectional.centerStart, child: menu);

class _Standard extends StatelessWidget {
  const _Standard();

  @override
  Widget build(BuildContext context) => kitSection(
    'Standard',
    children: <Widget>[
      _inline(
        ExpressiveMenuSurface(
          groups: <ExpressiveMenuGroup>[
            ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              ExpressiveMenuItem(
                'Copy',
                icon: ExpressiveSymbols.contentCopy,
                trailingText: 'Ctrl+C',
                onPressed: () {},
              ),
              const ExpressiveMenuItem(
                'Paste',
                icon: ExpressiveSymbols.draft,
                trailingText: 'Ctrl+V',
              ),
              ExpressiveMenuItem(
                'Select all',
                icon: ExpressiveSymbols.checklist,
                trailingText: 'Ctrl+A',
                onPressed: () {},
              ),
            ], label: 'Edit'),
            ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              ExpressiveMenuItem(
                'Share',
                icon: ExpressiveSymbols.share,
                supportingText: 'Send a link to anyone',
                onPressed: () {},
              ),
              const ExpressiveMenuDivider(),
              ExpressiveMenuItem(
                'Open in new window',
                icon: ExpressiveSymbols.openInNew,
                onPressed: () {},
              ),
            ]),
          ],
        ),
      ),
    ],
  );
}

class _Selectable extends StatefulWidget {
  const _Selectable();

  @override
  State<_Selectable> createState() => _SelectableState();
}

class _SelectableState extends State<_Selectable> {
  String _sort = 'Date';
  bool _hidden = false;
  bool _grid = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'Selectable items',
    children: <Widget>[
      _inline(
        ExpressiveMenuSurface(
          groups: <ExpressiveMenuGroup>[
            ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              for (final (name, icon) in <(String, IconData)>[
                ('Date', ExpressiveSymbols.calendarToday),
                ('Name', ExpressiveSymbols.sort),
                ('Size', ExpressiveSymbols.barChart),
              ])
                ExpressiveMenuRadioItem(
                  name,
                  icon: icon,
                  selected: _sort == name,
                  onSelected: () => setState(() => _sort = name),
                ),
            ], label: 'Sort by'),
            ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              ExpressiveMenuCheckItem(
                'Show hidden files',
                icon: ExpressiveSymbols.visibility,
                value: _hidden,
                onChanged: (v) => setState(() => _hidden = v),
              ),
              ExpressiveMenuCheckItem(
                'Grid view',
                icon: ExpressiveSymbols.gridView,
                value: _grid,
                onChanged: (v) => setState(() => _grid = v),
              ),
            ], label: 'View'),
          ],
        ),
      ),
    ],
  );
}

class _Vibrant extends StatelessWidget {
  const _Vibrant();

  @override
  Widget build(BuildContext context) => kitSection(
    'Vibrant, the hero moment',
    children: <Widget>[
      _inline(
        ExpressiveHeroMoment(
          label: 'photo actions',
          child: ExpressiveMenuSurface(
            vibrant: true,
            groups: <ExpressiveMenuGroup>[
              ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                ExpressiveMenuItem(
                  'Favourite',
                  icon: ExpressiveSymbols.favorite,
                  onPressed: () {},
                ),
                ExpressiveMenuItem(
                  'Add to album',
                  icon: ExpressiveSymbols.photoLibrary,
                  onPressed: () {},
                ),
              ]),
              ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                ExpressiveMenuItem(
                  'Delete',
                  icon: ExpressiveSymbols.delete,
                  onPressed: () {},
                ),
              ]),
            ],
          ),
        ),
      ),
    ],
  );
}

/// A demo trigger: a pill on the tonal container. The buttons family is its
/// own item; this demo keeps to what the menus family and the foundations
/// provide.
class _Trigger extends StatelessWidget {
  const _Trigger(this.label, {required this.icon, this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressivePressable(
      shapes: ExpressivePressShapes.all(t.shapes.full),
      motion: ExpressiveMotionKey.fastSpatial,
      color: t.colors.secondaryContainer,
      contentColor: t.colors.onSecondaryContainer,
      // A live button even when only a long press or a secondary click
      // answers it (the context menu's trigger): hover, press and keyboard
      // focus show on it as on any button.
      onPressed: onPressed ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ExpressiveSpacing.s16,
          vertical: ExpressiveSpacing.s12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ExpressiveIcon(icon),
            const SizedBox(width: ExpressiveSpacing.s8),
            Flexible(child: Text(label, style: t.type.labelLarge)),
          ],
        ),
      ),
    );
  }
}

class _Live extends StatefulWidget {
  const _Live();

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  final ExpressiveMenuController _controller = ExpressiveMenuController();
  String _last = 'Nothing chosen yet';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _chose(String what) => setState(() => _last = 'Chose $what');

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Live menus',
      children: <Widget>[
        Wrap(
          spacing: kitGap,
          runSpacing: kitGap,
          children: <Widget>[
            ExpressiveMenu(
              label: 'Project',
              groups: <ExpressiveMenuGroup>[
                ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                  ExpressiveMenuItem(
                    'Rename',
                    icon: ExpressiveSymbols.edit,
                    onPressed: () => _chose('Rename'),
                  ),
                  ExpressiveMenuItem(
                    'Duplicate',
                    icon: ExpressiveSymbols.contentCopy,
                    onPressed: () => _chose('Duplicate'),
                  ),
                  ExpressiveMenuSubmenu(
                    'Move to',
                    icon: ExpressiveSymbols.folder,
                    groups: <ExpressiveMenuGroup>[
                      ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                        for (final place in <String>['Inbox', 'Work', 'Home'])
                          ExpressiveMenuItem(
                            place,
                            onPressed: () => _chose('Move to $place'),
                          ),
                      ]),
                    ],
                  ),
                ]),
                ExpressiveMenuGroup(<ExpressiveMenuEntry>[
                  ExpressiveMenuItem(
                    'Archive',
                    icon: ExpressiveSymbols.archive,
                    onPressed: () => _chose('Archive'),
                  ),
                ]),
              ],
              builder: (context, menu) => _Trigger(
                'Menu',
                icon: ExpressiveSymbols.moreVert,
                onPressed: menu.toggle,
              ),
            ),
            ExpressiveMenu(
              trigger: ExpressiveMenuTrigger.longPress,
              label: 'Message',
              entries: <ExpressiveMenuEntry>[
                ExpressiveMenuItem(
                  'Reply',
                  icon: ExpressiveSymbols.reply,
                  onPressed: () => _chose('Reply'),
                ),
                ExpressiveMenuItem(
                  'Pin',
                  icon: ExpressiveSymbols.pushPin,
                  onPressed: () => _chose('Pin'),
                ),
              ],
              child: const _Trigger(
                'Hold for context menu',
                icon: ExpressiveSymbols.chatBubble,
              ),
            ),
            ExpressiveMenu(
              controller: _controller,
              position: ExpressiveMenuPosition.end,
              entries: <ExpressiveMenuEntry>[
                ExpressiveMenuItem(
                  'Refresh',
                  icon: ExpressiveSymbols.refresh,
                  onPressed: () => _chose('Refresh'),
                ),
              ],
              builder: (context, menu) => _Trigger(
                'Controlled',
                icon: ExpressiveSymbols.tune,
                onPressed: _controller.toggle,
              ),
            ),
          ],
        ),
        Text(_last, style: TextStyle(color: t.colors.onSurfaceVariant)),
      ],
    );
  }
}

class _Popover extends StatelessWidget {
  const _Popover();

  @override
  Widget build(BuildContext context) => kitSection(
    'Popover',
    children: <Widget>[
      _inline(const ExpressivePopoverSurface(child: _PopoverBody())),
      Wrap(
        spacing: ExpressiveSpacing.s12,
        runSpacing: ExpressiveSpacing.s12,
        children: <Widget>[
          ExpressivePopover(
            label: 'Storage',
            content: (context) => const _PopoverBody(),
            builder: (context, popover) => _Trigger(
              'Show popover',
              icon: ExpressiveSymbols.info,
              onPressed: popover.toggle,
            ),
          ),
          // The same popover raised from code, against the trigger's box.
          Builder(
            builder: (context) => _Trigger(
              'Show from code',
              icon: ExpressiveSymbols.info,
              onPressed: () => showExpressivePopover(
                context,
                label: 'Storage',
                builder: (context) => const _PopoverBody(),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _PopoverBody extends StatelessWidget {
  const _PopoverBody();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Storage', style: t.type.titleMedium),
        const SizedBox(height: ExpressiveSpacing.s4),
        Text(
          '12.4 GB of 15 GB used.\nPhotos take the most room.',
          style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// An open menu: edit actions with their shortcuts, one disabled.
Widget kitSpecimenMenuEdit() => Center(
  child: ExpressiveMenuSurface(
    groups: <ExpressiveMenuGroup>[
      ExpressiveMenuGroup(<ExpressiveMenuEntry>[
        ExpressiveMenuItem(
          'Copy',
          icon: ExpressiveSymbols.contentCopy,
          trailingText: 'Ctrl+C',
          onPressed: () {},
        ),
        const ExpressiveMenuItem(
          'Paste',
          icon: ExpressiveSymbols.draft,
          trailingText: 'Ctrl+V',
        ),
        ExpressiveMenuItem(
          'Select all',
          icon: ExpressiveSymbols.checklist,
          trailingText: 'Ctrl+A',
          onPressed: () {},
        ),
      ]),
    ],
  ),
);

const List<ExpressiveSelectOption<String>> _topics =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption('design', 'Design'),
      ExpressiveSelectOption('research', 'Research'),
      ExpressiveSelectOption('writing', 'Writing'),
      ExpressiveSelectOption('photography', 'Photography'),
      ExpressiveSelectOption('travel', 'Travel'),
    ];

class _MultiSelect extends StatefulWidget {
  const _MultiSelect();

  @override
  State<_MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<_MultiSelect> {
  List<String> _chosen = <String>['design', 'writing'];

  @override
  Widget build(BuildContext context) => kitSection(
    'Multi-select · chips in the field, type to filter',
    children: <Widget>[
      // The field's visible label comes from the form field around it (the
      // multi-select's own label is its name for a screen reader).
      ExpressiveFormField(
        label: 'Topics',
        help: 'Type to filter; Backspace steps onto the chips.',
        child: ExpressiveMultiSelect<String>(
          label: 'Topics',
          hintText: 'Add a topic',
          options: _topics,
          values: _chosen,
          onChanged: (v) => setState(() => _chosen = v),
        ),
      ),
    ],
  );
}

/// Two topics chosen in the field.
Widget kitSpecimenMultiSelectTags() => ExpressiveMultiSelect<String>(
  label: 'Topics',
  hintText: 'Add a topic',
  options: _topics,
  values: const <String>['design', 'writing'],
  onChanged: (_) {},
);

class _MenuBars extends StatelessWidget {
  const _MenuBars();

  @override
  Widget build(BuildContext context) => kitSection(
    'Menu bar · menus that open one from the next',
    children: <Widget>[kitSpecimenMenuBar()],
  );
}

/// File, Edit and View, closed.
Widget kitSpecimenMenuBar() => Align(
  alignment: AlignmentDirectional.centerStart,
  child: ExpressiveMenuBar(
    menus: <ExpressiveMenuBarEntry>[
      ExpressiveMenuBarEntry(
        'File',
        children: <ExpressiveMenuBarEntry>[
          ExpressiveMenuBarEntry('New', shortcut: 'Ctrl N', onPressed: () {}),
          ExpressiveMenuBarEntry('Open…', shortcut: 'Ctrl O', onPressed: () {}),
          const ExpressiveMenuBarEntry.divider(),
          ExpressiveMenuBarEntry('Close', onPressed: () {}),
        ],
      ),
      ExpressiveMenuBarEntry(
        'Edit',
        children: <ExpressiveMenuBarEntry>[
          ExpressiveMenuBarEntry('Undo', shortcut: 'Ctrl Z', onPressed: () {}),
          ExpressiveMenuBarEntry('Redo', onPressed: () {}),
        ],
      ),
      ExpressiveMenuBarEntry(
        'View',
        children: <ExpressiveMenuBarEntry>[
          ExpressiveMenuBarEntry('Show ruler', checked: true, onPressed: () {}),
          ExpressiveMenuBarEntry('Show grid', checked: false, onPressed: () {}),
        ],
      ),
    ],
  ),
);
