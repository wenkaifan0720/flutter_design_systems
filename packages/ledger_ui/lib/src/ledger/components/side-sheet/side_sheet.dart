/// A sheet that stands in from a side of the screen, in Ledger's hand, on
/// ui_core's side sheet route.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';
import '../host.dart';
import '../icon-button/icon_button.dart';
import '../sheet.dart';

export 'package:ui_core/ui_core.dart' show DesignSheetEdge;

/// A side sheet's panel (a record's details beside its list, the filters of
/// a register): the raised paper the screen's height, a hairline on its
/// inner edge, its [title] in the serif with the ringed close at the head's
/// end, the [child] scrolling under a hairline and [foot]'s acts at its
/// foot. [showLedgerSideSheet] stands it in from a side; drawn in place it
/// is the same panel.
///
/// ```dart
/// LedgerSideSheet(title: 'Filters', onClose: () {}, child: Text('Money in'))
/// ```
class LedgerSideSheet extends StatelessWidget {
  /// A panel titled [title] holding [child].
  const LedgerSideSheet({
    required this.title,
    required this.child,
    this.foot = const [],
    this.onClose,
    this.side = AxisDirection.right,
    super.key,
  });

  /// The head's words.
  final String title;

  /// The body, scrolling.
  final Widget child;

  /// The acts at its foot: one takes the whole width, two share it.
  final List<Widget> foot;

  /// What the close does; null pops the sheet's route.
  final VoidCallback? onClose;

  /// The side of the screen it stands on, which puts its hairline on the
  /// other.
  final AxisDirection side;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(ObjectFlagProperty<VoidCallback>.has('onClose', onClose))
      ..add(DiagnosticsProperty<AxisDirection>('side', side));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final rule = BorderSide(color: t.border);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(
          left: side == AxisDirection.right ? rule : BorderSide.none,
          right: side == AxisDirection.left ? rule : BorderSide.none,
        ),
        boxShadow: t.sheetShadow,
      ),
      child: SafeArea(
        left: side == AxisDirection.left,
        right: side == AxisDirection.right,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LedgerChromeMetrics.gutter,
                LedgerSpacing.s16,
                LedgerChromeMetrics.gutter,
                LedgerSpacing.s12,
              ),
              child: LedgerSheetHead(
                title: title,
                close: LedgerIconButton.outlined(
                  LucideIcons.x,
                  semanticLabel: DesignLocalizations.of(context)
                      .closeButtonLabel,
                  size: LedgerIconButtonSize.small,
                  tapAlignment: AlignmentDirectional.centerEnd,
                  onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            SizedBox(height: 1, child: ColoredBox(color: t.hairline)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LedgerChromeMetrics.gutter,
                  vertical: LedgerSpacing.s20,
                ),
                child: child,
              ),
            ),
            if (foot.isNotEmpty) ...[
              SizedBox(height: 1, child: ColoredBox(color: t.hairline)),
              Padding(
                padding: const EdgeInsets.all(LedgerChromeMetrics.gutter),
                child: LedgerSheetShell.footOf(foot),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Stands a [LedgerSideSheet] titled [title] in from [edge] (the reading
/// end by default) over the whole app, [width] wide, leaving at least 56 of
/// the screen beside it on a phone; a tap on the scrim, the system back, the
/// Escape key, the close or a drag toward its edge dismisses it, focus
/// coming back to where it was. Completes with the value it pops with.
///
/// ```dart
/// final applied = await showLedgerSideSheet<bool>(context, title: 'Filters', builder: (context) => filters);
/// ```
Future<T?> showLedgerSideSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
  List<Widget> Function(BuildContext context)? foot,
  DesignSheetEdge edge = DesignSheetEdge.end,
  double width = 400,
}) {
  final navigator = LedgerHost.navigatorOf(context);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  return navigator.push<T>(
    DesignSideSheetRoute<T>(
      edge: edge,
      width: width,
      semanticLabel: title,
      builder: (sheetContext, sheet) => themes.wrap(
        Builder(
          builder: (context) => LedgerSideSheet(
            title: title,
            side: sheet.side,
            onClose: sheet.close,
            foot: foot?.call(context) ?? const [],
            child: builder(context),
          ),
        ),
      ),
    ),
  );
}
