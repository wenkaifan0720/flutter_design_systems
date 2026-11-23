/// Simmer's week planner: the seven days as a well of rows, a tray of
/// recipes to drag onto them (a day's menu does the same without a drag),
/// and the shopping list made from the week. Clearing the week asks first.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'art.dart';
import 'data.dart';
import 'simmer.dart';

/// The week planner.
class SimmerPlanner extends StatefulWidget {
  /// The planner; with [confirmClear] it opens asking to clear the week.
  const SimmerPlanner({super.key, this.confirmClear = false});

  /// Whether it opens on the clear-the-week dialog.
  final bool confirmClear;

  @override
  State<SimmerPlanner> createState() => _SimmerPlannerState();
}

class _SimmerPlannerState extends State<SimmerPlanner> {
  List<String?> get _week => SimmerFrame.of(context).week;

  @override
  void initState() {
    super.initState();
    if (widget.confirmClear) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confirmClear();
      });
    }
  }

  int get _planned => _week.whereType<String>().length;

  void _put(int day, String? id) {
    final frame = SimmerFrame.of(context);
    setState(() => frame.planDinner(day, id));
    showGlossToast(
      context,
      id == null
          ? '${simmerDays[day]} is a night off'
          : '${simmerRecipe(id).name} on ${simmerDays[day]}',
    );
  }

  Future<void> _confirmClear() async {
    final cleared = await showGlossDialog<bool>(
      isAlert: true,
      context: context,
      builder: (context) => GlossDialog(
        title: 'Delete this week’s plan?',
        content: Text(
          glossPlural(
            context,
            _planned,
            one: 'The one dinner in it goes back to your recipes. The shopping list stays as it is.',
            other:
                'The $_planned dinners in it go back to your recipes. The shopping list stays as it is.',
          ),
        ),
        actions: [
          GlossDialogAction(
            label: 'Keep',
            onPressed: () => Navigator.of(context).pop(false),
          ),
          GlossDialogAction(
            label: 'Delete plan',
            isDefaultAction: true,
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (cleared != true || !mounted) return;
    final frame = SimmerFrame.of(context);
    final before = [..._week];
    setState(() => frame.replaceWeek(List.filled(before.length, null)));
    showGlossToast(
      context,
      'The week is clear',
      actionLabel: 'Undo',
      onAction: () {
        if (!frame.mounted) return;
        frame.replaceWeek(before);
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final frame = SimmerFrame.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 1024;
    final phone = width < 600;
    final days = GlossWell(
      header: 'Dinners',
      dividerIndent: GlossListTile.leadingExtent,
      children: [
        for (var i = 0; i < simmerDays.length; i++)
          _DayRow(
            day: i,
            recipe: _week[i] == null ? null : simmerRecipe(_week[i]!),
            onPut: (id) => _put(i, id),
          ),
      ],
    );
    final hint = Text(
      phone
          ? 'Press and hold a recipe, then drag it onto a day.'
          : 'Drag a recipe onto a day, or choose from a day’s menu.',
      style: glossLetterpress(t.secondary, c),
    );
    final tray = wide
        ? GlossWell(
            header: 'Recipes',
            dividerIndent: GlossListTile.leadingExtent,
            children: [
              for (final r in simmerRecipes)
                _Draggable(
                  recipe: r,
                  longPress: false,
                  child: GlossListTile(
                    leading: _Thumb(recipe: r),
                    title: r.name,
                    subtitle: simmerMinutes(r.minutes),
                    trailing: Icon(
                      LucideIcons.gripVertical,
                      color: c.inkSecondary,
                    ),
                    showChevron: false,
                  ),
                ),
            ],
          )
        : SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: simmerRecipes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: GlossSpacing.small),
              itemBuilder: (context, i) => Center(
                child: _Draggable(
                  recipe: simmerRecipes[i],
                  longPress: phone,
                  child: _Puck(recipe: simmerRecipes[i]),
                ),
              ),
            ),
          );
    final makeList = GlossButton.filled(
      'Make the shopping list',
      icon: const Icon(LucideIcons.shoppingBasket),
      onPressed: _planned == 0
          ? null
          : () {
              final count = _planned;
              final servings = SimmerPrefs.of(context).household;
              Navigator.of(context).popUntil((route) => route.isFirst);
              frame.makeShoppingList(servings);
              showGlossToast(
                context,
                glossPlural(
                  context,
                  count,
                  one: 'The list has 1 dinner in it',
                  other: 'The list has $count dinners in it',
                ),
              );
            },
    );
    final clear = GlossButton.text(
      'Clear',
      isDestructiveAction: true,
      onPressed: _planned == 0 ? null : _confirmClear,
    );
    return SimmerPage(
      title: 'This week',
      maxWidth: wide ? 1080 : GlossMetrics.readingWidth,
      bottom: SimmerKeys(primary: makeList, secondary: clear),
      children: wide
          ? [
              hint,
              const SizedBox(height: GlossSpacing.large),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: days),
                  const SizedBox(width: GlossSpacing.extraLarge),
                  Expanded(flex: 4, child: tray),
                ],
              ),
            ]
          : [
              hint,
              const SizedBox(height: GlossSpacing.regular),
              tray,
              simmerGroupGap,
              days,
            ],
    );
  }
}

/// A day's row: what is planned, a drop place for a dragged recipe, and a
/// menu to choose one without dragging.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.recipe, required this.onPut});

  final int day;
  final SimmerRecipe? recipe;
  final ValueChanged<String?> onPut;

  @override
  Widget build(BuildContext context) {
    final name = simmerDays[day];
    return DragTarget<SimmerRecipe>(
      onAcceptWithDetails: (details) => onPut(details.data.id),
      builder: (context, candidates, _) {
        final over = candidates.isNotEmpty;
        final r = recipe;
        return GlossListTile(
          leading: r == null
              ? const Icon(LucideIcons.moon)
              : _Thumb(recipe: r, size: 32),
          title: over
              ? 'Drop on $name'
              : r == null
              ? 'Night off'
              : r.name,
          subtitle: r == null || over
              ? name
              : '$name · ${simmerMinutes(r.minutes)}',
          selected: over || day == simmerToday,
          showChevron: false,
          trailing: GlossMenu(
            semanticLabel: 'Dinner on $name',
            alignEnd: true,
            items: [
              for (final option in simmerRecipes)
                GlossMenuItem(
                  label: option.name,
                  onPressed: () => onPut(option.id),
                ),
              if (r != null)
                GlossMenuItem(
                  label: 'Night off',
                  icon: LucideIcons.moon,
                  onPressed: () => onPut(null),
                ),
            ],
            builder: (context, toggle, open) => GlossIconButton.plain(
              onPressed: toggle,
              isSelected: open,
              tooltip: 'Choose dinner for $name',
              icon: const Icon(LucideIcons.ellipsis),
            ),
          ),
        );
      },
    );
  }
}

/// A recipe that drags: a long press first on a phone (the tray scrolls
/// under a finger), at once with a pointer.
class _Draggable extends StatelessWidget {
  const _Draggable({
    required this.recipe,
    required this.longPress,
    required this.child,
  });

  final SimmerRecipe recipe;
  final bool longPress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lifted = _Puck(recipe: recipe, lifted: true);
    final resting = Opacity(opacity: 0.45, child: child);
    final body = MouseRegion(cursor: SystemMouseCursors.grab, child: child);
    return Semantics(
      hint: 'Drag onto a day, or choose it from a day’s menu',
      child: longPress
          ? LongPressDraggable<SimmerRecipe>(
              data: recipe,
              delay: const Duration(milliseconds: 300),
              feedback: lifted,
              childWhenDragging: resting,
              child: body,
            )
          : Draggable<SimmerRecipe>(
              data: recipe,
              feedback: lifted,
              childWhenDragging: resting,
              child: body,
            ),
    );
  }
}

/// A recipe as a pearl puck: its dish and its name.
class _Puck extends StatelessWidget {
  const _Puck({required this.recipe, this.lifted = false});

  final SimmerRecipe recipe;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final theme = context.glossTheme;
    return SizedBox(
      height: 48,
      child: GlossSurface(
        face: GlossFace.pearl(theme.colors).copyWith(lift: lifted ? 1 : 0.6),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            6,
            6,
            GlossSpacing.regular,
            6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Thumb(recipe: recipe, size: 36),
              const SizedBox(width: GlossSpacing.small),
              Text(
                recipe.name,
                maxLines: 1,
                style: theme.textTheme.label.copyWith(
                  fontSize: 14,
                  color: theme.colors.ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A recipe's dish, small and round.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.recipe, this.size = 40});

  final SimmerRecipe recipe;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: SimmerDish(recipe: recipe, radius: size / 2),
      ),
    ),
  );
}
