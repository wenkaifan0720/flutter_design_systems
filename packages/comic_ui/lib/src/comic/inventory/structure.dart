// The structural rows the shared inventory adds: the menu bar, the command palette, the data table, the
// scroll area, a resizable split, a reorderable list, swipe actions, pull to refresh and a tree. The design kit keeps
// the behaviour; every part here is Comic's ink: a rim, a caption fill for what is lit, a ring for the keyboard.
import 'package:ui_core/ui_core.dart';
import 'package:flutter/widgets.dart';

import '../controls.dart';
import '../glyphs.dart';
import '../layout.dart';
import '../localizations.dart';
import '../moves.dart';
import '../press.dart';
import '../raised.dart';
import '../rows.dart';
import '../styled.dart';
import '../tell.dart';
import '../theme.dart';
import 'action_rows.dart' show comicRaisedSurface;
import 'inputs.dart' show ComicBareEditor;

bool _lit(Set<WidgetState> states) =>
    !states.contains(WidgetState.disabled) &&
    (states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed) ||
        states.contains(WidgetState.selected));

const Set<WidgetState> _none = {};
const Set<WidgetState> _focused = {WidgetState.focused};

/// A row of menus across the head of a desktop window, each dropping a list of commands with their keys; arrow keys
/// walk the bar and the lists. An entry's `data`, when it is an `IconData`, is drawn beside its words.
///
/// ```dart
/// ComicMenuBar(menus: const [DesignMenuEntry(label: 'File', children: [DesignMenuEntry(label: 'New', shortcut: 'Ctrl+N')])])
/// ```
class ComicMenuBar extends StatelessWidget {
  /// Creates a [ComicMenuBar].
  const ComicMenuBar({super.key, required this.menus, this.label});

  /// The menus, in order; each one's `children` are its commands.
  final List<DesignMenuEntry> menus;

  /// What a screen reader calls the bar.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final look = ComicStyleOf([t.menuTheme], _none);
    final rim = comicRim(t, look, c.nightLine, 3);
    final shape = (look.shape ?? t.shapes.medium).copyWith(side: rim);
    final itemShape = comicInsetShape(
      look.shape ?? t.shapes.medium,
      rim.width + 4,
    );
    return DesignMenuBar(
      menus: menus,
      semanticLabel: label ?? DesignLocalizations.of(context).menuBarLabel,
      barBuilder: (context, items) => DecoratedBox(
        decoration: ShapeDecoration(color: look.fill ?? c.card, shape: shape),
        child: Padding(
          padding: EdgeInsets.all(rim.width + 4).add(shape.dimensions),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, item) in items.indexed) ...[
                  if (i > 0) const SizedBox(width: 2),
                  item,
                ],
              ],
            ),
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        if (level == DesignMenuLevel.menu) {
          return ComicMenuRowFace(
            states: states,
            label: entry.label,
            icon: entry.data is IconData ? entry.data! as IconData : null,
            checked: entry.checked == true,
            trailing: entry.isSubmenu
                ? const Icon(ComicGlyphs.forward, size: 18)
                : entry.shortcut == null
                ? null
                : Text(entry.shortcut!),
          );
        }
        final lit = _lit(states), off = states.contains(WidgetState.disabled);
        final ink = lit
            ? c.onCaption
            : off
            ? c.textSecondary
            : c.text;
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: ComicTapTarget.targetOf(context),
          ),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: itemShape,
              color: lit ? c.caption : const Color(0x00000000),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              // Its own height: under a parent that hands a tall loose height the bar stays a bar, and its menus
              // open under it.
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: Text(
                  entry.label,
                  style: t.type.button.copyWith(color: ink),
                ),
              ),
            ),
          ),
        );
      },
      dividerBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: t.rule(),
          child: ColoredBox(color: c.divider),
        ),
      ),
      surfaceBuilder: (context, info, items) => comicRaisedSurface(
        context,
        info.animation,
        info.maxSize,
        items,
        width: 280,
      ),
    );
  }
}

DesignCommandPalette _palette(
  BuildContext context, {
  required List<DesignCommand> commands,
  required bool autofocus,
  required double maxHeight,
  String? hint,
  String? label,
  ValueChanged<DesignCommand>? onRun,
  TextEditingController? controller,
  FocusNode? focusNode,
}) => DesignCommandPalette(
  commands: commands,
  focusNode: focusNode,
  autofocus: autofocus,
  maxHeight: maxHeight,
  onSelected: onRun,
  controller: controller,
  semanticLabel: label ?? DesignLocalizations.of(context).commandPaletteLabel,
  resultsMessage: DesignLocalizations.of(context).commandPaletteResultsMessage,
  fieldBuilder: (context, field) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Row(
      children: [
        Icon(
          ComicGlyphs.search,
          size: 20,
          color: ComicTheme.of(context).colors.text,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ComicBareEditor(
            focusNode: field.focusNode,
            controller: field.controller,
            label: label ?? DesignLocalizations.of(context).commandPaletteLabel,
            hint: hint ?? ComicLocalizations.of(context).searchCommands,
            onSubmitted: (_) => field.submit(),
          ),
        ),
      ],
    ),
  ),
  // The keyboard's row is the lit one; a resting pointer must not light a second.
  itemBuilder: (context, command, states) => ComicMenuRowFace(
    states: states.difference(const {WidgetState.hovered}),
    label: command.label,
    icon: command.data is IconData ? command.data! as IconData : null,
    trailing: command.shortcut == null ? null : Text(command.shortcut!),
  ),
  groupBuilder: (context, group) {
    final t = ComicTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Text(
        group.toUpperCase(),
        style: t.type.label.copyWith(color: t.colors.textSecondary),
      ),
    );
  },
  emptyBuilder: (context) {
    final t = ComicTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        DesignLocalizations.of(context).noResultsLabel,
        style: t.type.body,
        textAlign: TextAlign.center,
      ),
    );
  },
  layoutBuilder: (context, field, results) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      field,
      Flexible(child: ComicRuled(child: results)),
    ],
  ),
);

/// Rings its child while the keyboard is anywhere inside it.
class _FocusWithin extends StatefulWidget {
  const _FocusWithin({required this.shape, required this.child});

  final OutlinedBorder shape;
  final Widget child;

  @override
  State<_FocusWithin> createState() => _FocusWithinState();
}

class _FocusWithinState extends State<_FocusWithin> {
  bool _focus = false;

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onFocusChange: (on) => setState(() => _focus = on),
    child: ComicHighlight(
      states: _focus ? _focused : _none,
      shape: widget.shape,
      wash: false,
      child: widget.child,
    ),
  );
}

/// A field over a list of commands that narrows as you type; arrows walk it and Enter runs one. Stands inline on a
/// page. [showComicCommand] raises the same palette over the page, for Ctrl+K. A command's `data`, when it is an
/// `IconData`, is drawn beside its words.
///
/// ```dart
/// ComicCommand(commands: [DesignCommand(label: 'New issue', group: 'Issues', onPressed: create)])
/// ```
class ComicCommand extends StatelessWidget {
  /// Creates a [ComicCommand].
  const ComicCommand({
    super.key,
    required this.commands,
    this.hint,
    this.label,
    this.onRun,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.maxHeight = 320,
  });

  /// The commands, in the order they list with no query.
  final List<DesignCommand> commands;

  /// The field's prompt.
  final String? hint;

  /// What a screen reader calls the field and its results.
  final String? label;

  /// Runs a chosen command; null runs its own `onPressed`.
  final ValueChanged<DesignCommand>? onRun;

  /// The field's text; null keeps its own.
  final TextEditingController? controller;

  /// The field's focus node, if any; the palette makes its own when null.
  final FocusNode? focusNode;

  /// Whether the field takes focus when built.
  final bool autofocus;

  /// The results' greatest height before they scroll.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return _FocusWithin(
      shape: ComicStyleOf([t.menuTheme], _none).shape ?? t.shapes.medium,
      // A palette standing in the page: no plate, which is for one floating over it.
      child: ComicRaisedFrame(
        plate: false,
        child: _palette(
          context,
          commands: commands,
          focusNode: focusNode,
          autofocus: autofocus,
          maxHeight: maxHeight,
          hint: hint,
          label: label,
          onRun: onRun,
          controller: controller,
        ),
      ),
    );
  }
}

/// Raises the [ComicCommand] palette over the page with the field ready for typing. Choosing closes it, then runs the
/// command; Escape or a press on the scrim closes it and focus goes back where it was.
///
/// ```dart
/// showComicCommand(context, commands: [DesignCommand(label: 'New issue', onPressed: create)])
/// ```
Future<void> showComicCommand(
  BuildContext context, {
  required List<DesignCommand> commands,
  String? hint,
  String? label,
  double maxHeight = 340,
}) {
  final carry = comicCarryTo(
    context,
    Navigator.of(context, rootNavigator: true),
  );
  return showDesignCommandPalette(
    context: context,
    barrierColor: ComicTheme.of(context).colors.scrim,
    barrierLabel: DesignLocalizations.of(context).commandPaletteBarrierLabel,
    palette: (run) => _palette(
      context,
      commands: commands,
      autofocus: true,
      maxHeight: maxHeight,
      hint: hint,
      label: label,
      onRun: run,
    ),
    surfaceBuilder: (context, palette) => carry(
      context,
      Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ComicRaisedFrame(child: palette),
        ),
      ),
    ),
  );
}

const double _columnFloor = 104, _checkCell = 52;

/// A table of records the reader can sort, page and pick from: press a heading to sort, press a row or its box to pick
/// it; arrows walk the rows. For a few plain facts use [ComicTable]. Too narrow for its columns, it scrolls sideways.
///
/// ```dart
/// ComicDataTable<Map<String, String>>(controller: issues, cellBuilder: (context, row, column) => Text(row[column.id] ?? ''))
/// ```
class ComicDataTable<R> extends StatelessWidget {
  /// Creates a [ComicDataTable] over [controller].
  const ComicDataTable({
    super.key,
    required this.controller,
    required this.cellBuilder,
    this.selectable = true,
    this.onActivate,
  });

  /// The rows, columns, sort, page and selection.
  final DesignTableController<R> controller;

  /// Draws one cell; a [Text] takes the table's type.
  final Widget Function(
    BuildContext context,
    R row,
    DesignTableColumn<R> column,
  )
  cellBuilder;

  /// Whether a press and Space pick rows, with a box on each.
  final bool selectable;

  /// A row's Enter, or its press when the table does not pick.
  final ValueChanged<R>? onActivate;

  // At least the touch target tall: a heading sorts, a row picks.
  Widget _cell(double floor, bool numeric, Widget child) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: floor),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Align(
        alignment: numeric
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final words = ComicLocalizations.of(context);
    final rowShape = t.shapes.small;
    final floor = ComicTapTarget.targetOf(context);
    final table = DesignDataTable<R>(
      controller: controller,
      selectable: selectable,
      onActivate: onActivate,
      sortedHint: (direction) => direction == DesignSortDirection.ascending
          ? DesignLocalizations.of(context)
                .dataTableSortedHint(DesignSortDirection.ascending)
          : DesignLocalizations.of(context)
                .dataTableSortedHint(DesignSortDirection.descending),
      headerBuilder: (context, column, sort, states) => ComicHighlight(
        states: states,
        shape: rowShape,
        child: _cell(
          floor,
          column.numeric,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(column.label, style: t.type.title)),
              if (sort != null) ...[
                const SizedBox(width: 4),
                Icon(
                  sort == DesignSortDirection.ascending
                      ? ComicGlyphs.chevronUp
                      : ComicGlyphs.chevronDown,
                  size: 18,
                  color: c.text,
                ),
              ],
            ],
          ),
        ),
      ),
      headerRowBuilder: (context, cells) => DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.nightLine, width: t.rim(3)),
          ),
        ),
        child: Row(
          children: [
            if (selectable)
              SizedBox(
                width: _checkCell,
                child: Center(
                  child: ComicCheckbox(
                    value: switch (controller.pageSelection) {
                      DesignSelection.none => false,
                      DesignSelection.some => null,
                      DesignSelection.all => true,
                    },
                    tristate: true,
                    label: words.selectPage,
                    onChanged: (_) => controller.togglePage(),
                  ),
                ),
              ),
            for (final cell in cells) Expanded(child: cell),
          ],
        ),
      ),
      cellBuilder: (context, row, column) => _cell(
        floor,
        column.numeric,
        DefaultTextStyle.merge(
          style: column.numeric ? t.type.body.tabular : t.type.body,
          child: cellBuilder(context, row, column),
        ),
      ),
      rowBuilder: (context, row, cells) => ComicHighlight(
        states: row.states,
        shape: rowShape,
        // A Container, so the rule under a row is room of its own: the row's words stand on the middle of what is above
        // it, not on the middle of the row and its rule (the design kit's checks: 0.8 px low at 1440).
        child: Container(
          decoration: BoxDecoration(
            color: row.selected ? c.currentUserTint : null,
            border: row.index == controller.pageRows.length - 1
                ? null
                : Border(
                    bottom: BorderSide(color: c.divider, width: t.rule()),
                  ),
          ),
          child: Row(
            children: [
              if (selectable)
                // The row is the tab stop and says it is picked; the box is only for the pointer.
                SizedBox(
                  width: _checkCell,
                  child: Center(
                    child: ExcludeFocus(
                      child: ExcludeSemantics(
                        child: ComicCheckbox(
                          value: row.selected,
                          label: words.selectRow,
                          onChanged: (_) => row.toggle(),
                        ),
                      ),
                    ),
                  ),
                ),
              for (final cell in cells) Expanded(child: cell),
            ],
          ),
        ),
      ),
    );
    final need =
        controller.columns.length * _columnFloor +
        (selectable ? _checkCell : 0);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) => box.maxWidth >= need
                ? table
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: need, child: table),
                  ),
          ),
          if (controller.pageCount > 1) ...[
            const SizedBox(height: 12),
            Center(
              child: ComicPagination(
                count: controller.pageCount,
                page: controller.page,
                onChanged: controller.goToPage,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A scrolling region whose bar is drawn in Comic's ink and stays out of the way until it is wanted. Give [child] a
/// scroll view on [controller]; arrow keys scroll it when [label]led.
///
/// ```dart
/// ComicScrollArea(controller: scroll, child: ListView(controller: scroll, children: rows))
/// ```
class ComicScrollArea extends StatelessWidget {
  /// Creates a [ComicScrollArea].
  const ComicScrollArea({
    super.key,
    required this.controller,
    required this.child,
    this.axis = Axis.vertical,
    this.visibility = DesignScrollbarVisibility.auto,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// The scroll view's controller.
  final ScrollController controller;

  /// The scroll view.
  final Widget child;

  /// Which way it scrolls.
  final Axis axis;

  /// When the bar shows.
  final DesignScrollbarVisibility visibility;

  /// What a screen reader calls the region.
  final String? label;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final motion = ComicMotion.of(context);
    return DesignScrollArea(
      focusNode: focusNode,
      autofocus: autofocus,
      controller: controller,
      axis: axis,
      visibility: visibility,
      semanticLabel: label,
      thumbBuilder: (context, thumb) => AnimatedOpacity(
        opacity: thumb.visible ? 1 : 0,
        duration: motion.state,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: thumb.states.contains(WidgetState.pressed)
                  ? c.caption
                  : c.nightLine,
              shape: t.shapes.capsule,
            ),
          ),
        ),
      ),
      frameBuilder: (context, focused, area) => ComicHighlight(
        states: focused ? _focused : _none,
        shape: t.shapes.small,
        wash: false,
        child: area,
      ),
      child: child,
    );
  }
}

/// Two panes with an inked rule between them that drags to share the room; arrow keys move it when it has the focus.
///
/// ```dart
/// ComicResizable(first: list, second: detail, minFirst: 200, minSecond: 280)
/// ```
class ComicResizable extends StatelessWidget {
  /// Creates a [ComicResizable].
  const ComicResizable({
    super.key,
    required this.first,
    required this.second,
    this.axis = Axis.horizontal,
    this.fraction,
    this.initialFraction = .5,
    this.onChanged,
    this.minFirst = 0,
    this.minSecond = 0,
    this.label,
    this.focusNode,
    this.autofocus = false,
  });

  /// The pane before the rule.
  final Widget first;

  /// The pane after the rule.
  final Widget second;

  /// How the panes sit: side by side, or stacked.
  final Axis axis;

  /// [first]'s share, when the caller holds it.
  final double? fraction;

  /// [first]'s share to begin with, when the widget holds it.
  final double initialFraction;

  /// Told the new share as the rule moves.
  final ValueChanged<double>? onChanged;

  /// The least room each pane keeps.
  final double minFirst, minSecond;

  /// What a screen reader calls the rule.
  final String? label;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final thickness = t.rim(3);
    return DesignSplitView(
      focusNode: focusNode,
      autofocus: autofocus,
      first: first,
      second: second,
      axis: axis,
      fraction: fraction,
      initialFraction: initialFraction,
      onChanged: onChanged,
      minFirst: minFirst,
      minSecond: minSecond,
      dividerThickness: thickness,
      hitExtent: 20,
      semanticLabel: label ?? ComicLocalizations.of(context).resize,
      dividerBuilder: (context, states, axis) {
        final lit = _lit(states);
        final across = axis == Axis.horizontal;
        return Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.nightLine),
            OverflowBox(
              minWidth: across ? 14 : 40,
              maxWidth: across ? 14 : 40,
              minHeight: across ? 40 : 14,
              maxHeight: across ? 40 : 14,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: lit ? c.caption : c.card,
                  shape: t.shapes.capsule.copyWith(
                    side: BorderSide(
                      color: states.contains(WidgetState.focused)
                          ? t.focus.color
                          : c.nightLine,
                      width: thickness,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GripPainter extends CustomPainter {
  const _GripPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dots = Paint()..color = color;
    final middle = size.center(Offset.zero);
    for (final x in [-3.5, 3.5]) {
      for (final y in [-6.0, 0.0, 6.0]) {
        canvas.drawCircle(middle + Offset(x, y), 1.75, dots);
      }
    }
  }

  @override
  bool shouldRepaint(_GripPainter old) => old.color != color;
}

/// Rows the reader can put in their own order: drag a row by its dots, or long press it; a screen reader gets move up
/// and move down.
///
/// ```dart
/// ComicReorderableListView<String>(items: names, labelOf: (n) => n, onReorder: move, itemBuilder: (context, n) => Text(n))
/// ```
class ComicReorderableListView<T extends Object> extends StatelessWidget {
  /// Creates a [ComicReorderableListView].
  const ComicReorderableListView({
    super.key,
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.labelOf,
    this.keyOf,
    this.shrinkWrap = false,
    this.controller,
    this.padding,
  });

  /// The rows, in their order.
  final List<T> items;

  /// Told the row moved from one index to another.
  final void Function(int from, int to) onReorder;

  /// Draws a row's words.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// What a screen reader calls a row.
  final String Function(T item) labelOf;

  /// A row's identity, when the item itself is not.
  final Object Function(T item)? keyOf;

  /// Whether the list is only as tall as its rows.
  final bool shrinkWrap;

  /// The scroll position.
  final ScrollController? controller;

  /// Room around the rows.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    final shape = t.shapes.small.copyWith(
      side: BorderSide(color: c.nightLine, width: t.rim(3)),
    );
    return DesignReorderableList<T>(
      items: items,
      onReorder: onReorder,
      labelOf: labelOf,
      keyOf: keyOf,
      shrinkWrap: shrinkWrap,
      controller: controller,
      padding: padding,
      movedMessage: DesignLocalizations.of(context).reorderableListMovedMessage,
      proxyDecorator: (child, index, animation) => DecoratedBox(
        decoration: ShapeDecoration(color: c.card, shape: shape),
        child: child,
      ),
      itemBuilder: (context, item, reorder) => DecoratedBox(
        decoration: BoxDecoration(
          border: reorder.index == reorder.count - 1
              ? null
              : Border(
                  bottom: BorderSide(color: c.divider, width: t.rule()),
                ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: ComicTapTarget.targetOf(context),
          ),
          child: Row(
            children: [
              reorder.handle(
                comicOwnSize(
                  width: 40,
                  height: ComicTapTarget.targetOf(context),
                  child: CustomPaint(painter: _GripPainter(c.textSecondary)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: 12,
                    top: 8,
                    bottom: 8,
                  ),
                  child: DefaultTextStyle.merge(
                    style: t.type.body,
                    child: itemBuilder(context, item),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with commands hidden behind its edge: slide it to show them, press one, or slide all the way to run the first.
/// A destructive one is inked in the danger tone. An action's `data`, when it is an `IconData`, is drawn over its words.
/// Keep every action reachable another way.
///
/// ```dart
/// ComicSwipeActions(endActions: [DesignSwipeAction(label: 'Delete', onPressed: remove, destructive: true)], child: row)
/// ```
class ComicSwipeActions extends StatefulWidget {
  /// Creates a [ComicSwipeActions].
  const ComicSwipeActions({
    super.key,
    required this.child,
    this.startActions = const [],
    this.endActions = const [],
    this.actionExtent = 88,
    this.fullSwipe = true,
    this.onOpenChanged,
    this.initiallyOpen = false,
  });

  /// The row.
  final Widget child;

  /// The commands behind its start edge.
  final List<DesignSwipeAction> startActions;

  /// The commands behind its end edge.
  final List<DesignSwipeAction> endActions;

  /// Each command's width.
  final double actionExtent;

  /// Whether a slide all the way runs the first command.
  final bool fullSwipe;

  /// Told when the commands show and hide.
  final ValueChanged<bool>? onOpenChanged;

  /// Whether the end commands show from the start.
  final bool initiallyOpen;

  @override
  State<ComicSwipeActions> createState() => _ComicSwipeActionsState();
}

class _ComicSwipeActionsState extends State<ComicSwipeActions> {
  // Whether the keyboard is in the row itself (not in its commands).
  bool _rowFocused = false;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    // A slid row is cut at the row's edge, so it never runs over what stands beside the row; while the keyboard is in
    // the row the cut stands the ring's width further out, so the row's own ring shows whole.
    return ClipRect(
      clipper: _SwipeClip(_rowFocused ? t.focus.gap + t.focus.width : 0),
      child: DesignSwipeActions(
        startActions: widget.startActions,
        endActions: widget.endActions,
        actionExtent: widget.actionExtent,
        fullSwipe: widget.fullSwipe,
        onOpenChanged: widget.onOpenChanged,
        initiallyOpen: widget.initiallyOpen,
        actionBuilder: (context, action, state) {
          final fill = action.destructive ? c.tones.danger : c.caption;
          final ink = action.destructive ? c.card : c.onCaption;
          // A plate runs the row's full height and takes the control step, as
          // every framed part does; its wash and ring take that same plate.
          final plate = t.shapes.small;
          // The strip is clipped at the plates' edge, so a ring outside one would not show: the keyboard's ring stands
          // inside the plate, an opaque band of the card between it and the fill.
          final room = t.focus.gap + t.focus.width;
          final face = ComicHighlight(
            states: state.states,
            shape: plate,
            washColor: ink,
            ring: false,
            child: DecoratedBox(
              decoration: ShapeDecoration(color: fill, shape: plate),
              child: ClipRect(
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (action.data is IconData)
                          Icon(action.data! as IconData, size: 20, color: ink),
                        Text(
                          action.label,
                          softWrap: false,
                          style: t.type.small.copyWith(
                            color: ink,
                            fontWeight: state.armed ? FontWeight.w700 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          if (!state.states.contains(WidgetState.focused)) return face;
          return Stack(
            fit: StackFit.expand,
            children: [
              face,
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(room),
                  child: ComicHighlight(
                    states: state.states,
                    shape: comicInsetShape(plate, room),
                    wash: false,
                    ringGap: c.card,
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          );
        },
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          includeSemantics: false,
          onFocusChange: (focused) => setState(() => _rowFocused = focused),
          child: widget.child,
        ),
      ),
    );
  }
}

class _SwipeClip extends CustomClipper<Rect> {
  const _SwipeClip(this.room);

  /// How far past the row's edge the cut stands.
  final double room;

  @override
  Rect getClip(Size size) => (Offset.zero & size).inflate(room);

  @override
  bool shouldReclip(_SwipeClip old) => old.room != room;
}

/// A list that refreshes when pulled down from its top: the dial fills as it is pulled, spins while [onRefresh] runs and
/// ticks when done. Give it a scrolling [child].
///
/// ```dart
/// ComicRefreshIndicator(onRefresh: load, child: ListView(children: rows))
/// ```
class ComicRefreshIndicator extends StatelessWidget {
  /// Creates a [ComicRefreshIndicator].
  const ComicRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  /// Runs the refresh.
  final Future<void> Function() onRefresh;

  /// The scrolling list.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DesignPullToRefresh(
      onRefresh: onRefresh,
      refreshLabel: DesignLocalizations.of(context).refreshLabel,
      refreshingMessage: DesignLocalizations.of(context).refreshingMessage,
      doneMessage: DesignLocalizations.of(context).refreshedMessage,
      indicatorBuilder: (context, state) {
        final c = ComicTheme.of(context).colors;
        return Center(
          child: ExcludeSemantics(
            child: switch (state.mode) {
              DesignRefreshMode.done => Icon(
                ComicGlyphs.check,
                size: 26,
                color: c.text,
              ),
              DesignRefreshMode.refresh => const ComicCircularProgressIndicator(
                size: 28,
              ),
              _ => ComicCircularProgressIndicator(
                value: state.progress.clamp(0.0, 1.0),
                size: 28,
                color: state.mode == DesignRefreshMode.armed ? c.caption : null,
              ),
            },
          ),
        );
      },
      child: child,
    );
  }
}

/// A nested list that opens and closes: folders, chapters, an org chart. Press a parent to open it, a leaf to activate
/// it; arrows walk it and left and right fold it.
///
/// ```dart
/// ComicTreeView<String>(controller: tree, labelOf: (n) => n, onActivate: open)
/// ```
class ComicTreeView<T extends Object> extends StatelessWidget {
  /// Creates a [ComicTreeView].
  const ComicTreeView({
    super.key,
    required this.controller,
    required this.labelOf,
    this.onActivate,
    this.label,
  });

  /// The nodes, what is open and what is picked.
  final DesignTreeController<T> controller;

  /// A node's words.
  final String Function(T node) labelOf;

  /// Told when a leaf is pressed, or a row gets Enter.
  final ValueChanged<T>? onActivate;

  /// What a screen reader calls the tree.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    // The rows stand edge to edge on opaque faces, so a ring outside one is painted over by the next: it goes inside.
    final room = t.focus.gap + t.focus.width;
    return DesignTree<T>(
      controller: controller,
      labelOf: labelOf,
      onActivate: onActivate,
      semanticLabel: label,
      levelHint: DesignLocalizations.of(context).treeLevelHint,
      // A tree keeps a picked row, so the fill is the pick's (and a press's) and the keyboard's row wears the ring:
      // lit by focus as a menu's row is, it could not be told from the picked one.
      rowBuilder: (context, item) => Stack(
        children: [
          ComicMenuRowFace(
            states: {
              ...item.states.difference(const {
                WidgetState.hovered,
                WidgetState.focused,
              }),
              if (item.selected) WidgetState.selected,
            },
            label: labelOf(item.row.node),
            lead: 20.0 * item.row.depth + (item.hasChildren ? 0 : 30),
            icon: !item.hasChildren
                ? null
                : item.expanded
                ? ComicGlyphs.chevronDown
                : ComicGlyphs.forward,
          ),
          if (item.states.contains(WidgetState.focused))
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(room),
                child: ComicHighlight(
                  states: _focused,
                  shape: comicInsetShape(comicMenuRowShape(t), room),
                  wash: false,
                  // On a picked row the ring stands on the fill: the card's colour keeps it apart.
                  ringGap: t.colors.card,
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
