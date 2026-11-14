import 'dart:async';

import 'package:material_ui/material_ui.dart'
    show MaterialLocalizations, RawDialogRoute;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../theme.dart';
import '../host.dart';
import '../menu/menu.dart';
import '../pressable/pressable.dart';
import '../sheet.dart';
import '../toast.dart';

/// Raises [builder]'s dialog (a [FrostedDialog], or any card of the
/// page's) over the whole app, as `showDialog` does: centred over the scrim,
/// the caller's themes riding along; a tap on the scrim (when
/// [barrierDismissible]), the system back or Escape dismisses it, and focus
/// returns to what opened it. Completes with the value the dialog pops
/// with: null when dismissed. Fades in [FrostedSheet.motionOf]'s time (a
/// cut under Reduce Motion).
///
/// ```dart
/// final ok = await showFrostedDialog<bool>(context, builder: (context) => FrostedDialog(title: 'Delete this note?', confirmLabel: 'Delete', cancelLabel: 'Cancel', destructive: true, onConfirm: () => Navigator.pop(context, true), onCancel: () => Navigator.pop(context, false)));
/// ```
Future<T?> showFrostedDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final t = context.frostedTheme;
  final navigator = FrostedHost.navigatorOf(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push(
    RawDialogRoute<T>(
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      barrierColor: t.colorScheme.overlay,
      transitionDuration:
          FrostedSheet.motionOf(context).duration ?? Duration.zero,
      pageBuilder: (dialogContext, _, _) => themes.wrap(
        RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(FrostedChromeMetrics.dialogEdge),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Opens a [FrostedMenu] of [items] under the control [context] belongs to
/// ([anchor] widens the box it drops from), as `showMenu` does, and
/// completes with the chosen value: null when dismissed (a tap outside,
/// the system back, Escape). The same as [FrostedMenu.show].
///
/// ```dart
/// Builder(builder: (anchor) => FrostedIconButton(FrostedGlyphs.more, label: 'More', onPressed: () async { final v = await showFrostedMenu<String>(anchor, items: const [FrostedMenuItem('rename', 'Rename'), FrostedMenuItem('delete', 'Delete')]); }))
/// ```
Future<T?> showFrostedMenu<T>(
  BuildContext context, {
  required List<FrostedMenuItem<T>> items,
  BuildContext? anchor,
  String? title,
  String? label,
}) => FrostedMenu.show<T>(
  context,
  items: items,
  anchor: anchor,
  title: title,
  label: label,
);

/// Shows [message] as a [FrostedSnackBar] over the page for a few seconds,
/// replacing one still showing, as `ScaffoldMessenger.showSnackBar` does.
/// The same as [FrostedToast.show].
///
/// ```dart
/// showFrostedSnackBar(context, 'Saved to Drafts', actionLabel: 'Undo', onAction: undo);
/// ```
void showFrostedSnackBar(
  BuildContext context,
  String message, {
  String? title,
  FrostedTone tone = FrostedTone.success,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
}) => FrostedToast.show(
  context,
  message,
  title: title,
  tone: tone,
  icon: icon,
  actionLabel: actionLabel,
  onAction: onAction,
);

/// One act of a [FrostedActionSheet]: its [label], what it does
/// ([onPressed], after the sheet closes with [value]), and whether it is a
/// loss ([destructive], set in the over ink).
class FrostedActionSheetAction<T> {
  /// An act named [label].
  const FrostedActionSheetAction(
    this.label, {
    this.value,
    this.onPressed,
    this.destructive = false,
    this.key,
  });

  /// The act's words.
  final String label;

  /// What the sheet's route pops with when it is chosen.
  final T? value;

  /// What it does, once the sheet has closed.
  final VoidCallback? onPressed;

  /// Whether it is a loss (Delete).
  final bool destructive;

  /// A key for its row.
  final Key? key;
}

/// A short list of acts for one thing, as iOS raises one: a glass card
/// with a quiet [title] and [message] over the acts, each a row 56 tall
/// with its word centred, a hairline between each two, a loss in the over
/// ink; under it, apart, the cancel on its own card in the ink, semibold.
/// A press closes the sheet (popping its route with the act's value), then
/// runs the act. [showFrostedActionSheet] raises it.
///
/// ```dart
/// showFrostedActionSheet<void>(context, builder: (context) => FrostedActionSheet(title: 'This photo', actions: [FrostedActionSheetAction('Share', onPressed: share), FrostedActionSheetAction('Delete', destructive: true, onPressed: delete)]))
/// ```
class FrostedActionSheet<T> extends StatelessWidget {
  /// A sheet of [actions].
  const FrostedActionSheet({
    required this.actions,
    this.title,
    this.message,
    this.cancelLabel,
    super.key,
  });

  /// What the acts are for.
  final String? title;

  /// One sentence under the title.
  final String? message;

  /// The acts, in order.
  final List<FrostedActionSheetAction<T>> actions;

  /// The cancel's word; null says the localized Cancel.
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final radius = BorderRadius.circular(FrostedCorners.r22);
    final rule = BorderSide(
      color: t.colorScheme.border,
      width: FrostedStrokes.hairline,
    );
    Widget card(Widget child) => FrostedFace(
      material: FrostedMaterial.slab,
      radius: radius,
      edge: t.glass.sheetEdge,
      sheen: t.glass.rim,
      shadows: t.shadows.sheet,
      clipChild: true,
      child: child,
    );
    Widget row(
      String label,
      TextStyle style,
      VoidCallback onPressed, {
      Key? key,
    }) => FrostedPressable(
      key: key,
      onPressed: onPressed,
      label: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FrostedSpacing.s16,
              vertical: FrostedSpacing.s12,
            ),
            child: Text(label, textAlign: TextAlign.center, style: style),
          ),
        ),
      ),
    );
    void choose(FrostedActionSheetAction<T> act) {
      Navigator.of(context).pop(act.value);
      act.onPressed?.call();
    }

    final head = [
      if (title case final title?)
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: t.textTheme.labelMedium.semibold.c(
              t.colorScheme.textSecondary,
            ),
          ),
        ),
      if (message case final message?)
        Text(
          message,
          textAlign: TextAlign.center,
          style: t.textTheme.bodySmall,
        ),
    ];
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(FrostedSpacing.s8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: FrostedChromeMetrics.sheetWideWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedSpacing.s8,
              children: [
                card(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (head.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            spacing: FrostedSpacing.s4,
                            children: head,
                          ),
                        ),
                      for (final (i, act) in actions.indexed)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: i == 0 && head.isEmpty
                                ? null
                                : Border(top: rule),
                          ),
                          child: row(
                            act.label,
                            act.destructive
                                ? t.textTheme.bodyLarge.c(t.colorScheme.over)
                                : t.textTheme.bodyLarge.c(
                                    t.colorScheme.textPrimary,
                                  ),
                            () => choose(act),
                            key: act.key,
                          ),
                        ),
                    ],
                  ),
                ),
                card(
                  row(
                    cancelLabel ??
                        DesignLocalizations.of(context).cancelButtonLabel,
                    t.textTheme.bodyLarge.semibold.c(t.colorScheme.textPrimary),
                    () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raises [builder]'s [FrostedActionSheet] over the whole app, as
/// `showCupertinoModalPopup` does: off the bottom edge over the scrim (on
/// a phone; at desktop width it stands centred), dismissed by a tap on the
/// scrim, the system back or Escape, focus returning to what opened it.
/// Completes with the chosen act's value: null when dismissed or cancelled.
///
/// ```dart
/// final pick = await showFrostedActionSheet<String>(context, builder: (context) => FrostedActionSheet<String>(actions: const [FrostedActionSheetAction('Camera', value: 'camera'), FrostedActionSheetAction('Library', value: 'library')]));
/// ```
Future<T?> showFrostedActionSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final t = context.frostedTheme;
  final navigator = FrostedHost.navigatorOf(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final style = FrostedSheet.motionOf(context);
  final wide = FrostedBreakpoints.isWide(context);
  return navigator.push(
    RawDialogRoute<T>(
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).scrimLabel,
      barrierColor: t.colorScheme.overlay,
      transitionDuration: style.duration ?? Duration.zero,
      transitionBuilder: (context, animation, _, child) {
        if (wide) return FadeTransition(opacity: animation, child: child);
        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(
              parent: animation,
              curve: style.curve ?? Curves.easeOutCubic,
              reverseCurve: style.reverseCurve ?? Curves.easeInCubic,
            ),
          ),
          child: child,
        );
      },
      pageBuilder: (sheetContext, _, _) => themes.wrap(
        RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: Align(
            alignment: wide ? Alignment.center : Alignment.bottomCenter,
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}

/// A few words about [child], raised over it: the toast's ink slab, 8
/// round, the [message] in the inverse caption, standing 8 over the child
/// (under it when there is no room above). It shows while a pointer rests
/// on the child, after a long press (for a moment past the lift), and
/// while the keyboard's focus is on it; Escape hides it. A screen reader
/// hears [message] as the child's tooltip.
///
/// ```dart
/// FrostedTooltip(message: 'Copy link', child: FrostedIconButton(FrostedGlyphs.share, label: 'Copy link', onPressed: copy))
/// ```
class FrostedTooltip extends StatefulWidget {
  /// [message] over [child].
  const FrostedTooltip({
    required this.message,
    required this.child,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(milliseconds: 1500),
    this.style,
    super.key,
  });

  /// The words.
  final String message;

  /// What they are about.
  final Widget child;

  /// How long a resting pointer waits before it shows.
  final Duration waitDuration;

  /// How long it stays after a long press lifts.
  final Duration showDuration;

  /// This tooltip's own style, over `FrostedThemeData.components.tooltip`:
  /// its fill, the words' colour and style, its shape
  /// ([FrostedCorners.medium] by default) and its padding.
  ///
  /// ```dart
  /// FrostedTooltip(
  ///   message: 'Copy the link',
  ///   style: const FrostedStyle(
  ///     fill: WidgetStatePropertyAll(Color(0xFF26215C)),
  ///   ),
  ///   child: copyButton,
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  State<FrostedTooltip> createState() => _FrostedTooltipState();
}

class _FrostedTooltipState extends State<FrostedTooltip> {
  final OverlayPortalController _portal = OverlayPortalController();
  final LayerLink _link = LayerLink();
  Timer? _timer;
  bool _focused = false;

  void _show() {
    _timer?.cancel();
    if (!_portal.isShowing) setState(_portal.show);
  }

  void _hide() {
    _timer?.cancel();
    if (_portal.isShowing && !_focused) setState(_portal.hide);
  }

  void _showSoon() {
    _timer?.cancel();
    _timer = Timer(widget.waitDuration, _show);
  }

  void _hideLater() {
    _timer?.cancel();
    _timer = Timer(widget.showDuration, _hide);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Whether the bubble has room over the child, under the window's top
  /// inset; else it stands under it.
  bool _roomAbove(BuildContext overlayContext) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return true;
    final top = box.localToGlobal(Offset.zero).dy;
    return top - MediaQuery.paddingOf(overlayContext).top > 48;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final motion = FrostedMotion.of(context);
    final bubble = FrostedStyleLayers(widget.style, t.components.tooltip);
    final (cut, corner) = bubble.surface(
      FrostedCorners.medium,
      FrostedStyleLayers.stockMedium,
      8,
    );
    return Semantics(
      tooltip: widget.message,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) {
          final keyboard =
              FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional;
          _focused = focused && keyboard;
          if (_focused) {
            _show();
          } else {
            _hide();
          }
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _portal.isShowing) {
            _focused = false;
            _hide();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          onEnter: (_) => _showSoon(),
          onExit: (_) => _hide(),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: _show,
            onLongPressUp: _hideLater,
            excludeFromSemantics: true,
            child: CompositedTransformTarget(
              link: _link,
              child: OverlayPortal(
                controller: _portal,
                overlayChildBuilder: (overlayContext) => _TooltipBubble(
                  link: _link,
                  above: _roomAbove(overlayContext),
                  message: widget.message,
                  duration: motion.fast,
                  slab: bubble.fill ?? t.colorScheme.surfaceInverse,
                  style: bubble.words(
                    t.textTheme.labelMedium.c(t.colorScheme.textInverse),
                  ),
                  shadows: t.shadows.menu,
                  shape: cut,
                  radius: corner,
                  padding: bubble.padding,
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({
    required this.link,
    required this.above,
    required this.message,
    required this.duration,
    required this.slab,
    required this.style,
    required this.shadows,
    required this.shape,
    required this.radius,
    required this.padding,
  });

  final LayerLink link;
  final bool above;
  final String message;
  final Duration duration;
  final Color slab;
  final TextStyle style;
  final List<BoxShadow> shadows;
  final OutlinedBorder? shape;
  final double radius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        targetAnchor: above ? Alignment.topCenter : Alignment.bottomCenter,
        followerAnchor: above ? Alignment.bottomCenter : Alignment.topCenter,
        offset: Offset(0, above ? -8 : 8),
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: duration,
              builder: (context, v, child) => Opacity(opacity: v, child: child),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: DecoratedBox(
                  decoration: switch (shape) {
                    final shape? => ShapeDecoration(
                      shape: shape,
                      color: slab,
                      shadows: shadows,
                    ),
                    null => BoxDecoration(
                      color: slab,
                      borderRadius: BorderRadius.circular(radius),
                      boxShadow: shadows,
                    ),
                  },
                  child: Padding(
                    padding:
                        padding ??
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(message, style: style),
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
