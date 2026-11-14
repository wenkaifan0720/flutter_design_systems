/// Minimal's record history and its code register: Morning run's audit
/// log, a team log with actors, status dots and rows that open, the empty
/// log; code blocks with a caption, floating copy, line numbers and
/// wrapping; and the key caps a shortcut prints in.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitActivityDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Activity & code',
  sections: [
    kitSection(
      'Activity log',
      children: [
        MinimalTimeline(
          entries: [
            MinimalActivity(
              at: DateTime(2026, 8, 28, 7, 12),
              text: 'Marked done',
            ),
            MinimalActivity(
              at: DateTime(2026, 8, 27, 7, 40),
              text: 'Marked done',
              detail: 'note added',
            ),
            MinimalActivity(
              at: DateTime(2026, 8, 26, 6, 58),
              text: 'Marked done',
            ),
            MinimalActivity(
              at: DateTime(2026, 8, 19, 20, 15),
              text: 'Reminder moved to 07:00',
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'Actors, tones, rows that open',
      children: [
        Builder(
          builder: (context) {
            void open(String what) =>
                showMinimalSnackBar(context, 'Open: $what');
            return MinimalTimeline(
              entries: [
                MinimalActivity(
                  at: DateTime(2026, 8, 28, 9, 32),
                  actor: 'Ana',
                  text: 'marked order #1044 ready',
                  tone: MinimalTone.success,
                  onPressed: () => open('#1044'),
                ),
                MinimalActivity(
                  at: DateTime(2026, 8, 28, 9, 30),
                  actor: 'System',
                  text: 'flagged #1047 late',
                  detail: '18 min',
                  tone: MinimalTone.warning,
                  onPressed: () => open('#1047'),
                ),
                MinimalActivity(
                  at: DateTime(2026, 8, 28, 8, 5),
                  text: 'Card payment failed for #1038',
                  tone: MinimalTone.destructive,
                  onPressed: () => open('#1038'),
                ),
                // A time like the rows above, so the column reads as one.
                MinimalActivity(
                  at: DateTime(2026, 8, 28, 7),
                  actor: 'Ines',
                  text: 'opened the shop',
                  tone: MinimalTone.neutral,
                ),
              ],
            );
          },
        ),
      ],
    ),
    kitSection('Empty log', children: const [MinimalTimeline(entries: [])]),
    kitSection(
      'Code block',
      children: [
        const MinimalCodeBlock(
          'curl -X POST https://api.ritual.app/v1/habits/HAB-4/done',
          label: 'bash',
        ),
        const MinimalCodeBlock('rk_live_7Hc2QpX9vB41mNf0'),
        const MinimalCodeBlock(
          '{\n'
          '  "id": "HAB-4",\n'
          '  "name": "Morning run",\n'
          '  "reminder": "07:00",\n'
          '  "streak": 12\n'
          '}',
          label: 'habit.json',
          lineNumbers: true,
        ),
        const MinimalCodeBlock(
          'Out the door before 8. Any distance counts. The reminder fires at '
          '07:00 every day, and a run logged before 08:00 keeps the streak.',
          label: 'wrapped',
          wrap: true,
          copyable: false,
        ),
        kitNote(
          'Copy puts the code on the clipboard and confirms with a toast.',
        ),
      ],
    ),
    kitSection(
      'Key caps',
      children: [
        kitRow([
          MinimalKbd.chord('⌘ K'),
          const MinimalKbd('Esc'),
          const MinimalKbd('↑'),
          const MinimalKbd('↓'),
          const MinimalKbd('↵'),
          const MinimalKbd('Shift'),
          const MinimalKbd('N'),
        ]),
        Builder(
          builder: (context) {
            final t = context.minimalTheme;
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MinimalSpacing.s4,
              runSpacing: MinimalSpacing.s4,
              children: [
                Text('Press', style: t.bodySmall.c(t.mutedForeground)),
                MinimalKbd.chord('⌘ K'),
                Text(
                  'for commands, or',
                  style: t.bodySmall.c(t.mutedForeground),
                ),
                const MinimalKbd('N'),
                Text(
                  'for a new habit.',
                  style: t.bodySmall.c(t.mutedForeground),
                ),
              ],
            );
          },
        ),
        Builder(
          builder: (context) => kitRow([
            MinimalButton(
              'Search habits',
              variant: MinimalButtonVariant.secondary,
              leading: const MinimalKbd('/'),
              onPressed: () => showMinimalSnackBar(
                context,
                'Search opens with /',
                icon: LucideIcons.search,
              ),
            ),
          ]),
        ),
      ],
    ),
  ],
);

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A habit's history, newest first, the times in a mono column.
Widget kitSpecimenActivityLogHistory() => _Body(
  child: MinimalTimeline(
    entries: [
      MinimalActivity(at: DateTime(2026, 8, 28, 7, 12), text: 'Marked done'),
      MinimalActivity(
        at: DateTime(2026, 8, 27, 7, 40),
        text: 'Marked done',
        detail: 'note added',
      ),
      MinimalActivity(at: DateTime(2026, 8, 26, 6, 58), text: 'Marked done'),
      MinimalActivity(
        at: DateTime(2026, 8, 19, 20, 15),
        text: 'Reminder moved to',
        figure: '07:00',
      ),
    ],
  ),
);

/// The shop's events with who did them, each marked by its tone's dot.
Widget kitSpecimenActivityLogActors() => _Body(
  child: MinimalTimeline(
    entries: [
      MinimalActivity(
        at: DateTime(2026, 8, 28, 9, 32),
        actor: 'Ana',
        text: 'marked order #1044 ready',
        tone: MinimalTone.success,
        onPressed: () {},
      ),
      MinimalActivity(
        at: DateTime(2026, 8, 28, 9, 30),
        actor: 'System',
        text: 'flagged #1047 late',
        detail: '18 min',
        tone: MinimalTone.warning,
        onPressed: () {},
      ),
      MinimalActivity(
        at: DateTime(2026, 8, 28, 8, 5),
        text: 'Card payment failed for #1038',
        tone: MinimalTone.destructive,
        onPressed: () {},
      ),
    ],
  ),
);

/// A command on the sunken well, its language in the caption band.
Widget kitSpecimenCodeBlockCommand() => const _InBody(
  MinimalCodeBlock(
    'curl -X POST https://api.ritual.app/v1/habits/HAB-4/done',
    label: 'bash',
  ),
);

/// A payload with its line numbers.
Widget kitSpecimenCodeBlockJson() => const _InBody(
  MinimalCodeBlock(
    '{\n'
    '  "id": "HAB-4",\n'
    '  "name": "Morning run",\n'
    '  "reminder": "07:00",\n'
    '  "streak": 12\n'
    '}',
    label: 'habit.json',
    lineNumbers: true,
  ),
);

/// [child] as a scrolling page body lays it out: height unbounded, so a
/// block with a caption sizes to its lines instead of filling the stage.
class _InBody extends StatelessWidget {
  const _InBody(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [child]);
}

/// A chord printed as caps beside the action it runs.
Widget kitSpecimenKbdChord() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        Expanded(child: Text('Open the command palette', style: t.bodySmall)),
        MinimalKbd.chord('⌘ K'),
      ],
    );
  },
);

/// Single caps, each one key.
Widget kitSpecimenKbdKeys() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    MinimalKbd('Esc'),
    MinimalGap(MinimalSpacing.s8),
    MinimalKbd('↑'),
    MinimalGap(MinimalSpacing.s4),
    MinimalKbd('↓'),
    MinimalGap(MinimalSpacing.s8),
    MinimalKbd('↵'),
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
