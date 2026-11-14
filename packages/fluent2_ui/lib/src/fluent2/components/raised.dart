// What rises over the page, by the names every look shares: the dialog, the side and bottom sheets, the action sheet,
// the popover (on ui_core's DesignAnchoredOverlay and DesignSideSheetRoute), and the menu's opener.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show ModalBottomSheetRoute;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/host.dart';

import '../chrome_metrics.dart';
import '../icons.dart';
import '../internal/measure.dart';
import '../theme.dart';
import 'button/button.dart';
import 'dialog/dialog.dart';
import 'divider/divider.dart';
import 'host.dart';
import 'menu/menu.dart';
import 'popover/popover.dart';
import 'pressable/pressable.dart';
import 'sheet.dart';

/// Raises the [Fluent2Dialog] [builder] makes over the whole app; completes
/// with what it pops with, null when the overlay is tapped or Escape pressed.
///
/// ```dart
/// showFluent2Dialog<bool>(context, builder: (context) => Fluent2Dialog(title: 'Delete Q3 plan.docx?', message: 'It moves to the recycle bin for 30 days.', actions: [cancel, delete]))
/// ```
Future<T?> showFluent2Dialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => Fluent2Dialog.show<T>(context, builder);

/// Raises the [Fluent2Sheet] [builder] makes at the window's [edge], [width]
/// wide (never closer than 56 to the far side), over the overlay. The builder
/// gets the sheet's close. Escape, a press on the overlay or a drag to its edge
/// closes it and the focus goes back where it was.
///
/// ```dart
/// showFluent2Sheet<void>(context, builder: (context, close) => Fluent2Sheet(title: 'Filters', onClose: close, child: filters))
/// ```
Future<T?> showFluent2Sheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context, VoidCallback close) builder,
  DesignSheetEdge edge = DesignSheetEdge.end,
  double width = Fluent2ChromeMetrics.drawerWidth,
}) {
  final t = context.fluent2Theme;
  final navigator = Fluent2Host.navigatorOf(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    DesignSideSheetRoute<T>(
      edge: edge,
      width: width,
      barrierColor: t.overlay,
      barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: Fluent2Motion.of(context, Fluent2Motion.gentle),
      builder: (inner, sheet) => themes.wrap(
        RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: builder(inner, sheet.close),
        ),
      ),
    ),
  );
}

/// Fluent 2's bottom sheet: the surface rising off the bottom edge in
/// `shadow28`, its top corners 8, the handle over its optional [title] with
/// the dismiss beside it when [onClose] is set, [child] scrolling once it
/// outgrows the sheet, and the [actions] at its foot. [showFluent2BottomSheet]
/// raises one.
///
/// ```dart
/// Fluent2BottomSheet(title: 'Share', onClose: close, child: people, actions: [Fluent2Button('Send', appearance: Fluent2ButtonAppearance.primary, onPressed: send)])
/// ```
class Fluent2BottomSheet extends StatelessWidget {
  /// A bottom sheet holding [child].
  const Fluent2BottomSheet({
    super.key,
    required this.child,
    this.title,
    this.actions = const [],
    this.onClose,
  });

  /// What it holds.
  final Widget child;

  /// Its head; null draws only the handle.
  final String? title;

  /// The acts at its foot, the primary last.
  final List<Widget> actions;

  /// What the dismiss does; null draws no dismiss.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final head = title;
    final close = onClose;
    return _sheetWidth(
      context,
      Fluent2ChromeMetrics.dialogWidth,
      Fluent2SheetCard.bottom(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Fluent2ChromeMetrics.sheetSide,
              Fluent2ChromeMetrics.sheetTop,
              Fluent2ChromeMetrics.sheetSide,
              Fluent2ChromeMetrics.sheetBottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Fluent2SheetHandle(),
                if (head != null) ...[
                  Fluent2SheetHead(
                    title: head,
                    close: close == null
                        ? null
                        : Fluent2IconButton(
                            Fluent2Icons.dismiss,
                            label: DesignLocalizations.of(context)
                                .closeButtonLabel,
                            onPressed: close,
                          ),
                  ),
                  const SizedBox(height: Fluent2ChromeMetrics.sheetBodyGap),
                ],
                Flexible(child: SingleChildScrollView(child: child)),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: Fluent2ChromeMetrics.dialogActionsGap),
                  Fluent2SheetShell.footOf(actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sheet laid in a page from 600 ([fluent2Roomy]): at most [maxWidth]
/// (Fluent's dialog for a bottom sheet, a menu's 320 for an action sheet),
/// at the page's start; the sheet's route, which holds it to the dialog's
/// width, centres it. On a phone it runs the width.
Widget _sheetWidth(BuildContext context, double maxWidth, Widget sheet) =>
    !fluent2Roomy(context)
    ? sheet
    : Align(
        alignment: AlignmentDirectional.topStart,
        widthFactor: 1,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: sheet,
        ),
      );

/// Raises what [builder] makes (a [Fluent2BottomSheet], usually) off the
/// bottom edge over the overlay, at most 600 wide; completes with what it pops
/// with, null when it is dismissed. It rides above the keyboard.
///
/// ```dart
/// showFluent2BottomSheet<void>(context, builder: (context) => Fluent2BottomSheet(title: 'Share', onClose: () => Navigator.of(context).pop(), child: people))
/// ```
Future<T?> showFluent2BottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final t = context.fluent2Theme;
  final navigator = Fluent2Host.navigatorOf(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    ModalBottomSheetRoute<T>(
      capturedThemes: themes,
      barrierLabel: DesignLocalizations.of(context).modalBarrierDismissLabel,
      backgroundColor: const Color(0x00000000),
      modalBarrierColor: t.overlay,
      elevation: 0,
      isScrollControlled: true,
      sheetAnimationStyle: Fluent2Sheet.motionOf(context),
      constraints: BoxConstraints(
        maxHeight: Fluent2Sheet.maxHeight(context),
        maxWidth: Fluent2ChromeMetrics.dialogWidth,
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: RoutePresentationScope(
          presentation: RoutePresentation.sheet,
          child: builder(sheetContext),
        ),
      ),
    ),
  );
}

/// One act of a [Fluent2ActionSheet].
///
/// ```dart
/// Fluent2ActionSheetAction('delete', 'Delete', icon: Fluent2Icons.delete, destructive: true)
/// ```
@immutable
class Fluent2ActionSheetAction<T> {
  /// An act that answers [value] when chosen.
  const Fluent2ActionSheetAction(
    this.value,
    this.label, {
    this.icon,
    this.destructive = false,
    this.enabled = true,
  });

  /// What choosing it answers.
  final T value;

  /// Its words.
  final String label;

  /// The glyph before the words.
  final IconData? icon;

  /// A loss: its words take the danger ink.
  final bool destructive;

  /// False: it can't be chosen.
  final bool enabled;
}

/// A short list of acts up from the foot of the page, on Fluent 2's bottom
/// sheet: an optional [title] and [message], each act a row the height of a
/// phone's menu row, the way out apart under a hairline. Each row is the
/// menu's own face. [showFluent2ActionSheet] raises one and answers the
/// chosen value.
///
/// ```dart
/// Fluent2ActionSheet(title: 'Q3 plan.docx', actions: const [Fluent2ActionSheetAction('move', 'Move')], onSelected: act)
/// ```
class Fluent2ActionSheet<T> extends StatelessWidget {
  /// An action sheet of [actions].
  const Fluent2ActionSheet({
    super.key,
    required this.actions,
    required this.onSelected,
    this.title,
    this.message,
    this.onCancel,
    this.cancelLabel,
  });

  /// The acts, in order.
  final List<Fluent2ActionSheetAction<T>> actions;

  /// Told the chosen act's value.
  final ValueChanged<T> onSelected;

  /// Over the acts.
  final String? title;

  /// Under the title.
  final String? message;

  /// The way out, under the acts; null leaves it out.
  final VoidCallback? onCancel;

  /// The way out's words; null is [DesignLocalizations.cancelButtonLabel].
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final cancel = onCancel;
    final heading = title;
    final body = message;
    Widget row(
      String label,
      VoidCallback? onPressed, {
      IconData? icon,
      bool danger = false,
      bool emphasis = false,
    }) => Fluent2Pressable(
      onPressed: onPressed,
      label: label,
      radius: Fluent2Radius.medium,
      builder: (context, states) => Fluent2MenuRowFace(
        label: label,
        states: states,
        icon: icon,
        danger: danger,
        emphasis: emphasis,
      ),
    );
    // From 600 it stands as an iPad's action sheet does, a card at most 320
    // wide (at the start of a page; the sheet's route centres it); its rows
    // are a menu's, not a page's.
    final sheet = Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Fluent2SheetCard.bottom(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Fluent2Spacing.s,
              Fluent2ChromeMetrics.sheetTop,
              Fluent2Spacing.s,
              Fluent2Spacing.s,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Fluent2SheetHandle(),
                if (heading != null || body != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Fluent2Spacing.s,
                      Fluent2Spacing.xs,
                      Fluent2Spacing.s,
                      Fluent2Spacing.s,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Fluent2Spacing.xxs,
                      children: [
                        if (heading != null)
                          Semantics(
                            header: true,
                            child: Text(heading, style: t.body1Strong),
                          ),
                        if (body != null)
                          Text(body, style: t.caption1.c(t.textSecondary)),
                      ],
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final a in actions)
                          row(
                            a.label,
                            a.enabled ? () => onSelected(a.value) : null,
                            icon: a.icon,
                            danger: a.destructive,
                          ),
                      ],
                    ),
                  ),
                ),
                if (cancel != null) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: Fluent2Spacing.xs),
                    child: Fluent2Divider(),
                  ),
                  row(
                    cancelLabel ??
                        DesignLocalizations.of(context).cancelButtonLabel,
                    cancel,
                    emphasis: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return _sheetWidth(context, fluent2ControlMax, sheet);
  }
}

/// Raises a [Fluent2ActionSheet] of [actions] off the bottom edge; answers the
/// chosen value, or null on the way out, Escape or the overlay.
///
/// ```dart
/// final act = await showFluent2ActionSheet<String>(context, actions: const [Fluent2ActionSheetAction('delete', 'Delete', destructive: true)]);
/// ```
Future<T?> showFluent2ActionSheet<T>(
  BuildContext context, {
  required List<Fluent2ActionSheetAction<T>> actions,
  String? title,
  String? message,
  String? cancelLabel,
}) => showFluent2BottomSheet<T>(
  context,
  builder: (sheetContext) => Fluent2ActionSheet<T>(
    actions: actions,
    title: title,
    message: message,
    cancelLabel: cancelLabel,
    onSelected: (value) => Navigator.of(sheetContext).pop(value),
    onCancel: () => Navigator.of(sheetContext).pop(),
  ),
);

/// The surface's rise: a fade and 8 of travel from the side it opens on, by
/// the overlay's spring.
Widget _rise(DesignOverlayInfo info, Widget child) => AnimatedBuilder(
  animation: info.animation,
  builder: (context, surface) {
    final p = info.animation.value.clamp(0.0, 1.0);
    final d = (1 - p) * Fluent2Spacing.s;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Opacity(
      opacity: p,
      child: Transform.translate(
        offset: switch (info.side) {
          DesignOverlaySide.below => Offset(0, -d),
          DesignOverlaySide.above => Offset(0, d),
          DesignOverlaySide.start => Offset(rtl ? -d : d, 0),
          DesignOverlaySide.end => Offset(rtl ? d : -d, 0),
        },
        child: surface,
      ),
    );
  },
  child: child,
);

/// Words or a small form on Fluent's flyout beside its trigger, opened and
/// closed by a press. Escape, a press outside and Tab out close it, and the
/// focus goes back to the trigger. [Fluent2Flyout.show] raises a flyout from
/// code with no trigger of its own.
///
/// ```dart
/// Fluent2Popover(label: 'Sharing', trigger: (context, toggle) => Fluent2Button('Share', onPressed: toggle), content: const Text('Shared with 4 people'))
/// ```
class Fluent2Popover extends StatelessWidget {
  /// A popover opened by what [trigger] builds.
  const Fluent2Popover({
    super.key,
    required this.label,
    required this.trigger,
    required this.content,
    this.side = DesignOverlaySide.below,
    this.align = DesignOverlayAlign.start,
    this.width = 288,
    this.appearance = Fluent2FlyoutAppearance.neutral,
    this.size = Fluent2FlyoutSize.medium,
  });

  /// The popover's name, read as it opens.
  final String label;

  /// Builds the control that opens it: call `toggle` from its press.
  final Widget Function(BuildContext context, VoidCallback toggle) trigger;

  /// What it holds.
  final Widget content;

  /// The side of the trigger it opens on; it flips where there's no room.
  final DesignOverlaySide side;

  /// How it lines up with the trigger along that side.
  final DesignOverlayAlign align;

  /// Its width, never wider than the window leaves.
  final double width;

  /// Fluent's surface: neutral, brand or inverted.
  final Fluent2FlyoutAppearance appearance;

  /// Its padding, Fluent's `size`.
  final Fluent2FlyoutSize size;

  @override
  Widget build(BuildContext context) => DesignAnchoredOverlay(
    semanticLabel: label,
    // Fluent's popover keeps its own width under a wide trigger.
    placement: DesignOverlayPlacement(
      side: side,
      align: align,
      gap: Fluent2Spacing.xs,
      matchAnchorWidth: false,
    ),
    anchorBuilder: (context, anchor) => Semantics(
      expanded: anchor.isOpen,
      child: trigger(context, anchor.toggle),
    ),
    overlayBuilder: (context, info) {
      final w = math.min(width, info.maxSize.width);
      return _rise(
        info,
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: info.maxSize.height),
          child: Fluent2Flyout(
            appearance: appearance,
            size: size,
            minWidth: w,
            maxWidth: w,
            child: SingleChildScrollView(child: content),
          ),
        ),
      );
    },
  );
}

/// Opens a [Fluent2Menu] of [items] under the control [context] belongs to (a
/// [Builder] round it) over the whole app; [anchor] widens the box it drops
/// from. Completes with the value chosen, or null when it is dismissed.
///
/// ```dart
/// final picked = await showFluent2Menu<String>(context, items: const [Fluent2MenuItem('rename', 'Rename')]);
/// ```
Future<T?> showFluent2Menu<T>(
  BuildContext context, {
  required List<Fluent2MenuItem<T>> items,
  BuildContext? anchor,
  String? title,
  String? label,
}) => Fluent2Menu.show<T>(
  context,
  items: items,
  anchor: anchor,
  title: title,
  label: label,
);
