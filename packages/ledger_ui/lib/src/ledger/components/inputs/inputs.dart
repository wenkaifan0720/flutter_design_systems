import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/cap_center.dart';
import '../../internal/end_glyph.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/on_cheque.dart';
import '../../internal/text_input.dart';
import '../../theme.dart';
import '../marks/marks.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';

/// A segmented set of words (`.chips`): the range of a chart (1M 3M 1Y
/// All), Today or Later. The chosen one is set in the ink, the rest in
/// the mono's second ink, all in one ring of the light paper; [onChanged]
/// null shows the set without letting it change. Each says whether it is
/// chosen.
///
/// ```dart
/// LedgerSegmentedControl(options: const ['1M', '3M', '1Y', 'All'], value: '1Y', onChanged: (r) {})
/// ```
class LedgerSegmentedControl extends StatelessWidget {
  /// A strip of [options], [value] the chosen one.
  const LedgerSegmentedControl({
    required this.options,
    required this.value,
    this.onChanged,
    super.key,
  });

  /// The segments' words, in order.
  final List<String> options;

  /// The chosen segment's words.
  final String value;

  /// Called with the segment chosen; null shows the set without letting it
  /// change.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(11).line(16).tracked(.02);
    // A chip grows with its words at a large text size rather than cut them:
    // its 5 above and under its line stay.
    final height =
        _height - _line + MediaQuery.textScalerOf(context).scale(_line);
    return Container(
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.controlRadius),
        border: Border.all(color: t.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap,
        children: [
          for (final o in options)
            // Each chip answers a 44 point touch round its 26 face.
            LedgerHitSlop(
              child: LedgerPressable(
                // The chosen chip stays live (a screen reader must not call it
                // dimmed); choosing it again changes nothing.
                onTap: onChanged == null
                    ? null
                    : o == value
                    ? _keep
                    : () => onChanged!(o),
                label: o,
                selected: o == value,
                radius: t.controlRadius,
                // The ink fill leaves the old choice and inks in under the new
                // one in Ledger's one motion.
                child: LedgerFace(
                  style: LedgerFaceStyle(
                    ink: o == value ? t.surface : t.textSecondary,
                    ground: BoxDecoration(
                      color: o == value ? t.textPrimary : null,
                      borderRadius: BorderRadius.circular(t.controlRadius),
                    ),
                  ),
                  builder: (context, s, _) => Container(
                    height: height,
                    padding: const EdgeInsets.symmetric(horizontal: _chipPad),
                    decoration: s.ground,
                    // Its own width under a loose one: a Container's alignment
                    // would stretch it.
                    child: Center(
                      widthFactor: 1,
                      child: ledgerCapCenter(
                        words,
                        Text(o, softWrap: false, style: words.colored(s.ink)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static void _keep() {}

  // `.chips`: 3 inside its ring, 2 between; `.chip` 26 tall, 0 12.
  static const double _pad = 3;
  static const double _gap = 2;
  static const double _height = 26;
  static const double _line = 16;
  static const double _chipPad = 12;
}

/// Filter pills (`.filters`): each its own ring of the light paper, the
/// chosen one in the ink, wrapping 6 apart; [value] null chooses none.
/// [label] names the set. [onChanged] null shows them without letting
/// them change. [optionKeys] keys each pill by its words.
///
/// ```dart
/// LedgerFilters(label: 'Direction', options: const ['All', 'Money in', 'Money out'], value: 'All', onChanged: (f) {})
/// ```
class LedgerFilters extends StatelessWidget {
  /// Pills for each of [options], the [value] chosen, named [label].
  const LedgerFilters({
    required this.options,
    required this.value,
    required this.label,
    this.onChanged,
    this.optionKeys,
    super.key,
  });

  /// The pills' words, in order.
  final List<String> options;

  /// The chosen pill's words; null chooses none.
  final String? value;

  /// What the set filters, for a screen reader.
  final String label;

  /// Called with the pill chosen; null shows them without letting them change.
  final ValueChanged<String?>? onChanged;

  /// A key for each option's pill, by its words (a test's or a walk's
  /// target); an option it leaves out stands unkeyed.
  final Map<String, Key>? optionKeys;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = t.meta.medium.sized(11).line(16).tracked(.02);
    return Semantics(
      container: true,
      label: label,
      child: Wrap(
        spacing: _gap,
        runSpacing: _gap,
        children: [
          for (final o in options)
            // Each filter answers a 44 point touch round its 32 face.
            LedgerHitSlop(
              key: optionKeys?[o],
              child: LedgerPressable(
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(o == value ? null : o),
                label: o,
                selected: o == value,
                radius: t.controlRadius,
                child: LedgerFace(
                  style: LedgerFaceStyle(
                    ink: o == value ? t.surface : t.textSecondary,
                    ground: BoxDecoration(
                      color: o == value ? t.textPrimary : t.surface,
                      borderRadius: BorderRadius.circular(t.controlRadius),
                      border: Border.all(
                        color: o == value ? t.textPrimary : t.border,
                      ),
                    ),
                  ),
                  builder: (context, s, _) => Container(
                    height: _height,
                    padding: const EdgeInsets.symmetric(horizontal: _pad),
                    decoration: s.ground,
                    // Its own width under a loose one: a Container's alignment
                    // would stretch it.
                    child: Center(
                      widthFactor: 1,
                      child: ledgerCapCenter(
                        words,
                        Text(o, softWrap: false, style: words.colored(s.ink)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // `.filter`: 32 tall, 0 13, 500 11/30; `.filters` 6 apart. Its words on a
  // line of their own inside the ring (DesignCapCenter sets their capitals
  // on its middle), so the ring stays out of their box.
  static const double _height = 32;
  static const double _pad = 13;
  static const double _gap = 6;
}

/// The switch (`.toggle`): 44 by 26, its knob of the light paper on the
/// darker paper, at the end on the ink when on; a null [onChanged] dims it
/// to .45. Taps reach 44 round it. Says its [semanticLabel] and whether it
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
    super.key,
  });

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

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
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
          child: CustomPaint(painter: _SwitchPainter(at, t)),
        ),
      ),
    );
    final change = onChanged;
    return LedgerHitSlop(
      child: LedgerPressable(
        onTap: change == null ? null : () => change(!value),
        label: semanticLabel,
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

class _SwitchPainter extends CustomPainter {
  _SwitchPainter(this.at, this.t);

  /// 0 off, 1 on, between on the way.
  final double at;
  final LedgerThemeData t;

  @override
  void paint(Canvas canvas, Size size) {
    final box = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    // Off, the source rings the darker paper in the rule (the ink at .14,
    // about 1.3:1 on the paper) and sets a paper knob on it: a switch read
    // as nothing there. Here its ring and a smaller knob are in the third
    // ink (over 4.5:1), so an off switch is seen as one (WCAG 1.4.11).
    canvas
      ..drawRRect(
        box,
        Paint()..color = Color.lerp(t.surfaceAlt, t.textPrimary, at)!,
      )
      // A 1 px ring whose outer edge is the box's: a hairline (a stroke of
      // no width) is one device pixel half a pixel in, so at 2x and 3x an
      // off switch drew a device pixel smaller than an on one beside it.
      ..drawRRect(
        box.deflate(.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Color.lerp(t.textTertiary, t.textPrimary, at)!,
      );
    // The knob: radial-gradient(circle at 12px 12px, #F9F6F0 8.5px, 0 at
    // 9.2px), placed from inside the 1 px ring (30px when on); off, 6 of
    // the third ink.
    final c = Offset(13 + 18 * at, 13);
    final knob = Color.lerp(t.textTertiary, t.surface, at)!;
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

/// A switch's row (`.toggle-row`): its glyph, its [title] and [subtitle],
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

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final off = onChanged == null;
    final ink = off ? t.textTertiary : t.textPrimary;
    return LedgerPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onTap: off ? null : () => onChanged!(!value),
      label: semanticLabel ?? title,
      toggled: value,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          spacing: 14,
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
                    const SizedBox(height: 3),
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
                  child: LedgerSwitch(
                    value: value,
                    semanticLabel: semanticLabel ?? title,
                    onChanged: off ? null : onChanged,
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

/// A setting's row (`.set-row`): its glyph, its [title] on the dot leader
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

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether it can be used now; false holds it in the third ink, a button
  /// that says it is not enabled.
  final bool enabled;

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
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        spacing: 14,
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
                  const SizedBox(height: 3),
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
      label: semanticLabel ?? title,
      value: value,
      child: line,
    );
  }

  static const double _leaderInset = 6;
  static const double _leaderMin = 8;
  static const double _chevron = 16;
}

/// The search field (`.search`), a round field of the light paper 46
/// tall: as a link ([onTap]: Activity's, leading to the search) its glyph
/// and [hint]; live (no onTap) ringed in the ink, the words typed
/// in the medium, a round clear at its end when [onCleared] is set and it
/// holds words ([clearKey] keys it). Says its [semanticLabel].
///
/// ```dart
/// LedgerSearchField(hint: 'Search merchants and categories', onTap: () => open('/activity/search'))
/// ```
class LedgerSearchField extends StatelessWidget {
  /// A link to the search with [onTap], else a live field.
  const LedgerSearchField({
    this.hint,
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
  /// ([DesignLocalizations.searchFieldLabel]).
  final String? hint;

  /// What a screen reader says; null says the [hint].
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
  /// words' Clear ([DesignLocalizations.clearButtonTooltip]).
  final String? clearLabel;

  /// The field's focus; never disposed when given.
  final FocusNode? focusNode;

  /// Whether the field takes the focus when it first stands.
  final bool autofocus;

  /// A key for the round clear (a test's or a walk's target).
  final Key? clearKey;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final words = DesignLocalizations.of(context);
    final hint = this.hint ?? words.searchFieldLabel;
    final live = onTap == null;
    final glyph = Icon(
      LucideIcons.search,
      size: LedgerChromeMetrics.searchGlyph,
      color: t.textSecondary,
    );
    Widget box(Widget child) => Container(
      height: LedgerChromeMetrics.searchHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: LedgerChromeMetrics.searchPad,
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
        label: semanticLabel ?? hint,
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
    final field = LedgerTextInput(
      controller: controller,
      placeholder: hint,
      style: t.search.medium.colored(t.textPrimary),
      placeholderStyle: t.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
    );
    return Semantics(
      textField: true,
      label: semanticLabel ?? hint,
      child: box(
        Row(
          spacing: LedgerChromeMetrics.searchGap,
          children: [
            Expanded(child: field),
            if (onCleared != null && controller != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller!,
                builder: (context, v, _) => v.text.isEmpty
                    ? const SizedBox.shrink()
                    // The 24 disc answers a 44 point touch round it.
                    : LedgerHitSlop(
                        child: LedgerPressable(
                          key: clearKey,
                          onTap: onCleared,
                          label: clearLabel ?? words.clearButtonTooltip,
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
      ),
    );
  }

  static const double _clear = 24;
  static const double _clearGlyph = 14;
}

/// A form's field (`.field`): its [label] in the small capitals, then on
/// the ink rule the words typed (the medium at 16; the [hint] in
/// the third ink) after an optional serif [prefix] ($), its [note] under
/// it. 16 above it. Says its label. A [child] stands in the typed line's
/// place, a control rather than words (a cheque's When and its chips: 4
/// above it, 6 under it, at its start, no rule). A [value] stands there
/// read only: the words as typed, which no one here types (a transfer's
/// note shown on its cheque). On a cheque the rule is the faint ink
/// (`.cheque .field-box`), the ink off one.
///
/// ```dart
/// LedgerField(label: 'Note', controller: note, hint: 'What it is for')
/// ```
///
/// ```dart
/// LedgerField(label: 'When', child: LedgerSegmentedControl(options: const ['Today', 'Later'], value: when, onChanged: pick))
/// ```
///
/// ```dart
/// LedgerField(label: 'Note', value: 'November top-up')
/// ```
class LedgerField extends StatelessWidget {
  /// A field named [label]: typed with a [controller], a [child] control, or a
  /// read-only [value].
  const LedgerField({
    required this.label,
    this.controller,
    this.hint,
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
  final String label;

  /// The words typed; the field makes its own when none is given, and never
  /// disposes one it was given.
  final TextEditingController? controller;

  /// The words shown while it is empty.
  final String? hint;

  /// Words in the serif before the typed ones (`$`).
  final String? prefix;

  /// A line under the field.
  final String? note;

  /// Called with the words as they are typed.
  final ValueChanged<String>? onChanged;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// The keyboard the field asks for.
  final TextInputType? keyboardType;

  /// The field's focus; never disposed when given.
  final FocusNode? focusNode;

  /// A control in the typed line's place; it speaks for itself.
  final Widget? child;

  /// Words shown read only on the typed line, read as the field's value.
  final String? value;

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
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 4,
          children: [
            ExcludeSemantics(
              child: Text(
                label.toUpperCase(),
                style: t.label.colored(t.textSecondary),
              ),
            ),
            if (control != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: control,
                ),
              )
            else
              Container(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
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
                    spacing: 6,
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
                                placeholder: hint,
                                style: words.colored(t.textPrimary),
                                placeholderStyle: words
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

/// A cheque's line (`.pick-row`): its [label] in the small capitals, then
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

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Ruled under it (none in a sheet).
  final bool ruled;

  /// Whether the chevron ends the line; null draws it only live.
  final bool? showChevron;

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
      spacing: 12,
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
                        padding: const EdgeInsets.only(top: 4),
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
      padding: const EdgeInsets.only(top: 12, bottom: 14),
      decoration: ruled
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          ExcludeSemantics(
            child: Text(
              label.toUpperCase(),
              style: t.label.colored(t.textSecondary),
            ),
          ),
          if (onTap != null)
            // The 36 line answers a 44 point touch, 4 into the room above
            // and below it.
            LedgerHitSlop(
              child: LedgerPressable(
                focusNode: focusNode,
                autofocus: autofocus,
                onTap: onTap,
                label: '$label: $name',
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

/// A cheque's amount (`.amount-row`): its [label], then in a box ruled in the
/// ink the sum in the serif after its `$` (typed live with a [controller], else
/// read back as the engraved [amount]), and under it the sum in [words] on the
/// cheque's line with its [unit] (DOLLARS). The typed line stands as Chrome
/// holds an input's, at least its font's normal line: 1.3 of the serif's size
/// to the pixel (the transfer's box 95 tall at 56, 116 at 72), its label on the
/// body's line (21.75). [typed] reads the [amount] back as the input holds it
/// ("500.00" after its `$`), a sum shown that no one types here (the form's).
///
/// ```dart
/// LedgerChequeAmount(label: 'Amount', words: 'Five hundred and 00/100', unit: 'dollars', amount: 500)
/// ```
///
/// ```dart
/// LedgerChequeAmount(label: 'Amount', words: 'Five hundred and 00/100', unit: 'dollars', amount: 500, typed: true)
/// ```
class LedgerChequeAmount extends StatelessWidget {
  /// A cheque's sum: typed with a [controller], else read back as [amount].
  const LedgerChequeAmount({
    required this.label,
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
  final String label;

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

  /// The control's focus; null keeps one of its own. The caller disposes
  /// the node it gives.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Whether the [amount] reads back in the input's typed look rather
  /// than engraved; read only.
  final bool typed;

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
      padding: const EdgeInsets.only(top: 6),
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
            label: label,
            value: LedgerFormat.money(amount!),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
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
              label: label,
              child: LedgerFigure(amount!, size: LedgerFigureSize.entry),
            ),
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              cur,
              Expanded(
                child: Semantics(
                  textField: true,
                  label: label,
                  // An engraved figure, already large: it keeps its size at
                  // any text size, as the read-back figure does, rather
                  // than run past its box.
                  child: MediaQuery.withNoTextScaling(
                    child: LedgerTextInput(
                      focusNode: focusNode,
                      autofocus: autofocus,
                      controller: controller,
                      style: typedStyle,
                      placeholderStyle: t.figure
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
      padding: const EdgeInsets.only(top: 14, bottom: 16),
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
                label.toUpperCase(),
                style: t.label.colored(t.textSecondary),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
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
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.only(bottom: 3),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.textFaint)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 10,
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

/// The budget's stepper (`.stepper`): the sum in the serif, 72 (88 on the
/// desktop), between two 48 rings that lower and raise it by [step];
/// [onChanged] null holds it. Read as an adjustable value; each ring says
/// its [lowerLabel] or [raiseLabel] whole ('Lower the budget'), or, left
/// unset, Lower or Raise and the [label]. The sum stands on its input's
/// own line, 1.05 of its size (75.6 at 72, 92.4 at 88, as the budget and
/// add money sheets measure). [showRings]
/// false shows the sum alone, chosen from elsewhere (the add sheet's
/// amount under its chips, `.stepper-v.add-amount`: 4 above, 8 under),
/// still an adjustable value with [onChanged]; centred on a phone, at its
/// slot's start from 600, as the rings are.
///
/// ```dart
/// LedgerStepper(value: 250, label: 'Monthly budget', onChanged: (v) {})
/// ```
///
/// ```dart
/// LedgerStepper(value: 250, label: 'Monthly budget', lowerLabel: 'Lower the budget', raiseLabel: 'Raise the budget', onChanged: (v) {})
/// ```
///
/// ```dart
/// LedgerStepper(value: 110, label: 'Amount to add', step: 1, showRings: false)
/// ```
class LedgerStepper extends StatelessWidget {
  /// A [value] named [label], lowered and raised by [step].
  const LedgerStepper({
    required this.value,
    required this.label,
    this.step = 5,
    this.min = 0,
    this.lowerLabel,
    this.raiseLabel,
    this.onChanged,
    this.showRings = true,
    super.key,
  });

  /// The sum.
  final num value;

  /// What the sum is, for a screen reader.
  final String label;

  /// How much a ring lowers or raises the sum.
  final num step;

  /// The lowest the sum goes.
  final num min;

  /// The lower ring's words; null reads 'Lower' and the [label].
  final String? lowerLabel;

  /// The raise ring's words; null reads 'Raise' and the [label].
  final String? raiseLabel;

  /// Called with the new sum; null holds it.
  final ValueChanged<num>? onChanged;

  /// Whether the lower and raise rings stand at its ends.
  final bool showRings;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final words = LedgerFormat.money(value, showCents: false);
    final canLower = onChanged != null && value - step >= min;
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
          label: name,
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
      label: label,
      value: words,
      increasedValue: onChanged == null
          ? null
          : LedgerFormat.money(value + step, showCents: false),
      decreasedValue: canLower
          ? LedgerFormat.money(value - step, showCents: false)
          : null,
      onIncrease: onChanged == null ? null : () => onChanged!(value + step),
      onDecrease: canLower ? () => onChanged!(value - step) : null,
      child: showRings
          ? Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              // From 600 at its measure, at the start of its slot: its
              // rings round the sum, not at the ends of a wide column.
              child: LedgerLayout.atMeasure(
                context,
                Row(
                  spacing: 16,
                  children: [
                    ring(
                      LucideIcons.minus,
                      lowerLabel ?? 'Lower $label',
                      canLower ? () => onChanged!(value - step) : null,
                    ),
                    Expanded(child: sum),
                    ring(
                      LucideIcons.plus,
                      raiseLabel ?? 'Raise $label',
                      onChanged == null ? null : () => onChanged!(value + step),
                    ),
                  ],
                ),
              ),
            )
          // `.add-amount`: 4 above, 8 under.
          : Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
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
