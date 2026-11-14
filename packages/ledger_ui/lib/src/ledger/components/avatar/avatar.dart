import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/cap_center.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// The owner's avatar: their [initials] in the italic serif on a 36 ink
/// disc, saying [label] (Profile and settings). A null [onTap] draws it
/// unpressable (the sidebar's foot presses as a whole).
///
/// ```dart
/// LedgerAvatar(initials: 'MH', label: 'Profile and settings', onTap: () {})
/// ```
class LedgerAvatar extends StatelessWidget {
  /// The avatar of [initials], saying [label].
  const LedgerAvatar({
    required this.initials,
    this.label,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// One or two letters.
  final String initials;

  /// What a press opens, spoken; null speaks the initials.
  final String? label;

  /// Opens the profile; null draws it unpressable.
  final VoidCallback? onTap;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final disc = Container(
      width: LedgerChromeMetrics.avatar,
      height: LedgerChromeMetrics.avatar,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: t.avatar),
      // Its capitals on the disc's middle, as every face's label stands.
      child: ledgerCapCenter(
        t.initials,
        Text(
          initials,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: t.initials.colored(t.onAvatar),
        ),
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: label ?? initials,
        excludeSemantics: true,
        child: disc,
      );
    }
    return LedgerHitSlop(
      child: LedgerPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onTap: onTap,
        label: label ?? initials,
        radius: LedgerChromeMetrics.avatar / 2,
        child: disc,
      ),
    );
  }
}
