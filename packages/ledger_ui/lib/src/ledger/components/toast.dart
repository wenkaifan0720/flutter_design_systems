import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart' show ShellInsets;
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/corners.dart';
import '../internal/end_glyph.dart';
import '../internal/footer_band.dart';
import '../internal/styled.dart';
import '../style.dart';
import '../theme.dart';
import 'host.dart';
import 'pressable/pressable.dart';

/// A short confirmation over the page, as Ledger raises one (Moved to
/// Groceries, Card number copied): the toast rising 12 clear of the tab bar
/// on a tab's page (96 over its foot), 24 over the bottom edge elsewhere,
/// 16 in from either side; at desktop width 380 wide at the window's bottom
/// right, 32 in. It stays a few seconds, longer with its one inline act
/// (Undo), and a new toast replaces the one still showing. Its time stops
/// while a pointer rests on it or the keyboard is in it; F6 takes the
/// keyboard to it, Escape dismisses it, and a screen reader hears it. The
/// behaviour is ui_core's ([RawToaster]), installed by [LedgerHost]
/// ([LedgerToaster]); Ledger paints it.
///
/// ```dart
/// LedgerToast.show(context, 'Moved to Groceries', actionLabel: 'Undo', onActionPressed: undo);
/// ```
abstract final class LedgerToast {
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
    final toaster =
        context.findAncestorStateOfType<_LedgerToasterState>() ??
        _rootToaster(context);
    // Where it stands is read here, at the caller: the toaster stands above
    // the navigator, where no page's tab bar is in sight.
    final place = _placeFor(context, toaster);
    final toast = RawToast(
      message: message,
      actionLabel: actionLabel,
      onAction: actionLabel == null ? null : (onActionPressed ?? () {}),
      duration: actionLabel == null
          ? LedgerChromeMetrics.toastDwell
          : LedgerChromeMetrics.toastDwellAction,
      id: _oneAtATime,
      data: icon,
    );
    if (toaster != null) {
      toaster._show(toast, place);
    } else {
      // The fallback toaster builds next frame; the first toast waits for it.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _fallbacks[LedgerHost.navigatorOf(context).overlay!]
            ?.currentState
            ?._show(toast, place),
      );
    }
  }

  /// Every Ledger toast's id: a new one replaces the one showing.
  static const Object _oneAtATime = #ledgerToast;

  /// Where a toast raised from [context] stands over [toaster]'s ground.
  static _Place _placeFor(BuildContext context, _LedgerToasterState? toaster) {
    final wide = LedgerLayout.isWide(context);
    if (wide) return const _Place(LedgerChromeMetrics.toastEdgeWide, true);
    final box = toaster?.context.findRenderObject();
    final stands = math.max(
      ShellInsets.of(context),
      box is RenderBox ? LedgerBottomStand.reachOf(context, box) : 0.0,
    );
    // Ledger stands it 96 over a tab's foot, 12 clear of the 84 bar,
    // and 24 over any other.
    const clear =
        LedgerChromeMetrics.toastOverBar - LedgerChromeMetrics.tabBarHeight;
    return _Place(
      stands > 0
          ? stands + clear
          : math.max(
              LedgerChromeMetrics.toastFoot,
              MediaQuery.paddingOf(context).bottom + clear,
            ),
      false,
    );
  }
}

/// How far over the bottom edge a toast stands, and whether at desk width.
@immutable
class _Place {
  const _Place(this.bottom, this.wide);

  final double bottom;
  final bool wide;
}

/// A toaster of the app's root overlay, for a caller with no
/// [LedgerToaster] above it (a page composed without [LedgerHost]).
final Expando<GlobalKey<_LedgerToasterState>> _fallbacks = Expando();

_LedgerToasterState? _rootToaster(BuildContext context) {
  final overlay = LedgerHost.navigatorOf(context).overlay!;
  final known = _fallbacks[overlay];
  if (known != null) return known.currentState;
  final made = _fallbacks[overlay] = GlobalKey<_LedgerToasterState>();
  final themes = InheritedTheme.capture(from: context, to: overlay.context);
  overlay.insert(
    OverlayEntry(
      builder: (_) =>
          themes.wrap(LedgerToaster(key: made, child: const SizedBox.expand())),
    ),
  );
  return null;
}

/// Hosts Ledger's toasts over [child]: [LedgerHost] installs one above the
/// app's navigator, so a page needs nothing of its own. One shows at a
/// time, where [LedgerToast.show] says (over the tab bar on a phone, at the
/// bottom right from desk width). The behaviour is ui_core's
/// ([RawToaster]); Ledger paints each toast as a [LedgerToastCard].
///
/// ```dart
/// LedgerToaster(child: app)
/// ```
class LedgerToaster extends StatefulWidget {
  /// A toaster over [child].
  const LedgerToaster({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  State<LedgerToaster> createState() => _LedgerToasterState();
}

class _LedgerToasterState extends State<LedgerToaster> {
  final GlobalKey<RawToasterState> _toaster = GlobalKey();
  _Place _place = const _Place(LedgerChromeMetrics.toastFoot, false);

  void _show(RawToast toast, _Place place) {
    if (place.bottom != _place.bottom || place.wide != _place.wide) {
      setState(() => _place = place);
    }
    _toaster.currentState?.show(toast);
  }

  Widget _toast(BuildContext context, RawToastDetails d) {
    final t = context.ledgerTheme;
    final still = LedgerMotion.isReduced(context);
    final icon = d.toast.data;
    final card = Container(
      foregroundDecoration: d.focused
          ? BoxDecoration(
              borderRadius: ledgerStep(t, RawCorner.medium),
              border: Border.all(
                color: t.onToast,
                width: LedgerChromeMetrics.focusRing,
              ),
            )
          : null,
      child: LedgerToastCard(
        d.toast.message,
        icon: icon is IconData ? icon : LucideIcons.check,
        actionLabel: d.toast.actionLabel,
        onActionPressed: d.runAction,
      ),
    );
    return IgnorePointer(
      // Without an action every tap must still reach the page beneath.
      ignoring: d.toast.actionLabel == null,
      child: still
          ? card
          : AnimatedBuilder(
              animation: d.animation,
              builder: (context, child) {
                final v = d.animation.value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * LedgerChromeMetrics.toastRise),
                    child: child,
                  ),
                );
              },
              child: card,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The toaster keeps the safe area; the place counts from the edge.
    final safe = MediaQuery.paddingOf(context).bottom;
    final bottom = math.max(_place.bottom - safe, 0.0);
    const side = LedgerChromeMetrics.toastSide;
    const edge = LedgerChromeMetrics.toastEdgeWide;
    return RawToaster(
      key: _toaster,
      maxVisible: 1,
      alignment: _place.wide
          ? AlignmentDirectional.bottomEnd
          : AlignmentDirectional.bottomCenter,
      padding: _place.wide
          ? EdgeInsetsDirectional.fromSTEB(edge, edge, edge, bottom)
          : EdgeInsetsDirectional.fromSTEB(side, side, side, bottom),
      constraints: _place.wide
          ? const BoxConstraints.tightFor(width: LedgerChromeMetrics.toastWidth)
          : const BoxConstraints(),
      swipeDirection: DismissDirection.horizontal,
      toastBuilder: _toast,
      child: widget.child,
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
    this.style,
  });

  /// The confirmation.
  final String message;

  /// The mark's glyph.
  final IconData icon;

  /// The one inline action's word ("Undo"); none when null.
  final String? actionLabel;

  /// What the action does.
  final VoidCallback? onActionPressed;

  /// The toast's look, over `components.toast`. It reads `fill`, `foreground`
  /// (its words' and mark's ink), `edge`, `side`, `corners` (or `shape`),
  /// `padding`, `textStyle` and `iconSize`; its act keeps the toast's own.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onActionPressed',
          onActionPressed,
        ),
      )
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    const mark = LedgerChromeMetrics.toastMark;
    const act = LedgerChromeMetrics.toastAct;
    // At a large text size the act grows with its word rather than cut it:
    // its height is the least it stands.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final so = LedgerStyleOf([style, t.components.toast], const {});
    final ink = so.foreground ?? t.onToast;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: const BoxConstraints(
          minHeight: LedgerChromeMetrics.toastMinHeight,
        ),
        padding:
            so.padding(Directionality.of(context)) ??
            const EdgeInsetsDirectional.fromSTEB(
              LedgerChromeMetrics.toastStart,
              LedgerChromeMetrics.toastPad,
              LedgerChromeMetrics.toastPad,
              LedgerChromeMetrics.toastPad,
            ),
        decoration: so.paper(
          BoxDecoration(
            color: t.toast,
            borderRadius: ledgerRadius(t, so, RawCorner.medium),
            boxShadow: t.toastShadow,
          ),
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
                size: so.iconSize ?? LedgerChromeMetrics.toastGlyph,
                color: ink,
              ),
            ),
            Expanded(child: Text(message, style: so.words(t.toastText, ink))),
            if (actionLabel != null)
              // Its own button, beside the words rather than merged into
              // the toast's node.
              Semantics(
                container: true,
                child: TapTargetPadding(
                  child: LedgerPressable(
                    onTap: onActionPressed,
                    semanticLabel: actionLabel,
                    borderRadius: BorderRadius.circular(act / 2),
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
                          style:
                              (larger ? t.toastAction.line(16) : t.toastAction)
                                  .colored(t.onToastAction),
                        ),
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
