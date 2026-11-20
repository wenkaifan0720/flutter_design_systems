import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Overlays: a dialog with its actions as cells across its foot, a sheet
/// from the bottom, a toast; each opened by a button, and the dialog drawn
/// in place.
Widget kitOverlaysDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dialogs and sheets',
  sections: const [_Overlays(), _Anchored()],
);

class _Overlays extends StatelessWidget {
  const _Overlays();

  @override
  Widget build(BuildContext context) {
    final t = context.brutalTheme.textTheme;
    // In place its actions do nothing; opened, they close it.
    BrutalDialog cancel(BuildContext context, {bool open = true}) =>
        BrutalDialog(
          title: 'Cancel this ticket?',
          content: const Text(
            'Low Tide, Sat 21 Nov. Your seat goes back on sale and the 32.00 '
            'comes back to your card in 3 to 5 days.',
          ),
          actions: [
            BrutalDialogAction(
              label: 'Keep it',
              onPressed: open ? () => Navigator.of(context).maybePop() : () {},
            ),
            BrutalDialogAction(
              label: 'Cancel ticket',
              primary: true,
              destructive: true,
              onPressed: open
                  ? () => Navigator.of(context).maybePop(true)
                  : () {},
            ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(
          title: 'Dialog',
          note:
              'Raised on the hard shadow; its actions are cells across its '
              'foot, the main one filled.',
          children: [
            Builder(builder: (context) => cancel(context, open: false)),
            KitRow(
              children: [
                BrutalButton(
                  'Open the dialog',
                  onPressed: () => showBrutalDialog<bool>(
                    context: context,
                    builder: (context) => cancel(context),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Sheet',
          note: 'From the bottom edge under a heavy rule; framed past 600.',
          children: [
            KitRow(
              children: [
                BrutalButton(
                  'Open the sheet',
                  onPressed: () => showBrutalBottomSheet<void>(
                    context: context,
                    title: 'Filter',
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('When', style: t.label),
                        const SizedBox(height: BrutalSpacing.small),
                        kitState(
                          0,
                          (context, when, change) => BrutalSegmentedButton<int>(
                            segments: const [
                              BrutalSegment(value: 0, label: 'Tonight'),
                              BrutalSegment(value: 1, label: 'Weekend'),
                            ],
                            value: when,
                            onChanged: change,
                          ),
                        ),
                        const SizedBox(height: BrutalSpacing.large),
                        BrutalButton.filled(
                          'Show 14 events',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Toast',
          note: 'An ink block that says what just happened.',
          children: [
            KitRow(
              children: [
                BrutalButton(
                  'Show a toast',
                  onPressed: () => showBrutalToast(
                    context,
                    'Ticket cancelled.',
                    actionLabel: 'Undo',
                    onAction: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Menu',
          note:
              'A raised box of rows on rules, dropped from what opens it; '
              'the pointer\'s or the keyboard\'s row goes ink.',
          children: [
            KitRow(
              children: [
                BrutalMenu(
                  semanticLabel: 'Ticket',
                  items: [
                    BrutalMenuItem(
                      label: 'Add to calendar',
                      icon: LucideIcons.calendarPlus,
                      onPressed: () {},
                    ),
                    BrutalMenuItem(
                      label: 'Share',
                      icon: LucideIcons.share2,
                      shortcut: '⌘S',
                      onPressed: () {},
                    ),
                    const BrutalMenuItem(
                      label: 'Transfer',
                      icon: LucideIcons.arrowLeftRight,
                      onPressed: null,
                    ),
                    BrutalMenuItem(
                      label: 'Cancel ticket',
                      icon: LucideIcons.trash2,
                      isDestructiveAction: true,
                      onPressed: () {},
                    ),
                  ],
                  builder: (context, toggle, open) => BrutalButton(
                    'Ticket',
                    onPressed: toggle,
                    icon: const Icon(LucideIcons.ellipsis),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Anchored extends StatelessWidget {
  const _Anchored();

  @override
  Widget build(BuildContext context) {
    final t = context.brutalTheme.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Popover, hover card, tooltip',
          note:
              'A raised box dropped from a press; the same box while the '
              'pointer rests on a link; an ink slab over an icon.',
          children: [
            KitRow(
              children: [
                BrutalPopover(
                  semanticLabel: 'Share',
                  builder: (context, toggle, open) => BrutalButton(
                    'Share',
                    onPressed: toggle,
                    icon: const Icon(LucideIcons.share2),
                  ),
                  content: (context, close) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Share Low Tide', style: t.title),
                      const SizedBox(height: BrutalSpacing.medium),
                      const BrutalTextField(
                        label: 'Email',
                        hint: 'name@example.com',
                      ),
                      const SizedBox(height: BrutalSpacing.medium),
                      BrutalButton.filled('Send', onPressed: close),
                    ],
                  ),
                ),
                BrutalHoverCard(
                  content: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('The Shed', style: t.title),
                      Text('12 Quay Street, 400 standing', style: t.secondary),
                    ],
                  ),
                  child: BrutalLink('The Shed', onPressed: () {}),
                ),
                BrutalTooltip(
                  message: 'Save for later',
                  child: BrutalIconButton(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.heart),
                    tooltip: 'Save for later',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Side sheet and action sheet',
          note:
              'A panel the full height from the end edge; a set of choices '
              'from the foot, with a cancel under them.',
          children: [
            KitRow(
              children: [
                BrutalButton(
                  'Filters',
                  icon: const Icon(LucideIcons.slidersHorizontal),
                  onPressed: () => showBrutalSideSheet<void>(
                    context: context,
                    title: 'Filters',
                    builder: (context) => const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BrutalTextField(label: 'Venue'),
                        SizedBox(height: BrutalSpacing.regular),
                        BrutalTextField(label: 'Most per ticket'),
                      ],
                    ),
                  ),
                ),
                BrutalButton(
                  'Ticket actions',
                  icon: const Icon(LucideIcons.ellipsis),
                  onPressed: () => showBrutalActionSheet<String>(
                    context: context,
                    title: 'This ticket',
                    message: 'Low Tide, Friday 19:30',
                    actions: const [
                      BrutalSheetAction(
                        label: 'Add to calendar',
                        value: 'calendar',
                        icon: LucideIcons.calendarPlus,
                      ),
                      BrutalSheetAction(
                        label: 'Transfer',
                        value: 'transfer',
                        icon: LucideIcons.arrowLeftRight,
                      ),
                      BrutalSheetAction(
                        label: 'Cancel ticket',
                        value: 'cancel',
                        icon: LucideIcons.trash2,
                        isDestructiveAction: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

Widget kitSpecimenDialog() => Builder(
  builder: (context) => Center(
    child: BrutalDialog(
      title: 'Cancel this ticket?',
      icon: const Icon(LucideIcons.triangleAlert),
      content: const Text(
        'Your seat goes back on sale and the money back to your card.',
      ),
      actions: [
        BrutalDialogAction(
          label: 'Keep it',
          onPressed: () => kitFeedback(context, 'Kept.'),
        ),
        BrutalDialogAction(
          label: 'Cancel ticket',
          destructive: true,
          primary: true,
          onPressed: () => kitFeedback(context, 'Ticket cancelled.'),
        ),
      ],
    ),
  ),
);

Widget kitSpecimenSheet() => kitState<Set<String>>(
  const {'Music'},
  (context, kinds, change) => SizedBox(
    height: 380,
    child: BrutalSheet(
      title: 'Filter',
      onClose: () => kitFeedback(context, 'Closed.'),
      footer: [
        BrutalButton.filled(
          'Show 12 nights',
          onPressed: () => kitFeedback(context, 'Showing 12 nights.'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final kind in const ['Music', 'Talks', 'Film'])
            BrutalListTile(
              title: kind,
              trailing: BrutalCheckbox(
                value: kinds.contains(kind),
                onChanged: (on) => change(
                  on == true ? {...kinds, kind} : ({...kinds}..remove(kind)),
                ),
                semanticLabel: kind,
              ),
            ),
        ],
      ),
    ),
  ),
);

Widget kitSpecimenMenu() => const Align(
  alignment: AlignmentDirectional.centerStart,
  child: BrutalMenuPanel(
    children: [
      BrutalMenuRow(label: 'Share', icon: LucideIcons.share2, states: {}),
      BrutalMenuRow(
        label: 'Add to calendar',
        icon: LucideIcons.calendarPlus,
        trailing: BrutalKbd(['Ctrl', 'D']),
        states: {},
      ),
      BrutalMenuRow(label: 'Reminders', checked: true, states: {}),
      BrutalMenuRow(
        label: 'Cancel ticket',
        icon: LucideIcons.trash2,
        isDestructiveAction: true,
        states: {},
      ),
    ],
  ),
);
