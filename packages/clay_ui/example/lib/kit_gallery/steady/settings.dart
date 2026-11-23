/// Steady's Settings: appearance, reminders, the week, the account. Neutral
/// clay only, no pastel and no picture: the look has to hold up on its
/// material alone.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'steady.dart';

/// Settings.
class SteadySettings extends StatelessWidget {
  /// The settings page.
  const SteadySettings({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = SteadyPrefs.of(context);
    final theme = context.clayTheme;
    final c = theme.colors;
    final desk =
        MediaQuery.sizeOf(context).width >= ClayMetrics.sidebarBreakpoint;
    final habits = steadyHabits().where((h) => !h.paused).toList();
    // On a desk the card spans both columns; two figures fill its middle.
    Widget figure(String value, String label) => Padding(
      padding: const EdgeInsetsDirectional.only(end: ClaySpacing.extraLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.title.copyWith(color: c.ink)),
          Text(label, style: theme.textTheme.secondary),
        ],
      ),
    );
    final profile = ClayCard(
      child: Row(
        children: [
          const SteadyAvatar(size: 52),
          const SizedBox(width: ClaySpacing.regular),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  steadyOwner.name,
                  style: theme.textTheme.title.copyWith(color: c.ink),
                ),
                Text(steadyOwner.email, style: theme.textTheme.secondary),
              ],
            ),
          ),
          if (desk) ...[
            figure('${habits.length}', 'Habits'),
            figure(
              '${habits.map((h) => h.streak).reduce((a, b) => a > b ? a : b)} days',
              'Longest streak',
            ),
          ],
          ClayIconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.pencil),
            tooltip: 'Edit profile',
          ),
        ],
      ),
    );
    final you = <Widget>[
      ClayGroup(
        header: 'Appearance',
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ClaySpacing.roomy,
              ClaySpacing.regular,
              ClaySpacing.roomy,
              ClaySpacing.regular,
            ),
            child: ClaySegmentedButton<SteadyAppearance>(
              segments: const [
                ClaySegment(
                  value: SteadyAppearance.light,
                  label: 'Light',
                  icon: Icon(LucideIcons.sun),
                ),
                ClaySegment(
                  value: SteadyAppearance.dark,
                  label: 'Dark',
                  icon: Icon(LucideIcons.moon),
                ),
                ClaySegment(value: SteadyAppearance.system, label: 'Auto'),
              ],
              selected: prefs.appearance,
              expanded: true,
              onChanged: (v) => prefs.update((p) => p.appearance = v),
              semanticLabel: 'Appearance',
            ),
          ),
          ClayListTile(
            title: 'Compact rows',
            subtitle: 'More on screen at once',
            trailing: ClaySwitch(
              value: prefs.density == ClayDensity.compact,
              onChanged: (on) => prefs.update(
                (p) =>
                    p.density = on ? ClayDensity.compact : ClayDensity.standard,
              ),
              semanticLabel: 'Compact rows',
            ),
          ),
          ClayListTile(
            title: 'Right to left',
            trailing: ClaySwitch(
              value: prefs.direction == TextDirection.rtl,
              onChanged: (on) => prefs.update(
                (p) => p.direction = on ? TextDirection.rtl : TextDirection.ltr,
              ),
              semanticLabel: 'Right to left',
            ),
          ),
        ],
      ),
      steadyGroupGap,
      ClayGroup(
        header: 'Units',
        children: [
          ClayListTile(
            title: 'Water',
            trailing: ClaySegmentedButton<String>(
              segments: const [
                ClaySegment(value: 'glasses', label: 'Glasses'),
                ClaySegment(value: 'ml', label: 'ml'),
                ClaySegment(value: 'oz', label: 'oz'),
              ],
              selected: prefs.water,
              expanded: false,
              onChanged: (v) => prefs.update((p) => p.water = v),
              semanticLabel: 'Water',
            ),
          ),
          ClayListTile(
            title: 'Distance',
            trailing: ClaySegmentedButton<String>(
              segments: const [
                ClaySegment(value: 'km', label: 'km'),
                ClaySegment(value: 'mi', label: 'mi'),
              ],
              selected: prefs.distance,
              expanded: false,
              onChanged: (v) => prefs.update((p) => p.distance = v),
              semanticLabel: 'Distance',
            ),
          ),
          ClayListTile(
            title: 'Week starts on',
            trailing: ClaySegmentedButton<String>(
              segments: const [
                ClaySegment(value: 'mon', label: 'Mon'),
                ClaySegment(value: 'sat', label: 'Sat'),
                ClaySegment(value: 'sun', label: 'Sun'),
              ],
              selected: prefs.weekStart,
              expanded: false,
              onChanged: (v) => prefs.update((p) => p.weekStart = v),
              semanticLabel: 'Week starts on',
            ),
          ),
        ],
      ),
    ];
    final rest = <Widget>[
      ClayGroup(
        header: 'Reminders',
        footer: 'Each habit can also remind you at its own time.',
        children: [
          ClayListTile(
            title: 'Morning check-in',
            subtitle: 'At 8:00',
            trailing: ClaySwitch(
              value: prefs.checkIn,
              onChanged: (v) => prefs.update((p) => p.checkIn = v),
              semanticLabel: 'Morning check-in',
            ),
          ),
          ClayListTile(
            title: 'Streak at risk',
            subtitle: 'At 20:00 if a habit is open',
            trailing: ClaySwitch(
              value: prefs.streakAtRisk,
              onChanged: (v) => prefs.update((p) => p.streakAtRisk = v),
              semanticLabel: 'Streak at risk',
            ),
          ),
          ClayListTile(
            title: 'Weekly summary',
            trailing: ClaySwitch(
              value: prefs.weekly,
              onChanged: (v) => prefs.update((p) => p.weekly = v),
              semanticLabel: 'Weekly summary',
            ),
          ),
          ClayListTile(
            title: 'Sounds',
            trailing: ClaySwitch(
              value: prefs.sounds,
              onChanged: (v) => prefs.update((p) => p.sounds = v),
              semanticLabel: 'Sounds',
            ),
          ),
        ],
      ),
      steadyGroupGap,
      ClayGroup(
        header: 'Data',
        children: [
          ClayListTile(title: 'Export history', onTap: () {}),
          ClayListTile(
            title: 'Archived habits',
            trailingText: '2',
            onTap: () {},
          ),
          const ClayListTile(title: 'Version', trailingText: '2.4.0'),
        ],
      ),
    ];
    final signOut = ClayGroup(
      children: [
        ClayListTile(
          title: 'Sign out',
          leading: const Icon(LucideIcons.logOut),
          isDestructiveAction: true,
          showChevron: false,
          onTap: () {},
        ),
      ],
    );
    return SteadyPage(
      title: 'Settings',
      large: true,
      maxWidth: desk ? 960 : ClayMetrics.readingWidth,
      children: [
        profile,
        steadyGroupGap,
        if (desk)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Each column is its own Tab group, so Tab runs down one
              // before the next rather than across the two by rows.
              Expanded(
                // Sign out ends the shorter column, so the two end level.
                child: FocusTraversalGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [...you, steadyGroupGap, signOut],
                  ),
                ),
              ),
              const SizedBox(width: ClaySpacing.large),
              Expanded(
                child: FocusTraversalGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rest,
                  ),
                ),
              ),
            ],
          )
        else ...[
          ...you,
          steadyGroupGap,
          ...rest,
          steadyGroupGap,
          signOut,
        ],
      ],
    );
  }
}
