import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/menu_row.dart';
import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../icon-button/icon_button.dart';

/// The scrim under a sheet: ink by day, a deeper black by night, as the
/// dialog's.
Color _scrim(CivicThemeData t) => t.isDark
    ? const Color(0xFF000000).withValues(alpha: 0.85)
    : const Color(0xFF0C1116).withValues(alpha: 0.6);

/// Raises [builder]'s content from the foot of the screen on a sheet: the
/// page's face on a hairline and the soft shadow, its top corners rounded
/// as a card's, a grabber over its [title] and a Close button at the
/// title's end, the content under them scrolling, [actions] at its foot
/// over a hairline. From 600 wide it stands on the reading measure,
/// centred. ui_core's [RawBottomSheetRoute], Civic's painting.
///
/// It rises on Civic's panel spring (under Reduce Motion it fades) and
/// rides above the on-screen keyboard. A drag on the grabber or the title
/// moves it; let go low or flung down, it closes; with [snapSizes] it rests
/// at each (shares of the screen), its content handing the drag on from
/// its top. The grabber is a button too: a press moves it to the next size,
/// and a screen reader hears it. Close, Escape, Android's back and a press
/// on the scrim close it ([isDismissible] false leaves only its own
/// buttons), and the focus goes back to what opened it. Completes with
/// what it pops with.
///
/// A sheet holds a short task beside the page (filters, a choice of
/// places): never the page's one question, which is a page of its own.
///
/// Reads [CivicStyle]'s fill and edge (the sheet), foreground, padding and
/// textStyle (the title): its `style:`, then [CivicThemeData.sheetStyle].
///
/// ```dart
/// showCivicBottomSheet<void>(
///   context: context,
///   title: 'Filter applications',
///   builder: (context) => const Text('Status'),
///   actions: [CivicButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Show applications'))],
/// );
/// ```
Future<T?> showCivicBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  List<Widget> actions = const [],
  List<double>? snapSizes,
  double? initialSize,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showClose = true,
  bool useRootNavigator = true,
  String? semanticLabel,
  CivicStyle? style,
}) {
  final t = CivicTheme.of(context);
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    RawBottomSheetRoute<T>(
      snapSizes: snapSizes,
      initialSize: initialSize,
      enableDrag: enableDrag,
      useSafeArea: true,
      barrierDismissible: isDismissible,
      barrierColor: _scrim(t),
      semanticLabel: semanticLabel ?? title,
      dampingRatio: CivicMotion.panel.dampingRatio,
      stiffness: CivicMotion.panel.stiffness,
      builder: (sheetContext, details) => CivicTheme(
        data: t,
        child: PopScope<T>(
          canPop: isDismissible,
          child: _BottomPanel(
            title: title,
            actions: actions,
            grabber: enableDrag,
            close: showClose && isDismissible ? details.close : null,
            scrollController: details.scrollController,
            fills: snapSizes != null && snapSizes.isNotEmpty,
            style: style,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

/// Slides [builder]'s content in from the page's end (its start with
/// [edge] start) on a sheet the screen's height: the page's face over a
/// hairline and the soft shadow, its [title] at the top with a Close button
/// at its end, the content scrolling under it, [actions] at its foot over a
/// hairline. [width] wide from 600 (at most the screen less 56); below 600
/// it takes the screen's width, so its words keep their length at any text
/// size.
/// ui_core's [RawSideSheetRoute], Civic's painting.
///
/// It slides on Civic's panel spring (under Reduce Motion it fades); a drag
/// toward its edge closes it. Close, Escape, Android's back and a press on
/// the scrim close it, and the focus goes back to what opened it. Completes
/// with what it pops with.
///
/// On a desk a list's filters stand in it; on a phone, a bottom sheet
/// ([showCivicBottomSheet]) holds them.
///
/// Reads [CivicStyle] as [showCivicBottomSheet] does:
/// [CivicThemeData.sheetStyle].
///
/// ```dart
/// showCivicSideSheet<void>(
///   context: context,
///   title: 'Filter applications',
///   builder: (context) => const Text('Status'),
/// );
/// ```
Future<T?> showCivicSideSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  List<Widget> actions = const [],
  RawSheetEdge edge = RawSheetEdge.end,
  double width = 400,
  bool isDismissible = true,
  bool useRootNavigator = true,
  String? semanticLabel,
  CivicStyle? style,
}) {
  final t = CivicTheme.of(context);
  final phone =
      (MediaQuery.maybeSizeOf(context)?.width ?? CivicLayout.medium) <
      CivicLayout.medium;
  return Navigator.of(context, rootNavigator: useRootNavigator).push(
    RawSideSheetRoute<T>(
      edge: edge,
      width: phone ? double.infinity : width,
      minGap: phone ? 0 : 56,
      barrierDismissible: isDismissible,
      barrierColor: _scrim(t),
      semanticLabel: semanticLabel ?? title,
      dampingRatio: CivicMotion.panel.dampingRatio,
      stiffness: CivicMotion.panel.stiffness,
      builder: (sheetContext, info) => CivicTheme(
        data: t,
        child: PopScope<T>(
          canPop: isDismissible,
          child: _SidePanel(
            title: title,
            actions: actions,
            close: info.close,
            left: info.side == AxisDirection.left,
            style: style,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

/// One of an action sheet's actions: its [label], the [value] it answers
/// with, a glyph before it ([icon]), the error colour when it destroys
/// something ([isDestructiveAction]).
///
/// ```dart
/// CivicActionSheetAction(value: 'withdraw', label: 'Withdraw application', isDestructiveAction: true)
/// ```
@immutable
class CivicActionSheetAction<T> {
  /// An action answering [value], worded [label].
  const CivicActionSheetAction({
    required this.value,
    required this.label,
    this.icon,
    this.isDestructiveAction = false,
    this.enabled = true,
  });

  /// What [showCivicActionSheet] answers when it is chosen.
  final T value;

  /// What it does, in words.
  final String label;

  /// A glyph before [label].
  final IconData? icon;

  /// Whether it destroys something: its words in the error colour.
  final bool isDestructiveAction;

  /// Whether it can be chosen.
  final bool enabled;
}

/// Raises a bottom sheet of worded [actions] for one thing (an
/// application, a document), with a [title] and a [message] over them and
/// Cancel apart at the foot ([cancelLabel]; the localized Cancel by
/// default); completes with the value chosen, or null on Cancel, Escape,
/// Android's back or the scrim. The actions are rows: a pointer greys one,
/// the keys move the yellow plate over the ink bar, one that destroys
/// something says so in the error colour.
///
/// Each action is also reachable on the thing's own page: an action sheet
/// gathers them, it never hides one.
///
/// ```dart
/// final action = await showCivicActionSheet<String>(
///   context: context,
///   title: 'Application BRM-4821-K',
///   actions: const [
///     CivicActionSheetAction(value: 'print', label: 'Print your answers'),
///     CivicActionSheetAction(value: 'withdraw', label: 'Withdraw application', isDestructiveAction: true),
///   ],
/// );
/// ```
Future<T?> showCivicActionSheet<T>({
  required BuildContext context,
  required List<CivicActionSheetAction<T>> actions,
  String? title,
  String? message,
  String? cancelLabel,
  bool useRootNavigator = true,
  CivicStyle? style,
}) => showCivicBottomSheet<T>(
  context: context,
  title: title,
  showClose: false,
  useRootNavigator: useRootNavigator,
  semanticLabel: title,
  style: style,
  actions: [
    Builder(
      builder: (context) => CivicButton.secondary(
        expand: true,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          cancelLabel ?? RawWidgetsLocalizations.of(context).cancelButtonLabel,
        ),
      ),
    ),
  ],
  builder: (sheetContext) => _ActionList<T>(
    actions: actions,
    message: message,
    onSelected: (value) => Navigator.of(sheetContext).pop(value),
  ),
);

class _ActionList<T> extends StatelessWidget {
  const _ActionList({
    required this.actions,
    required this.message,
    required this.onSelected,
  });

  final List<CivicActionSheetAction<T>> actions;
  final String? message;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final glyphs = actions.any((a) => a.icon != null);
    final words = message;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (words != null)
          Padding(
            padding: const EdgeInsets.only(bottom: CivicSpacing.s12),
            child: Text(
              words,
              style: text.body.copyWith(color: t.textSecondary),
            ),
          ),
        // The rows reach the sheet's edges, as a menu's reach its panel's.
        _Bleed(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final a in actions)
                RawButton(
                  onPressed: a.enabled ? () => onSelected(a.value) : null,
                  semanticLabel: a.label,
                  excludeSemantics: true,
                  mouseCursor: a.enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  builder: (context, states, _) => CivicMenuRow(
                    label: a.label,
                    states: states,
                    icon: a.icon,
                    glyphColumn: glyphs,
                    destructive: a.isDestructiveAction,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lets its child reach past the sheet's side margins to its hairlines,
/// which stay drawn.
class _Bleed extends StatelessWidget {
  const _Bleed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reach = _margin(context) - _hairline;
    return LayoutBuilder(
      builder: (context, box) => OverflowBox(
        minWidth: box.maxWidth + 2 * reach,
        maxWidth: box.maxWidth + 2 * reach,
        // As tall as its rows: a sheet's content is measured by them.
        fit: OverflowBoxFit.deferToChild,
        child: child,
      ),
    );
  }
}

/// The width of a sheet's hairline (`civicFloating`'s border).
const double _hairline = 1;

/// A sheet's side margin: the page's on a phone, wider from 600.
double _margin(BuildContext context) =>
    (MediaQuery.maybeSizeOf(context)?.width ?? 0) < CivicLayout.medium
    ? CivicSpacing.s16
    : CivicSpacing.s24;

/// The title row: the title as a heading and, at its end, Close.
class _Head extends StatelessWidget {
  const _Head({required this.title, required this.close, required this.so});

  final String? title;
  final VoidCallback? close;
  final DesignStyleOf so;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final heading = title;
    final shut = close;
    if (heading == null && shut == null) return const SizedBox.shrink();
    final words = RawWidgetsLocalizations.of(context).closeButtonLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: heading == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: CivicSpacing.s8),
                  child: Semantics(
                    header: true,
                    child: Text(
                      heading,
                      style: text.headingM
                          .merge(so.textStyle)
                          .copyWith(color: so.foreground ?? t.textPrimary),
                    ),
                  ),
                ),
        ),
        if (shut != null)
          // Its corner meets the sheet's margin, so the glyph lines up with
          // the content's end.
          Transform.translate(
            offset: Offset(
              Directionality.of(context) == TextDirection.rtl
                  ? -CivicSpacing.s12
                  : CivicSpacing.s12,
              0,
            ),
            child: CivicIconButton(
              icon: LucideIcons.x,
              semanticLabel: words,
              tooltip: words,
              onPressed: shut,
            ),
          ),
      ],
    );
  }
}

/// The foot: the sheet's actions over a hairline, kept in sight while the
/// content scrolls.
class _Foot extends StatelessWidget {
  const _Foot({required this.actions, required this.margin});

  final List<Widget> actions;
  final double margin;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.rule)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          margin,
          CivicSpacing.s16,
          margin,
          CivicSpacing.s16,
        ),
        child: Wrap(
          spacing: CivicSpacing.s16,
          runSpacing: CivicSpacing.s12,
          children: actions,
        ),
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.title,
    required this.actions,
    required this.grabber,
    required this.close,
    required this.scrollController,
    required this.fills,
    required this.style,
    required this.child,
  });

  final String? title;
  final List<Widget> actions;
  final bool grabber;
  final VoidCallback? close;
  final ScrollController scrollController;
  final bool fills;
  final CivicStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf([style, t.sheetStyle], const {});
    final margin = _margin(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    const corner = Radius.circular(CivicMetrics.cardCorner);
    final face = so.fill ?? t.background;
    final sheet = DecoratedBox(
      decoration: civicFloating(
        face: face,
        hairline: so.edge ?? t.rule,
        dark: t.isDark,
      ).copyWith(borderRadius: const BorderRadius.vertical(top: corner)),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: corner),
        child: Column(
          mainAxisSize: fills ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (grabber)
              const Center(child: _Grabber())
            else
              const SizedBox(height: CivicSpacing.s16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: _Head(title: title, close: close, so: so),
            ),
            Flexible(
              fit: fills ? FlexFit.tight : FlexFit.loose,
              child: PrimaryScrollController(
                controller: scrollController,
                child: SingleChildScrollView(
                  primary: true,
                  padding: EdgeInsets.fromLTRB(
                    so.padding(Directionality.of(context))?.left ?? margin,
                    CivicSpacing.s16,
                    so.padding(Directionality.of(context))?.right ?? margin,
                    actions.isEmpty ? CivicSpacing.s24 + bottom : 24,
                  ),
                  child: DefaultTextStyle(
                    style: context.civicText.body.copyWith(
                      color: t.textPrimary,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: bottom),
                child: _Foot(actions: actions, margin: margin),
              ),
          ],
        ),
      ),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: CivicLayout.readingWidth),
        child: sheet,
      ),
    );
  }
}

/// The grabber: a short rule a finger finds, in a 48 target that moves the
/// sheet to its next size.
class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return RawBottomSheetDragHandle(
      // The keyboard's focus lays the yellow plate round the rule, which
      // turns to the ink bar.
      builder: (context, states) => CivicSpringValue(
        value: states.contains(WidgetState.focused) ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) => SizedBox(
          width: CivicMetrics.controlHeight * 2,
          height: CivicSpacing.s24,
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(t.rule, t.focusBar, focus),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: t.focus.withValues(alpha: focus),
                    spreadRadius: 6 * focus,
                  ),
                ],
              ),
              child: const SizedBox(width: 40, height: 4),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.actions,
    required this.close,
    required this.left,
    required this.style,
    required this.child,
  });

  final String? title;
  final List<Widget> actions;
  final VoidCallback close;
  final bool left;
  final CivicStyle? style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf([style, t.sheetStyle], const {});
    final padding = MediaQuery.paddingOf(context);
    const margin = CivicSpacing.s24;
    final hairline = BorderSide(color: so.edge ?? t.rule);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: so.fill ?? t.background,
        border: Border(
          right: left ? hairline : BorderSide.none,
          left: left ? BorderSide.none : hairline,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(t.isDark ? 0x99000000 : 0x2E0C1116),
            blurRadius: 24,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                margin,
                CivicSpacing.s16,
                margin,
                0,
              ),
              child: _Head(title: title, close: close, so: so),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    so.padding(Directionality.of(context)) ??
                    const EdgeInsets.fromLTRB(
                      margin,
                      CivicSpacing.s16,
                      margin,
                      CivicSpacing.s24,
                    ),
                child: DefaultTextStyle(
                  style: context.civicText.body.copyWith(color: t.textPrimary),
                  child: child,
                ),
              ),
            ),
            if (actions.isNotEmpty) _Foot(actions: actions, margin: margin),
          ],
        ),
      ),
    );
  }
}
