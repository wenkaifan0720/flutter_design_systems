/// Minimal's sheet: the compact modal card raised over a dimmed page
/// (open it live), a whole page raised as a sheet with its header and close
/// derived, and the card composed statically (another habit than the live
/// one's) — floating, and as the edge-attached drawer, each with room for
/// its shadow.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitSheetDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Sheet',
  sections: [
    kitSection(
      'Modal',
      children: [
        Builder(
          builder: (context) => kitRow([
            MinimalButton(
              'New habit',
              icon: LucideIcons.plus,
              onPressed: () => showMinimalBottomSheet<void>(
                context,
                title: 'New habit',
                subtitle: 'Habits',
                accessory: const _CreateAnother(),
                leading: const MinimalSheetAction('Cancel'),
                trailing: MinimalSheetAction(
                  'Create habit',
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                // Another habit than the floating card's below, so the
                // raised sheet never reads as that card doubled.
                builder: (_) => const _NewHabitForm(
                  name: 'Morning pages',
                  repeats: 'Every morning',
                  time: '06:45',
                  group: 'Morning',
                ),
              ),
            ),
            MinimalButton(
              'Sheet page',
              variant: MinimalButtonVariant.secondary,
              onPressed: () => Navigator.of(context).push(
                MinimalBottomSheet.pageRoute<void>(
                  context: context,
                  builder: (_) => const _RenamePage(),
                ),
              ),
            ),
          ]),
        ),
        kitNote(
          'The sheet rises over the dimmed page; drag it down, tap outside it '
          'or the close to dismiss.',
        ),
      ],
    ),
    kitSection(
      'Floating card',
      children: const [
        _Afloat(
          MinimalBottomSheet(
            title: 'New habit',
            subtitle: 'Habits',
            floating: true,
            accessory: _CreateAnother(),
            leading: MinimalSheetAction('Cancel'),
            trailing: MinimalSheetAction('Create habit', isDefaultAction: true),
            child: _NewHabitForm(),
          ),
        ),
      ],
    ),
    kitSection(
      'Drawer',
      children: const [
        _Afloat(
          MinimalBottomSheet(
            title: 'Filters',
            trailing: MinimalSheetAction('Apply', isDefaultAction: true),
            child: _Filters(),
          ),
        ),
      ],
    ),
  ],
);

/// A sheet card shown in place, with room for its one soft shadow (about
/// 40 px out each side and 60 below): the shadow ends before the next
/// heading and, on a page wider than a phone, inside the column, never
/// over the sidebar's rule.
class _Afloat extends StatelessWidget {
  const _Afloat(this.card);

  final Widget card;

  @override
  Widget build(BuildContext context) {
    final side = MinimalLayout.isCompact(context) ? 0.0 : MinimalSpacing.s40;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, MinimalSpacing.s48),
      child: card,
    );
  }
}

/// The create form the mockup raises: a big name, a note, and the property
/// pills a create form sets ([repeats], [time] and [group] set; a goal and a
/// start date still to set).
class _NewHabitForm extends StatelessWidget {
  const _NewHabitForm({
    this.name = 'Stretch before bed',
    this.repeats = 'Every evening',
    this.time = '21:30',
    this.group = 'Evening',
  });

  /// The habit's name, as typed so far.
  final String name;

  /// How often it repeats.
  final String repeats;

  /// When it reminds.
  final String time;

  /// The group it stands in.
  final String group;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MinimalGap(MinimalSpacing.s8),
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: t.h1,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsetsDirectional.only(start: 2),
              width: 2,
              height: 22,
              color: t.primary,
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s4),
        Text('Add a note…', style: t.body.c(t.textTertiary)),
        const MinimalGap(MinimalSpacing.s16),
        Wrap(
          spacing: MinimalChromeMetrics.iconGap,
          runSpacing: MinimalChromeMetrics.iconGap,
          children: [
            MinimalPropertyPill(
              icon: LucideIcons.repeat,
              label: repeats,
              name: 'Repeat',
              hasValue: true,
              onPressed: _pick,
            ),
            MinimalPropertyPill(
              icon: LucideIcons.bell,
              label: time,
              name: 'Reminder',
              mono: true,
              hasValue: true,
              onPressed: _pick,
            ),
            MinimalPropertyPill(
              icon: LucideIcons.folder,
              label: group,
              name: 'Group',
              hasValue: true,
              onPressed: _pick,
            ),
            const MinimalPropertyPill(
              icon: LucideIcons.target,
              label: 'Goal',
              onPressed: _pick,
            ),
            const MinimalPropertyPill(
              icon: LucideIcons.calendar,
              label: 'Start date',
              onPressed: _pick,
            ),
          ],
        ),
      ],
    );
  }

  /// The specimen's pills open nothing; a live form opens each one's menu.
  static void _pick() {}
}

/// The footer's leading slot in the mockup: the labelled switch, its words
/// and its track one control.
class _CreateAnother extends StatefulWidget {
  const _CreateAnother();

  @override
  State<_CreateAnother> createState() => _CreateAnotherState();
}

class _CreateAnotherState extends State<_CreateAnother> {
  bool _on = false;

  @override
  Widget build(BuildContext context) => MinimalSwitch(
    value: _on,
    label: 'Create another',
    showLabel: true,
    onChanged: (on) => setState(() => _on = on),
  );
}

class _Filters extends StatefulWidget {
  const _Filters();

  @override
  State<_Filters> createState() => _FiltersState();
}

class _FiltersState extends State<_Filters> {
  final Set<String> _on = {'Open'};

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // A row grows by what the text scale adds to a 16 px line, as the
    // kit's rows do, so larger words keep their air.
    final grown =
        t.rowHeightCompact +
        math.max(0.0, MediaQuery.textScalerOf(context).scale(16) - 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (label, count)) in const [
          ('Open', 2),
          ('Done', 3),
          ('Paused', 1),
        ].indexed)
          Container(
            constraints: BoxConstraints(minHeight: grown),
            decoration: BoxDecoration(
              border: i == 0 ? null : Border(top: t.rule),
            ),
            child: Row(
              children: [
                MinimalCheckbox(
                  value: _on.contains(label),
                  label: label,
                  onChanged: (v) =>
                      setState(() => v ? _on.add(label) : _on.remove(label)),
                ),
                const MinimalGap(10),
                Expanded(child: Text(label, style: t.body)),
                Text('$count', style: t.mono.c(t.mutedForeground)),
              ],
            ),
          ),
      ],
    );
  }
}

/// A whole page raised as a sheet: it authors a title and a footer; the
/// card's header and close are derived from the route.
class _RenamePage extends StatelessWidget {
  const _RenamePage();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalScaffold(
      topBar: const MinimalAppBar(title: 'Rename', subtitle: 'HAB-4'),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MinimalButton(
            'Save',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Morning run', style: t.h1),
          const MinimalGap(MinimalSpacing.s4),
          Text(
            'A sheet page is a plain screen: its header and its close come '
            'from the route it stands on.',
            style: t.bodySmall.c(t.mutedForeground),
          ),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// showMinimalBottomSheet presents MinimalBottomSheet; each specimen stands the
// card where the presenter raises it, over the dimmed page.
// The stage (kitSpecimenStage) styles it; a builder never names a style.

/// The floating card raised over the dimmed page: a short create form,
/// its footer's accessory and actions.
Widget kitSpecimenSheetFloating() => const _Raised(
  child: MinimalBottomSheet(
    title: 'New habit',
    subtitle: 'Habits',
    floating: true,
    accessory: _CreateAnother(),
    leading: MinimalSheetAction('Cancel'),
    trailing: MinimalSheetAction('Create habit', isDefaultAction: true),
    child: _NewHabitForm(),
  ),
);

/// The edge-attached drawer, over the home indicator's band.
Widget kitSpecimenSheetDrawer() => const _Raised(
  floating: false,
  child: MinimalBottomSheet(
    title: 'Filters',
    safe: true,
    trailing: MinimalSheetAction('Apply', isDefaultAction: true),
    child: _Filters(),
  ),
);

/// Stands a sheet card where [showMinimalBottomSheet] raises it — inset above the
/// bottom edge when [floating], on the edge as the drawer otherwise — over
/// the dimmed page, as one still frame of the open sheet.
class _Raised extends StatelessWidget {
  const _Raised({required this.child, this.floating = true});

  final Widget child;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final inset = floating ? MinimalChromeMetrics.sheetInset : 0.0;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: t.overlay),
        Positioned(
          left: inset,
          right: inset,
          bottom: floating ? MinimalBottomSheet.bottomGap(context) : 0,
          child: child,
        ),
      ],
    );
  }
}
