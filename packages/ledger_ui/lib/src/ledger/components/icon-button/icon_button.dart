import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../internal/end_glyph.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How large a [LedgerIconButton] stands, at [LedgerDensity.standard] (each
/// density step takes 4 off).
enum LedgerIconButtonSize {
  /// 36 round, its glyph 18: the way back, a sheet's close, a ringed tool.
  small(LedgerChromeMetrics.ringButton, LedgerChromeMetrics.ringGlyph),

  /// 40 round, its glyph 20: the bell, a bar's tool.
  medium(LedgerChromeMetrics.iconButton, LedgerChromeMetrics.iconGlyph),

  /// 48 round, its glyph 20: beside a large button or a field, on their
  /// line.
  large(48, LedgerChromeMetrics.iconGlyph);

  const LedgerIconButtonSize(this.size, this.glyph);

  /// Its side at [LedgerDensity.standard].
  final double size;

  /// Its glyph's size.
  final double glyph;
}

/// A round button of one glyph in the ink, saying [semanticLabel]: bare,
/// or with [LedgerIconButton.outlined] ringed in the rule (the way back, a
/// sheet's close, the desktop's bell). [showBadge] marks it with the green
/// dot ringed in the paper (unread notes). A null [onPressed] disables it:
/// its glyph in pencil, the third ink. Taps reach 44 round it at every
/// size. A left or right chevron or arrow turns the other way in a
/// right-to-left page, so a way back points to the reading start.
///
/// ```dart
/// LedgerIconButton(LucideIcons.search, semanticLabel: 'Search', onPressed: () {})
/// ```
///
/// ```dart
/// LedgerIconButton.outlined(LucideIcons.chevronLeft, semanticLabel: 'Back to Home', size: LedgerIconButtonSize.small, onPressed: () {})
/// ```
class LedgerIconButton extends StatelessWidget {
  /// A bare glyph.
  const LedgerIconButton(
    this.icon, {
    required this.semanticLabel,
    required this.onPressed,
    this.size = LedgerIconButtonSize.medium,
    this.showBadge = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : outlined = false;

  /// A glyph ringed in the rule.
  const LedgerIconButton.outlined(
    this.icon, {
    required this.semanticLabel,
    required this.onPressed,
    this.size = LedgerIconButtonSize.medium,
    this.showBadge = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : outlined = true;

  /// Its glyph.
  final IconData icon;

  /// What it does, spoken (Back to Home, Close).
  final String semanticLabel;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// How large it stands.
  final LedgerIconButtonSize size;

  /// Whether a rule rings it.
  final bool outlined;

  /// Whether it carries the green dot.
  final bool showBadge;

  /// The button's focus; never disposed when given.
  final FocusNode? focusNode;

  /// Whether it takes the focus when it first stands.
  final bool autofocus;

  /// Its side at [size] under [t]'s density: what a line it shares with
  /// words is made as tall as, so it stands on the line's middle.
  ///
  /// ```dart
  /// SizedBox(height: LedgerIconButton.sideOf(t, LedgerIconButtonSize.medium), child: row)
  /// ```
  static double sideOf(LedgerThemeData t, LedgerIconButtonSize size) =>
      t.density.height(size.size, floor: _floor);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final side = sideOf(t, size);
    final face = SizedBox.square(
      dimension: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            // Disabled, the glyph is in pencil (the third ink); the change
            // moves in Ledger's one motion.
            child: LedgerFace(
              style: LedgerFaceStyle(
                ink: onPressed == null ? t.textTertiary : t.textPrimary,
                ground: BoxDecoration(
                  shape: BoxShape.circle,
                  border: outlined ? Border.all(color: t.border) : null,
                ),
              ),
              builder: (context, s, _) => DecoratedBox(
                decoration: s.ground,
                child: Center(
                  child: ledgerGlyph(
                    context,
                    icon,
                    size: size.glyph,
                    color: s.ink,
                  ),
                ),
              ),
            ),
          ),
          if (showBadge)
            PositionedDirectional(
              top: LedgerChromeMetrics.dotTop * side / size.size,
              end: LedgerChromeMetrics.dotEnd * side / size.size,
              child: Container(
                width: LedgerChromeMetrics.dot,
                height: LedgerChromeMetrics.dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: t.accent,
                  border: Border.all(
                    color: t.dotRing,
                    width: LedgerChromeMetrics.dotRing,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return LedgerHitSlop(
      child: LedgerPressable(
        onTap: onPressed,
        label: semanticLabel,
        radius: side / 2,
        focusNode: focusNode,
        autofocus: autofocus,
        child: face,
      ),
    );
  }

  static const double _floor = 28;
}

/// The bell: the owner's notifications, its green dot while any are
/// unread, saying "Notifications, [unread] unread". Bare in the phone's
/// top bar; [LedgerBell.outlined] ringed on the desktop's masthead.
///
/// ```dart
/// LedgerBell(unread: 1, onPressed: () {})
/// ```
///
/// ```dart
/// LedgerBell.outlined(unread: 1, onPressed: () {})
/// ```
class LedgerBell extends StatelessWidget {
  /// A bare bell.
  const LedgerBell({
    required this.unread,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _outlined = false;

  /// A bell ringed in the rule (the desktop's masthead).
  const LedgerBell.outlined({
    required this.unread,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _outlined = true;

  /// How many notes are unread.
  final int unread;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  final bool _outlined;

  @override
  Widget build(BuildContext context) => _outlined
      ? LedgerIconButton.outlined(
          LucideIcons.bell,
          semanticLabel: 'Notifications, $unread unread',
          onPressed: onPressed,
          showBadge: unread > 0,
          focusNode: focusNode,
          autofocus: autofocus,
        )
      : LedgerIconButton(
          LucideIcons.bell,
          semanticLabel: 'Notifications, $unread unread',
          onPressed: onPressed,
          showBadge: unread > 0,
          focusNode: focusNode,
          autofocus: autofocus,
        );
}
