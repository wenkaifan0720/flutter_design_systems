import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';
import '../link/link.dart';
import '../top-bar/top_bar.dart';

/// Hosts Civic's toasts over [child]: put it above the app's navigator
/// (`WidgetsApp.builder`), under a [CivicTheme], then call
/// [CivicToast.show]. F6 moves the focus to the newest toast; Escape
/// dismisses it. Where the toasts are taller than the screen (a long
/// toast at twice the text, or one leaving as the next comes), they scroll,
/// the newest in sight at the foot, rather than run off it.
///
/// Its toasts read [CivicStyle]'s fill (the band), edge (its hairline by
/// night), foreground (the words and the glyph) and textStyle: its
/// `style:`, then [CivicThemeData.toastStyle]. Keep the words at 7:1 on the
/// band.
///
/// In an app's `builder:`, under its theme:
/// `builder: (context, child) => CivicTheme(data: CivicThemeData.light(), child: CivicToaster(child: child!))`.
class CivicToaster extends StatelessWidget {
  /// A toaster over [child].
  const CivicToaster({super.key, required this.child, this.style});

  /// The app.
  final Widget child;

  /// Overrides for its toasts' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => RawToaster(
    maxVisible: 1,
    regionLabel: null,
    padding: const EdgeInsets.all(CivicSpacing.s16),
    // Nothing stands in the host while no toast shows; the scroll is never
    // the page's own.
    stackBuilder: (context, toasts) => toasts.isEmpty
        ? const SizedBox.shrink()
        : SingleChildScrollView(
            primary: false,
            reverse: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: toasts,
            ),
          ),
    toastBuilder: (context, details) =>
        _CivicToastView(details: details, style: style),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
    );
  }
}

/// A short word that something happened (Saved, Link copied), on the ink
/// band at the foot of the screen (by night, where the band is as dark as
/// the page, on the raised band inside a hairline that reads, as what floats
/// stands), read out by a screen reader. Never the only place something
/// important is said: a change that matters is on the page.
///
/// ```dart
/// CivicToast.show(context, 'Your answers have been saved');
/// ```
abstract final class CivicToast {
  /// Shows [message], replacing any still showing.
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onActionPressed,
    Duration duration = const Duration(seconds: 6),
  }) {
    final toaster = RawToaster.maybeOf(context);
    assert(toaster != null, 'No CivicToaster above this context.');
    toaster?.show(
      RawToast(
        id: _id,
        message: message,
        actionLabel: actionLabel,
        onAction: onActionPressed,
        duration: duration,
      ),
    );
  }

  static const Object _id = 'civic.toast';
}

class _CivicToastView extends StatelessWidget {
  const _CivicToastView({required this.details, required this.style});

  final RawToastDetails details;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.toastStyle], const {});
    // By night the top bar's band is as dark as the page under it: the
    // toast stands on the raised band inside the floating hairline instead,
    // so it reads as its own surface over the page.
    final night = t.isDark;
    final band = so.fill ?? (night ? t.surface : CivicTopBar.bandOf(t));
    final onBand = so.foreground ?? CivicTopBar.onBandOf(t);
    final words = text.label.merge(so.textStyle).copyWith(color: onBand);
    final a = details.animation.drive(
      Animatable<double>.fromCallback((v) => v.clamp(0.0, 1.0)),
    );
    final run = details.runAction;
    return FadeTransition(
      opacity: a,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: DecoratedBox(
          decoration: night
              ? civicFloating(
                  face: band,
                  hairline: so.edge ?? t.rule,
                  dark: true,
                  radius: 0,
                )
              : BoxDecoration(color: band),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              CivicSpacing.s20,
              CivicSpacing.s8,
              CivicSpacing.s4,
              CivicSpacing.s8,
            ),
            child: IconTheme.merge(
              data: IconThemeData(color: onBand),
              child: Row(
                spacing: CivicSpacing.s12,
                children: [
                  Expanded(child: Text(details.toast.message, style: words)),
                  if (run != null && details.toast.actionLabel != null)
                    CivicLink(
                      onPressed: run,
                      textStyle: words,
                      child: Text(details.toast.actionLabel!),
                    ),
                  CivicIconButton(
                    icon: LucideIcons.x,
                    semanticLabel: RawWidgetsLocalizations.of(context)
                        .closeButtonLabel,
                    tooltip: RawWidgetsLocalizations.of(context)
                        .closeButtonLabel,
                    onPressed: details.dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RawToastDetails>('details', details));
  }
}
