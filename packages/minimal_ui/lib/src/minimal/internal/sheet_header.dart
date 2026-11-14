import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'cap_label.dart';
import 'styled.dart';
import 'trailing_glyph.dart';

/// The sheet card's header band — the context the sheet acts in as a small
/// filled pill, what the sheet is, the header's actions and its close at
/// the far end. After a pill the title is a quiet crumb (`Habits  New
/// habit`); alone it names the sheet as a dialog names itself, in
/// [MinimalThemeData.h3] (`Filters`). One widget, so the static
/// [MinimalBottomSheet], the modal sheet and a sheet page's derived
/// [MinimalAppBar] print the same band.
class MinimalSheetHeader extends StatelessWidget {
  /// A sheet's header band.
  const MinimalSheetHeader({
    super.key,
    this.title,
    this.scope,
    this.actions = const <Widget>[],
    this.close,
  });

  /// What the sheet is: the quiet crumb after a [scope] pill, else the
  /// band's name in [MinimalThemeData.h3].
  final String? title;

  /// What the sheet acts in (a project, a team), printed as the pill.
  final String? scope;

  /// Buttons at its end, before the close.
  final List<Widget> actions;

  /// The dismiss control, or null for a header that cannot close.
  final Widget? close;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final scope = this.scope;
    final close = this.close;
    // The close is a bare cross in a bar square: its ink, not its square,
    // ends on the body's keyline, the square hanging past it.
    final square = t.density.height(MinimalChromeMetrics.barControl);
    final hang =
        (square - MinimalIconSize.i18) / 2 +
        MinimalIconSize.i18 * minimalCrossBearing;
    return SizedBox(
      height: MinimalChromeMetrics.sheetBar,
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: MinimalChromeMetrics.sheetPad,
          end: close == null
              ? MinimalChromeMetrics.sheetPad
              : math.max(0, MinimalChromeMetrics.sheetPad - hang),
        ),
        // A long scope (a team, a project name) ellipsizes inside at most
        // [_scopeShare] of the band, so the title always keeps a line.
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              if (scope != null) ...[
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * _scopeShare,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MinimalChromeMetrics.sheetPillPad,
                      vertical: MinimalSpacing.s2,
                    ),
                    decoration: minimalFrame(
                      t.shapes.mark,
                      fill: t.muted,
                      side: BorderSide(color: t.border, width: t.hairline),
                    ),
                    child: minimalCapLabel(
                      Text(
                        scope,
                        style: t.bodySmall.medium.c(t.foreground),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const MinimalGap(MinimalChromeMetrics.iconGap),
              ],
              Expanded(
                child: minimalCapLabel(
                  Text(
                    title ?? '',
                    style: scope == null
                        ? t.h3
                        : t.bodySmall.c(t.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              for (final action in actions) ...[
                const MinimalGap(MinimalSpacing.s4),
                action,
              ],
              if (close != null) ...[
                const MinimalGap(MinimalSpacing.s4),
                close,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// The most of the band the scope pill may take before it ellipsizes.
  static const double _scopeShare = 0.5;
}
