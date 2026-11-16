import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/fit_words.dart';
import '../../theme.dart';

/// The page that says it is done: a block in the success colour with the
/// outcome as the page's heading in white and, under it, what the reader
/// keeps (a reference number, in large bold figures). Once per service, at
/// its end.
///
/// Reads [CivicStyle]'s fill (the block), foreground (its words), padding
/// and textStyle (the heading): its `style:`, then
/// [CivicThemeData.panelStyle].
///
/// ```dart
/// CivicConfirmationPanel(
///   title: 'Application sent',
///   child: Column(children: [
///     const Text('Your reference number'),
///     Text('BRM-4821-K', style: context.civicText.code),
///   ]),
/// )
/// ```
class CivicConfirmationPanel extends StatelessWidget {
  /// A confirmation.
  const CivicConfirmationPanel({
    super.key,
    required this.title,
    this.child,
    this.style,
  });

  /// The outcome: the page's heading.
  final String title;

  /// What the reader keeps.
  final Widget? child;

  /// Overrides for this panel's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final body = child;
    final so = DesignStyleOf([style, t.panelStyle], const {});
    // By night the block keeps a deep green under white words, as by day,
    // rather than the light green the night's success words take: a result,
    // not the brightest thing on the screen.
    final night = t.isDark && so.fill == null;
    final fill =
        so.fill ??
        (night
            ? HSLColor.fromColor(t.success).withLightness(0.24).toColor()
            : t.success);
    final words =
        so.foreground ?? (night ? const Color(0xFFFFFFFF) : t.onSuccess);
    return Semantics(
      container: true,
      child: ColoredBox(
        color: fill,
        child: Padding(
          padding:
              so.padding(Directionality.of(context)) ??
              const EdgeInsets.all(CivicSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: CivicSpacing.s16,
            children: [
              Semantics(
                header: true,
                child: CivicFitWords(
                  title,
                  textAlign: TextAlign.center,
                  style: text.headingXL
                      .merge(so.textStyle)
                      .copyWith(color: words),
                ),
              ),
              if (body != null)
                DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: text.headingS.copyWith(
                    color: words,
                    fontWeight: FontWeight.w400,
                  ),
                  child: body,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// A message across the top of a page the reader should see before
/// anything else: an outage, a deadline, a change made. [tone] info draws
/// it in the action colour, success in the success colour: a band with the
/// [title] over a white well holding the words.
///
/// Reads [CivicStyle]'s fill (the band), foreground (its words) and
/// textStyle (the message): its `style:`, then
/// [CivicThemeData.bannerStyle].
///
/// ```dart
/// CivicNotificationBanner(
///   title: 'Important',
///   child: const Text('Permits for Zone C are paused until 1 December.'),
/// )
/// ```
class CivicNotificationBanner extends StatelessWidget {
  /// A banner.
  const CivicNotificationBanner({
    super.key,
    required this.title,
    required this.child,
    this.tone = CivicTone.info,
    this.style,
  });

  /// The band's words: Important, Success.
  final String title;

  /// The message.
  final Widget child;

  /// Info or success.
  final CivicTone tone;

  /// Overrides for this banner's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.bannerStyle], const {});
    final band = so.fill ?? (tone == CivicTone.success ? t.success : t.action);
    final onBand =
        so.foreground ?? (tone == CivicTone.success ? t.onSuccess : t.onAction);
    return Semantics(
      container: true,
      liveRegion: tone == CivicTone.success,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: band,
          border: Border.all(color: band, width: CivicMetrics.bar),
          borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                CivicSpacing.s16,
                CivicSpacing.s4,
                CivicSpacing.s16,
                CivicSpacing.s8,
              ),
              child: Semantics(
                header: true,
                child: Text(title, style: text.label.copyWith(color: onBand)),
              ),
            ),
            ColoredBox(
              color: t.background,
              child: Padding(
                padding: const EdgeInsets.all(CivicSpacing.s16),
                child: DefaultTextStyle(
                  style: text.headingS.merge(so.textStyle),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(EnumProperty<CivicTone>('tone', tone, defaultValue: CivicTone.info))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
