import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

import '../glyphs.dart';

import '../chrome_metrics.dart';
import '../internal/face.dart';
import '../internal/footer_band.dart';
import '../internal/ink_on.dart';
import '../internal/styled.dart';
import '../internal/toaster.dart';
import '../theme.dart';
import 'host.dart';
import 'pressable/pressable.dart';

/// A short confirmation over the page, as the source raises one (Moved to
/// Groceries, Card number copied): the ink slab rising 12 over the tab bar
/// on a root, 16 over the bottom edge elsewhere, 16 in from either side;
/// at desktop width 380 wide at the window's bottom right, 32 in. It stays
/// a few seconds, longer with its one inline action (Undo), and a new toast
/// replaces the one still showing.
///
/// ```dart
/// FrostedToast.show(context, 'Moved to Groceries', actionLabel: 'Undo', onAction: undo);
/// ```
abstract final class FrostedToast {
  /// The one toast's id: a new toast replaces the one still showing.
  static const Object _id = #frostedToast;

  /// Shows [message] for a few seconds, replacing any toast still showing,
  /// over a [title] when given, its mark in the [tone]'s ink wearing [icon]
  /// (the tone's glyph by default: the check for success). [actionLabel] plus
  /// [onAction] add ONE inline action; the slab then lingers longer and a
  /// tap on the action dismisses it. The host's toaster (ui_core's
  /// [DesignToaster]) holds it: its time stops while a pointer rests on it
  /// or focus is in it, a swipe or Escape dismisses it, and F6 reaches it.
  static void show(
    BuildContext context,
    String message, {
    String? title,
    FrostedTone tone = FrostedTone.success,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final toaster = DesignToaster.maybeOf(context);
    assert(toaster != null, 'FrostedToast.show needs a FrostedHost above it');
    if (toaster == null) return;
    final double bottom;
    if (FrostedBreakpoints.isWide(context)) {
      bottom = FrostedChromeMetrics.toastWideEdge;
    } else {
      // Measured against the app's ROOT overlay (its root navigator's), the
      // box the toaster stands over.
      final overlay = FrostedHost.navigatorOf(context).overlay!;
      final stands = math.max(
        ShellInsets.of(context),
        FrostedBottomStand.reachOf(
          context,
          overlay.context.findRenderObject()! as RenderBox,
        ),
      );
      bottom = stands > 0
          ? stands + FrostedChromeMetrics.toastOverBar
          : math.max(
              FrostedChromeMetrics.toastBottom,
              MediaQuery.paddingOf(overlay.context).bottom +
                  FrostedChromeMetrics.toastOverBar,
            );
    }
    toaster.show(
      DesignToast(
        id: _id,
        message: message,
        title: title,
        actionLabel: actionLabel,
        onAction: actionLabel == null ? null : (onAction ?? () {}),
        duration: actionLabel == null
            ? FrostedChromeMetrics.toastDwell
            : FrostedChromeMetrics.toastDwellAction,
        data: FrostedToastLook(tone: tone, icon: icon, bottom: bottom),
      ),
    );
  }
}

/// The toast's face, drawn in place (a still of a toast on a showcase or a
/// walkthrough frame): the ink slab with a light along its top and its
/// shadow (`.toast`), the round mark in the money-in green wearing the
/// [icon], the [message] in the toast's type, and the one action's word
/// ([actionLabel]) on its own faint pill at the end. A [title] stands over
/// the message in the semibold; a [tone] other than success takes its glyph
/// and its ink for the mark (info, a warning, danger). A page confirms
/// through [FrostedToast.show], never by standing this in its body.
///
/// ```dart
/// FrostedSnackBar('Moved to Groceries', actionLabel: 'Undo', onAction: undo)
/// ```
class FrostedSnackBar extends StatelessWidget {
  /// Creates a [FrostedSnackBar].
  const FrostedSnackBar(
    this.message, {
    super.key,
    this.title,
    this.tone = FrostedTone.success,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.style,
  });

  /// The confirmation.
  final String message;

  /// A line over the message.
  final String? title;

  /// What kind of news it is; success, by default.
  final FrostedTone tone;

  /// The mark's glyph; null for the [tone]'s own.
  final IconData? icon;

  /// The one inline action's word ("Undo"); none when null.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onAction;

  /// This snack bar's own style, over
  /// `FrostedThemeData.components.snackBar`: its fill (a flat colour in
  /// place of the dark slab), the edge's colour or a whole side, its shape
  /// ([FrostedCorners.medium] by default) and its padding.
  ///
  /// ```dart
  /// FrostedSnackBar(
  ///   'Saved',
  ///   style: const FrostedStyle(
  ///     fill: WidgetStatePropertyAll(Color(0xFF1E2A3A)),
  ///   ),
  /// )
  /// ```
  final FrostedStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final s = FrostedStyleLayers(style, t.components.snackBar);
    final (cut, corner) = s.surface(
      FrostedCorners.medium,
      FrostedStyleLayers.stockMedium,
      FrostedChromeMetrics.toastRadius,
    );
    final fill = s.fill;
    final side = s.side;
    const mark = FrostedChromeMetrics.toastMark;
    const act = FrostedChromeMetrics.toastAct;
    final glyph =
        icon ??
        switch (tone) {
          FrostedTone.success => FrostedGlyphs.check,
          FrostedTone.warning => FrostedGlyphs.warning,
          FrostedTone.danger => FrostedGlyphs.danger,
          FrostedTone.info || FrostedTone.quiet => FrostedGlyphs.info,
        };
    // By night every tone wears success's recipe, its ink over its own
    // tint: a pale opaque warning or danger disc beside success's dark tint
    // read as two kinds of mark (self-review round 5). By day the tones'
    // inks are too dark to stand on the slab as a glyph, so their discs
    // stay opaque.
    final success = tone == FrostedTone.success;
    final tinted = !success && t.isDark;
    final markFill = success
        ? t.toast.mark
        : tinted
        ? t.toneInk(tone).withValues(alpha: 0.2)
        : t.toneInk(tone);
    final head = title;
    // On the desktop a snack bar is the look's 380 wide wherever it stands,
    // at the line's start: placed in a page it ran the page's whole width.
    final wide = FrostedBreakpoints.isWide(context);
    final Widget bar = Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.toastHeight,
        ),
        child: FrostedFace(
          material: FrostedMaterial.paint,
          radius: BorderRadius.circular(corner),
          shape: cut,
          color: fill,
          gradients: fill == null ? [t.toast.slab] : const <Gradient>[],
          edge: side?.color ?? s.edge,
          edges: EdgeInsets.all(side?.width ?? FrostedStrokes.regular),
          sheen: t.toast.sheen,
          shadows: t.shadows.toast,
          padding:
              (s.padding ??
                      const EdgeInsetsDirectional.fromSTEB(
                        FrostedChromeMetrics.toastInsetStart,
                        FrostedChromeMetrics.toastInset,
                        FrostedChromeMetrics.toastInset,
                        FrostedChromeMetrics.toastInset,
                      ))
                  .resolve(Directionality.of(context)),
          child: Row(
            spacing: FrostedChromeMetrics.toastGap,
            children: [
              SizedBox.square(
                dimension: mark,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: markFill,
                  ),
                  child: Center(
                    child: Icon(
                      glyph,
                      size: FrostedChromeMetrics.toastMarkGlyph,
                      // Success wears its own tint and ink; another tone's
                      // disc is opaque, and the success ink on it read
                      // 1.3:1 by night (law 8).
                      color: success
                          ? t.toast.onMark
                          : tinted
                          ? t.toneInk(tone)
                          : frostedInkOn(t, markFill),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: head == null
                    ? Text(
                        message,
                        style: t.textTheme.link.line(18).c(t.toast.text),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            head,
                            style: t.textTheme.link
                                .line(18)
                                .semibold
                                .c(t.toast.text),
                          ),
                          Text(
                            message,
                            style: t.textTheme.link
                                .line(18)
                                .c(t.toast.text.withValues(alpha: .8)),
                          ),
                        ],
                      ),
              ),
              if (actionLabel != null)
                // Its own button, beside the words rather than merged into
                // the toast's node.
                Semantics(
                  container: true,
                  child: FrostedPressable(
                    onPressed: onAction,
                    label: actionLabel,
                    radius: act / 2,
                    child: Container(
                      height: act,
                      padding: const EdgeInsets.symmetric(
                        horizontal: FrostedChromeMetrics.toastActInset,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: t.toast.action,
                        borderRadius: BorderRadius.circular(act / 2),
                      ),
                      child: Text(
                        actionLabel!,
                        maxLines: 1,
                        style: t.textTheme.labelLarge.c(t.toast.text),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (!wide) return bar;
    // 380, or the room when there is less.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: FrostedChromeMetrics.toastWideWidth,
        ),
        child: SizedBox(width: double.infinity, child: bar),
      ),
    );
  }
}
