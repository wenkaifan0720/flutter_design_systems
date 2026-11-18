/// Simmer's Today: tonight's dinner as the screen's one object, its gel key
/// to start cooking, then the week's dinners in a well and the shopping
/// list's state.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'data.dart';
import 'planner.dart';
import 'recipes.dart';
import 'search.dart';
import 'simmer.dart';

/// Today.
class SimmerHome extends StatelessWidget {
  /// Today.
  const SimmerHome({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = SimmerFrame.of(context);
    final id = frame.week[simmerToday];
    final tonight = id == null ? null : simmerRecipe(id);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final list = frame.shoppingItems;
    final left = list.where((i) => !i.bought).length;
    final lead = tonight == null
        ? GlossWell(
            header: 'Tonight · ${simmerDays[simmerToday]}',
            children: [
              GlossListTile(
                title: 'Night off',
                subtitle: 'Plan a dinner for tonight',
                onTap: () => frame.push(const SimmerPlanner()),
              ),
            ],
          )
        : GlossCard(
            padding: EdgeInsets.zero,
            onTap: () => frame.push(SimmerRecipePage(recipe: tonight)),
            semanticLabel: 'Tonight, ${tonight.name}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: wide ? 16 / 9 : 16 / 10,
                  child: SimmerDish(recipe: tonight, radius: 0),
                ),
                Padding(
                  padding: const EdgeInsets.all(GlossSpacing.regular + 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tonight · ${simmerDays[simmerToday]}',
                        style: t.caption.copyWith(color: c.jadeInk),
                      ),
                      const SizedBox(height: GlossSpacing.small),
                      Text(tonight.name, style: t.headline),
                      const SizedBox(height: GlossSpacing.tight),
                      Text(tonight.blurb, style: t.secondary),
                      const SizedBox(height: GlossSpacing.medium),
                      Wrap(
                        spacing: GlossSpacing.regular,
                        runSpacing: GlossSpacing.small,
                        children: [
                          _Fact(
                            LucideIcons.clock,
                            simmerMinutes(tonight.minutes),
                          ),
                          _Fact(LucideIcons.users, 'Serves ${tonight.serves}'),
                          _Fact(LucideIcons.flame, '${tonight.kcal} kcal'),
                        ],
                      ),
                      const SizedBox(height: GlossSpacing.large),
                      // The key keeps its words whole: with large text, Swap
                      // goes under it.
                      Wrap(
                        spacing: GlossSpacing.small,
                        runSpacing: GlossSpacing.small,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          GlossButton.filled(
                            'Start cooking',
                            icon: const Icon(LucideIcons.cookingPot),
                            onPressed: () => frame.push(
                              SimmerRecipePage(recipe: tonight, cooking: true),
                            ),
                          ),
                          GlossButton.text(
                            'Swap',
                            onPressed: () => frame.go(SimmerPlace.recipes),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
    final week = GlossWell(
      header: 'This week',
      children: [
        for (final (i, id) in frame.week.indexed)
          GlossListTile(
            leading: _DayBead(day: simmerDays[i], today: i == simmerToday),
            title: id == null ? 'Night off' : simmerRecipe(id).name,
            subtitle: id == null
                ? simmerDays[i]
                : '${simmerDays[i]} · ${simmerMinutes(simmerRecipe(id).minutes)}',
            selected: i == simmerToday,
            onTap: id == null
                ? null
                : () => frame.push(SimmerRecipePage(recipe: simmerRecipe(id))),
          ),
      ],
    );
    final shopping = GlossWell(
      header: 'Shopping',
      children: [
        GlossListTile(
          leading: const Icon(LucideIcons.shoppingBasket),
          title: glossPlural(
            context,
            left,
            one: '1 thing to buy',
            other: '$left things to buy',
          ),
          subtitle: 'For the rest of the week, by aisle',
          onTap: () => frame.go(SimmerPlace.shopping),
        ),
      ],
    );
    return SimmerPage(
      title: 'Today',
      large: true,
      maxWidth: wide ? 1080 : GlossMetrics.readingWidth,
      actions: [
        GlossIconButton(
          onPressed: () => frame.push(const SimmerSearch()),
          tooltip: 'Search recipes',
          icon: const Icon(LucideIcons.search),
        ),
        GlossIconButton(
          onPressed: () => frame.push(const SimmerPlanner()),
          tooltip: 'Plan the week',
          icon: const Icon(LucideIcons.calendarDays),
        ),
      ],
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: lead),
              const SizedBox(width: GlossSpacing.extraLarge),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [week, simmerGroupGap, shopping],
                ),
              ),
            ],
          )
        else ...[
          lead,
          simmerGroupGap,
          week,
          simmerGroupGap,
          shopping,
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: theme.colors.inkSecondary),
        const SizedBox(width: GlossSpacing.tight + 2),
        Text(text, style: theme.textTheme.secondary),
      ],
    );
  }
}

/// A day's first letters, pressed into a small round socket; today's in
/// jade.
class _DayBead extends StatelessWidget {
  const _DayBead({required this.day, required this.today});

  final String day;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final c = theme.colors;
    return SizedBox.square(
      dimension: 24,
      child: GlossSurface(
        face: GlossFace.well(c).copyWith(lift: -0.7),
        child: Center(
          child: Text(
            day.substring(0, 2),
            style: theme.textTheme.caption.copyWith(
              fontSize: 11,
              height: 1,
              color: today ? c.jadeInk : c.inkSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
