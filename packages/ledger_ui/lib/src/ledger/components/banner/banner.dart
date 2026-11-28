/// A notice standing in the page's flow, in Ledger's hand.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/corners.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../icon-button/icon_button.dart';

/// What a [LedgerBanner] says: news, a thing done, a thing to mind, or a
/// thing gone wrong.
enum LedgerBannerTone {
  /// News (a statement is ready): the ink.
  note,

  /// A thing done (the transfer cleared): the green.
  done,

  /// A thing to mind (a bill due before payday): the amber.
  mind,

  /// A thing gone wrong (the card was declined): the vermilion.
  wrong,
}

/// A notice in the page's flow (a statement ready, a card declined): the raised
/// paper in the rule with a stroke of its [tone] down its reading start, the
/// tone's glyph, [title] in the medium and [text] in the second ink;
/// [actionLabel] a text button under them (pressing it calls [onAction]),
/// [onDismiss] the ringed close at its end. A screen reader hears it as it
/// appears when it is [LedgerBannerTone.wrong] or [LedgerBannerTone.mind].
///
/// ```dart
/// LedgerBanner(title: 'Your October statement is ready', tone: LedgerBannerTone.note, actionLabel: 'Open', onAction: () {})
/// ```
class LedgerBanner extends StatelessWidget {
  // The glyph's middle set on the first line's cap height: its box dropped a
  // point below the line's top.
  static const double _glyphDrop = 1;

  /// A notice titled [title].
  const LedgerBanner({
    required this.title,
    this.text,
    this.tone = LedgerBannerTone.note,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
    this.style,
    super.key,
  }) : assert((actionLabel == null) == (onAction == null));

  /// What happened.
  final String title;

  /// The line under it.
  final String? text;

  /// What kind of notice it is.
  final LedgerBannerTone tone;

  /// The words of the act under it.
  final String? actionLabel;

  /// What the act does.
  final VoidCallback? onAction;

  /// What its close does; null shows none.
  final VoidCallback? onDismiss;

  /// The banner's look, over `components.banner`. It reads `fill`, `edge`,
  /// `side`, `corners` (or `shape`), `foreground` (its title's ink) and
  /// `textStyle` (its title's); a [LedgerBannerTone.wrong] banner is in the
  /// `error` state. The tone's stroke and glyph keep their inks: they carry its
  /// meaning.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('text', text, defaultValue: null))
      ..add(EnumProperty<LedgerBannerTone>('tone', tone))
      ..add(StringProperty('actionLabel', actionLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onAction', onAction))
      ..add(ObjectFlagProperty<VoidCallback>.has('onDismiss', onDismiss))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final (stroke, glyph) = switch (tone) {
      LedgerBannerTone.note => (t.textPrimary, LucideIcons.info),
      LedgerBannerTone.done => (t.moneyIn, LucideIcons.circleCheck),
      LedgerBannerTone.mind => (t.warning, LucideIcons.triangleAlert),
      LedgerBannerTone.wrong => (t.danger, LucideIcons.circleAlert),
    };
    final urgent =
        tone == LedgerBannerTone.wrong || tone == LedgerBannerTone.mind;
    final close = onDismiss;
    final so = LedgerStyleOf(
      [style, t.components.banner],
      {if (tone == LedgerBannerTone.wrong) WidgetState.error},
    );
    final ground = so.paper(
      BoxDecoration(
        color: t.surface,
        borderRadius: ledgerRadius(t, so, RawCorner.medium),
        border: Border.all(color: t.border),
      ),
    );
    return Semantics(
      container: true,
      liveRegion: urgent,
      child: DecoratedBox(
        decoration: ground,
        child: ClipRRect(
          borderRadius: ground.borderRadius ?? ledgerStep(t, RawCorner.medium),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: _stroke,
                  child: ColoredBox(color: stroke),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      LedgerSpacing.s12,
                      LedgerSpacing.s12,
                      LedgerSpacing.s4,
                      LedgerSpacing.s12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: LedgerSpacing.s10,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: _glyphDrop),
                          child: Icon(
                            glyph,
                            size: LedgerIconSize.i18,
                            color: stroke,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: LedgerSpacing.s2,
                            children: [
                              Text(
                                title,
                                style: so.words(
                                  t.rowTitle,
                                  so.foreground ?? t.textPrimary,
                                ),
                              ),
                              if (text case final line?)
                                Text(
                                  line,
                                  style: t.bodySmall.colored(t.textSecondary),
                                ),
                              if (actionLabel case final act?)
                                LedgerButton.text(
                                  act,
                                  size: LedgerButtonSize.small,
                                  onPressed: onAction,
                                ),
                            ],
                          ),
                        ),
                        if (close != null)
                          LedgerIconButton(
                            LucideIcons.x,
                            semanticLabel: RawWidgetsLocalizations.of(context)
                                .closeButtonLabel,
                            size: LedgerIconButtonSize.small,
                            tapAlignment: AlignmentDirectional.topEnd,
                            onPressed: close,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const double _stroke = 3;
}
