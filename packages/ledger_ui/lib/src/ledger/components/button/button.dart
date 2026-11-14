import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../internal/button_ends.dart';
import '../../internal/cap_center.dart';
import '../../internal/end_glyph.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';

/// How tall a [LedgerButton] stands, at [LedgerDensity.standard] (each
/// density step takes 4 off).
enum LedgerButtonSize {
  /// 32, its words 13: the small act at a section head's end or in a row.
  small,

  /// 40, its words 14: acts side by side under a slip.
  medium,

  /// 48, its words 15: a page's or a sheet's act.
  large,
}

enum _Face { ringed, filled, ink, text }

/// A round button: its [label] and an optional [icon] (before the words, or
/// after with [iconAfter]; a left or right chevron or arrow turns the other
/// way in a right-to-left page). [expand] stretches it across its room: its
/// column on a phone; from 600 up to 320 (`LedgerLayout.fieldMeasure`),
/// wider only for longer words, at the start of its slot.
///
/// - `LedgerButton(label)` is the ordinary act, ringed in the ink (at
///   [LedgerButtonSize.small], ringed in the rule on the raised paper).
/// - `LedgerButton.filled` is the page's one act: the accent green, its
///   words in the raised paper, a soft green drop under it.
/// - `LedgerButton.ink` is a firm act on a raised surface (a sheet's or a
///   dialog's confirm): filled with the ink.
/// - `LedgerButton.text` has no frame: its words alone.
///
/// [isDestructiveAction] draws any of them in the danger red. A null
/// [onPressed] disables it: written in pencil, not ink (no fill, the light
/// rule round it, its words in the third ink). Pressed, the face sinks into
/// the paper and its drop goes; a frameless one's words take the ink
/// underline while held. The touch target is 44
/// at every size and density; what shrinks is the drawn face.
/// [semanticLabel] names it for a screen reader when its words say less
/// than the act ("Change category" for a Change).
///
/// ```dart
/// LedgerButton.filled('Move money', icon: LucideIcons.arrowRightLeft, onPressed: () {})
/// ```
///
/// ```dart
/// LedgerButton('Add money', size: LedgerButtonSize.medium, icon: LucideIcons.plus, onPressed: () {})
/// ```
///
/// ```dart
/// LedgerButton.ink('Freeze card', onPressed: () {})
/// ```
///
/// ```dart
/// LedgerButton.text('View all', onPressed: () {})
/// ```
class LedgerButton extends StatelessWidget {
  /// The ordinary act, ringed in the ink.
  const LedgerButton(
    this.label, {
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.expand = false,
    this.isDestructiveAction = false,
    this.size = LedgerButtonSize.large,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = _Face.ringed;

  /// The page's one act, filled in the accent green.
  const LedgerButton.filled(
    this.label, {
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.expand = false,
    this.isDestructiveAction = false,
    this.size = LedgerButtonSize.large,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = _Face.filled;

  /// A firm act on a raised surface, filled with the ink.
  const LedgerButton.ink(
    this.label, {
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.expand = false,
    this.isDestructiveAction = false,
    this.size = LedgerButtonSize.large,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = _Face.ink;

  /// An act with no frame: its words alone, in the ink.
  const LedgerButton.text(
    this.label, {
    required this.onPressed,
    this.icon,
    this.iconAfter = false,
    this.expand = false,
    this.isDestructiveAction = false,
    this.size = LedgerButtonSize.large,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _face = _Face.text;

  /// Its words.
  final String label;

  /// What a press does; null disables it.
  final VoidCallback? onPressed;

  /// A Lucide glyph beside the words.
  final IconData? icon;

  /// Whether the glyph follows the words.
  final bool iconAfter;

  /// Whether it fills its room's width.
  final bool expand;

  /// Whether the act destroys or removes something: drawn in the danger
  /// red.
  final bool isDestructiveAction;

  /// How tall it stands.
  final LedgerButtonSize size;

  /// The spoken name; null speaks the [label].
  final String? semanticLabel;

  /// Its focus node, which the caller disposes; null keeps its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  final _Face _face;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final live = onPressed != null;
    final danger = isDestructiveAction;
    final small = size == LedgerButtonSize.small;
    // Disabled, an act is written in pencil, not ink: no fill, the light
    // rule round it and its words in the third ink; a frameless one keeps
    // only the words.
    final (Color? fill, Color ink, Color? ring) = switch (_face) {
      _ when !live => (
        null,
        t.textTertiary,
        _face == _Face.text ? null : t.border,
      ),
      _Face.filled => (
        danger ? t.danger : t.accent,
        danger ? t.onDanger : t.onAccent,
        null,
      ),
      _Face.ink => (
        danger ? t.danger : t.surfaceInverse,
        danger ? t.onDanger : t.textInverse,
        null,
      ),
      // A destructive act's words on the paper in the vermilion as words
      // (`over`, 4.5:1 there); its ring in the vermilion itself.
      _Face.ringed when small => (
        t.surface,
        danger ? t.over : t.textPrimary,
        danger ? t.danger : t.border,
      ),
      _Face.ringed => (
        null,
        danger ? t.over : t.textPrimary,
        danger ? t.danger : t.borderStrong,
      ),
      _Face.text => (null, danger ? t.over : t.textPrimary, null),
    };
    final (
      double base,
      double pad,
      double glyphSize,
      double gap,
    ) = switch (size) {
      LedgerButtonSize.small => (
        LedgerChromeMetrics.quietButton,
        LedgerChromeMetrics.quietPad,
        LedgerChromeMetrics.quietGlyph,
        LedgerChromeMetrics.quietGap,
      ),
      LedgerButtonSize.medium => (
        _mediumHeight,
        _mediumPad,
        LedgerChromeMetrics.buttonGlyph,
        LedgerChromeMetrics.buttonGap,
      ),
      LedgerButtonSize.large => (
        LedgerChromeMetrics.button,
        LedgerChromeMetrics.buttonPad,
        LedgerChromeMetrics.buttonGlyph,
        LedgerChromeMetrics.buttonGap,
      ),
    };
    final style = switch (size) {
      LedgerButtonSize.small => t.buttonSmall.colored(ink),
      LedgerButtonSize.medium => t.button.sized(_mediumWords).colored(ink),
      LedgerButtonSize.large => t.button.colored(ink),
    }.copyWith(leadingDistribution: TextLeadingDistribution.even);
    final height = t.density.height(base, floor: _floor);
    // From 600 a button keeps to its words; one that [expand]s fills its
    // room up to the measure (320), wider only for longer words, at the
    // start of its slot: never a banner across a wide column.
    final measured = LedgerLayout.keepsMeasure(context);
    final ends = _face == _Face.text
        ? _textPad
        : small
        ? pad
        : LedgerButtonEnds.of(context) ?? pad;
    final shadow = _face == _Face.filled && live && !danger
        ? t.primaryShadow
        : null;
    final frameless = _face == _Face.text;
    // At a large text size a label too long for its line wraps whole and
    // the face grows taller (its height the least it stands), never cut.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    // Pressed, the face sinks into the paper and its drop goes, and a
    // frameless act's words take the ink underline; every change of fill,
    // rim, drop and ink moves in Ledger's one motion ([LedgerFace]).
    final face = Builder(
      builder: (context) {
        final held = LedgerPressStates.of(context)
            .contains(WidgetState.pressed);
        // Held, the face takes a stamp's impression: its fill a shade
        // further into the ink, a ring's paper a wash of it; by lamplight,
        // where no drop falls, it is all the press writes.
        final Color? pressedFill = fill != null
            ? Color.lerp(fill, t.textPrimary, _impression)
            : ring != null
            ? t.textPrimary.withValues(alpha: _impression / 2)
            : null;
        return LedgerFace(
          style: LedgerFaceStyle(
            ink: ink,
            rule: frameless && held ? ink : null,
            ground: BoxDecoration(
              color: held && live ? pressedFill : fill,
              borderRadius: BorderRadius.circular(t.controlRadius),
              border: ring == null ? null : Border.all(color: ring),
              boxShadow: held ? null : shadow,
            ),
          ),
          builder: (context, s, _) {
            final type = style.colored(s.ink);
            final words = s.rule == null
                ? type
                : type.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: s.rule,
                  );
            // A left or right chevron or arrow turns the other way in a
            // right-to-left page: Continue's arrow points on.
            final glyph = icon == null
                ? null
                : ledgerGlyph(context, icon!, size: glyphSize, color: s.ink);
            return Container(
              height: larger ? null : height,
              constraints: larger ? BoxConstraints(minHeight: height) : null,
              padding: EdgeInsets.symmetric(
                horizontal: ends,
                vertical: larger ? _largerPad : 0,
              ),
              decoration: s.ground,
              child: Row(
                mainAxisSize: expand && !measured
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: gap,
                children: [
                  if (glyph != null && !iconAfter) glyph,
                  Flexible(
                    child: larger
                        ? Text(label, textAlign: TextAlign.center, style: words)
                        : ledgerCapCenter(
                            words,
                            Text(
                              label,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: words,
                            ),
                          ),
                  ),
                  if (glyph != null && iconAfter) glyph,
                ],
              ),
            );
          },
        );
      },
    );
    final button = LedgerHitSlop(
      child: LedgerPressable(
        onTap: onPressed,
        label: semanticLabel ?? label,
        radius: t.controlRadius,
        focusNode: focusNode,
        autofocus: autofocus,
        child: face,
      ),
    );
    if (!measured) return button;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: expand
          ? ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: LedgerLayout.fieldMeasure,
              ),
              child: button,
            )
          : button,
    );
  }

  // `.memo-acts .btn`: 40 tall, 0 16, 14; its glyph and gap the `.btn`'s.
  static const double _mediumHeight = 40;
  static const double _mediumPad = 16;
  static const double _mediumWords = 14;

  // A frameless button keeps its words 8 from the reach of its press.
  static const double _textPad = 8;

  // Grown with a large text, its words stand 4 clear of its rim (a face of
  // one line keeps its height).
  static const double _largerPad = 4;

  // No face shorter than this at any density.
  static const double _floor = 28;

  // How far a held face's fill goes into the ink.
  static const double _impression = .12;
}
