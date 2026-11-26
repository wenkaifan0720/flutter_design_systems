import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../internal/end_glyph.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../style.dart';
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
/// its glyph in pencil, the third ink. It lays out at the tap floor round
/// its face at every size (40 for a finger, 24 for a pointer). A left or right chevron or arrow turns the other way in a
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
    this.tapAlignment = AlignmentDirectional.center,
    this.style,
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
    this.tapAlignment = AlignmentDirectional.center,
    this.style,
    super.key,
  }) : outlined = true;

  /// Its glyph.
  final IconData icon;

  /// Where the face stands in its tap target where the target is larger:
  /// centred, or on the edge a keyline runs ([AlignmentDirectional.centerStart]
  /// at the start of a column, [AlignmentDirectional.centerEnd] at its end),
  /// the target growing away from it.
  final AlignmentDirectional tapAlignment;

  /// What it does, spoken (Back to Home, Close).
  final String semanticLabel;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// How large it stands.
  final LedgerIconButtonSize size;

  /// Whether a rule rings it.
  final bool outlined;

  /// This button's look, over `components.iconButton`. It reads `fill`,
  /// `foreground`, `edge`, `side`, `overlay`, `shape` and `iconSize`.
  final LedgerStyle? style;

  /// Whether it carries the green dot.
  final bool showBadge;

  /// The button's focus; never disposed when given.
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
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
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(
        DiagnosticsProperty<AlignmentDirectional>('tapAlignment', tapAlignment),
      )
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(EnumProperty<LedgerIconButtonSize>('size', size))
      ..add(FlagProperty('outlined', value: outlined, ifTrue: 'outlined'))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      )
      ..add(FlagProperty('showBadge', value: showBadge, ifTrue: 'showBadge'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }

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
            child: Builder(
              builder: (context) {
                final so = LedgerStyleOf(
                  [style, t.components.iconButton],
                  {
                    ...LedgerPressStates.of(context),
                    if (onPressed == null) WidgetState.disabled,
                  },
                );
                return LedgerFace(
                  style: so.dress(
                    LedgerFaceStyle(
                      ink: onPressed == null ? t.textTertiary : t.textPrimary,
                      ground: BoxDecoration(
                        shape: BoxShape.circle,
                        border: outlined ? Border.all(color: t.border) : null,
                      ),
                    ),
                  ),
                  builder: (context, s, _) => DecoratedBox(
                    decoration: s.ground,
                    child: Center(
                      child: ledgerGlyph(
                        context,
                        icon,
                        size: so.iconSize ?? size.glyph,
                        color: s.ink,
                      ),
                    ),
                  ),
                );
              },
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
    return TapTargetPadding(
      alignment: tapAlignment,
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
    this.tapAlignment = AlignmentDirectional.center,
    super.key,
  }) : _outlined = false;

  /// A bell ringed in the rule (the desktop's masthead).
  const LedgerBell.outlined({
    required this.unread,
    required this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.tapAlignment = AlignmentDirectional.center,
    super.key,
  }) : _outlined = true;

  /// How many notes are unread.
  final int unread;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  final bool _outlined;

  /// Where the bell stands in its tap target where the target is larger:
  /// centred, or on the edge a keyline runs ([AlignmentDirectional.centerStart]
  /// at the start of a column, [AlignmentDirectional.centerEnd] at its end),
  /// the target growing away from it.
  final AlignmentDirectional tapAlignment;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('unread', unread))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<AlignmentDirectional>('tapAlignment', tapAlignment),
      );
  }

  @override
  Widget build(BuildContext context) => _outlined
      ? LedgerIconButton.outlined(
          LucideIcons.bell,
          semanticLabel: 'Notifications, $unread unread',
          onPressed: onPressed,
          showBadge: unread > 0,
          focusNode: focusNode,
          autofocus: autofocus,
          tapAlignment: tapAlignment,
        )
      : LedgerIconButton(
          LucideIcons.bell,
          semanticLabel: 'Notifications, $unread unread',
          onPressed: onPressed,
          showBadge: unread > 0,
          focusNode: focusNode,
          autofocus: autofocus,
          tapAlignment: tapAlignment,
        );
}
