/// A slip of detail anchored to the control that opens it, in Ledger's hand,
/// on ui_core's anchored overlay.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../theme.dart';

export 'package:ui_core/ui_core.dart' show DesignOverlayAnchor;

/// A slip of detail anchored to a control (how a figure was reached, a
/// payee's details beside its name): the raised paper in the rule, at most
/// [width] wide, its [title] in the medium over the [child], below the
/// anchor (above it when there is no room), lining up with its reading
/// start. [anchor] builds the control from its [DesignOverlayAnchor]: its
/// press calls `toggle`, and its `isOpen` is the control's expanded state.
/// The slip fades and settles in on Ledger's spring (at once with reduced
/// motion); a tap outside, Escape or the anchor again closes it, focus
/// going back to the anchor.
///
/// ```dart
/// LedgerPopover(semanticLabel: 'How this is worked out', title: 'Safe to spend', anchor: (context, a) => LedgerButton.text('How?', onPressed: a.toggle), child: Text('Your balance less bills due before payday.'))
/// ```
class LedgerPopover extends StatelessWidget {
  /// A slip of [child] anchored to [anchor].
  const LedgerPopover({
    required this.anchor,
    required this.child,
    required this.semanticLabel,
    this.title,
    this.width = 320,
    super.key,
  }) : assert(width > 0);

  /// Builds the control that opens it.
  final Widget Function(BuildContext context, DesignOverlayAnchor anchor)
  anchor;

  /// The slip's body.
  final Widget child;

  /// The slip's head, in the medium.
  final String? title;

  /// What a screen reader calls the slip.
  final String semanticLabel;

  /// The most it is wide.
  final double width;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(DoubleProperty('width', width));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final reduced = LedgerMotion.isReduced(context);
    return DesignAnchoredOverlay(
      semanticLabel: semanticLabel,
      placement: const DesignOverlayPlacement(
        gap: LedgerSpacing.s6,
        matchAnchorWidth: false,
      ),
      stiffness: reduced ? 1e6 : 1400,
      anchorBuilder: anchor,
      overlayBuilder: (context, info) => FadeTransition(
        opacity: info.animation,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width.clamp(0, info.maxSize.width),
            maxHeight: info.maxSize.height,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(t.smallRadius),
              border: Border.all(color: t.border),
              boxShadow: t.menuShadow,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(LedgerSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: LedgerSpacing.s6,
                children: [
                  if (title case final head?)
                    Text(head, style: t.rowTitle.colored(t.textPrimary)),
                  DefaultTextStyle.merge(
                    style: t.bodySmall.colored(t.textSecondary),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
