/// Gloss's Overview, the pitch: what the look is in a sentence, a live piece
/// of Simmer at its best, the screens to open, what the package holds, and
/// only then every part's page.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'data.dart';
import 'recipes.dart';
import 'simmer.dart';

/// The Overview.
class SimmerOverview extends StatelessWidget {
  /// The Overview, listing the gallery's [parts].
  const SimmerOverview({super.key, this.parts = const []});

  /// The gallery's pages.
  final List<SimmerPart> parts;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = SimmerFrame.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final pitch = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('gloss_ui', style: t.caption.copyWith(color: c.jadeInk)),
        const SizedBox(height: GlossSpacing.small),
        Semantics(
          header: true,
          child: Text('Glazed parts under one\u00A0light.', style: t.display),
        ),
        const SizedBox(height: GlossSpacing.regular),
        Text(
          'A Flutter design system of moulded objects: a jade gel key for '
          'the one thing a screen is for, pearl beads and keys for what you '
          'handle, groups in wells pressed into a porcelain page. Every part '
          'is raised, level or sunken under the same light, and moves '
          'between them when you press it.',
          style: t.body.copyWith(color: c.inkSecondary),
        ),
        const SizedBox(height: GlossSpacing.large),
        Wrap(
          spacing: GlossSpacing.small,
          runSpacing: GlossSpacing.small,
          children: [
            GlossButton.filled(
              'Open Simmer',
              onPressed: () => frame.go(SimmerPlace.home),
            ),
            GlossButton(
              'See the parts',
              onPressed: parts.isEmpty
                  ? null
                  : () => frame.push(parts.first.build(theme.brightness)),
            ),
          ],
        ),
      ],
    );
    const live = _LivePiece();
    final screens = GlossWell(
      header: 'Simmer, a week of dinners',
      children: [
        GlossListTile(
          leading: const Icon(LucideIcons.house),
          title: 'Today',
          subtitle: 'Tonight’s dinner, then the week',
          onTap: () => frame.go(SimmerPlace.home),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.bookOpen),
          title: 'Recipes',
          subtitle: 'Search, diet chips and a grid of dishes',
          onTap: () => frame.go(SimmerPlace.recipes),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.cookingPot),
          title: 'A recipe',
          subtitle: 'Servings, ingredients, method and timers',
          onTap: () => frame.push(
            SimmerRecipePage(recipe: simmerRecipe('miso-aubergine')),
          ),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.shoppingBasket),
          title: 'Shopping list',
          subtitle: 'By aisle, ticked off as you go',
          onTap: () => frame.go(SimmerPlace.shopping),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.settings),
          title: 'Settings',
          subtitle: 'Diet, units, light and dark, right to left',
          onTap: () => frame.go(SimmerPlace.settings),
        ),
      ],
    );
    const package = GlossWell(
      header: 'In the package',
      children: [
        GlossListTile(
          leading: Icon(LucideIcons.layers),
          title: 'The everyday parts',
          subtitle:
              'Keys, beads, fields, selects, checkboxes, radios, switches, '
              'segments, steppers, sliders, chips, wells, rows, cards, bars, '
              'tabs, dialogs, sheets and toasts',
        ),
        GlossListTile(
          leading: Icon(LucideIcons.monitorSmartphone),
          title: 'Phone to desktop',
          subtitle: 'A bottom bar, a rail from 600, a sidebar from 1024',
        ),
        GlossListTile(
          leading: Icon(LucideIcons.sunMoon),
          title: 'Light and dark',
          subtitle: 'The same objects by day and in low light',
        ),
        GlossListTile(
          leading: Icon(LucideIcons.accessibility),
          title: 'For everyone',
          subtitle:
              'Readable on every glaze, keyboard and screen reader, large '
              'text, right to left, reduced motion',
        ),
      ],
    );
    final index = parts.isEmpty
        ? null
        : GlossWell(
            header: 'Every part',
            children: [
              for (final p in parts)
                GlossListTile(
                  title: p.title,
                  onTap: () => frame.push(p.build(theme.brightness)),
                ),
            ],
          );
    return SimmerPage(
      title: 'Gloss',
      maxWidth: wide ? 1080 : GlossMetrics.readingWidth,
      children: [
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: pitch),
              const SizedBox(width: GlossSpacing.huge),
              const SizedBox(width: 420, child: _LivePiece()),
            ],
          )
        else ...[
          pitch,
          simmerGroupGap,
          // A piece of the app, at a phone's width wherever it stands.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: live,
            ),
          ),
        ],
        simmerGroupGap,
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: screens),
              const SizedBox(width: GlossSpacing.extraLarge),
              const Expanded(child: package),
            ],
          )
        else ...[
          screens,
          simmerGroupGap,
          package,
        ],
        if (index != null) ...[simmerGroupGap, index],
      ],
    );
  }
}

/// A live piece of Simmer: a recipe's card with its servings and a switch,
/// every part working.
class _LivePiece extends StatefulWidget {
  const _LivePiece();

  @override
  State<_LivePiece> createState() => _LivePieceState();
}

class _LivePieceState extends State<_LivePiece> {
  int _servings = 2;
  bool _remind = true;
  String _when = 'tonight';

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final recipe = simmerRecipe('miso-aubergine');
    return GlossCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: SimmerDish(recipe: recipe, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.all(GlossSpacing.regular + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(recipe.name, style: t.title),
                const SizedBox(height: GlossSpacing.tight),
                Text(
                  '${simmerMinutes(recipe.minutes)} · ${recipe.cuisine}',
                  style: t.secondary,
                ),
                const SizedBox(height: GlossSpacing.regular),
                GlossSegmentedButton<String>(
                  expanded: true,
                  semanticLabel: 'When',
                  segments: const [
                    GlossSegment(value: 'tonight', label: 'Tonight'),
                    GlossSegment(value: 'tomorrow', label: 'Tomorrow'),
                  ],
                  selected: _when,
                  onChanged: (v) => setState(() => _when = v),
                ),
                const SizedBox(height: GlossSpacing.regular),
                GlossWell(
                  children: [
                    GlossListTile(
                      title: 'Servings',
                      trailing: GlossStepper(
                        value: _servings,
                        min: 1,
                        max: 8,
                        semanticLabel: 'Servings',
                        onChanged: (v) => setState(() => _servings = v),
                      ),
                    ),
                    GlossListTile(
                      title: 'Remind me at five',
                      trailing: GlossSwitch(
                        value: _remind,
                        semanticLabel: 'Remind me at five',
                        onChanged: (v) => setState(() => _remind = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
