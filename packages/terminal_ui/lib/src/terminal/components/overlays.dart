/// What comes up over the screen besides a dialog: a pane at the side, a
/// list of actions at the foot, a pane by what opened it (on a press or
/// under a pointer), a tooltip, and a menu.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/words.dart';
import '../internal/menu_marks.dart';
import '../internal/reveal.dart';
import '../internal/type_ahead.dart';
import '../primitives/menu.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
import 'dialog.dart';
import 'key_hint.dart';
import 'pane.dart';

/// A side sheet's face: a raised pane the screen's height, [title] cut
/// into its top line, the keys that work in its bottom one.
///
/// Show one with [showTermSideSheet].
class TermSideSheet extends StatelessWidget {
  /// A side sheet showing [child].
  const TermSideSheet({
    super.key,
    this.title,
    required this.child,
    this.footer = 'esc close',
    this.style,
  });

  /// What it is about.
  final String? title;

  /// What it shows; it scrolls when long.
  final Widget child;

  /// The keys that work in it.
  ///
  /// Left as `'esc close'`, it is the reader's words for it
  /// (`TermLocalizations.closeKeyHint`): Arabic or German in an app in either.
  final String? footer;

  /// Overrides, over the theme's [TermThemeData.sheetStyle]: `fill` (the
  /// ground), `foreground` (the title) and `edge` (the box lines).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final lh = context.termGrid.lineHeight;
    return TermPane(
      title: title,
      footer: termKeysShown(context)
          ? switch (footer) {
              final f? => termWords(
                context,
                f,
                'esc close',
                (w) => w.closeKeyHint,
              ),
              null => null,
            }
          : null,
      raised: true,
      focused: true,
      style: TermStyle.layered([style, theme.sheetStyle]),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: lh),
        child: child,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title, defaultValue: null));
  }
}

class _TermSideSheetRoute<T> extends RawSideSheetRoute<T> {
  _TermSideSheetRoute({
    required super.builder,
    super.edge,
    super.width,
    super.barrierColor,
    super.barrierLabel,
    super.semanticLabel,
  }) : super(
         dampingRatio: TermMotion.surface.dampingRatio,
         stiffness: TermMotion.surface.stiffness,
       );

  // Terminal's surfaces come up where they stay: a very short fade on the
  // route's spring, no slide (a finger's drag still moves the pane with
  // it).
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}

/// Raises the side sheet [builder] makes at the screen's [edge] (the end,
/// by default), [cols] cells wide, the screen behind dimmed: it comes up
/// in place in a very short fade, a finger drags it away, Escape or a tap
/// outside closes it, and it completes with what it pops.
///
/// ```dart
/// showTermSideSheet<void>(
///   context: context,
///   builder: (context) => const TermSideSheet(title: 'run #1482', child: RunDetails()),
/// );
/// ```
Future<T?> showTermSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  RawSheetEdge edge = RawSheetEdge.end,
  int cols = 44,
  String? semanticLabel,
  bool useRootNavigator = true,
}) {
  final theme = TermTheme.of(context);
  final grid = context.termGrid;
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    _TermSideSheetRoute<T>(
      edge: edge,
      width: grid.cols(cols),
      barrierColor: theme.background.withValues(alpha: 0.72),
      barrierLabel: RawWidgetsLocalizations.of(context)
          .modalBarrierDismissLabel,
      semanticLabel: semanticLabel,
      builder: (context, info) =>
          themes.wrap(SafeArea(child: Builder(builder: builder))),
    ),
  );
}

/// One choice of [showTermActionSheet].
@immutable
class TermSheetAction<T> {
  /// A choice saying [label] that completes the sheet with [value].
  const TermSheetAction({
    required this.label,
    required this.value,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What the sheet completes with.
  final T value;

  /// Whether it destroys something: in the danger ink.
  final bool isDestructiveAction;
}

/// A list of actions at the screen's foot: [title] cut into the top line,
/// [message] dim under it, a row per action (lit under the keyboard or a
/// pointer, the destructive in red) and `cancel` last. Completes with the
/// chosen action's value, or null.
///
/// ```dart
/// final what = await showTermActionSheet<String>(
///   context: context,
///   title: 'run #1482',
///   actions: const [
///     TermSheetAction(label: 'rerun', value: 'rerun'),
///     TermSheetAction(label: 'delete logs', value: 'delete', isDestructiveAction: true),
///   ],
/// );
/// ```
Future<T?> showTermActionSheet<T>({
  required BuildContext context,
  required List<TermSheetAction<T>> actions,
  String? title,
  String? message,
  String cancelLabel = 'cancel',
  TermStyle? style,
}) => showTermSheet<T>(
  context: context,
  builder: (context) => TermActionSheet<T>(
    title: title,
    message: message,
    actions: actions,
    cancelLabel: cancelLabel,
    style: style,
  ),
);

/// The face of [showTermActionSheet]: a sheet of action rows.
class TermActionSheet<T> extends StatelessWidget {
  /// A sheet of [actions].
  const TermActionSheet({
    super.key,
    required this.actions,
    this.title,
    this.message,
    this.cancelLabel = 'cancel',
    this.onSelected,
    this.style,
  });

  /// Takes the chosen action's value (null for cancel); null: the sheet
  /// pops its route with it.
  final ValueChanged<T?>? onSelected;

  /// The choices.
  final List<TermSheetAction<T>> actions;

  /// What they act on.
  final String? title;

  /// More about it, dim.
  final String? message;

  /// The last row's words.
  ///
  /// Left as `'cancel'`, it is the reader's words for it
  /// (`TermLocalizations.cancelLabel`): Arabic or German in an app in either.
  final String cancelLabel;

  /// Overrides for the sheet, over the theme's
  /// [TermThemeData.sheetStyle]; its rows read [TermThemeData.menuStyle].
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final lh = context.termGrid.lineHeight;
    void choose(T? value) {
      final take = onSelected;
      if (take != null) {
        take(value);
      } else {
        Navigator.of(context).pop(value);
      }
    }

    Widget row(String label, VoidCallback onPressed, {bool danger = false}) =>
        RawButton(
          onPressed: onPressed,
          semanticLabel: label,
          excludeSemantics: true,
          mouseCursor: SystemMouseCursors.click,
          builder: (context, states, _) =>
              TermMenuRow(label: label, states: states, danger: danger),
        );
    return TermSheet(
      title: title,
      footer: TermLocalizations.of(context).cancelKeyHint,
      style: style,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (message != null) ...[
            Text(message!, style: theme.dimStyle),
            SizedBox(height: lh),
          ],
          for (final a in actions)
            row(a.label, () => choose(a.value), danger: a.isDestructiveAction),
          SizedBox(height: lh / 2),
          row(
            termWords(context, cancelLabel, 'cancel', (w) => w.cancelLabel),
            () => choose(null),
          ),
        ],
      ),
    );
  }
}

RawPopoverPlacement _placement(BuildContext context) {
  final grid = context.termGrid;
  return RawPopoverPlacement(
    gap: 0,
    margin: grid.cellWidth,
    preferredExtent: grid.lines(6),
    matchAnchorWidth: false,
  );
}

Widget _surface(
  BuildContext context,
  RawPopoverInfo info, {
  required Widget child,
  required int cols,
  String? title,
  TermStyle? style,
}) {
  final theme = TermTheme.of(context);
  final grid = context.termGrid;
  return TermMenuReveal(
    info: info,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: grid.cols(cols)),
      child: TermPane(
        title: title,
        raised: true,
        focused: true,
        style: TermStyle.layered([style, theme.popoverStyle]),
        child: SingleChildScrollView(child: child),
      ),
    ),
  );
}

/// A raised pane by what opened it, revealed from its top line on a
/// press, as a menu is; focus goes in, Escape or a tap outside closes it.
///
/// ```dart
/// TermPopover(
///   anchorBuilder: (context, anchor) =>
///       TermButton(label: 'filters', onPressed: anchor.toggle),
///   builder: (context) => const FilterForm(),
/// )
/// ```
class TermPopover extends StatelessWidget {
  /// A popover over what [builder] makes, opened by [anchorBuilder]'s
  /// press.
  const TermPopover({
    super.key,
    required this.anchorBuilder,
    required this.builder,
    this.title,
    this.cols = 36,
    this.semanticLabel,
    this.style,
  });

  /// What opens it: give the anchor's `toggle` to its press.
  final DesignOverlayAnchorBuilder anchorBuilder;

  /// What it shows.
  final WidgetBuilder builder;

  /// Words cut into its top line.
  final String? title;

  /// The most cells across it takes.
  final int cols;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Overrides, over the theme's [TermThemeData.popoverStyle]: `fill`,
  /// `foreground` (the title) and `edge` (the box lines).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    placement: _placement(context),
    dampingRatio: TermMotion.reveal.dampingRatio,
    stiffness: TermMotion.reveal.stiffness,
    semanticLabel: semanticLabel ?? title,
    anchorBuilder: anchorBuilder,
    overlayBuilder: (context, info) => _surface(
      context,
      info,
      cols: cols,
      title: title,
      style: style,
      child: Builder(builder: builder),
    ),
  );
}

/// A raised pane that comes up while a pointer rests on [child] (or the
/// keyboard is on it, or a finger holds it): more about a person, a commit
/// or a link, read without leaving the screen.
///
/// ```dart
/// TermHoverCard(
///   builder: (context) => const Text('4f2a91c fix the cache key'),
///   child: TermLink(label: '4f2a91c', onPressed: openCommit),
/// )
/// ```
class TermHoverCard extends StatelessWidget {
  /// A card about [child].
  const TermHoverCard({
    super.key,
    required this.child,
    required this.builder,
    this.title,
    this.cols = 36,
    this.style,
  });

  /// What it is about.
  final Widget child;

  /// What it shows.
  final WidgetBuilder builder;

  /// Words cut into its top line.
  final String? title;

  /// The most cells across it takes.
  final int cols;

  /// Overrides, over the theme's [TermThemeData.popoverStyle].
  final TermStyle? style;

  @override
  Widget build(BuildContext context) => RawPopover(
    trigger: RawPopoverTrigger.hover,
    focusOnOpen: false,
    placement: _placement(context),
    dampingRatio: TermMotion.reveal.dampingRatio,
    stiffness: TermMotion.reveal.stiffness,
    semanticLabel: title,
    anchorBuilder: (context, anchor) => child,
    overlayBuilder: (context, info) => _surface(
      context,
      info,
      cols: cols,
      title: title,
      style: style,
      child: Builder(builder: builder),
    ),
  );
}

/// A line of words on a block of the foreground's ink, shown while a
/// pointer rests on [child] or the keyboard is on it, and after a long
/// press; a screen reader hears [message] as [child]'s tooltip.
///
/// The behaviour is Flutter's [RawTooltip]: the pointer may rest on the
/// tip, Escape hides it, and one shows at a time. ui_core's
/// [RawTooltipFocusFix] shows it on the keyboard's focus too, and
/// [RawTooltipPlacement] sets it on the line above, or below where there is
/// no line above. Terminal paints the block and its reveal.
///
/// ```dart
/// TermTooltip(message: 'rerun (r)', child: TermIconButton(glyph: 'r', semanticLabel: 'rerun', onPressed: rerun))
/// ```
class TermTooltip extends StatelessWidget {
  /// A tooltip saying [message] about [child].
  const TermTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
  });

  /// Its words.
  final String message;

  /// What it is about.
  final Widget child;

  /// Overrides, over the theme's [TermThemeData.tooltipStyle]: `fill` (the
  /// ground) and `foreground` (the words).
  final TermStyle? style;

  /// How long a pointer rests on [child] before the tip shows.
  static const Duration _hoverDelay = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.tooltipStyle], const {});
    final spring = DesignMotionPolicy.of(context)
        .effects(dampingRatio: 1, stiffness: 1600);
    // The tip comes and goes on its own spring. RawTooltip's animation says
    // only whether it shows: at once when it shows, and while it hides, as
    // long as the spring takes to close from open, so the tip stays until
    // it has closed.
    final closing = _settleTime(spring);
    // The message joins the child's node: one control, one node.
    return MergeSemantics(
      child: RawTooltipPlacement(
        // On the line above, the words a cell in from the screen's edges.
        placement: RawPopoverPlacement(
          side: RawPopoverSide.above,
          gap: 0,
          margin: grid.cellWidth,
          preferredExtent: grid.lineHeight,
          matchAnchorWidth: false,
        ),
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: message,
          hoverDelay: _hoverDelay,
          animationStyle: AnimationStyle(
            duration: Duration.zero,
            reverseDuration: closing,
          ),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, shown) => ExcludeSemantics(
            child: _TipPresence(
              shown: shown,
              spring: spring,
              builder: (context, presence) => TermReveal(
                presence: presence,
                above:
                    (RawTooltipPlacement.sideOf(context) ??
                        RawPopoverSide.above) ==
                    RawPopoverSide.above,
                child: ColoredBox(
                  color: own.fill ?? theme.foreground,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: grid.cellWidth),
                    child: SizedBox(
                      height: grid.lineHeight,
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          message,
                          maxLines: 1,
                          style: theme.textStyle.copyWith(
                            color: own.foreground ?? theme.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  // How long [spring] takes to close the tip from open: until its
  // simulation is done, to the millisecond above.
  static Duration _settleTime(SpringDescription spring) {
    final closing = designSpringSimulation(spring, from: 1, to: 0);
    var ms = 1;
    while (ms < 5000 && !closing.isDone(ms / 1000)) {
      ms++;
    }
    return Duration(milliseconds: ms);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}

// A tip's presence, 0 to 1, on [spring]: toward 1 while [shown] runs
// forward or has completed, toward 0 while it runs back.
class _TipPresence extends StatefulWidget {
  const _TipPresence({
    required this.shown,
    required this.spring,
    required this.builder,
  });

  final Animation<double> shown;
  final SpringDescription spring;
  final Widget Function(BuildContext context, Animation<double> presence)
  builder;

  @override
  State<_TipPresence> createState() => _TipPresenceState();
}

class _TipPresenceState extends State<_TipPresence>
    with SingleTickerProviderStateMixin {
  // Bounded: a tip's presence is a reveal, 0 to 1.
  late final AnimationController _presence = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _presence.addStatusListener(_settled);
    widget.shown.addStatusListener(_follow);
    _follow(widget.shown.status);
  }

  @override
  void didUpdateWidget(_TipPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shown != widget.shown) {
      oldWidget.shown.removeStatusListener(_follow);
      widget.shown.addStatusListener(_follow);
      _follow(widget.shown.status);
    }
  }

  @override
  void dispose() {
    widget.shown.removeStatusListener(_follow);
    _presence.dispose();
    super.dispose();
  }

  void _follow(AnimationStatus status) {
    final target = status.isForwardOrCompleted ? 1.0 : 0.0;
    if (_presence.value == target && !_presence.isAnimating) return;
    _presence.springTo(target, widget.spring);
  }

  // The spring started or came to rest: whether the tip is gone may change.
  void _settled(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  // A hiding tip is gone once its spring has closed it, as ui_core's tooltip
  // took it away then. RawTooltip's own animation can run on (it lasts as
  // long as a close from fully open), and the tip would stay in place,
  // unseen, where a pointer could bring it back.
  bool get _gone =>
      !widget.shown.isForwardOrCompleted &&
      !_presence.isAnimating &&
      _presence.value == 0;

  @override
  Widget build(BuildContext context) =>
      _gone ? const SizedBox.shrink() : widget.builder(context, _presence);
}

/// One item of a [TermMenu].
@immutable
class TermMenuItem {
  /// An item saying [label] that calls [onPressed].
  const TermMenuItem({
    required this.label,
    required this.onPressed,
    this.shortcut,
    this.isDestructiveAction = false,
  });

  /// Its words.
  final String label;

  /// What it does; null disables it.
  final VoidCallback? onPressed;

  /// The key that does the same, dim at the end.
  final String? shortcut;

  /// Whether it destroys something: in the danger ink.
  final bool isDestructiveAction;
}

/// A menu, by what opened it: a raised pane of rows revealed from its top
/// line, each with its key dim at the end. The keys and the pointer mark a
/// row with the accent (its words, and a block at its start). The keys
/// start on the first row; the arrows walk it, round from the last to the
/// first, Home and End go to the ends, a letter to the next row it starts;
/// Return picks, Escape closes and the keys are back on what opened it.
///
/// ```dart
/// TermMenu(
///   anchorBuilder: (context, anchor) =>
///       TermIconButton(glyph: '⋯', semanticLabel: 'more', onPressed: anchor.toggle),
///   items: [TermMenuItem(label: 'rerun', shortcut: 'r', onPressed: rerun)],
/// )
/// ```
class TermMenu extends StatelessWidget {
  /// A menu of [items], opened by [anchorBuilder]'s press.
  const TermMenu({
    super.key,
    required this.anchorBuilder,
    required this.items,
    this.cols = 28,
    this.semanticLabel,
    this.style,
  });

  /// What opens it: give the anchor's `toggle` to its press.
  final DesignOverlayAnchorBuilder anchorBuilder;

  /// Its items.
  final List<TermMenuItem> items;

  /// Its width in cells.
  final int cols;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Overrides for its rows, over the theme's
  /// [TermThemeData.menuStyle]: `fill` (the lit row) and `foreground`.
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    TermMenuMarks.watchInput();
    return RawPopover(
      placement: _placement(context),
      arrowKeyNavigation: true,
      dampingRatio: TermMotion.reveal.dampingRatio,
      stiffness: TermMotion.reveal.stiffness,
      semanticLabel: semanticLabel,
      anchorBuilder: anchorBuilder,
      overlayBuilder: (context, info) => TermMenuReveal(
        info: info,
        child: SizedBox(
          width: grid.cols(cols),
          child: TermPane(
            raised: true,
            focused: true,
            // A cell inside the frame each side, so a lit row's bar stands
            // clear of the frame's sides as of its top and bottom lines.
            padding: const TermInset(),
            // A letter takes the keys to the next item it starts; one row
            // current, shown once the keys or the pointer move.
            child: TermTypeAhead(
              child: TermMenuMarks(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final item in items)
                        RawButton(
                          onPressed: item.onPressed == null
                              ? null
                              : () {
                                  info.close();
                                  item.onPressed!();
                                },
                          semanticLabel: item.label,
                          excludeSemantics: true,
                          mouseCursor: item.onPressed == null
                              ? SystemMouseCursors.basic
                              : SystemMouseCursors.click,
                          builder: (context, states, _) => TermMenuRow(
                            label: item.label,
                            states: states,
                            trailing: termKeysShown(context)
                                ? item.shortcut
                                : null,
                            danger: item.isDestructiveAction,
                            style: style,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
