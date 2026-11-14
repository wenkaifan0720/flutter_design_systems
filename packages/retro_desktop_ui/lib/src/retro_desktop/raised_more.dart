// Round 4's raised parts: a menu bar, a side sheet, an action sheet, a popover, a hover card and the toaster that
// stacks snack bars. All but the action sheet stand on ui_core's behaviour (menus and their keys, the sheet's route,
// the anchored overlay, the toast queue); this file paints them as the period's
// desktop raised things: the machine's grey, an outline, the hard shadow, the highlight for the keyboard's row.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'acts.dart';
import 'behavior.dart' show RetroDesktopMotion;
import 'controls.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'internal/parts.dart';
import 'layout.dart'
    show RetroDesktopReach, retroDesktopHugMost, retroDesktopHugs;
import 'press.dart';
import 'raised.dart';
import 'theme.dart';
import 'internal/caps.dart';

/// A menu's panel under its anchor, fading in as it opens.
Widget _panel(
  BuildContext context,
  DesignOverlayInfo info,
  Widget child, {
  double minWidth = 180,
  double? maxWidth,
  EdgeInsetsGeometry padding = const EdgeInsets.all(4),
}) => FadeTransition(
  opacity: info.animation,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      minWidth: minWidth,
      maxWidth: maxWidth == null
          ? info.maxSize.width
          : maxWidth.clamp(0, info.maxSize.width),
      maxHeight: info.maxSize.height,
    ),
    child: retroDesktopPanel(context, padding: padding, child: child),
  ),
);

/// The desktop's menu bar: its titles along the top of a window, each opening
/// its menu; the arrows walk the bar and the menus, Escape closes them. A
/// title whose menu is open is lit, as is the keyboard's row in a menu.
/// ui_core's menubar carries the menus, their keys and their semantics.
/// Across the top of an app's screen it is the app's own bar: [leading] (the
/// app's mark) stands before the titles and [trailing] at the bar's end.
///
/// ```dart
/// RetroDesktopMenuBar(menus: [DesignMenuEntry(label: 'File', children: [DesignMenuEntry(label: 'New', shortcut: 'Ctrl+N', onPressed: () {})])])
/// ```
class RetroDesktopMenuBar extends StatelessWidget {
  /// Creates a [RetroDesktopMenuBar].
  const RetroDesktopMenuBar({
    super.key,
    required this.menus,
    this.label,
    this.leading,
    this.trailing,
  });

  /// The bar's titles, each with its menu.
  final List<DesignMenuEntry> menus;

  /// The bar's name for a screen reader.
  final String? label;

  /// Before the titles: the app's mark.
  final Widget? leading;

  /// At the bar's end: a fact or one quiet action.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    return DesignMenuBar(
      menus: menus,
      semanticLabel: label ?? DesignLocalizations.of(context).menuBarLabel,
      barBuilder: (context, items) => DecoratedBox(
        decoration: BoxDecoration(
          color: t.chisel ? c.platinum : c.paper,
          border: Border(bottom: BorderSide(color: c.control)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // Where the titles outrun the bar (large text on a phone), they wrap onto a second row between the mark
          // and the trailing action, as a narrow window's menu bar did: scrolled across, the last titles stood out of
          // sight with nothing to say they were there.
          child: LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                if (leading case final leading?)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 6, end: 6),
                    child: leading,
                  ),
                if (box.hasBoundedWidth)
                  Expanded(child: Wrap(children: items))
                else
                  ...items,
                // A button in the bar stands off its edges, whatever the text size.
                if (trailing case final trailing?)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: trailing,
                  ),
              ],
            ),
          ),
        ),
      ),
      dividerBuilder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(height: 1, child: ColoredBox(color: c.outline)),
      ),
      // A menu is as wide as its longest item and its keys, under its title; a row's label takes what is left of
      // that, so without the measure every menu ran the screen's width.
      // A bar's menu hangs from the bar itself, its top line the bar's bottom line (ui_core leaves 4 between an anchor
      // and its surface, which showed a sliver of the page between bar and menu; 4 up, the two lines stood as one 2 px
      // edge).
      surfaceBuilder: (context, info, items) => Transform.translate(
        offset: switch (info.side) {
          DesignOverlaySide.below => const Offset(0, -5),
          DesignOverlaySide.above => const Offset(0, 5),
          _ => Offset.zero,
        },
        child: _panel(
          context,
          info,
          maxWidth: 360,
          // The lit row runs from rim to rim, the period's bar across the menu (inset 4, it was a modern chip).
          padding: const EdgeInsets.symmetric(vertical: 4),
          IntrinsicWidth(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: items,
              ),
            ),
          ),
        ),
      ),
      itemBuilder: (context, entry, level, states) {
        final enabled = !states.contains(WidgetState.disabled);
        // In a menu the keyboard's row is lit, or the row under the pointer: opened by a click, the focus ui_core puts
        // on the first row lit it before the pointer came near, and it read as chosen (the bar's other menus open
        // with nothing lit).
        final lit =
            states.contains(WidgetState.selected) ||
            (level == DesignMenuLevel.bar &&
                states.contains(WidgetState.pressed)) ||
            (level == DesignMenuLevel.menu &&
                enabled &&
                (states.contains(WidgetState.hovered) ||
                    (states.contains(WidgetState.focused) &&
                        RetroDesktopLastInput.byKey)));
        if (level == DesignMenuLevel.bar) {
          return RetroDesktopHighlight(
            shape: retroDesktopItemShape(t),
            focused: states.contains(WidgetState.focused) && !lit,
            inside: true,
            child: retroDesktopLitRow(
              context,
              lit: lit,
              enabled: enabled,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              // A short title ("File") still spans a finger's width, centred.
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: math.max(0, RetroDesktopReach.least(context) - 20),
                ),
                child: RetroDesktopCaps(
                  style: t.type.chrome,
                  Text(
                    entry.label,
                    textAlign: TextAlign.center,
                    style: t.type.chrome.copyWith(
                      color: lit
                          ? c.onHighlight
                          : (enabled ? c.text : c.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return retroDesktopLitRow(
          context,
          lit: lit,
          enabled: enabled,
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: entry.checked == true
                    ? const Icon(RetroDesktopGlyphs.check, size: 14)
                    : null,
              ),
              // A menu's rows in the chrome's face, as every other menu's and the bar's titles are.
              Expanded(
                child: RetroDesktopCaps(
                  style: t.type.chrome,
                  Text(
                    entry.label,
                    style: t.type.chrome.copyWith(
                      color: lit
                          ? c.onHighlight
                          : (enabled ? c.text : c.textTertiary),
                    ),
                  ),
                ),
              ),
              if (entry.shortcut != null) ...[
                const SizedBox(width: 16),
                Text(
                  entry.shortcut!,
                  style: t.type.small.copyWith(
                    color: lit ? c.onHighlight : c.textSecondary,
                  ),
                ),
              ],
              if (entry.children != null) ...[
                const SizedBox(width: 8),
                RetroDesktopTriangleMark(
                  Directionality.of(context) == TextDirection.rtl
                      ? AxisDirection.left
                      : AxisDirection.right,
                  size: 8,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A window at the page's side, over the page and blocking it, nothing dimmed:
/// filters, details, a form that does not need the whole screen. Open it with
/// [showRetroDesktopSheet]; its close box, Escape, a press outside or a drag
/// back closes it.
///
/// ```dart
/// RetroDesktopSheet(title: 'Filters', child: filters)
/// ```
class RetroDesktopSheet extends StatelessWidget {
  /// Creates a [RetroDesktopSheet].
  const RetroDesktopSheet({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.icon,
  });

  /// The sheet's title bar.
  final String title;

  /// What it holds; it scrolls when taller than the screen.
  final Widget child;

  /// Closes it; null hides the close box.
  final VoidCallback? onClose;

  /// A glyph before the title.
  final IconData? icon;

  @override
  Widget build(BuildContext context) => RetroDesktopWindowScope(
    active: true,
    compact: false,
    child: RetroDesktopWindow(
      title: title,
      icon: icon,
      onClose: onClose,
      child: SingleChildScrollView(child: child),
    ),
  );
}

/// Opens a [RetroDesktopSheet] at [edge]; returns what it is popped with. It
/// stands in one frame, as the look's dialogs and windows do (the theme's
/// motion), and follows a finger that drags it closed.
Future<T?> showRetroDesktopSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  DesignSheetEdge edge = DesignSheetEdge.end,
  double width = 360,
  IconData? icon,
}) => Navigator.of(context).push<T>(
  DesignSideSheetRoute<T>(
    edge: edge,
    width: width,
    semanticLabel: title,
    // Nothing behind a window is dimmed (the look's stacking law).
    barrierColor: const Color(0x00000000),
    transitionDuration: RetroDesktopMotion.of(context).travel,
    // A window standing on the desk, 8 off the screen's edges and the bar above it, its shadow showing: against the
    // top bar its top line doubled the bar's into one heavy rule. On a desk it is as tall as what it holds, from the
    // top, up to the screen's height (stretched to the foot, a short form stood over a tall empty grey window); on a
    // phone it runs the screen's height, as a phone's sheet does.
    builder: (context, sheet) {
      final window = RetroDesktopSheet(
        title: title,
        icon: icon,
        onClose: sheet.close,
        child: builder(context),
      );
      return Padding(
        padding: const EdgeInsets.all(8),
        child: RetroDesktopTheme.of(context).desk
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [Flexible(child: window)],
              )
            : window,
      );
    },
  ),
);

/// One choice of a [RetroDesktopActionSheet].
@immutable
class RetroDesktopActionSheetAction {
  /// Creates a [RetroDesktopActionSheetAction].
  const RetroDesktopActionSheetAction(
    this.label, {
    required this.onPressed,
    this.destructive = false,
    this.icon,
  });

  /// The choice's words.
  final String label;

  /// What it does.
  final VoidCallback onPressed;

  /// Whether it destroys something (its button is the danger button).
  final bool destructive;

  /// A glyph before the words.
  final IconData? icon;
}

/// A short list of what can be done to one thing, from the foot of a phone's
/// screen (a dialog's place on a desktop): a button each, the destructive one
/// the danger button, Cancel apart. Open it with
/// [showRetroDesktopActionSheet].
///
/// ```dart
/// RetroDesktopActionSheet(title: 'Project notes', actions: [RetroDesktopActionSheetAction('Duplicate', onPressed: () {}), RetroDesktopActionSheetAction('Delete', destructive: true, onPressed: () {})], cancelLabel: 'Cancel', onCancel: () {})
/// ```
class RetroDesktopActionSheet extends StatelessWidget {
  /// Creates a [RetroDesktopActionSheet].
  const RetroDesktopActionSheet({
    super.key,
    required this.actions,
    this.title,
    this.message,
    this.cancelLabel,
    this.onCancel,
  });

  /// The choices, in order.
  final List<RetroDesktopActionSheetAction> actions;

  /// The thing they act on, and a line more.
  final String? title, message;

  /// The cancel button's words; null shows none.
  final String? cancelLabel;

  /// What cancel does.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Text(
            title!,
            textAlign: TextAlign.center,
            style: t.type.chrome.copyWith(color: t.colors.text),
          ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              message!,
              textAlign: TextAlign.center,
              style: t.type.meta,
            ),
          ),
        if (title != null || message != null) const SizedBox(height: 12),
        for (final a in actions)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            // A destructive action is never the sheet's default: a plain button with the caution mark.
            child: a.destructive
                ? RetroDesktopButton(
                    a.label,
                    isDestructiveAction: true,
                    icon: a.icon,
                    wide: true,
                    onPressed: a.onPressed,
                  )
                : RetroDesktopButton(
                    a.label,
                    wide: true,
                    icon: a.icon,
                    onPressed: a.onPressed,
                  ),
          ),
        if (cancelLabel != null) ...[
          const SizedBox(height: 6),
          RetroDesktopButton(cancelLabel!, wide: true, onPressed: onCancel),
        ],
      ],
    );
    // From 600 up the choices stand in one column a form cell wide, in the
    // middle of the sheet, not across it.
    if (!retroDesktopHugs(context)) return column;
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: retroDesktopHugMost),
        child: column,
      ),
    );
  }
}

/// Opens a [RetroDesktopActionSheet] in a bottom sheet; a choice closes it
/// and then runs.
Future<void> showRetroDesktopActionSheet(
  BuildContext context, {
  required List<RetroDesktopActionSheetAction> actions,
  String? title,
  String? message,
  String cancelLabel = 'Cancel',
}) => showRetroDesktopBottomSheet<void>(
  context,
  // In the sheet's own window (its plate, rim and hard shadow, at the foot or a wide screen's centre): the choices
  // alone stood bare over the page, at its top, with nothing behind them.
  builder: (sheet) => RetroDesktopBottomSheet(
    child: RetroDesktopActionSheet(
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      onCancel: () => Navigator.of(sheet).pop(),
      actions: [
        for (final a in actions)
          RetroDesktopActionSheetAction(
            a.label,
            icon: a.icon,
            destructive: a.destructive,
            onPressed: () {
              Navigator.of(sheet).pop();
              a.onPressed();
            },
          ),
      ],
    ),
  ),
);

/// A small raised panel under a button, holding a few controls or words: it
/// opens on the press, closes on Escape or a press outside, and keeps focus
/// inside while open. ui_core's anchored overlay carries the placement, the
/// flip at the screen's edge, focus and its return.
///
/// ```dart
/// RetroDesktopPopover(label: 'Share', content: (context) => const Text('Anyone with the link can view'))
/// ```
class RetroDesktopPopover extends StatelessWidget {
  /// Creates a [RetroDesktopPopover].
  const RetroDesktopPopover({
    super.key,
    required this.content,
    this.label,
    this.icon,
    this.anchorBuilder,
    this.width = 280,
    this.semanticLabel,
  }) : assert(label != null || anchorBuilder != null);

  /// What the panel holds.
  final WidgetBuilder content;

  /// The button's words, when no [anchorBuilder] draws the anchor.
  final String? label;

  /// The button's glyph.
  final IconData? icon;

  /// Draws your own anchor; call `toggle` on its press.
  final Widget Function(BuildContext context, VoidCallback toggle, bool open)?
  anchorBuilder;

  /// The panel's widest.
  final double width;

  /// The panel's name for a screen reader.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    semanticLabel: semanticLabel ?? label,
    // The panel keeps its own width under a wide anchor.
    placement: const DesignOverlayPlacement(matchAnchorWidth: false),
    anchorBuilder: (context, a) =>
        anchorBuilder?.call(context, a.toggle, a.isOpen) ??
        RetroDesktopButton(label!, wide: true, icon: icon, onPressed: a.toggle),
    overlayBuilder: (context, info) => _panel(
      context,
      info,
      SingleChildScrollView(child: content(context)),
      minWidth: 0,
      maxWidth: width,
      padding: const EdgeInsets.all(12),
    ),
  );
}
