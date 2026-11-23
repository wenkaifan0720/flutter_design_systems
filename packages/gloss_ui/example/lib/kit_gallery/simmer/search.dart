/// Simmer's search: recipes found by name, cuisine or what goes in them,
/// with the ingredients that match; when nothing does, a page that says so
/// and offers what to try instead.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'data.dart';
import 'recipes.dart';
import 'simmer.dart';

/// The search page, opened on [initialQuery].
class SimmerSearch extends StatefulWidget {
  /// Search, typed as far as [initialQuery].
  const SimmerSearch({super.key, this.initialQuery = ''});

  /// What is in the field when it opens.
  final String initialQuery;

  @override
  State<SimmerSearch> createState() => _SimmerSearchState();
}

const _tryInstead = ['Lemon', 'Miso', 'Beans', 'Mushroom'];
const _recent = ['Orzo', 'Something quick', 'Tofu'];

class _SimmerSearchState extends State<SimmerSearch> {
  late final TextEditingController _field = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  String get _query => _field.text.trim().toLowerCase();

  void _search(String words) {
    _field.text = words;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = SimmerFrame.of(context);
    final q = _query;
    final recipes = [
      for (final r in simmerRecipes)
        if (q.isNotEmpty &&
            (r.name.toLowerCase().contains(q) ||
                r.cuisine.toLowerCase().contains(q) ||
                r.ingredients.any((i) => i.name.toLowerCase().contains(q))))
          r,
    ];
    final ingredients = <String, int>{};
    if (q.isNotEmpty) {
      for (final r in simmerRecipes) {
        for (final i in r.ingredients) {
          if (i.name.toLowerCase().contains(q)) {
            ingredients.update(i.name, (n) => n + 1, ifAbsent: () => 1);
          }
        }
      }
    }
    final List<Widget> body;
    if (q.isEmpty) {
      body = [
        GlossWell(
          header: 'Recent',
          children: [
            for (final words in _recent)
              GlossListTile(
                leading: const Icon(LucideIcons.history),
                title: words,
                onTap: () => _search(words),
              ),
          ],
        ),
      ];
    } else if (recipes.isEmpty) {
      body = [
        const SizedBox(height: GlossSpacing.large),
        GlossStateView(
          state: GlossState.empty,
          icon: const Icon(LucideIcons.searchX),
          title: '\u2066Nothing for “\u2068${_field.text.trim()}\u2069”\u2069',
          message: 'No recipe has that in its name or its ingredients. Try something in your cupboard.',
          actions: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: GlossSpacing.small,
              runSpacing: GlossSpacing.small,
              children: [
                for (final words in _tryInstead)
                  GlossChip(
                    label: words,
                    selected: false,
                    onSelected: (_) => _search(words),
                  ),
              ],
            ),
          ],
        ),
      ];
    } else {
      body = [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            start: GlossSpacing.regular,
            bottom: GlossSpacing.small,
          ),
          child: Text(
            glossPlural(
              context,
              recipes.length,
              one: '1 recipe',
              other: '${recipes.length} recipes',
            ),
            style: glossLetterpress(
              t.caption.copyWith(color: c.inkSecondary),
              c,
            ),
          ),
        ),
        GlossWell(
          dividerIndent: GlossListTile.leadingExtent,
          children: [
            for (final r in recipes)
              GlossListTile(
                leading: ExcludeSemantics(
                  child: SizedBox.square(
                    dimension: 40,
                    child: ClipOval(child: SimmerDish(recipe: r, radius: 20)),
                  ),
                ),
                title: r.name,
                subtitle: simmerRecipeSummary(context, r),
                onTap: () => frame.push(SimmerRecipePage(recipe: r)),
              ),
          ],
        ),
        if (ingredients.isNotEmpty) ...[
          simmerGroupGap,
          GlossWell(
            header: 'Ingredients',
            children: [
              for (final MapEntry(key: name, value: n) in ingredients.entries)
                GlossListTile(
                  leading: Icon(_glyphOf(name)),
                  title: name,
                  trailingText: glossPlural(
                    context,
                    n,
                    one: 'In 1 recipe',
                    other: 'In $n recipes',
                  ),
                  showChevron: false,
                ),
            ],
          ),
        ],
      ];
    }
    // Nothing found stands in the middle of the whole page, as every
    // state does; results keep the reading column.
    final none = _field.text.trim().isNotEmpty && recipes.isEmpty;
    return SimmerPage(
      title: 'Search',
      maxWidth: none ? double.infinity : GlossMetrics.readingWidth,
      // The field is as wide as the results under it.
      barBottom: Align(
        alignment: AlignmentDirectional.centerStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: GlossMetrics.readingWidth,
          ),
          child: GlossSearchField(
            controller: _field,
            hintText: 'Recipes, cuisines, ingredients',
            semanticLabel: 'Search recipes',
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
      children: body,
    );
  }
}

/// An ingredient's glyph: citrus for a citrus fruit, a grain for a grain, an
/// egg for eggs, a carrot for a root, a leaf otherwise.
IconData _glyphOf(String name) {
  final n = name.toLowerCase();
  if (RegExp('lemon|lime|orange|citrus|yuzu').hasMatch(n)) {
    return LucideIcons.citrus;
  }
  if (RegExp('rice|orzo|flour|oat|noodle|pasta|bread').hasMatch(n)) {
    return LucideIcons.wheat;
  }
  if (n.contains('egg')) return LucideIcons.egg;
  if (RegExp('carrot|parsnip|beet|radish|potato').hasMatch(n)) {
    return LucideIcons.carrot;
  }
  return LucideIcons.leaf;
}
