/// Minimal's property register: the breadcrumb a record sits under, the
/// issue-style property list of Morning run (status cycles live, repeats
/// opens its own anchored menu, a widget value, an empty property, a
/// read-only row), and the create form's property pills — set, unset, one
/// with its own menu, disabled — alone and in the new-habit card they
/// belong to.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitPropertiesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Properties & breadcrumb',
  sections: [
    kitSection(
      'Breadcrumb',
      children: [
        // One stack of bands, each as tall as a tappable crumb's target and
        // no gap between them: the paths stand a row apart, not a section.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CrumbBand(
              Builder(
                builder: (context) => MinimalBreadcrumb(
                  crumbs: [
                    MinimalBreadcrumbItem(
                      'Habits',
                      onPressed: () =>
                          showMinimalSnackBar(context, 'Back to Habits'),
                    ),
                    const MinimalBreadcrumbItem('HAB-4', mono: true),
                  ],
                ),
              ),
            ),
            _CrumbBand(
              Builder(
                builder: (context) => MinimalBreadcrumb(
                  crumbs: [
                    MinimalBreadcrumbItem(
                      'Ritual',
                      onPressed: () =>
                          showMinimalSnackBar(context, 'Back to Ritual'),
                    ),
                    MinimalBreadcrumbItem(
                      'Morning',
                      onPressed: () =>
                          showMinimalSnackBar(context, 'Back to Morning'),
                    ),
                    const MinimalBreadcrumbItem('Morning run'),
                    const MinimalBreadcrumbItem('HAB-4', mono: true),
                  ],
                ),
              ),
            ),
            _CrumbBand(
              Builder(
                builder: (context) => MinimalBreadcrumb(
                  crumbs: [
                    MinimalBreadcrumbItem(
                      'HAB-4',
                      mono: true,
                      onPressed: () =>
                          showMinimalSnackBar(context, 'Back to HAB-4'),
                    ),
                    const MinimalBreadcrumbItem('Log'),
                  ],
                ),
              ),
            ),
            _CrumbBand(
              const MinimalBreadcrumb(
                crumbs: [
                  MinimalBreadcrumbItem('Orders'),
                  MinimalBreadcrumbItem('Standing'),
                  MinimalBreadcrumbItem(
                    'Café Morgen, weekly bread and pastry order',
                  ),
                  MinimalBreadcrumbItem('#1045', mono: true),
                ],
              ),
            ),
          ],
        ),
        kitNote(
          'Ancestors are quiet and tappable (an id ancestor stays mono); '
          'the current step is the ink. A path too long for the line '
          'shortens its longest step first.',
        ),
      ],
    ),
    kitSection(
      'Property list',
      children: [
        const _MorningRun(),
        kitNote(
          'Tap Status to cycle it; Repeats opens its own menu; Owner shows '
          'a face; Goal is empty; Started only reads.',
        ),
      ],
    ),
    kitSection(
      'Property pills',
      children: [
        const _Pills(),
        kitNote(
          'Every pill is the same outline: a set one draws its glyph and '
          "value in the ink, an unset one its glyph and the property's name "
          'in the quiet ink. Tap one to set or clear it. Area is disabled.',
        ),
      ],
    ),
    kitSection(
      'In the create card',
      children: [
        MinimalBottomSheet(
          title: 'New habit',
          subtitle: 'Habits',
          floating: true,
          closable: false,
          leading: const MinimalSheetAction('Cancel'),
          trailing: const MinimalSheetAction(
            'Create habit',
            isDefaultAction: true,
          ),
          child: Builder(
            builder: (context) {
              final t = context.minimalTheme;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const MinimalGap(MinimalSpacing.s8),
                  Text('Stretch before bed', style: t.h2),
                  const MinimalGap(MinimalSpacing.s4),
                  Text('Add a note…', style: t.body.c(t.textTertiary)),
                  const MinimalGap(MinimalSpacing.s16),
                  MinimalPropertyBar(
                    pills: [
                      MinimalPropertyPill(
                        icon: LucideIcons.repeat,
                        label: 'Every evening',
                        name: 'Repeats',
                        hasValue: true,
                        onPressed: () {},
                      ),
                      MinimalPropertyPill(
                        icon: LucideIcons.bell,
                        label: '21:30',
                        name: 'Reminder',
                        mono: true,
                        hasValue: true,
                        onPressed: () {},
                      ),
                      MinimalPropertyPill(
                        icon: LucideIcons.folder,
                        label: 'Evening',
                        name: 'Group',
                        hasValue: true,
                        onPressed: () {},
                      ),
                      MinimalPropertyPill(
                        icon: LucideIcons.target,
                        label: 'Goal',
                        onPressed: () {},
                      ),
                      MinimalPropertyPill(
                        icon: LucideIcons.calendar,
                        label: 'Start date',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  ],
);

/// Morning run's properties, the status cycling on tap.
class _MorningRun extends StatefulWidget {
  const _MorningRun();

  @override
  State<_MorningRun> createState() => _MorningRunState();
}

class _MorningRunState extends State<_MorningRun> {
  static const List<(String, MinimalTone)> _statuses = [
    ('Active', MinimalTone.success),
    ('Paused', MinimalTone.warning),
    ('Archived', MinimalTone.neutral),
  ];

  int _status = 0;
  String _repeat = 'Every day';

  @override
  Widget build(BuildContext context) {
    final (status, tone) = _statuses[_status];
    return MinimalDescriptionList(
      properties: [
        MinimalProperty(
          icon: LucideIcons.circleDot,
          label: 'Status',
          value: status,
          tone: tone,
          onPressed: () =>
              setState(() => _status = (_status + 1) % _statuses.length),
        ),
        MinimalProperty(
          icon: LucideIcons.repeat,
          label: 'Repeats',
          value: _repeat,
          items: [
            for (final repeat in const ['Every day', 'Weekdays', 'Weekends'])
              MinimalMenuItem(
                repeat,
                selected: repeat == _repeat,
                onPressed: () => setState(() => _repeat = repeat),
              ),
          ],
        ),
        MinimalProperty(
          icon: LucideIcons.bell,
          label: 'Reminder',
          value: '07:00',
          mono: true,
          onPressed: () {},
        ),
        const MinimalProperty(
          icon: LucideIcons.flame,
          label: 'Streak',
          value: '12d',
          mono: true,
          detail: 'best 21d',
        ),
        MinimalProperty(
          icon: LucideIcons.user,
          label: 'Owner',
          semanticValue: 'Ana Berg',
          onPressed: () {},
          child: const Row(
            children: [
              MinimalAvatar('Ana Berg', size: 20),
              MinimalGap(6),
              Flexible(child: Text('Ana Berg')),
            ],
          ),
        ),
        MinimalProperty(
          icon: LucideIcons.target,
          label: 'Goal',
          onPressed: () {},
        ),
        MinimalProperty(
          icon: LucideIcons.calendar,
          label: 'Started',
          value: MinimalFormat.isoDate(DateTime(2026, 6, 2)),
          mono: true,
        ),
      ],
    );
  }
}

/// The create form's pills: tap to set or clear.
class _Pills extends StatefulWidget {
  const _Pills();

  @override
  State<_Pills> createState() => _PillsState();
}

class _PillsState extends State<_Pills> {
  final Set<String> _set = {'Repeats', 'Reminder', 'Group'};

  void _toggle(String name) => setState(() {
    if (!_set.remove(name)) _set.add(name);
  });

  MinimalPropertyPill _pill(
    String name,
    IconData icon,
    String value, {
    bool mono = false,
  }) {
    final set = _set.contains(name);
    return MinimalPropertyPill(
      icon: icon,
      label: set ? value : name,
      name: name,
      hasValue: set,
      mono: mono && set,
      onPressed: () => _toggle(name),
    );
  }

  String _group = 'Evening';

  @override
  Widget build(BuildContext context) => MinimalPropertyBar(
    pills: [
      _pill('Repeats', LucideIcons.repeat, 'Every evening'),
      _pill('Reminder', LucideIcons.bell, '21:30', mono: true),
      // A pill that opens its own anchored menu of values.
      MinimalPropertyPill(
        icon: LucideIcons.folder,
        label: _group,
        name: 'Group',
        hasValue: true,
        items: [
          for (final group in const ['Morning', 'Evening', 'Weekends'])
            MinimalMenuItem(
              group,
              selected: group == _group,
              onPressed: () => setState(() => _group = group),
            ),
        ],
      ),
      _pill('Goal', LucideIcons.target, '20 min'),
      _pill('Start date', LucideIcons.calendar, '2026-08-28', mono: true),
      const MinimalPropertyPill(
        icon: LucideIcons.lock,
        label: 'Area',
        name: 'Area',
      ),
    ],
  );
}

/// One breadcrumb specimen in the 44 px band a path with a way back
/// stands in, so every specimen keeps the same rhythm whether its crumbs
/// are tappable or not.
class _CrumbBand extends StatelessWidget {
  const _CrumbBand(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: MinimalLayout.minHitTarget),
    alignment: AlignmentDirectional.centerStart,
    child: child,
  );
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A record's path: the tappable ancestor quiet, the current id in mono.
Widget kitSpecimenBreadcrumbRecord() => MinimalBreadcrumb(
  crumbs: [
    MinimalBreadcrumbItem('Habits', onPressed: () {}),
    MinimalBreadcrumbItem('Morning', onPressed: () {}),
    const MinimalBreadcrumbItem('HAB-4', mono: true),
  ],
);

/// A path too long for its line, shortening its longest step.
Widget kitSpecimenBreadcrumbLong() => const MinimalBreadcrumb(
  crumbs: [
    MinimalBreadcrumbItem('Orders'),
    MinimalBreadcrumbItem('Standing'),
    MinimalBreadcrumbItem('Weekly bread and pastry order'),
    MinimalBreadcrumbItem('#1045', mono: true),
  ],
);

/// A habit's properties: a toned status, figures in mono, a face, an
/// empty one.
Widget kitSpecimenPropertyListHabit() => _Body(
  child: MinimalDescriptionList(
    properties: [
      MinimalProperty(
        icon: LucideIcons.circleDot,
        label: 'Status',
        value: 'Active',
        tone: MinimalTone.success,
        onPressed: () {},
      ),
      MinimalProperty(
        icon: LucideIcons.repeat,
        label: 'Repeats',
        value: 'Every day',
        items: [
          MinimalMenuItem('Every day', selected: true, onPressed: () {}),
          MinimalMenuItem('Weekdays', onPressed: () {}),
        ],
      ),
      MinimalProperty(
        icon: LucideIcons.bell,
        label: 'Reminder',
        value: '07:00',
        mono: true,
        onPressed: () {},
      ),
      const MinimalProperty(
        icon: LucideIcons.flame,
        label: 'Streak',
        value: '12d',
        mono: true,
        detail: 'best 21d',
      ),
      MinimalProperty(
        icon: LucideIcons.user,
        label: 'Owner',
        semanticValue: 'Ana Berg',
        onPressed: () {},
        child: const Row(
          children: [
            MinimalAvatar('Ana Berg', size: 20),
            MinimalGap(6),
            Flexible(child: Text('Ana Berg')),
          ],
        ),
      ),
      MinimalProperty(
        icon: LucideIcons.target,
        label: 'Goal',
        onPressed: () {},
      ),
    ],
  ),
);

/// A property that has its value, on the quiet fill.
Widget kitSpecimenPropertyPillSet() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalPropertyPill(
      icon: LucideIcons.bell,
      label: '21:30',
      name: 'Reminder',
      mono: true,
      hasValue: true,
      onPressed: () {},
    ),
  ],
);

/// A property still to choose: the outline printing its name.
Widget kitSpecimenPropertyPillUnset() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalPropertyPill(
      icon: LucideIcons.target,
      label: 'Goal',
      onPressed: () {},
    ),
  ],
);

/// A create form's pills, the set ones first, wrapping to a second line.
Widget kitSpecimenPropertyBarCreate() => MinimalPropertyBar(
  pills: [
    MinimalPropertyPill(
      icon: LucideIcons.repeat,
      label: 'Every evening',
      name: 'Repeats',
      hasValue: true,
      onPressed: () {},
    ),
    MinimalPropertyPill(
      icon: LucideIcons.bell,
      label: '21:30',
      name: 'Reminder',
      mono: true,
      hasValue: true,
      onPressed: () {},
    ),
    MinimalPropertyPill(
      icon: LucideIcons.folder,
      label: 'Evening',
      name: 'Group',
      hasValue: true,
      onPressed: () {},
    ),
    MinimalPropertyPill(
      icon: LucideIcons.target,
      label: 'Goal',
      onPressed: () {},
    ),
    MinimalPropertyPill(
      icon: LucideIcons.calendar,
      label: 'Start date',
      onPressed: () {},
    ),
  ],
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage.
class _Body extends StatelessWidget {
  const _Body({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      UnconstrainedBox(constrainedAxis: Axis.horizontal, child: child);
}
