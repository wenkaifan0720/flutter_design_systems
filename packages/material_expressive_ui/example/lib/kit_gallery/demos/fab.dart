/// The fab group's demo: the floating action button in its three sizes and
/// six colour styles, the extended FAB (sizes, lowered, collapsing as a list
/// scrolls), the FAB menu — the page's one hero moment, in each colour
/// family and optionally dimming the page — and the shell's action drawing
/// each kind of spec.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';

/// The fab group's demo, in [brightness].
Widget kitFabDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Floating action button',
  sections: const <Widget>[
    _Sizes(),
    _Colors(),
    _Extended(),
    _Scroll(),
    _Menu(),
    _ShellAction(),
  ],
);

void _none() {}

/// [child] over its caption.
Widget _captioned(BuildContext context, String caption, Widget child) {
  final t = context.expressiveTheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      child,
      // Clear of the button's shadow, so the caption sits on the page.
      const SizedBox(height: ExpressiveSpacing.s16),
      Text(
        caption,
        style: t.type.labelMedium.copyWith(color: t.colors.onSurfaceVariant),
      ),
    ],
  );
}

class _Sizes extends StatelessWidget {
  const _Sizes();

  @override
  Widget build(BuildContext context) => kitSection(
    'Sizes · FAB, medium and large',
    children: <Widget>[
      Wrap(
        spacing: ExpressiveSpacing.s16,
        runSpacing: ExpressiveSpacing.s16,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          _captioned(
            context,
            'FAB',
            const ExpressiveFloatingActionButton(
              icon: ExpressiveSymbols.edit,
              semanticLabel: 'Write',
              onPressed: _none,
            ),
          ),
          _captioned(
            context,
            'Medium',
            const ExpressiveFloatingActionButton(
              icon: ExpressiveSymbols.add,
              semanticLabel: 'Add a habit',
              size: ExpressiveFabSize.medium,
              onPressed: _none,
            ),
          ),
          _captioned(
            context,
            'Large',
            const ExpressiveFloatingActionButton(
              icon: ExpressiveSymbols.photoCamera,
              semanticLabel: 'Take a photo',
              size: ExpressiveFabSize.large,
              onPressed: _none,
            ),
          ),
        ],
      ),
    ],
  );
}

class _Colors extends StatelessWidget {
  const _Colors();

  static const List<(String, ExpressiveFabColor, IconData)> _container = [
    ('Primary', ExpressiveFabColor.primaryContainer, ExpressiveSymbols.edit),
    ('Secondary', ExpressiveFabColor.secondaryContainer, ExpressiveSymbols.mic),
    ('Tertiary', ExpressiveFabColor.tertiaryContainer, ExpressiveSymbols.map),
  ];

  static const List<(String, ExpressiveFabColor, IconData)> _vibrant = [
    ('Primary', ExpressiveFabColor.primary, ExpressiveSymbols.edit),
    ('Secondary', ExpressiveFabColor.secondary, ExpressiveSymbols.mic),
    ('Tertiary', ExpressiveFabColor.tertiary, ExpressiveSymbols.map),
  ];

  Widget _row(
    BuildContext context,
    List<(String, ExpressiveFabColor, IconData)> styles,
  ) => Wrap(
    spacing: ExpressiveSpacing.s24,
    runSpacing: ExpressiveSpacing.s16,
    children: <Widget>[
      for (final (name, color, icon) in styles)
        _captioned(
          context,
          name,
          ExpressiveFloatingActionButton(
            icon: icon,
            color: color,
            semanticLabel: name,
            onPressed: _none,
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => kitSection(
    'Colour styles — container and vibrant',
    children: <Widget>[
      _row(context, _container),
      _row(context, _vibrant),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: _captioned(
          context,
          'Lowered',
          const ExpressiveFloatingActionButton(
            icon: ExpressiveSymbols.navigation,
            semanticLabel: 'Directions',
            lowered: true,
            onPressed: _none,
          ),
        ),
      ),
    ],
  );
}

class _Extended extends StatefulWidget {
  const _Extended();

  @override
  State<_Extended> createState() => _ExtendedState();
}

class _ExtendedState extends State<_Extended> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'Extended — tap the first to fold it',
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ExpressiveFloatingActionButton.extended(
          icon: ExpressiveSymbols.edit,
          label: 'New entry',
          expanded: _expanded,
          onPressed: () => setState(() => _expanded = !_expanded),
        ),
      ),
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: ExpressiveFloatingActionButton.extended(
          icon: ExpressiveSymbols.taskAlt,
          label: 'Check in',
          size: ExpressiveFabSize.medium,
          color: ExpressiveFabColor.secondaryContainer,
          onPressed: _none,
        ),
      ),
      const Align(
        alignment: AlignmentDirectional.centerStart,
        child: ExpressiveFloatingActionButton.extended(
          icon: ExpressiveSymbols.send,
          label: 'Send',
          size: ExpressiveFabSize.large,
          color: ExpressiveFabColor.tertiary,
          onPressed: _none,
        ),
      ),
    ],
  );
}

class _Scroll extends StatelessWidget {
  const _Scroll();

  static const List<(String, String)> _entries = [
    ('Morning pages', 'Three pages, no editing'),
    ('Walk to the river', '42 minutes'),
    ('Read before bed', 'Chapter 7 of 12'),
    ('Stretch', 'Ten minutes, slow'),
    ('No phone at dinner', 'Kept for 5 days'),
    ('Water the herbs', 'Basil, mint, thyme'),
    ('Call Grandma', 'Sundays'),
    ('Evening review', 'What went well'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    return kitSection(
      'Folds as the list scrolls down, returns as it scrolls up',
      children: <Widget>[
        SizedBox(
          height: ExpressiveSpacing.s72 * 4,
          child: ExpressiveSurface(
            shape: t.shapes.large,
            color: c.surfaceContainerLow,
            contentColor: c.onSurface,
            child: ExpressiveFabScrollExpansion(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  ExpressiveSpacing.s16,
                  ExpressiveSpacing.s8,
                  ExpressiveSpacing.s16,
                  ExpressiveSpacing.s72 + ExpressiveSpacing.s16,
                ),
                children: <Widget>[
                  for (final (title, detail) in _entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: ExpressiveSpacing.s12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.type.bodyLarge,
                          ),
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.type.bodyMedium.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              builder: (context, expanded, list) => Stack(
                children: <Widget>[
                  Positioned.fill(child: list),
                  PositionedDirectional(
                    end: ExpressiveSpacing.s16,
                    bottom: ExpressiveSpacing.s16,
                    child: ExpressiveFloatingActionButton.extended(
                      icon: ExpressiveSymbols.add,
                      label: 'New habit',
                      expanded: expanded,
                      onPressed: _none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Menu extends StatefulWidget {
  const _Menu();

  @override
  State<_Menu> createState() => _MenuState();
}

/// The FAB menu in each colour family — `vibrant` wears primary on the
/// toggle, the close button and the items, for a page whose surfaces sit too
/// close to the containers — and, switched on, dimming the page behind it
/// with the scrim role while it is open (tap the scrim to close it). The
/// page holds it (`expanded` / `onExpandedChanged`, as an app does to open
/// it once and show what it offers): "Show it from the page" opens it with
/// its own motion.
class _MenuState extends State<_Menu> {
  ExpressiveFabMenuColor _color = ExpressiveFabMenuColor.primary;
  bool _scrim = false;

  /// Open on the first frame unless it dims the page, so the demo never
  /// lands dimmed.
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'FAB menu — this page\'s hero moment',
      children: <Widget>[
        ExpressiveSegmentedButton<ExpressiveFabMenuColor>(
          segments: <ExpressiveButtonSegment<ExpressiveFabMenuColor>>[
            for (final color in <ExpressiveFabMenuColor>[
              ExpressiveFabMenuColor.primary,
              ExpressiveFabMenuColor.secondary,
              ExpressiveFabMenuColor.tertiary,
              ExpressiveFabMenuColor.vibrant,
            ])
              ExpressiveButtonSegment<ExpressiveFabMenuColor>(
                color,
                '${color.name[0].toUpperCase()}${color.name.substring(1)}',
              ),
          ],
          value: _color,
          onChanged: (next) => setState(() => _color = next),
        ),
        ExpressiveSwitchRow(
          label: 'Dim the page while open',
          value: _scrim,
          onChanged: (value) => setState(() {
            _scrim = value;
            _open = !value;
          }),
        ),
        ExpressiveTextButton(
          'Show it from the page',
          onPressed: _open ? null : () => setState(() => _open = true),
        ),
        ExpressiveSurface(
          shape: t.shapes.large,
          color: t.colors.surfaceContainerLow,
          contentColor: t.colors.onSurface,
          child: SizedBox(
            height: ExpressiveSpacing.s72 * 5,
            child: Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: ExpressiveHeroMoment(
                label: 'FAB menu',
                child: ExpressiveFabMenu(
                  key: ValueKey<Object>((_color, _scrim)),
                  icon: ExpressiveSymbols.add,
                  semanticLabel: 'Create',
                  color: _color,
                  scrim: _scrim,
                  overlayItems: _scrim,
                  expanded: _open,
                  onExpandedChanged: (open) => setState(() => _open = open),
                  items: <ExpressiveFabMenuItem>[
                    ExpressiveFabMenuItem(
                      icon: ExpressiveSymbols.photoCamera,
                      label: 'Photo',
                      onPressed: (_) {},
                    ),
                    ExpressiveFabMenuItem(
                      icon: ExpressiveSymbols.mic,
                      label: 'Voice note',
                      onPressed: (_) {},
                    ),
                    ExpressiveFabMenuItem(
                      icon: ExpressiveSymbols.checklist,
                      label: 'Checklist',
                      onPressed: (_) {},
                    ),
                    ExpressiveFabMenuItem(
                      icon: ExpressiveSymbols.description,
                      label: 'Note',
                      onPressed: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ShellAction extends StatelessWidget {
  const _ShellAction();

  @override
  Widget build(BuildContext context) => kitSection(
    'The shell\'s action — what ExpressiveShell draws',
    children: <Widget>[
      Wrap(
        spacing: ExpressiveSpacing.s24,
        runSpacing: ExpressiveSpacing.s16,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: <Widget>[
          _captioned(
            context,
            'Default',
            ExpressiveShellAction(
              action: ShellAction(
                icon: ExpressiveSymbols.add,
                label: 'New habit',
                onPressed: (_) {},
              ),
            ),
          ),
          _captioned(
            context,
            'Accent',
            ExpressiveShellAction(
              action: ShellAction(
                icon: ExpressiveSymbols.add,
                label: 'New habit',
                accent: true,
                onPressed: (_) {},
              ),
            ),
          ),
          _captioned(
            context,
            'Labelled',
            ExpressiveShellAction(
              action: ExpressiveShellAction(
                icon: ExpressiveSymbols.taskAlt,
                label: 'Check in',
                onPressed: (_) {},
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// The standard FAB on primary container.
Widget kitSpecimenFabStandard() => const Center(
  child: ExpressiveFloatingActionButton(
    icon: ExpressiveSymbols.edit,
    semanticLabel: 'Write a note',
    onPressed: _none,
  ),
);

/// The extended FAB: the glyph and its label.
Widget kitSpecimenExtendedFabCompose() => const Center(
  child: ExpressiveFloatingActionButton.extended(
    icon: ExpressiveSymbols.edit,
    label: 'Compose',
    onPressed: _none,
  ),
);

/// The FAB menu open: three related acts over the close button (a hero
/// widget, so in its hero).
Widget kitSpecimenFabMenuOpen() => SafeArea(
  child: Align(
    alignment: AlignmentDirectional.bottomEnd,
    child: ExpressiveHeroMoment(
      child: ExpressiveFabMenu(
        icon: ExpressiveSymbols.add,
        semanticLabel: 'New',
        initiallyExpanded: true,
        items: <ExpressiveFabMenuItem>[
          ExpressiveFabMenuItem(
            icon: ExpressiveSymbols.mic,
            label: 'Voice note',
            onPressed: (_) {},
          ),
          ExpressiveFabMenuItem(
            icon: ExpressiveSymbols.photoCamera,
            label: 'Photo',
            onPressed: (_) {},
          ),
          ExpressiveFabMenuItem(
            icon: ExpressiveSymbols.checklist,
            label: 'Checklist',
            onPressed: (_) {},
          ),
        ],
      ),
    ),
  ),
);
