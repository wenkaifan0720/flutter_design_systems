import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show InputBorder, InputDecoration, Material, MaterialType, TextField;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/cap_center.dart';
import '../../internal/end_glyph.dart';
import '../../internal/face.dart';
import '../../internal/field_frame.dart';
import '../../internal/on_cheque.dart';
import '../../internal/text_input.dart';
import '../../internal/styled.dart';
import '../../style.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../text-field/text_field.dart';

/// A segmented set of words: the range of a chart (1M 3M 1Y
/// All), Today or Later. The chosen one is set in the ink, the rest in
/// the mono's second ink, all in one ring of the light paper; [onChanged]
/// null shows the set without letting it change. The chips are radios of
/// one group: one Tab stop, on the chosen one; the arrows move and choose,
/// round the ends. The ring is as wide as its chips, at the start of a
/// wider slot.
/// Keyboard focus rules the double rule under the focused chip, as wide
/// as the chip and touching it. The options are any values: [labelOf]
/// words each (its `toString()` when null), so a range can be an enum.
///
/// ```dart
/// LedgerSegmentedControl(options: const ['1M', '3M', '1Y', 'All'], value: '1Y', onChanged: (r) {})
/// ```
///
/// ```dart
/// LedgerSegmentedControl<({String short, int months})>(options: ranges, value: ranges.last, labelOf: (r) => r.short, onChanged: (r) {})
/// ```
class LedgerSegmentedControl<T> extends StatelessWidget {
  /// A strip of [options], [value] the chosen one.
  const LedgerSegmentedControl({
    required this.options,
    required this.value,
    this.onChanged,
    this.labelOf,
    this.style,
    super.key,
  });

  /// The segments' values, in order.
  final List<T> options;

  /// The chosen segment's value.
  final T value;

  /// Called with the segment chosen; null shows the set without letting it
  /// change.
  final ValueChanged<T>? onChanged;

  /// The words of each segment; null: the value's `toString()`.
  final String Function(T option)? labelOf;

  /// Each segment's look, over `components.segmentedControl`. It reads
  /// `fill`, `foreground`, `edge`, `side`, `overlay`, `shape`, `padding` and
  /// `textStyle`; the chosen segment is `selected`.
  final LedgerStyle? style;

  String _say(T option) => labelOf?.call(option) ?? '$option';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('labelOf', labelOf));
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(11).line(16).tracked(.02);
    // A chip grows with its words at a large text size rather than cut them:
    // its 5 above and under its line stay.
    final height =
        _height - _line + MediaQuery.textScalerOf(context).scale(_line);
    // The strip stands at the tap floor: its chips as tall as the floor less
    // the ring's room round them, each at least the floor's width. Each
    // chip's target runs the strip's whole height through the ring's room
    // above and under it, so its chosen ink fills the slot it is given.
    final floor = RawTapTargets.of(context).floorOn();
    final chip = math.max(height, floor.height - 2 * _pad);
    final innerRadius = math.max(0.0, t.controlRadius - _pad);
    // A chip: a radio of the strip's group, in a pressable's dress. The
    // chosen chip stays live (a screen reader must not call it dimmed);
    // choosing it again changes nothing.
    Widget chipOf(T o) => LedgerRadioPress<T>(
      value: o,
      enabled: onChanged != null,
      semanticLabel: _say(o),
      // The focus rule runs the chip's whole width and stands on its foot:
      // its face is 2 inside the target above, and the rule's own drop under
      // a face is taken back.
      radius: 0,
      ringInsets: const EdgeInsets.only(
        top: _pad,
        bottom: _pad + 2 * LedgerChromeMetrics.focusGap,
      ),
      // The ink fill leaves the old choice and inks in under the new one in
      // Ledger's one motion.
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _pad),
        child: Builder(
          builder: (context) {
            final so = LedgerStyleOf(
              [style, t.components.segmentedControl],
              {
                ...LedgerPressStates.of(context),
                if (o == value) WidgetState.selected,
                if (onChanged == null) WidgetState.disabled,
              },
            );
            return LedgerFace(
              style: so.dress(
                LedgerFaceStyle(
                  ink: o == value ? t.surface : t.textSecondary,
                  ground: BoxDecoration(
                    color: o == value ? t.textPrimary : null,
                    borderRadius: BorderRadius.circular(innerRadius),
                  ),
                ),
              ),
              builder: (context, s, _) => Container(
                height: chip,
                constraints: BoxConstraints(minWidth: floor.width),
                padding:
                    so.padding(Directionality.of(context)) ??
                    const EdgeInsets.symmetric(horizontal: _chipPad),
                decoration: s.ground,
                // Its own width under a loose one: a Container's alignment
                // would stretch it. A word longer than the strip's share
                // is set smaller, never cut.
                child: Center(
                  widthFactor: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ledgerCapCenter(
                      words,
                      Text(
                        _say(o),
                        softWrap: false,
                        style: so.words(words, s.ink),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    // The ring is drawn behind the strip, not padded round it: 3 inside its
    // outer edge (its 1 rule, then 2 of paper) at the ends, and the chips'
    // own 3 above and under them. A slot wider than the chips (a column
    // that stretches its children) keeps the ring to the chips, at the
    // slot's start, rather than drawing an empty run of ring after them.
    final strip = DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.controlRadius),
        border: Border.all(color: t.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _pad),
        // Flutter's radio group, with ui_core's keyboard fix inside it (the
        // arrows follow the reading direction); each chip a radio.
        child: RadioGroup<T>(
          groupValue: value,
          onChanged: (next) {
            if (next is T && next != value) onChanged?.call(next);
          },
          child: RadioGroupKeyboardFix<T>(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _gap,
              children: [for (final o in options) Flexible(child: chipOf(o))],
            ),
          ),
        ),
      ),
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: strip,
    );
  }

  // `.chips`: 2 inside its ring, 2 between; `.chip` 26 tall, 0 12.
  static const double _pad = 2;
  static const double _gap = 2;
  static const double _height = 26;
  static const double _line = 16;
  static const double _chipPad = 12;
}

/// Filter pills: each its own ring of the light paper, the
/// chosen one in the ink, wrapping 6 apart; [value] null chooses none.
/// [semanticLabel] names the set. [onChanged] null shows them without letting
/// them change. [optionKeys] keys each pill by its value. The options are
/// any values: [labelOf] words each (its `toString()` when null).
///
/// ```dart
/// LedgerFilters(semanticLabel: 'Direction', options: const ['All', 'Money in', 'Money out'], value: 'All', onChanged: (f) {})
/// ```
///
/// ```dart
/// LedgerFilters<({String words, bool? incoming})>(semanticLabel: 'Direction', options: directions, value: directions.first, labelOf: (d) => d.words, onChanged: (d) {})
/// ```
class LedgerFilters<T> extends StatelessWidget {
  /// Pills for each of [options], the [value] chosen, named [semanticLabel].
  const LedgerFilters({
    required this.options,
    required this.value,
    required this.semanticLabel,
    this.onChanged,
    this.optionKeys,
    this.labelOf,
    this.style,
    super.key,
  });

  /// The pills' values, in order.
  final List<T> options;

  /// The chosen pill's value; null chooses none.
  final T? value;

  /// What the set filters, for a screen reader.
  final String semanticLabel;

  /// Called with the pill chosen; null shows them without letting them change.
  final ValueChanged<T?>? onChanged;

  /// A key for each option's pill, by its value (a test's or a walk's
  /// target); an option it leaves out stands unkeyed.
  final Map<T, Key>? optionKeys;

  /// The words of each pill; null: the value's `toString()`.
  final String Function(T option)? labelOf;

  /// Each pill's look, over `components.toggleGroup` (the same pill). It
  /// reads `fill`, `foreground`, `edge`, `side`, `overlay`, `shape`,
  /// `padding` and `textStyle`; the chosen pill is `selected`.
  final LedgerStyle? style;

  /// The words of [option].
  String wordsOf(T option) => labelOf?.call(option) ?? '$option';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Object?>.has('labelOf', labelOf));
    properties
      ..add(IterableProperty<T>('options', options))
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(ObjectFlagProperty<ValueChanged<T?>>.has('onChanged', onChanged))
      ..add(
        DiagnosticsProperty<Map<T, Key>>(
          'optionKeys',
          optionKeys,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(11).line(16).tracked(.02);
    return Semantics(
      container: true,
      label: semanticLabel,
      // The faces stand the gap apart, their targets reaching into the room
      // between (ui_core's RawChipGroup): in a Wrap each target's slack stood
      // between too.
      child: RawChipGroup(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (final o in options)
            // Each filter laid out at the tap floor round its 32 face.
            TapTargetPadding(
              key: optionKeys?[o],
              child: LedgerPressable(
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(o == value ? null : o),
                semanticLabel: wordsOf(o),
                selected: o == value,
                radius: t.controlRadius,
                child: Builder(
                  builder: (context) {
                    final so = LedgerStyleOf(
                      [style, t.components.toggleGroup],
                      {
                        ...LedgerPressStates.of(context),
                        if (o == value) WidgetState.selected,
                        if (onChanged == null) WidgetState.disabled,
                      },
                    );
                    return LedgerFace(
                      style: so.dress(
                        LedgerFaceStyle(
                          ink: o == value ? t.surface : t.textSecondary,
                          ground: BoxDecoration(
                            color: o == value ? t.textPrimary : t.surface,
                            borderRadius: BorderRadius.circular(
                              t.controlRadius,
                            ),
                            border: Border.all(
                              color: o == value ? t.textPrimary : t.border,
                            ),
                          ),
                        ),
                      ),
                      builder: (context, s, _) => Container(
                        // 32 at the standard density, 4 off a step.
                        height: t.density.height(_height),
                        padding:
                            so.padding(Directionality.of(context)) ??
                            const EdgeInsets.symmetric(horizontal: _pad),
                        decoration: s.ground,
                        // Its own width under a loose one: a Container's alignment
                        // would stretch it.
                        child: Center(
                          widthFactor: 1,
                          child: ledgerCapCenter(
                            words,
                            Text(
                              wordsOf(o),
                              softWrap: false,
                              style: so.words(words, s.ink),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // `.filter`: 32 tall, 0 13, 500 11/30; `.filters` 6 apart. Its words on a
  // line of their own inside the ring (RawCapCenter sets their capitals
  // on its middle), so the ring stays out of their box.
  static const double _height = 32;
  static const double _pad = 12;
  static const double _gap = 6;
}

/// The switch: 44 by 26, its knob of the light paper on the
/// darker paper, at the end on the ink when on; a null [onChanged] dims it
/// to .45. It lays out at the tap floor round its face. Says its [semanticLabel] and whether it
/// is on.
///
/// ```dart
/// LedgerSwitch(value: true, semanticLabel: 'Bills', onChanged: (on) {})
/// ```
class LedgerSwitch extends StatelessWidget {
  /// A switch at [value], flipped by [onChanged].
  const LedgerSwitch({
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
    super.key,
  }) : _drawn = false;

  /// The switch drawn in a row that is the one control (a toggle row): no
  /// target or focus of its own.
  const LedgerSwitch._drawn({required this.value, this.semanticLabel})
    : onChanged = null,
      focusNode = null,
      autofocus = false,
      style = null,
      _drawn = true;

  final bool _drawn;

  /// On or off.
  final bool value;

  /// Called with the flipped value; null disables it.
  final ValueChanged<bool>? onChanged;

  /// The spoken name: the switch draws no words of its own.
  final String? semanticLabel;

  /// The switch's focus; the switch makes its own when none is given, and never
  /// disposes one it was given.
  final FocusNode? focusNode;

  /// Whether the switch takes the focus when it first stands.
  final bool autofocus;

  /// This switch's look, over `components.switchTheme`. It reads `fill`
  /// (the track), `foreground` (the knob) and `edge` (the track's ring),
  /// each for its off and its `selected` (on) states.
  final LedgerStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('value', value: value, ifTrue: 'value'))
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<LedgerStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final layers = [style, t.components.switchTheme];
    final base = {if (onChanged == null && !_drawn) WidgetState.disabled};
    final off = LedgerStyleOf(layers, base);
    final on = LedgerStyleOf(layers, {...base, WidgetState.selected});
    final inks = _SwitchInks(
      offTrack: off.fill ?? t.surfaceAlt,
      onTrack: on.fill ?? t.textPrimary,
      offRing: off.edge ?? t.textTertiary,
      onRing: on.edge ?? t.textPrimary,
      offKnob: off.foreground ?? t.textTertiary,
      onKnob: on.foreground ?? t.surface,
    );
    // The knob slides and the inks cross over the base 200 (DERIVED: the
    // source's toggle jumps).
    final face = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value ? 1 : 0),
      duration: LedgerMotion.of(context, LedgerMotion.base),
      curve: LedgerMotion.out,
      builder: (context, at, _) => SizedBox(
        width: _width,
        height: _height,
        // On is the reading end: mirrored in a right-to-left page.
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: CustomPaint(painter: _SwitchPainter(at, inks)),
        ),
      ),
    );
    final change = onChanged;
    if (_drawn) return face;
    return TapTargetPadding(
      child: LedgerPressable(
        onTap: change == null ? null : () => change(!value),
        semanticLabel: semanticLabel,
        toggled: value,
        radius: _height / 2,
        focusNode: focusNode,
        autofocus: autofocus,
        child: change == null ? Opacity(opacity: _off, child: face) : face,
      ),
    );
  }

  static const double _width = 44;
  static const double _height = 26;
  static const double _off = .45;
}

/// A switch's inks, off and on: its track, its ring and its knob.
@immutable
class _SwitchInks {
  const _SwitchInks({
    required this.offTrack,
    required this.onTrack,
    required this.offRing,
    required this.onRing,
    required this.offKnob,
    required this.onKnob,
  });

  final Color offTrack, onTrack, offRing, onRing, offKnob, onKnob;

  @override
  bool operator ==(Object other) =>
      other is _SwitchInks &&
      other.offTrack == offTrack &&
      other.onTrack == onTrack &&
      other.offRing == offRing &&
      other.onRing == onRing &&
      other.offKnob == offKnob &&
      other.onKnob == onKnob;

  @override
  int get hashCode =>
      Object.hash(offTrack, onTrack, offRing, onRing, offKnob, onKnob);
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter(this.at, this.t);

  /// 0 off, 1 on, between on the way.
  final double at;
  final _SwitchInks t;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    // Off, Ledger rings the darker paper in the rule (the ink at .14,
    // about 1.3:1 on the paper) and sets a paper knob on it: a switch read
    // as nothing there. Here its ring and a smaller knob are in the third
    // ink (over 4.5:1), so an off switch is seen as one (WCAG 1.4.11).
    canvas
      ..drawRRect(box, Paint()..color = Color.lerp(t.offTrack, t.onTrack, at)!)
      // A 1 px ring whose outer edge is the box's: a hairline (a stroke of
      // no width) is one device pixel half a pixel in, so at 2x and 3x an
      // off switch drew a device pixel smaller than an on one beside it.
      ..drawRRect(
        box.deflate(.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Color.lerp(t.offRing, t.onRing, at)!,
      );
    // The knob: radial-gradient(circle at 12px 12px, #F9F6F0 8.5px, 0 at
    // 9.2px), placed from inside the 1 px ring (30px when on); off, 6 of
    // the third ink.
    final c = Offset(13 + 18 * at, 13);
    final knob = Color.lerp(t.offKnob, t.onKnob, at)!;
    final r = 6 + 2.5 * at;
    final edge = r + .7;
    canvas.drawCircle(
      c,
      edge,
      Paint()
        ..shader = RadialGradient(
          colors: [knob, knob, knob.withValues(alpha: 0)],
          stops: [0, r / edge, 1],
        ).createShader(Rect.fromCircle(center: c, radius: edge)),
    );
  }

  @override
  bool shouldRepaint(_SwitchPainter old) => old.at != at || old.t != t;
}

/// A switch's row: its glyph, its [title] and [subtitle],
/// the [LedgerSwitch] at the end; the whole row flips it. A null
/// [onChanged] dims it (the third ink). Says its title and whether it is on.
///
/// ```dart
/// LedgerToggleRow(icon: LucideIcons.receipt, title: 'Bills', subtitle: 'A reminder before each bill is due', value: true, onChanged: (on) {})
/// ```
class LedgerToggleRow extends StatelessWidget {
  /// A row that flips [value] with [onChanged].
  const LedgerToggleRow({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.semanticLabel,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The setting's name.
  final String title;

  /// On or off.
  final bool value;

  /// A line under the title that says what the setting does.
  final String? subtitle;

  /// The row's glyph.
  final IconData? icon;

  /// The switch's spoken name when the label repeats on the page.
  final String? semanticLabel;

  /// Called with the flipped value; null disables the row.
  final ValueChanged<bool>? onChanged;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(FlagProperty('value', value: value, ifTrue: 'value'))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<bool>>.has('onChanged', onChanged))
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
    final off = onChanged == null;
    final ink = off ? t.textTertiary : t.textPrimary;
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: off ? null : () => onChanged!(!value),
      semanticLabel: semanticLabel ?? title,
      toggled: value,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s14),
        child: Row(
          spacing: LedgerSpacing.s14,
          children: [
            if (icon case final g?) LedgerGlyph(g),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The title stands inline in `.row-main`, on the line of
                  // the body's 15/1.45, its own 20 centred in it.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: (_titleLine - _ownLine) / 2,
                    ),
                    child: Text(title, style: t.rowTitle.colored(ink)),
                  ),
                  if (subtitle case final words?) ...[
                    const SizedBox(height: LedgerSpacing.s4),
                    Text(words, style: t.bodySmall),
                  ],
                ],
              ),
            ),
            // The row is the one target and focus stop; its switch is
            // drawn, not a second control.
            ExcludeFocus(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: off ? LedgerSwitch._off : 1,
                    child: LedgerSwitch._drawn(
                      value: value,
                      semanticLabel: semanticLabel ?? title,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // `.row-main` takes the body's line (15/1.45), 21.75 in the
  // browser; held at a whole 21 here, so a row is 28 + 21 + 3 + 18 (70, 71
  // with its rule) and every row and rule under it stays on a whole pixel
  // (at 21.75 each row's rule straddled two device rows and blurred), and
  // its words 42 tall centre the 40 glyph and the 26 switch on whole pixels
  // (22 would set both on a half).
  static const double _titleLine = 21;

  // `.title`: 500 15/20; the line's extra stands as padding, the title
  // centred (one font, one size).
  static const double _ownLine = 20;
}

/// A setting's row: its glyph, its [title] on the dot leader
/// (6 clear, 8 at the least) to its [value], its [subtitle] under it, a
/// faint chevron at the end. With [onTap] it opens its setting. With none
/// it opens nothing and stands in the full ink, read as its words rather
/// than as a control. [enabled] false holds it in the third ink, a control
/// that cannot be used now (a frozen card's limit). Says its title and
/// value.
///
/// ```dart
/// LedgerSettingRow(icon: LucideIcons.gauge, title: 'Monthly limit', value: '\$2,000', onTap: () {})
/// ```
///
/// ```dart
/// LedgerSettingRow(icon: LucideIcons.circleDollarSign, title: 'Currency', value: 'USD', subtitle: 'US dollar')
/// ```
class LedgerSettingRow extends StatelessWidget {
  /// A setting named [title] showing its [value].
  const LedgerSettingRow({
    required this.title,
    this.value,
    this.subtitle,
    this.icon,
    this.semanticLabel,
    this.onTap,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The setting's name.
  final String title;

  /// What the setting is set to, at the leader's end.
  final String? value;

  /// A line under the title.
  final String? subtitle;

  /// The row's glyph.
  final IconData? icon;

  /// What a screen reader says; null says the title and value.
  final String? semanticLabel;

  /// Opens the setting; null makes the row words, not a control.
  final VoidCallback? onTap;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// Whether it can be used now; false holds it in the third ink, a button
  /// that says it is not enabled.
  final bool enabled;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('value', value, defaultValue: null))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(DiagnosticsProperty<IconData>('icon', icon, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('enabled', value: enabled, ifTrue: 'enabled'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final off = !enabled;
    final ink = off ? t.textTertiary : t.textPrimary;
    // A name longer than its room wraps (at a large text size, it turns
    // over its leader first), never cut.
    final name = Text(title, style: t.rowTitle.colored(ink));
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final Widget? shown = switch (value) {
      null => null,
      // At a large text size a value wider than the whole line (an email)
      // is set smaller on its line rather than cut.
      final v when larger => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerEnd,
        child: Text(
          v,
          maxLines: 1,
          softWrap: false,
          style: t.rowTitle.colored(ink),
        ),
      ),
      final v => Text(
        v,
        maxLines: 1,
        softWrap: false,
        style: t.rowTitle.colored(ink),
      ),
    };
    final line = Padding(
      padding: const EdgeInsets.symmetric(vertical: LedgerSpacing.s14),
      child: Row(
        spacing: LedgerSpacing.s14,
        children: [
          if (icon case final g?) LedgerGlyph(g),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (shown != null)
                  LedgerLeaderLine(
                    start: name,
                    end: shown,
                    inset: _leaderInset,
                    minLength: _leaderMin,
                  )
                else
                  name,
                if (subtitle case final words?) ...[
                  const SizedBox(height: LedgerSpacing.s4),
                  Text(words, style: t.bodySmall),
                ],
              ],
            ),
          ),
          if (onTap != null)
            LedgerEndGlyph(
              LucideIcons.chevronRight,
              size: _chevron,
              color: t.textFaint,
            ),
        ],
      ),
    );
    if (onTap == null && enabled) {
      // Opens nothing: its words, not a control.
      return Semantics(
        container: true,
        label: semanticLabel ?? title,
        value: value,
        excludeSemantics: true,
        child: line,
      );
    }
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: enabled ? onTap : null,
      semanticLabel: semanticLabel ?? title,
      value: value,
      child: line,
    );
  }

  static const double _leaderInset = 6;
  static const double _leaderMin = 8;
  static const double _chevron = 16;
}

/// The search field, a round field of the light paper 46
/// tall: as a link ([onTap]: Activity's, leading to the search) its glyph
/// and [hintText]; live (no onTap) ringed in the ink, the words typed
/// in the medium, a round clear at its end when [onCleared] is set and it
/// holds words ([clearKey] keys it). Says its [semanticLabel].
///
/// ```dart
/// LedgerSearchField(hintText: 'Search merchants and categories', onTap: () => open('/activity/search'))
/// ```
class LedgerSearchField extends StatelessWidget {
  /// A link to the search with [onTap], else a live field.
  const LedgerSearchField({
    this.hintText,
    this.semanticLabel,
    this.onTap,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onCleared,
    this.clearLabel,
    this.focusNode,
    this.autofocus = false,
    this.clearKey,
    super.key,
  });

  /// The words shown while it is empty; null is the shared words' Search
  /// ([RawWidgetsLocalizations.searchFieldLabel]).
  final String? hintText;

  /// What a screen reader says; null says the [hintText].
  final String? semanticLabel;

  /// Makes the field a link to the search.
  final VoidCallback? onTap;

  /// The words typed; the field makes its own when none is given, and never
  /// disposes one it was given.
  final TextEditingController? controller;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// Called with the words when the keyboard submits them.
  final ValueChanged<String>? onSubmitted;

  /// Called when the round clear empties it.
  final VoidCallback? onCleared;

  /// What a screen reader says the round clear is; null is the shared
  /// words' Clear ([RawWidgetsLocalizations.clearButtonTooltip]).
  final String? clearLabel;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// A key for the round clear (a test's or a walk's target).
  final Key? clearKey;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(ObjectFlagProperty<VoidCallback>.has('onCleared', onCleared))
      ..add(StringProperty('clearLabel', clearLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(DiagnosticsProperty<Key>('clearKey', clearKey, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = RawWidgetsLocalizations.of(context);
    final hint = hintText ?? words.searchFieldLabel;
    final live = onTap == null;
    final glyph = Icon(
      LucideIcons.search,
      size: LedgerChromeMetrics.searchGlyph,
      color: t.textSecondary,
    );
    Widget box(Widget child) => Container(
      height: LedgerChromeMetrics.searchHeight,
      padding: EdgeInsetsDirectional.only(
        start: LedgerChromeMetrics.searchPad,
        end: live && controller != null && onCleared != null
            ? (LedgerChromeMetrics.searchHeight - _clear) / 2 - 1
            : LedgerChromeMetrics.searchPad,
      ),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.controlRadius),
        border: Border.all(color: live ? t.textPrimary : t.border),
      ),
      child: Row(
        spacing: LedgerChromeMetrics.searchGap,
        children: [
          glyph,
          Expanded(child: child),
        ],
      ),
    );
    if (!live) {
      return LedgerPressable(
        onTap: onTap,
        role: LedgerPressRole.link,
        semanticLabel: semanticLabel ?? hint,
        radius: t.controlRadius,
        child: box(
          ledgerCapCenter(
            t.search,
            Text(
              hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.search,
            ),
          ),
        ),
      );
    }
    final field = Material(
      type: MaterialType.transparency,
      child: MergeSemantics(
        child: Semantics(
          label: semanticLabel ?? hint,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            style: t.search.medium.colored(t.textPrimary),
            cursorColor: t.textPrimary,
            decoration: InputDecoration(
              isCollapsed: true,
              maintainHintSize: false,
              hintFadeDuration: Duration.zero,
              border: InputBorder.none,
              hint: ExcludeSemantics(
                child: Text(
                  hint,
                  style: t.search,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
          ),
        ),
      ),
    );
    return box(
      Row(
        spacing: LedgerChromeMetrics.searchGap,
        children: [
          Expanded(
            child: TapTargetPadding(
              minSize: const Size(0, LedgerChromeMetrics.searchHeight - 2),
              child: Center(child: field),
            ),
          ),
          if (onCleared != null && controller != null)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller!,
              builder: (context, v, _) => v.text.isEmpty
                  ? const SizedBox.shrink()
                  // The 24 disc laid out at the tap floor round it, on
                  // the field's end.
                  : TapTargetPadding(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LedgerPressable(
                        key: clearKey,
                        onTap: onCleared,
                        semanticLabel: clearLabel ?? words.clearButtonTooltip,
                        radius: _clear / 2,
                        child: Container(
                          width: _clear,
                          height: _clear,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: t.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.x,
                            size: _clearGlyph,
                            color: t.textSecondary,
                          ),
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  static const double _clear = 24;
  static const double _clearGlyph = 14;
}

/// A form's field: its [labelText] in the small capitals, then on
/// the ink rule the words typed (the medium at 16; the [hintText] in
/// the third ink) after an optional serif [prefix] ($), its [note] under
/// it. 16 above it. Says its label. A [child] stands in the typed line's
/// place, a control rather than words (a cheque's When and its chips: 4
/// above it, 6 under it, at its start, no rule). A [value] stands there
/// read only: the words as typed, which no one here types (a transfer's
/// note shown on its cheque). On a cheque the rule is the faint ink
///, the ink off one.
///
/// ```dart
/// LedgerField(labelText: 'Note', controller: note, hintText: 'What it is for')
/// ```
///
/// ```dart
/// LedgerField(labelText: 'When', child: LedgerSegmentedControl(options: const ['Today', 'Later'], value: when, onChanged: pick))
/// ```
///
/// ```dart
/// LedgerField(labelText: 'Note', value: 'November top-up')
/// ```
class LedgerField extends StatelessWidget {
  /// A field named [labelText]: typed with a [controller], a [child] control, or a
  /// read-only [value].
  const LedgerField({
    required this.labelText,
    this.controller,
    this.hintText,
    this.prefix,
    this.note,
    this.onChanged,
    this.keyboardType,
    this.focusNode,
    this.child,
    this.value,
    this.autofocus = false,
    super.key,
  }) : assert(
         value == null || (controller == null && child == null),
         'a value is shown read only, with no controller or child',
       );

  /// The field's name, in the small capitals over it.
  final String labelText;

  /// The words typed; the field makes its own when none is given, and never
  /// disposes one it was given.
  final TextEditingController? controller;

  /// The words shown while it is empty.
  final String? hintText;

  /// Words in the serif before the typed ones (`$`).
  final String? prefix;

  /// A line under the field.
  final String? note;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// The keyboard the field asks for.
  final TextInputType? keyboardType;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// A control in the typed line's place; it speaks for itself.
  final Widget? child;

  /// Words shown read only on the typed line, read as the field's value.
  final String? value;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(StringProperty('prefix', prefix, defaultValue: null))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<TextInputType>(
          'keyboardType',
          keyboardType,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('value', value, defaultValue: null));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.rowTitle.sized(16).line(24);
    final control = child;
    final shown = value;
    return Semantics(
      textField: control == null,
      readOnly: shown != null,
      value: shown,
      container: control != null,
      label: labelText,
      child: Padding(
        padding: const EdgeInsets.only(top: LedgerSpacing.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: LedgerSpacing.s4,
          children: [
            ExcludeSemantics(
              child: Text(
                labelText.toUpperCase(),
                style: t.label.colored(t.textSecondary),
              ),
            ),
            if (control != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: LedgerSpacing.s4,
                  bottom: LedgerSpacing.s6,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: control,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.only(
                  top: LedgerSpacing.s4,
                  bottom: LedgerSpacing.s8,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: LedgerOnCheque.of(context)
                          ? t.textFaint
                          : t.headRule,
                    ),
                  ),
                ),
                // A sum reads left to right in either direction, its sign
                // before the figures.
                child: Directionality(
                  textDirection: prefix == null
                      ? Directionality.of(context)
                      : TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: LedgerSpacing.s6,
                    children: [
                      if (prefix case final p?)
                        Text(
                          p,
                          style: t.figureSmall
                              .sized(22)
                              .line(22)
                              .tracked(0)
                              .colored(t.textSecondary),
                        ),
                      Expanded(
                        child: shown != null
                            ? ExcludeSemantics(
                                child: Text(
                                  shown,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                  style: words.colored(t.textPrimary),
                                ),
                              )
                            : LedgerTextInput(
                                autofocus: autofocus,
                                controller: controller,
                                hintText: hintText,
                                style: words.colored(t.textPrimary),
                                hintStyle: words
                                    .copyWith(fontWeight: FontWeight.w400)
                                    .colored(t.textTertiary),
                                onChanged: onChanged,
                                keyboardType: keyboardType,
                                focusNode: focusNode,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            if (note case final n?)
              Text(n, style: t.bodySmall.sized(12).line(16)),
          ],
        ),
      ),
    );
  }
}

/// A cheque's line: its [label] in the small capitals, then
/// the account's glyph, its [name] over its [mask] in the mono, its
/// [balance] with its [note] (Available) at the end and, live ([onTap]),
/// a chevron to choose another; read back (no onTap) it is no control. A
/// choice shown that opens nothing keeps the chevron with [showChevron] (the
/// form's From and To), still no control.
///
/// ```dart
/// LedgerPickLine(label: 'From', icon: LucideIcons.wallet, name: 'Everyday', mask: '··4821', balance: 6248.30, note: 'Available', onTap: () {})
/// ```
///
/// ```dart
/// LedgerPickLine(label: 'From', icon: LucideIcons.wallet, name: 'Everyday', mask: '··4821', balance: 6248.30, note: 'Available', showChevron: true)
/// ```
class LedgerPickLine extends StatelessWidget {
  /// A cheque's line choosing an account: [label], its [icon], [name] and
  /// [mask].
  const LedgerPickLine({
    required this.label,
    required this.icon,
    required this.name,
    required this.mask,
    this.balance,
    this.note,
    this.onTap,
    this.ruled = true,
    this.showChevron,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The line's name (From, To), in the small capitals.
  final String label;

  /// The account's glyph.
  final IconData icon;

  /// The account's name.
  final String name;

  /// The account's masked number, in the mono.
  final String mask;

  /// The account's balance, at the line's end.
  final num? balance;

  /// Words with the balance (Available).
  final String? note;

  /// Opens the choice of another account; null reads the line back.
  final VoidCallback? onTap;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// Ruled under it (none in a sheet).
  final bool ruled;

  /// Whether the chevron ends the line; null draws it only live.
  final bool? showChevron;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(DiagnosticsProperty<IconData>('icon', icon))
      ..add(StringProperty('name', name))
      ..add(StringProperty('mask', mask))
      ..add(DiagnosticsProperty<num>('balance', balance, defaultValue: null))
      ..add(StringProperty('note', note, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onTap', onTap))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('ruled', value: ruled, ifTrue: 'ruled'))
      ..add(
        DiagnosticsProperty<bool>(
          'showChevron',
          showChevron,
          defaultValue: null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    // At a large text size the name wraps whole, the mask stands whole on
    // its line (set smaller rather than broken), and the balance turns under
    // them rather than squeeze them.
    final larger = MediaQuery.textScalerOf(context).scale(1) > 1;
    final held = balance == null
        ? null
        : Column(
            crossAxisAlignment: larger
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              LedgerAmount(balance!),
              if (note case final n?)
                Text(n.toUpperCase(), style: t.meta.sized(11).line(14)),
            ],
          );
    final line = Row(
      spacing: LedgerSpacing.s12,
      children: [
        LedgerGlyph(icon, size: LedgerGlyphSize.pick),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: larger
                ? [
                    Text(name, style: t.rowTitle.sized(16).line(20)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        mask,
                        maxLines: 1,
                        softWrap: false,
                        textDirection: TextDirection.ltr,
                        style: t.meta.tracked(0),
                      ),
                    ),
                    if (held != null)
                      Padding(
                        padding: const EdgeInsets.only(top: LedgerSpacing.s4),
                        child: held,
                      ),
                  ]
                : [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.rowTitle.sized(16).line(20),
                    ),
                    // A masked number reads left to right, its dots before
                    // the figures, in either direction.
                    Text(
                      mask,
                      textDirection: TextDirection.ltr,
                      style: t.meta.tracked(0),
                    ),
                  ],
          ),
        ),
        if (!larger) ?held,
        // `.pick > .i`: 16, the third ink.
        if (showChevron ?? onTap != null)
          LedgerEndGlyph(
            LucideIcons.chevronDown,
            size: 16,
            color: t.textTertiary,
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.only(
        top: LedgerSpacing.s12,
        bottom: LedgerSpacing.s14,
      ),
      decoration: ruled
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: LedgerSpacing.s8,
        children: [
          ExcludeSemantics(
            child: Text(
              label.toUpperCase(),
              style: t.label.colored(t.textSecondary),
            ),
          ),
          if (onTap != null)
            // The 36 line laid out at the tap floor, 4 of room above and
            // below it.
            TapTargetPadding(
              child: LedgerPressable(
                focusNode: focusNode,
                autofocus: autofocus,
                onTap: onTap,
                semanticLabel: '$label: $name',
                value: balance == null ? null : LedgerFormat.money(balance!),
                child: line,
              ),
            )
          else
            MergeSemantics(
              child: Semantics(label: '$label:', child: line),
            ),
        ],
      ),
    );
  }
}

/// A cheque's amount: its [labelText], then in a box ruled in the
/// ink the sum in the serif after its `$` (typed live with a [controller], else
/// read back as the engraved [amount]), and under it the sum in [words] on the
/// cheque's line with its [unit] (DOLLARS). The typed line stands as Chrome
/// holds an input's, at least its font's normal line: 1.3 of the serif's size
/// to the pixel (the transfer's box 95 tall at 56, 116 at 72), its label on the
/// body's line (21.75). [typed] reads the [amount] back as the input holds it
/// ("500.00" after its `$`), a sum shown that no one types here (the form's).
///
/// ```dart
/// LedgerChequeAmount(labelText: 'Amount', words: 'Five hundred and 00/100', unit: 'dollars', amount: 500)
/// ```
///
/// ```dart
/// LedgerChequeAmount(labelText: 'Amount', words: 'Five hundred and 00/100', unit: 'dollars', amount: 500, typed: true)
/// ```
class LedgerChequeAmount extends StatelessWidget {
  /// A cheque's sum: typed with a [controller], else read back as [amount].
  const LedgerChequeAmount({
    required this.labelText,
    required this.words,
    required this.unit,
    this.amount,
    this.controller,
    this.onChanged,
    this.typed = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : assert(
         amount != null || controller != null,
         'an amount or a controller',
       ),
       assert(!typed || amount != null, 'a typed sum shows its amount');

  /// The sum's name (Amount).
  final String labelText;

  /// The sum in words, on the cheque's line.
  final String words;

  /// The unit after the words (dollars).
  final String unit;

  /// The sum read back.
  final num? amount;

  /// The sum typed; never disposed.
  final TextEditingController? controller;

  /// Called with the sum as it is typed.
  final ValueChanged<String>? onChanged;

  /// {@macro ledger.focusNode}
  final FocusNode? focusNode;

  /// {@macro ledger.autofocus}
  final bool autofocus;

  /// Whether the [amount] reads back in the input's typed look rather
  /// than engraved; read only.
  final bool typed;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('labelText', labelText))
      ..add(StringProperty('words', words))
      ..add(StringProperty('unit', unit))
      ..add(DiagnosticsProperty<num>('amount', amount, defaultValue: null))
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('typed', value: typed, ifTrue: 'typed'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final figure = wide
        ? LedgerChromeMetrics.entryFigureWide
        : LedgerChromeMetrics.entryFigure;
    final typedStyle = t.figure
        .sized(figure)
        .line((figure * _normalLine).roundToDouble())
        .tracked(-.01)
        .colored(t.textPrimary);
    // `.amount-cur`: 400 24/1 serif, the second ink, 6 down.
    final cur = Padding(
      padding: const EdgeInsets.only(top: LedgerSpacing.s6),
      child: Text(
        '\$',
        style: t.figureSmall
            .sized(24)
            .line(24)
            .tracked(0)
            .colored(t.textSecondary),
      ),
    );
    // The input's value, `{amount:,.2f}`: "1,326.44".
    final typedWords = amount == null
        ? ''
        : LedgerFormat.money(amount!.abs()).replaceFirst('\$', '');
    final Widget sum = typed
        // Shown as typed, read as the sum: "Amount, $500.00".
        ? Semantics(
            container: true,
            label: labelText,
            value: LedgerFormat.money(amount!),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: LedgerSpacing.s4,
              children: [
                cur,
                Expanded(
                  // At a large text size a sum wider than its box is set
                  // smaller rather than cut.
                  child: MediaQuery.textScalerOf(context).scale(1) > 1
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            typedWords,
                            maxLines: 1,
                            softWrap: false,
                            style: typedStyle,
                          ),
                        )
                      : Text(
                          typedWords,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: typedStyle,
                        ),
                ),
              ],
            ),
          )
        : controller == null
        // Read back, the sum says what it is: "Amount, $500.00".
        ? MergeSemantics(
            child: Semantics(
              label: labelText,
              child: LedgerFigure(amount!, size: LedgerFigureSize.entry),
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: LedgerSpacing.s4,
            children: [
              cur,
              Expanded(
                child: Semantics(
                  textField: true,
                  label: labelText,
                  // An engraved figure, already large: it keeps its size at
                  // any text size, as the read-back figure does, rather
                  // than run past its box.
                  child: MediaQuery.withNoTextScaling(
                    child: LedgerTextInput(
                      focusNode: focusNode,
                      autofocus: autofocus,
                      controller: controller,
                      style: typedStyle,
                      hintStyle: t.figure
                          .sized(figure)
                          .line((figure * _normalLine).roundToDouble())
                          .colored(t.textTertiary),
                      onChanged: onChanged,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
    return Container(
      padding: const EdgeInsets.only(
        top: LedgerSpacing.s14,
        bottom: LedgerSpacing.s16,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            // `.amount-row .label` is inline in its block: its line is the
            // body's strut (15/1.45), the label on its baseline (the
            // capture's box 43.8 under the row's top). The strut stands as
            // padding round the 16, the whole 22 a Text of the body takes.
            child: Padding(
              padding: const EdgeInsets.only(
                top: _labelDrop,
                bottom: _bodyLine - _labelLine - _labelDrop,
              ),
              child: Text(
                labelText.toUpperCase(),
                style: t.label.colored(t.textSecondary),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: LedgerSpacing.s8),
            padding: const EdgeInsets.fromLTRB(
              LedgerSpacing.s14,
              LedgerSpacing.s12,
              LedgerSpacing.s14,
              LedgerSpacing.s8,
            ),
            decoration: BoxDecoration(
              color: t.background,
              borderRadius: BorderRadius.circular(t.smallRadius),
              border: Border.all(color: t.textPrimary),
            ),
            // The box holds a sum, left to right in either direction: its
            // `$` before the figures, typed or read back.
            child: Directionality(textDirection: TextDirection.ltr, child: sum),
          ),
          Container(
            margin: const EdgeInsets.only(top: LedgerSpacing.s14),
            padding: const EdgeInsets.only(bottom: LedgerSpacing.s4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.textFaint)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: LedgerSpacing.s10,
              children: [
                Expanded(
                  child: Text(
                    words,
                    style: t.figureSmall
                        .sized(21)
                        .line(24)
                        .tracked(0)
                        .italic
                        .colored(t.textPrimary),
                  ),
                ),
                Text(
                  unit.toUpperCase(),
                  style: t.label.sized(11).line(10).colored(t.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chrome holds an input's line at least its font's normal one: Instrument
  // Serif's ascent .99 and descent .31 of its em (hhea, no line gap), to the
  // pixel: 73 at 56, 94 at 72 (the transfer's boxes, 95 and 116 tall).
  static const double _normalLine = 1.3;

  // The body's line, 15/1.45 (21.75 in the browser, held at
  // the whole 22 so the row and its rule stay on whole pixels), and
  // `.label`'s, 11/16.
  static const double _bodyLine = 22;
  static const double _labelLine = 16;

  // Inter Tight's ascent 1984 and descent 494 of its 2048 em (hhea): on one
  // baseline, the 11/16 label's top stands this far under the 15/22
  // strut's, 4.46.
  static const double _ascent = 1984 / 2048;
  static const double _descent = 494 / 2048;
  static const double _labelDrop =
      (15 - 11) / 2 * (_ascent - _descent) + (_bodyLine - _labelLine) / 2;
}

/// How large a [LedgerStepper] stands.
enum LedgerStepperSize {
  /// The budget's sum: the figure in the serif, 72 (88 on the
  /// desktop), between two 48 rings. A display figure, stepped but not
  /// typed: a budget, a balance to set.
  figure,

  /// A form's number: written on a field's rule at the text field's
  /// height, its label in the small capitals over it, its help or error
  /// under it, the − and + rings at the line's end. The number takes
  /// typing.
  field,
}

/// A number stepped down and up by [step] between [min] and [max]; its
/// ring at a bound is off, and [onChanged] null holds it.
///
/// [size] [LedgerStepperSize.field] is a form's number (an estimate in
/// minutes, a count of copies): written on the text field's rule, at its
/// height, so it stands level with a field beside it; [labelText] in the small
/// capitals over the line, [helperText] or [errorText] under it. The number takes
/// typing in the reader's digits, read as Enter is pressed or the focus
/// leaves and kept within [min] and [max]; while a typed number is outside
/// them the field says so in its error ('From 5 to 480'; in another language
/// the range in its digits, '٥–٤٨٠'; [errorText] given says that instead).
/// Up and Down step it, Page Up and Page Down by ten steps; the rings step
/// once on a press and repeat while held. A screen reader hears one
/// adjustable number named [labelText]. [format] says the number to a screen
/// reader ('45 minutes'); the line shows the plain number.
///
/// [LedgerStepperSize.figure], the default, is the budget's stepper
///: the sum in the serif, 72 (88 on the desktop), between two
/// 48 rings that lower and raise it by [step], read as an adjustable value:
/// the plain number unless [format] says otherwise (a budget passes whole
/// dollars, `format: (v) => LedgerFormat.money(v, showCents: false)`); each ring says
/// its [lowerLabel] or [raiseLabel] whole ('Lower the budget'), or, left
/// unset, Lower or Raise and the [labelText]. The sum stands on its input's
/// own line, 1.05 of its size (75.6 at 72, 92.4 at 88, as the budget and
/// add money sheets measure). [showRings]
/// false shows the sum alone, chosen from elsewhere (the add sheet's
/// amount under its chips: 4 above, 8 under),
/// still an adjustable value with [onChanged]; centred on a phone, at its
/// slot's start from 600, as the rings are.
///
/// ```dart
/// LedgerStepper(value: 250, labelText: 'Monthly budget', format: (v) => LedgerFormat.money(v, showCents: false), onChanged: (v) {})
/// ```
///
/// ```dart
/// LedgerStepper(value: 250, labelText: 'Monthly budget', format: (v) => LedgerFormat.money(v, showCents: false), lowerLabel: 'Lower the budget', raiseLabel: 'Raise the budget', onChanged: (v) {})
/// ```
///
/// ```dart
/// LedgerStepper(value: 110, labelText: 'Amount to add', step: 1, showRings: false, format: (v) => LedgerFormat.money(v, showCents: false))
/// ```
///
/// ```dart
/// LedgerStepper(size: LedgerStepperSize.field, labelText: 'Estimate (minutes)', value: 45, min: 5, max: 480, step: 5, format: (minutes) => '$minutes minutes', onChanged: (v) {})
/// ```
class LedgerStepper extends StatelessWidget {
  /// A [value] named [labelText], lowered and raised by [step].
  const LedgerStepper({
    required this.value,
    required this.labelText,
    this.step = 5,
    this.min = 0,
    this.max,
    this.size = LedgerStepperSize.figure,
    this.format,
    this.lowerLabel,
    this.raiseLabel,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.showRings = true,
    super.key,
  }) : assert(step > 0),
       assert(max == null || max >= min);

  /// The sum.
  final num value;

  /// What the sum is, for a screen reader.
  final String labelText;

  /// How much a ring lowers or raises the sum.
  final num step;

  /// The lowest the sum goes.
  final num min;

  /// The highest the sum goes; null sets no bound.
  final num? max;

  /// How large it stands: the budget's [LedgerStepperSize.figure], or a
  /// form's [LedgerStepperSize.field].
  final LedgerStepperSize size;

  /// Formats the value a screen reader hears, and the figure's words. Null
  /// is the plain number in the reader's digits, on both sizes; money is
  /// the caller's (`(value) => LedgerFormat.money(value, showCents: false)`
  /// for a budget's whole dollars). A field shows the plain number either
  /// way.
  final String Function(num value)? format;

  /// The lower ring's words; null reads 'Lower' and the [labelText].
  final String? lowerLabel;

  /// The raise ring's words; null reads 'Raise' and the [labelText].
  final String? raiseLabel;

  /// Called with the new sum; null holds it.
  final ValueChanged<num>? onChanged;

  /// A field's help under its rule.
  final String? helperText;

  /// What is wrong with a field's number, under its rule in the danger
  /// red; null while it is fine (a typed number outside [min] and [max]
  /// says so itself).
  final String? errorText;

  /// Whether a figure's lower and raise rings stand at its ends.
  final bool showRings;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<num>('value', value))
      ..add(StringProperty('labelText', labelText))
      ..add(DiagnosticsProperty<num>('step', step))
      ..add(DiagnosticsProperty<num>('min', min))
      ..add(DiagnosticsProperty<num>('max', max, defaultValue: null))
      ..add(EnumProperty<LedgerStepperSize>('size', size))
      ..add(ObjectFlagProperty<Object?>.has('format', format))
      ..add(StringProperty('lowerLabel', lowerLabel, defaultValue: null))
      ..add(StringProperty('raiseLabel', raiseLabel, defaultValue: null))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<num>>.has('onChanged', onChanged))
      ..add(FlagProperty('showRings', value: showRings, ifTrue: 'showRings'));
  }

  @override
  Widget build(BuildContext context) {
    if (this.size == LedgerStepperSize.field) {
      return _StepperField(stepper: this);
    }
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    // The plain number unless the caller formats it: money is opt-in.
    String display(num amount) =>
        format?.call(amount) ??
        RawWidgetsLocalizations.of(context).formatDecimal(amount);
    final words = display(value);
    final canLower = onChanged != null && value - step >= min;
    final canRaise = onChanged != null && (max == null || value + step <= max!);
    final size = wide ? _sizeWide : _size;
    // The input's box is its line (75.6 in Chrome), held to the whole
    // pixel (76, 92 on the desktop) so the 48 rings centred on it, and the
    // rows under it, stand on whole pixels; it grows with the reader's text
    // size, and a sum wider than its slot is set smaller, never cut.
    final centred = showRings || !LedgerLayout.keepsMeasure(context);
    final sum = SizedBox(
      height: (MediaQuery.textScalerOf(context).scale(size) * _line)
          .roundToDouble(),
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          // Between its rings, or alone at its slot's start from 600 (a
          // phone centres it).
          alignment: centred
              ? Alignment.center
              : AlignmentDirectional.centerStart,
          child: Text(
            words,
            maxLines: 1,
            softWrap: false,
            style: t.figure
                .sized(size)
                .line(size * _line)
                .tracked(-.01)
                .colored(t.textPrimary),
          ),
        ),
      ),
    );
    Widget ring(IconData icon, String name, VoidCallback? tap) =>
        LedgerPressable(
          onTap: tap,
          semanticLabel: name,
          radius: _ring / 2,
          child: Container(
            width: _ring,
            height: _ring,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: t.textPrimary),
            ),
            child: Icon(icon, size: _glyph, color: t.textPrimary),
          ),
        );
    return Semantics(
      container: true,
      label: labelText,
      value: words,
      increasedValue: canRaise ? display(value + step) : null,
      decreasedValue: canLower ? display(value - step) : null,
      onIncrease: canRaise ? () => onChanged!(value + step) : null,
      onDecrease: canLower ? () => onChanged!(value - step) : null,
      child: showRings
          ? Padding(
              padding: const EdgeInsets.only(
                top: LedgerSpacing.s6,
                bottom: LedgerSpacing.s10,
              ),
              // From 600 at its measure, at the start of its slot: its
              // rings round the sum, not at the ends of a wide column.
              child: LedgerLayout.atMeasure(
                context,
                Row(
                  spacing: LedgerSpacing.s16,
                  children: [
                    ring(
                      LucideIcons.minus,
                      lowerLabel ?? 'Lower $labelText',
                      canLower ? () => onChanged!(value - step) : null,
                    ),
                    Expanded(child: sum),
                    ring(
                      LucideIcons.plus,
                      raiseLabel ?? 'Raise $labelText',
                      canRaise ? () => onChanged!(value + step) : null,
                    ),
                  ],
                ),
              ),
            )
          // `.add-amount`: 4 above, 8 under.
          : Padding(
              padding: const EdgeInsets.only(
                top: LedgerSpacing.s4,
                bottom: LedgerSpacing.s8,
              ),
              child: sum,
            ),
    );
  }

  static const double _ring = 48;
  static const double _glyph = 20;
  static const double _size = 72;
  static const double _sizeWide = 88;

  // `.stepper-input`: 400 72/1.05 (88 on the desktop); Chrome keeps that
  // line on this input (the live sheets' boxes: 75.59 and 92.4 tall).
  static const double _line = 1.05;
}

/// A [LedgerStepper] at [LedgerStepperSize.field]: ui_core's number field
/// written on a Ledger field's rule.
class _StepperField extends StatefulWidget {
  const _StepperField({required this.stepper});

  final LedgerStepper stepper;

  @override
  State<_StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<_StepperField> {
  final FocusNode _focus = FocusNode(debugLabel: 'LedgerStepper');
  final TextEditingController _controller = TextEditingController();

  // What the typed number breaks, while it has focus: its bounds, or that
  // it does not read as a number.
  String? _wrong;

  LedgerStepper get _s => widget.stepper;

  // A whole step from a whole least value keeps whole numbers.
  bool get _whole => _s.step is int && _s.min is int;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    _focus.addListener(_check);
  }

  @override
  void dispose() {
    _controller.removeListener(_check);
    _focus.removeListener(_check);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    // The number field writes the value into its text as the value comes
    // in, which may be mid-build: say what is wrong once the frame is laid.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _check());
      return;
    }
    final wrong = _wrongOf(_controller.text.trim());
    if (wrong != _wrong) setState(() => _wrong = wrong);
  }

  String? _wrongOf(String text) {
    if (!_focus.hasFocus || text.isEmpty) return null;
    final l = RawWidgetsLocalizations.of(context);
    final read = l.parseDecimal(text);
    final max = _s.max;
    if (read != null && read >= _s.min && (max == null || read <= max)) {
      return null;
    }
    final from = l.formatDecimal(_s.min);
    // In English in words; in another language the range alone, in its
    // digits ("٥–٤٨٠", "≥ ٥"), as ui_core has no words for it.
    if ((Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') != 'en') {
      return max == null
          ? '\u2265 $from'
          : '$from\u2013${l.formatDecimal(max)}';
    }
    if (read == null) return 'Enter a number';
    return max == null
        ? 'At least $from'
        : 'From $from to ${l.formatDecimal(max)}';
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final t = context.ledgerTheme;
    final l = RawWidgetsLocalizations.of(context);
    final enabled = s.onChanged != null;
    final whole = _whole;
    num taken(double v) => whole ? v.round() : v;
    String say(num n) => s.format?.call(n) ?? l.formatDecimal(n);
    final error = s.errorText ?? _wrong;
    final so = LedgerStyleOf(
      [t.components.textField],
      {
        if (!enabled) WidgetState.disabled,
        if (error != null) WidgetState.error,
      },
    );
    final ink = so.foreground ?? (enabled ? t.textPrimary : t.textTertiary);
    // The figures typed as a text field's words, each as wide as the next.
    final words = LedgerTextField.wordsOf(t)
        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
    final height = LedgerTextField.heightOf(t);
    Widget ring(RawNumberFieldButtonDetails button) {
      final off = button.states.contains(WidgetState.disabled);
      final pressed = button.states.contains(WidgetState.pressed);
      final hovered = button.states.contains(WidgetState.hovered);
      final line = off ? t.textFaint : t.textPrimary;
      return SizedBox(
        width: RawTapTargets.of(context).floorOn().width,
        height: height,
        child: Center(
          child: Container(
            width: _ring,
            height: _ring,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pressed
                  ? t.textPrimary
                  : hovered
                  ? t.surfaceAlt
                  : t.textPrimary.withValues(alpha: 0),
              border: Border.all(color: line),
            ),
            child: Icon(
              button.isIncrement ? LucideIcons.plus : LucideIcons.minus,
              size: _glyph,
              color: pressed ? t.background : line,
            ),
          ),
        ),
      );
    }

    final number = RawNumberField(
      value: s.value.toDouble(),
      onChanged: enabled
          // The number field tells only of a change, and of none while
          // empty: an emptied field puts its number back.
          ? (to) {
              if (to != null) s.onChanged!(taken(to));
            }
          : null,
      min: s.min.toDouble(),
      max: s.max?.toDouble(),
      step: s.step.toDouble(),
      pageStep: s.step.toDouble() * 10,
      fractionDigits: whole ? 0 : null,
      controller: _controller,
      focusNode: _focus,
      semanticLabel: s.labelText,
      semanticFormatterCallback: (v) => say(taken(v)),
      fieldBuilder: (context, field) {
        final input = Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: field.controller,
            focusNode: field.focusNode,
            keyboardType: field.keyboardType,
            inputFormatters: field.inputFormatters,
            onEditingComplete: field.onEditingComplete,
            readOnly: !enabled,
            enableInteractiveSelection: enabled,
            decoration: null,
            maxLines: 1,
            style: so.words(words, ink),
            cursorColor: t.textPrimary,
            cursorWidth: 1.5,
          ),
        );
        // ui_core's node steps the number, so it says the number too: a
        // Material text field says whether it is enabled, which keeps it
        // from merging there, so the value is given on the node round it.
        return ListenableBuilder(
          listenable: field.controller,
          builder: (context, child) {
            final read = l.parseDecimal(field.controller.text.trim());
            return Semantics(
              value: read == null ? field.controller.text : say(taken(read)),
              child: child,
            );
          },
          // The input's node stands over the whole line, a finger's
          // height, not over its one line of figures.
          child: MergeSemantics(
            child: ledgerCapCenter(
              words,
              RawTextEntryBox(minHeight: height, maxLines: 1, child: input),
            ),
          ),
        );
      },
      buttonBuilder: (context, button) => ring(button),
      // The number at the line's start, as a field's words; its rings at
      // the end, as a field's acts.
      layoutBuilder: (context, field, decrement, increment) => Row(
        children: [
          Expanded(child: field),
          decrement,
          increment,
        ],
      ),
    );
    final framed = RawInputDecorator(
      // The number field names itself; the frame shows the label.
      mergeSemantics: false,
      helperText: s.helperText,
      errorText: error,
      enabled: enabled,
      focusNode: _focus,
      builder: (context, parts) => LedgerFieldFrame(
        parts: parts,
        displayLabel: s.labelText,
        focusNode: _focus,
        labelCursor: SystemMouseCursors.text,
        line: parts.control,
      ),
      // A press on a ring is the field's, not a tap outside its words.
      child: TextFieldTapRegion(child: number),
    );
    // A number is a short entry: at its measure from 600, as a sum is.
    return LedgerLayout.measured(context, framed);
  }

  // The rings: a 32 circle in a target the tap floor wide, the glyph at 16.
  static const double _ring = 32;
  static const double _glyph = 16;
}
