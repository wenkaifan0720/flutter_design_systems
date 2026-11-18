/// Simmer's Recipes: a search well, latching diet chips and a grid of
/// recipe tiles; and a recipe's page, with its servings stepper, its
/// ingredients scaled to them, its method with timers, and save.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'data.dart';
import 'simmer.dart';

/// Recipes.
class SimmerRecipes extends StatefulWidget {
  /// Recipes, its filter sheet open when [showFilter].
  const SimmerRecipes({super.key, this.showFilter = false, this.selected});

  /// Whether the filter sheet opens with it.
  final bool showFilter;

  /// The recipe shown beside the list on a desk, by id; the first when null.
  final String? selected;

  @override
  State<SimmerRecipes> createState() => _SimmerRecipesState();
}

class _SimmerRecipesState extends State<SimmerRecipes> {
  final Set<String> _diets = {};
  bool _quick = false;
  String _query = '';
  late String _selected = widget.selected ?? simmerRecipes.first.id;

  @override
  void initState() {
    super.initState();
    if (widget.showFilter) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openFilters();
      });
    }
  }

  List<SimmerRecipe> get _shown => [
    for (final r in simmerRecipes)
      if (_diets.every(r.diets.contains) &&
          (!_quick || r.minutes <= 25) &&
          (_query.isEmpty ||
              r.name.toLowerCase().contains(_query.toLowerCase())))
        r,
  ];

  // On a phone the filters rise from the foot; on a desk, beside the list
  // and the recipe, they slide in from the side.
  void _openFilters() =>
      (MediaQuery.sizeOf(context).width >= simmerSplitWidth
      ? showGlossSideSheet<void>
      : showGlossSheet<void>)(
        context: context,
        title: 'Filters',
        // Every filter the chips hold: the time as well as the diets.
        builder: (context) => StatefulBuilder(
          builder: (context, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlossWell(
                header: 'Time',
                children: [
                  GlossListTile(
                    title: 'Under 25 min',
                    trailing: GlossSwitch(
                      value: _quick,
                      onChanged: (on) {
                        setState(() => _quick = on);
                        setSheet(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GlossSpacing.large),
              GlossWell(
                header: 'Diet',
                children: [
                  for (final d in simmerDiets)
                    GlossListTile(
                      title: d,
                      trailing: GlossSwitch(
                        value: _diets.contains(d),
                        onChanged: (on) {
                          setState(() => on ? _diets.add(d) : _diets.remove(d));
                          setSheet(() {});
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        footerBuilder: (context) => GlossButton.filled(
          'Show recipes',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final frame = SimmerFrame.of(context);
    final shown = _shown;
    // Every chip in reach at once: they wrap rather than run off the edge.
    final chips = Wrap(
      spacing: GlossSpacing.small,
      runSpacing: GlossSpacing.small,
      children: [
        GlossChip(
          label: 'Under 25 min',
          selected: _quick,
          onSelected: (on) => setState(() => _quick = on),
        ),
        for (final d in simmerDiets)
          GlossChip(
            label: d,
            selected: _diets.contains(d),
            onSelected: (on) =>
                setState(() => on ? _diets.add(d) : _diets.remove(d)),
          ),
      ],
    );
    final filters = GlossIconButton(
      onPressed: _openFilters,
      tooltip: 'Filters',
      icon: const Icon(LucideIcons.slidersHorizontal),
    );
    // The same round-ended search well as the search page's.
    final search = GlossSearchField(
      hint: 'Search recipes',
      onChanged: (v) => setState(() => _query = v),
    );
    final count = Padding(
      padding: const EdgeInsetsDirectional.only(
        start: GlossSpacing.regular,
        bottom: GlossSpacing.small,
      ),
      child: Text(
        glossPlural(
          context,
          shown.length,
          one: '1 recipe',
          other: '${shown.length} recipes',
        ),
        style: glossLetterpress(
          t.caption.copyWith(color: theme.colors.inkSecondary),
          theme.colors,
        ),
      ),
    );
    if (MediaQuery.sizeOf(context).width >= simmerSplitWidth) {
      // A desk: the list and the chosen recipe side by side, the groove
      // between them moved by a drag or the arrows.
      final chosen = simmerRecipe(_selected);
      return GlossSplitView(
        initialFraction: 0.36,
        minFirst: 340,
        minSecond: 520,
        semanticLabel: 'Resize the list',
        // The search heads the list, under a strip as tall as the
        // recipe's, so the two strips' rules run on as one line.
        first: SimmerPage(
          title: 'Recipes',
          large: true,
          actions: [filters],
          children: [
            search,
            const SizedBox(height: GlossSpacing.regular),
            chips,
            const SizedBox(height: GlossSpacing.large),
            count,
            if (shown.isEmpty)
              const GlossWell(
                children: [
                  GlossListTile(
                    title: 'No recipes fit',
                    subtitle: 'Loosen a filter to see more',
                  ),
                ],
              )
            else
              GlossWell(
                dividerIndent: GlossListTile.leadingExtent,
                children: [
                  for (final r in shown)
                    GlossListTile(
                      leading: ExcludeSemantics(
                        child: SizedBox.square(
                          dimension: 40,
                          child: ClipOval(
                            child: SimmerDish(recipe: r, radius: 20),
                          ),
                        ),
                      ),
                      title: r.name,
                      subtitle: '${simmerMinutes(r.minutes)} · ${r.cuisine}',
                      selected: r.id == _selected,
                      showChevron: false,
                      onTap: () => setState(() => _selected = r.id),
                    ),
                ],
              ),
          ],
        ),
        second: SimmerRecipePage(key: ValueKey(chosen.id), recipe: chosen),
      );
    }
    return SimmerPage(
      title: 'Recipes',
      large: true,
      maxWidth: 1080,
      actions: [filters],
      barBottom: search,
      children: [
        chips,
        const SizedBox(height: GlossSpacing.large),
        count,
        if (shown.isEmpty)
          GlossWell(
            children: [
              GlossListTile(
                title: 'No recipes fit',
                subtitle: 'Loosen a filter to see more',
                trailing: GlossButton.text(
                  'Clear',
                  onPressed: () => setState(() {
                    _diets.clear();
                    _quick = false;
                  }),
                ),
              ),
            ],
          )
        else
          LayoutBuilder(
            builder: (context, box) {
              // Columns by the room the words need: large text gets
              // fewer, wider cards rather than cut names.
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final room = box.maxWidth / scale.clamp(1.0, 3.0);
              final columns = room >= 900
                  ? 4
                  : room >= 540
                  ? 3
                  : room >= 300
                  ? 2
                  : 1;
              const gap = GlossSpacing.regular;
              final each = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final r in shown)
                    SizedBox(
                      width: each,
                      child: SimmerRecipeTile(
                        recipe: r,
                        onTap: () => frame.push(SimmerRecipePage(recipe: r)),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// A recipe's tile: its dish, its name, its time.
class SimmerRecipeTile extends StatelessWidget {
  /// The tile of [recipe].
  const SimmerRecipeTile({super.key, required this.recipe, this.onTap});

  /// The recipe.
  final SimmerRecipe recipe;

  /// Opens it.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    return GlossCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: '${recipe.name}, ${simmerMinutes(recipe.minutes)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: SimmerDish(recipe: recipe, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              GlossSpacing.medium,
              GlossSpacing.medium,
              GlossSpacing.medium,
              GlossSpacing.medium + 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.label.copyWith(fontSize: 15, height: 20 / 15),
                ),
                const SizedBox(height: GlossSpacing.tight),
                Text(
                  '${simmerMinutes(recipe.minutes)} · ${recipe.cuisine}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.secondary.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A recipe's page.
class SimmerRecipePage extends StatefulWidget {
  /// The page of [recipe]; its method open first when [cooking].
  const SimmerRecipePage({
    super.key,
    required this.recipe,
    this.cooking = false,
  });

  /// The recipe.
  final SimmerRecipe recipe;

  /// Whether it opens on the method.
  final bool cooking;

  @override
  State<SimmerRecipePage> createState() => _SimmerRecipePageState();
}

class _SimmerRecipePageState extends State<SimmerRecipePage> {
  late int _servings = widget.recipe.serves;
  late int _tab = widget.cooking ? 1 : 0;
  bool _saved = false;
  final Set<int> _have = {};

  SimmerRecipe get _r => widget.recipe;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // Two columns where the page itself is wide, beside a list or not.
    builder: (context, box) => _page(context, twoColumns: box.maxWidth >= 900),
  );

  Widget _page(BuildContext context, {required bool twoColumns}) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(GlossMetrics.cardRadius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: SimmerDish(
              recipe: _r,
              radius: GlossMetrics.cardRadius,
              semanticLabel: 'A bowl of ${_r.name.toLowerCase()}',
            ),
          ),
        ),
        const SizedBox(height: GlossSpacing.large),
        Text(_r.cuisine, style: t.caption.copyWith(color: c.jadeInk)),
        const SizedBox(height: GlossSpacing.small),
        Semantics(
          header: true,
          // Large words grow the name up to 1.4 times: past that it would
          // fill the first screen.
          child: Text(
            _r.name,
            style: t.display,
            textScaler: MediaQuery.textScalerOf(context)
                .clamp(maxScaleFactor: 1.4),
          ),
        ),
        const SizedBox(height: GlossSpacing.small),
        Text(_r.blurb, style: t.body.copyWith(color: c.inkSecondary)),
        const SizedBox(height: GlossSpacing.regular),
        Wrap(
          spacing: GlossSpacing.small,
          runSpacing: GlossSpacing.small,
          children: [for (final d in _r.diets) _Tag(d)],
        ),
      ],
    );
    final servings = GlossWell(
      children: [
        GlossListTile(
          leading: const Icon(LucideIcons.users),
          title: 'Servings',
          trailing: GlossStepper(
            value: _servings,
            min: 1,
            max: 12,
            semanticLabel: 'Servings',
            onChanged: (v) => setState(() => _servings = v),
          ),
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.clock),
          title: 'Time',
          trailingText: simmerMinutes(_r.minutes),
        ),
      ],
    );
    final ingredients = GlossWell(
      header: 'Ingredients for $_servings',
      children: [
        for (final (i, ing) in _r.ingredients.indexed)
          SimmerCheckRow(
            value: _have.contains(i),
            onChanged: (v) =>
                setState(() => v ? _have.add(i) : _have.remove(i)),
            title: ing.name,
            trailingText: ing.amountFor(_servings),
          ),
      ],
    );
    final method = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const GlossSectionHeader('Method'),
        for (final (i, step) in _r.steps.indexed) ...[
          if (i > 0) const SizedBox(height: GlossSpacing.medium),
          _Step(number: i + 1, step: step),
        ],
      ],
    );
    final body = twoColumns
        ? [
            head,
            simmerGroupGap,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      servings,
                      const SizedBox(height: GlossSpacing.large),
                      ingredients,
                    ],
                  ),
                ),
                const SizedBox(width: GlossSpacing.extraLarge),
                Expanded(child: method),
              ],
            ),
          ]
        : [
            head,
            const SizedBox(height: GlossSpacing.large),
            servings,
            simmerGroupGap,
            GlossTabBar(
              tabs: const ['Ingredients', 'Method'],
              selectedIndex: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: GlossSpacing.large),
            if (_tab == 0) ingredients else method,
          ];
    // The page's head names the recipe in large type; the bar above it
    // keeps only the way back and the keys, not the name a second time.
    return SimmerPage(
      title: '',
      maxWidth: twoColumns ? 1000 : GlossMetrics.readingWidth,
      actions: [
        GlossIconButton(
          onPressed: () {
            setState(() => _saved = !_saved);
            showGlossToast(
              context,
              _saved ? 'Saved to your recipes' : 'Removed from your recipes',
            );
          },
          selected: _saved,
          tooltip: 'Save',
          icon: const Icon(LucideIcons.heart),
        ),
      ],
      bottom: SimmerKeys(
        primary: GlossButton.filled(
          'Add to this week',
          icon: const Icon(LucideIcons.calendarPlus),
          onPressed: () => showGlossToast(
            context,
            'Added to Saturday',
            actionLabel: 'Undo',
            onAction: () {},
          ),
        ),
      ),
      children: body,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    return SizedBox(
      height: 28,
      child: GlossSurface(
        face: GlossFace.well(theme.colors).copyWith(lift: -0.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: GlossSpacing.medium),
          child: Center(
            widthFactor: 1,
            child: Text(
              text,
              style: theme.textTheme.caption.copyWith(
                color: theme.colors.inkSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A step of the method: its number pressed into a socket, its words, and
/// its timer when it has one.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.step});

  final int number;
  final SimmerStep step;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox.square(
          dimension: 32,
          child: GlossSurface(
            face: GlossFace.well(c).copyWith(lift: -0.8),
            child: Center(
              child: Text(
                '$number',
                style: t.label.copyWith(fontSize: 14, color: c.jadeInk),
              ),
            ),
          ),
        ),
        const SizedBox(width: GlossSpacing.medium),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.text, style: t.body),
                if (step.timer != null) ...[
                  const SizedBox(height: GlossSpacing.small),
                  SimmerTimer(minutes: step.timer!),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A kitchen timer: its time in a sunken window, a pearl key to start and
/// pause it, its progress lit jade along a groove.
class SimmerTimer extends StatefulWidget {
  /// A timer of [minutes].
  const SimmerTimer({super.key, required this.minutes});

  /// Its length.
  final int minutes;

  @override
  State<SimmerTimer> createState() => _SimmerTimerState();
}

class _SimmerTimerState extends State<SimmerTimer> {
  Timer? _ticker;
  late int _left = widget.minutes * 60;

  bool get _running => _ticker != null;

  void _toggle() {
    if (_running) {
      _ticker!.cancel();
      setState(() => _ticker = null);
      return;
    }
    setState(() {
      if (_left == 0) _left = widget.minutes * 60;
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          _left = math.max(0, _left - 1);
          if (_left == 0) {
            _ticker?.cancel();
            _ticker = null;
          }
        });
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final c = theme.colors;
    final total = widget.minutes * 60;
    final clock = '${_left ~/ 60}:${(_left % 60).toString().padLeft(2, '0')}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: GlossSurface(
            face: GlossFace.well(c, radius: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GlossSpacing.medium,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.timer,
                    size: 16,
                    color: _running ? c.jadeInk : c.inkSecondary,
                  ),
                  const SizedBox(width: GlossSpacing.small),
                  Semantics(
                    liveRegion: _running,
                    label: 'Timer',
                    value: clock,
                    child: ExcludeSemantics(
                      child: Text(
                        clock,
                        style: theme.textTheme.label.copyWith(
                          fontSize: 15,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _running ? c.jadeInk : c.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: GlossSpacing.small),
                  SizedBox(
                    width: 48,
                    height: 6,
                    child: CustomPaint(
                      painter: _ProgressPainter(c, 1 - _left / total),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: GlossSpacing.small),
        GlossButton(
          _running
              ? 'Pause'
              : (_left < total && _left > 0 ? 'Resume' : 'Start'),
          onPressed: _toggle,
          style: const GlossStyle(
            minimumSize: WidgetStatePropertyAll(Size(0, 40)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: GlossSpacing.regular),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.colors, this.done);

  final GlossColors colors;
  final double done;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintGlossFace(canvas, rect, GlossFace.well(colors));
    if (done > 0) {
      paintGlossFace(
        canvas,
        Rect.fromLTWH(
          0,
          0,
          math.max(size.height, size.width * done),
          size.height,
        ),
        GlossFace.well(colors).copyWith(
          top: colors.jadeBottom,
          middle: colors.jade,
          bottom: colors.jadeTop,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      old.colors != colors || old.done != done;
}
