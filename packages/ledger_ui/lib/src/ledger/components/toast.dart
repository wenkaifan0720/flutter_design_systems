import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellInsets;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/end_glyph.dart';
import '../internal/footer_band.dart';
import '../theme.dart';
import 'host.dart';
import 'pressable/pressable.dart';

/// A short confirmation over the page, as the source raises one (Moved to
/// Groceries, Card number copied): the toast rising 12 clear of the tab bar
/// on a tab's page (96 over its foot), 24 over the bottom edge elsewhere,
/// 16 in from either side; at desktop width 380 wide at the window's bottom
/// right, 32 in. It stays a few seconds, longer with its one inline act
/// (Undo), and a new toast replaces the one still showing.
///
/// ```dart
/// LedgerToast.show(context, 'Moved to Groceries', actionLabel: 'Undo', onActionPressed: undo);
/// ```
abstract final class LedgerToast {
  /// Dismisses the toast still showing, when a new one replaces it.
  static VoidCallback? _current;

  /// Shows [message] for a few seconds, replacing any toast still showing, its
  /// mark wearing [icon] (the check by default). [actionLabel] plus
  /// [onActionPressed] add ONE inline action; the card then lingers longer and
  /// a tap on the action dismisses it.
  static void show(
    BuildContext context,
    String message, {
    IconData icon = LucideIcons.check,
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final still = LedgerMotion.isReduced(context);
    final wide = LedgerLayout.isWide(context);
    // The app's ROOT overlay (its root navigator's): a branch navigator's
    // overlay paints below the shell's bar, and the toast would rise behind
    // it.
    final overlay = LedgerHost.navigatorOf(context).overlay!;
    final double bottom;
    if (wide) {
      bottom = LedgerChromeMetrics.toastEdgeWide;
    } else {
      final stands = math.max(
        ShellInsets.of(context),
        LedgerBottomStand.reachOf(
          context,
          overlay.context.findRenderObject()! as RenderBox,
        ),
      );
      // The source stands it 96 over a tab's foot, 12 clear of the 84 bar,
      // and 24 over any other.
      const clear =
          LedgerChromeMetrics.toastOverBar - LedgerChromeMetrics.tabBarHeight;
      bottom = stands > 0
          ? stands + clear
          : math.max(
              LedgerChromeMetrics.toastFoot,
              MediaQuery.paddingOf(overlay.context).bottom + clear,
            );
    }
    late final OverlayEntry entry;
    Timer? timer;
    var gone = false;
    void dismiss() {
      if (gone) return;
      gone = true;
      timer?.cancel();
      entry.remove();
      entry.dispose();
      if (_current == dismiss) _current = null;
    }

    _current?.call();
    _current = dismiss;

    // The entry builds under the root overlay, which in a page preview sits
    // above the host: carry the caller's themes across.
    final themes = InheritedTheme.capture(from: context, to: overlay.context);
    final card = Semantics(
      // A node of its own: unmarked, the toast's words and action merge up
      // into the overlay's.
      container: true,
      liveRegion: true,
      child: LedgerToastCard(
        message,
        icon: icon,
        actionLabel: actionLabel,
        onActionPressed: actionLabel == null
            ? null
            : () {
                dismiss();
                onActionPressed?.call();
              },
      ),
    );
    entry = OverlayEntry(
      builder: (_) => PositionedDirectional(
        bottom: bottom,
        start: wide ? null : LedgerChromeMetrics.toastSide,
        end: wide
            ? LedgerChromeMetrics.toastEdgeWide
            : LedgerChromeMetrics.toastSide,
        width: wide ? LedgerChromeMetrics.toastWidth : null,
        child: themes.wrap(
          IgnorePointer(
            // Without an action every tap must still reach the page beneath.
            ignoring: actionLabel == null,
            child: still
                ? card
                : TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: LedgerMotion.base,
                    curve: LedgerMotion.out,
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          (1 - v) * LedgerChromeMetrics.toastRise,
                        ),
                        child: child,
                      ),
                    ),
                    child: card,
                  ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    timer = Timer(
      actionLabel == null
          ? LedgerChromeMetrics.toastDwell
          : LedgerChromeMetrics.toastDwellAction,
      dismiss,
    );
  }
}

/// The toast's face, drawn in place (a still of a toast on a showcase or a
/// walkthrough frame): the ink slip, 6 at its corners, its deep drop under
/// it; the [icon] in a 28 ring, the [message] in the raised paper's ink,
/// and the one act's word ([actionLabel]) in pale green mono capitals at
/// its end. A page confirms through [LedgerToast.show], never by standing
/// this in its body.
///
/// ```dart
/// LedgerToastCard('Moved to Groceries', actionLabel: 'Undo', onActionPressed: undo)
/// ```
class LedgerToastCard extends StatelessWidget {
  /// A toast's face worded [message].
  const LedgerToastCard(
    this.message, {
    super.key,
    this.icon = LucideIcons.check,
    this.actionLabel,
    this.onActionPressed,
  });

  /// The confirmation.
  final String message;

  /// The mark's glyph.
  final IconData icon;

  /// The one inline action's word ("Undo"); none when null.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    const mark = LedgerChromeMetrics.toastMark;
    const act = LedgerChromeMetrics.toastAct;
    // At a large text size the act grows with its word rather than cut it:
    // its height is the least it stands.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: LedgerChromeMetrics.toastMinHeight,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(
          LedgerChromeMetrics.toastStart,
          LedgerChromeMetrics.toastPad,
          LedgerChromeMetrics.toastPad,
          LedgerChromeMetrics.toastPad,
        ),
        decoration: BoxDecoration(
          color: t.toast,
          borderRadius: BorderRadius.circular(t.cardRadius),
          boxShadow: t.toastShadow,
        ),
        child: Row(
          spacing: LedgerChromeMetrics.toastGap,
          children: [
            Container(
              width: mark,
              height: mark,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.toastRing),
              ),
              child: ledgerGlyph(
                context,
                icon,
                size: LedgerChromeMetrics.toastGlyph,
                color: t.onToast,
              ),
            ),
            Expanded(child: Text(message, style: t.toastText)),
            if (actionLabel != null)
              // Its own button, beside the words rather than merged into
              // the toast's node.
              Semantics(
                container: true,
                child: LedgerPressable(
                  onTap: onActionPressed,
                  label: actionLabel,
                  radius: act / 2,
                  child: Container(
                    height: larger ? null : act,
                    constraints: larger
                        ? const BoxConstraints(minHeight: act)
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: LedgerChromeMetrics.toastActPad,
                    ),
                    // Its own width under a loose one: a Container's alignment
                    // would stretch it.
                    child: Center(
                      widthFactor: 1,
                      heightFactor: larger ? 1 : null,
                      child: Text(
                        actionLabel!.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        // The word's line is the act's 36; grown, it sets
                        // on the mono's own 16.
                        style: (larger ? t.toastAction.line(16) : t.toastAction)
                            .colored(t.onToastAction),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
