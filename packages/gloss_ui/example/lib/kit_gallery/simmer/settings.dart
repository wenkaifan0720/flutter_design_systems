/// Simmer's Settings: the account and who it cooks for, diet, units,
/// notifications and appearance, each a well of rows. The screen with no
/// colour and no face of its own: wells, beads, readouts, gel in its slots
/// and a gel thumb in its troughs carry it.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'simmer.dart';

/// Settings.
class SimmerSettings extends StatelessWidget {
  /// Settings.
  const SimmerSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final prefs = SimmerPrefs.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final account = GlossWell(
      header: 'Account',
      children: [
        Padding(
          padding: const EdgeInsets.all(GlossSpacing.regular),
          child: Row(
            children: [
              const SimmerAvatar(),
              const SizedBox(width: GlossSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(simmerOwner.name, style: t.label),
                    // At large sizes an address breaks after its @, never mid-word.
                    Text(
                      simmerOwner.email.replaceFirst('@', '@\u200B'),
                      style: t.secondary,
                    ),
                  ],
                ),
              ),
              GlossButton(
                'Edit',
                onPressed: () {},
                style: const GlossStyle(
                  minimumSize: WidgetStatePropertyAll(Size(0, 36)),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: GlossSpacing.regular),
                  ),
                ),
              ),
            ],
          ),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.users),
          title: 'Cooking for',
          subtitle: glossPlural(
            context,
            prefs.household,
            one: '1 person',
            other: '${prefs.household} people',
          ),
          trailing: GlossStepper(
            value: prefs.household,
            min: 1,
            max: 12,
            semanticLabel: 'Cooking for',
            onChanged: (v) => prefs.update((p) => p.household = v),
          ),
        ),
      ],
    );
    final diet = GlossWell(
      header: 'Diet',
      footer: 'Recipes that do not fit are hidden from your week.',
      children: [
        for (final d in simmerDiets)
          GlossListTile(
            title: d,
            trailing: GlossSwitch(
              value: prefs.diets.contains(d),
              semanticLabel: d,
              onChanged: (on) =>
                  prefs.update((p) => on ? p.diets.add(d) : p.diets.remove(d)),
            ),
          ),
      ],
    );
    final units = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlossSectionHeader('Units'),
        GlossSegmentedButton<String>(
          semanticLabel: 'Units',
          segments: const [
            GlossSegment(value: 'metric', label: 'Metric'),
            GlossSegment(value: 'us', label: 'US cups'),
            GlossSegment(value: 'uk', label: 'Imperial'),
          ],
          selected: prefs.units,
          onChanged: (v) => prefs.update((p) => p.units = v),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: GlossSpacing.regular,
            top: GlossSpacing.small,
          ),
          child: Text(
            switch (prefs.units) {
              'us' => 'Cups, ounces and °F in every recipe.',
              'uk' => 'Pounds, ounces, pints and °C in every recipe.',
              _ => 'Grams, millilitres and °C in every recipe.',
            },
            style: glossLetterpress(
              t.secondary.copyWith(color: theme.colors.inkSecondary),
              theme.colors,
            ),
          ),
        ),
      ],
    );
    final notifications = GlossWell(
      header: 'Notifications',
      children: [
        GlossListTile(
          leading: const Icon(LucideIcons.bell),
          title: 'Cooking reminders',
          subtitle: 'An hour before you start',
          trailing: GlossSwitch(
            value: prefs.reminders,
            semanticLabel: 'Cooking reminders',
            onChanged: (v) => prefs.update((p) => p.reminders = v),
          ),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.listChecks),
          title: 'List is ready',
          trailing: GlossSwitch(
            value: prefs.listReady,
            semanticLabel: 'List is ready',
            onChanged: (v) => prefs.update((p) => p.listReady = v),
          ),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.sparkles),
          title: 'New recipes each week',
          trailing: GlossSwitch(
            value: prefs.newRecipes,
            semanticLabel: 'New recipes each week',
            onChanged: (v) => prefs.update((p) => p.newRecipes = v),
          ),
        ),
      ],
    );
    final appearance = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlossSectionHeader('Appearance'),
        GlossSegmentedButton<SimmerAppearance>(
          semanticLabel: 'Appearance',
          segments: const [
            GlossSegment(value: SimmerAppearance.light, label: 'Light'),
            GlossSegment(value: SimmerAppearance.dark, label: 'Dark'),
            GlossSegment(value: SimmerAppearance.system, label: 'System'),
          ],
          selected: prefs.appearance,
          onChanged: (v) => prefs.update((p) => p.appearance = v),
        ),
        const SizedBox(height: GlossSpacing.large),
        GlossWell(
          header: 'Preview',
          children: [
            GlossListTile(
              title: 'Right to left',
              trailing: GlossSwitch(
                value: prefs.direction == TextDirection.rtl,
                semanticLabel: 'Right to left',
                onChanged: (v) => prefs.update(
                  (p) =>
                      p.direction = v ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
            ),
            GlossListTile(
              title: 'Compact controls',
              trailing: GlossSwitch(
                value: prefs.density == GlossDensity.compact,
                semanticLabel: 'Compact controls',
                onChanged: (v) => prefs.update(
                  (p) => p.density = v
                      ? GlossDensity.compact
                      : GlossDensity.standard,
                ),
              ),
            ),
          ],
        ),
      ],
    );
    final signOut = Align(
      alignment: AlignmentDirectional.centerStart,
      child: GlossButton(
        'Sign out',
        isDestructiveAction: true,
        icon: const Icon(LucideIcons.logOut),
        onPressed: () {},
      ),
    );
    return SimmerPage(
      title: 'Settings',
      large: true,
      maxWidth: wide ? 1000 : GlossMetrics.readingWidth,
      children: wide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        account,
                        simmerGroupGap,
                        diet,
                        simmerGroupGap,
                        units,
                      ],
                    ),
                  ),
                  const SizedBox(width: GlossSpacing.extraLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        notifications,
                        simmerGroupGap,
                        appearance,
                        simmerGroupGap,
                        signOut,
                      ],
                    ),
                  ),
                ],
              ),
            ]
          : [
              account,
              simmerGroupGap,
              diet,
              simmerGroupGap,
              units,
              simmerGroupGap,
              notifications,
              simmerGroupGap,
              appearance,
              simmerGroupGap,
              signOut,
            ],
    );
  }
}
