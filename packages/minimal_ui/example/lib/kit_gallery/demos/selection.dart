/// Minimal's single choice: hairline radio rows with the accent check —
/// plain, with explanations, with leading glyphs and colour marks, with
/// rich content, with a disabled option, and the same group raised in a
/// sheet.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSelectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection',
  sections: [
    kitSection(
      'Repeats',
      children: [
        _Choice(
          initial: 'evening',
          builder: (value, choose, inset) => MinimalSelectionGroup(
            padding: inset,
            children: [
              for (final (id, label) in const [
                ('daily', 'Every day'),
                ('weekdays', 'Weekdays'),
                ('evening', 'Every evening'),
                ('weekly', 'Once a week'),
              ])
                MinimalChoiceRow(
                  title: label,
                  selected: value == id,
                  onPressed: () => choose(id),
                ),
            ],
          ),
        ),
        kitNote('Tab to an option; the arrow keys walk the group.'),
      ],
    ),
    kitSection(
      'With explanations',
      children: [
        _Choice(
          initial: 'streak',
          builder: (value, choose, inset) => MinimalSelectionGroup(
            padding: inset,
            children: [
              MinimalChoiceRow(
                title: 'Keep the streak',
                subtitle: 'A missed day ends it. Best 21\u00a0days.',
                selected: value == 'streak',
                onPressed: () => choose('streak'),
              ),
              MinimalChoiceRow(
                title: 'Allow a rest day',
                subtitle: 'One skipped day a week keeps it going.',
                selected: value == 'rest',
                onPressed: () => choose('rest'),
              ),
              MinimalChoiceRow(
                title: 'Count total days',
                subtitle: 'No streak: 23 of 28\u00a0days in August.',
                selected: value == 'total',
                onPressed: () => choose('total'),
              ),
              MinimalChoiceRow(
                title: 'Weekly target',
                subtitle: 'Available on a team plan.',
                selected: value == 'weekly',
              ),
            ],
          ),
        ),
        kitNote(
          'Weekly target needs a team plan, so it shows dimmed and cannot be '
          'chosen.',
        ),
      ],
    ),
    kitSection(
      'Leading glyphs',
      children: [
        _Choice(
          initial: 'evening',
          builder: (value, choose, inset) => MinimalSelectionGroup(
            padding: inset,
            children: [
              for (final (id, label, icon) in const [
                ('morning', 'Morning', LucideIcons.sunrise),
                ('afternoon', 'Afternoon', LucideIcons.sun),
                ('evening', 'Evening', LucideIcons.moon),
              ])
                MinimalChoiceRow(
                  title: label,
                  leading: MinimalIcon(icon),
                  selected: value == id,
                  onPressed: () => choose(id),
                ),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      'Colour marks',
      children: [
        _Choice(
          initial: 'green',
          builder: (value, choose, inset) => Builder(
            builder: (context) {
              final t = context.minimalTheme;
              return MinimalSelectionGroup(
                padding: inset,
                children: [
                  for (final (id, label, tone) in [
                    ('green', 'Health', t.success),
                    ('blue', 'Work', t.primary),
                    ('amber', 'Home', t.warning),
                    ('red', 'Focus', t.destructive),
                  ])
                    MinimalChoiceRow(
                      title: label,
                      // The mark centred in a glyph's 18 px slot, so these
                      // titles share the leading glyphs' keyline above.
                      leading: SizedBox(
                        width: MinimalIconSize.i18,
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: tone,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                      selected: value == id,
                      onPressed: () => choose(id),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
    kitSection(
      'Rich content',
      children: [
        _Choice(
          initial: 'HAB-4',
          builder: (value, choose, inset) => Builder(
            builder: (context) {
              final t = context.minimalTheme;
              return MinimalSelectionGroup(
                padding: inset,
                children: [
                  for (final (id, name, streak) in const [
                    ('HAB-1', 'Meditate', 4),
                    ('HAB-4', 'Morning run', 12),
                    ('HAB-2', 'Drink water', 10),
                  ])
                    MinimalChoiceRow(
                      title: '$name, $id',
                      selected: value == id,
                      onPressed: () => choose(id),
                      content: MinimalMetaRow(
                        leading: Text(id),
                        middle: Text(name, style: t.body),
                        trailing: Text('${streak}d'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    ),
    kitSection('In a sheet', children: const [_SheetChoice()]),
  ],
);

/// Holds one choice for a group.
class _Choice extends StatefulWidget {
  const _Choice({required this.initial, required this.builder});

  final String initial;
  final Widget Function(
    String value,
    ValueChanged<String> choose,
    EdgeInsets inset,
  )
  builder;

  @override
  State<_Choice> createState() => _ChoiceState();
}

class _ChoiceState extends State<_Choice> {
  late String _value = widget.initial;

  // Edge to edge on a phone, as the page's other lists run, its words on
  // the gutter; on the column's keylines in a wider window.
  @override
  Widget build(BuildContext context) => KitBleed(
    child: Builder(
      builder: (context) => widget.builder(
        _value,
        (v) => setState(() => _value = v),
        KitBleed.inset(context),
      ),
    ),
  );
}

/// A button that raises the same group in the modal card and prints what
/// was chosen.
class _SheetChoice extends StatefulWidget {
  const _SheetChoice();

  @override
  State<_SheetChoice> createState() => _SheetChoiceState();
}

class _SheetChoiceState extends State<_SheetChoice> {
  String _goal = 'Minutes';

  Future<void> _open() async {
    final chosen = await showMinimalBottomSheet<String>(
      context,
      title: 'Goal type',
      subtitle: 'HAB-4',
      builder: (sheetContext) => MinimalSelectionGroup(
        children: [
          for (final (label, detail) in const [
            ('Minutes', 'Run for 30\u00a0minutes'),
            ('Distance', 'Run 5\u00a0km'),
            ('Just show up', 'Any distance counts'),
          ])
            MinimalChoiceRow(
              title: label,
              subtitle: detail,
              selected: label == _goal,
              onPressed: () => Navigator.of(sheetContext).pop(label),
            ),
        ],
      ),
    );
    if (chosen != null && mounted) setState(() => _goal = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            'Goal: $_goal',
            style: t.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        MinimalButton(
          'Change',
          variant: MinimalButtonVariant.secondary,
          onPressed: _open,
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A single choice as hairline rows, the chosen one checked.
Widget kitSpecimenSelectionGroupRepeats() => _Body(
  child: MinimalSelectionGroup(
    children: [
      for (final (id, label) in const [
        ('daily', 'Every day'),
        ('weekdays', 'Weekdays'),
        ('evening', 'Every evening'),
        ('weekly', 'Once a week'),
      ])
        MinimalChoiceRow(
          title: label,
          selected: id == 'evening',
          onPressed: () {},
        ),
    ],
  ),
);

/// Options that explain themselves, one of them unavailable.
Widget kitSpecimenSelectionGroupExplained() => _Body(
  child: MinimalSelectionGroup(
    children: [
      MinimalChoiceRow(
        title: 'Keep the streak',
        subtitle: 'A missed day ends it. Best 21 days.',
        selected: true,
        onPressed: () {},
      ),
      MinimalChoiceRow(
        title: 'Allow a rest day',
        subtitle: 'One skipped day a week keeps it going.',
        selected: false,
        onPressed: () {},
      ),
      const MinimalChoiceRow(
        title: 'Count weekly',
        subtitle: 'Needs a weekly goal first.',
        selected: false,
      ),
    ],
  ),
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
