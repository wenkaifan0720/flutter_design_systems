import 'package:flutter/widgets.dart';

import '../../glyphs.dart';

import '../../chrome_metrics.dart';
import '../../theme.dart';
import '../controls/controls.dart';
import '../marks/marks.dart';
import '../pressable/pressable.dart';
import '../structure/structure.dart';
import 'forms.dart';
import '../../internal/dim.dart';
import '../../internal/flush_end.dart';
import '../../internal/cap.dart';

/// A tile's head as `.tile-h` sets it (the title in `.t20`, at least 24
/// tall), with the margin the settings and form tiles override to [gap]
/// (`.set-tile .tile-h { margin-bottom: 4px }`, `.form-tile .tile-h
/// { margin-bottom: 16px }`).
class _TileHead extends StatelessWidget {
  const _TileHead(this.title, {required this.gap});

  final String title;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: gap),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: FrostedChromeMetrics.tileHead,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Semantics(
            header: true,
            child: Text(title, style: t.textTheme.titleLarge),
          ),
        ),
      ),
    );
  }
}

/// Marks a settings row that stands under another (`.set-row + .set-row
/// { border-top: 1px solid var(--line) }`): its hairline is its own top
/// border, inside its 52 (the page's `box-sizing: border-box`), not a row
/// of its own between the two.
class _Ruled extends InheritedWidget {
  const _Ruled({required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Ruled>() != null;

  @override
  bool updateShouldNotify(_Ruled oldWidget) => false;
}

// ---------------------------------------------------------------------------
// Settings rows
// ---------------------------------------------------------------------------

/// A settings row's layout (`.set-row`): the title over its line taking the
/// width, then what the row ends in, 12 apart, at least 52 tall with 8
/// above and below.
class _SetRow extends StatelessWidget {
  const _SetRow({
    required this.title,
    required this.end,
    this.sub,
    this.excludeWords = false,
  });

  final String title;
  final String? sub;
  final List<Widget> end;

  /// Whether the words stay out of the semantics tree: a switch row reads
  /// them through its switch's one node.
  final bool excludeWords;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .set-row { gap: 12px; min-height: 52px; padding: 8px 0 }
    // .set-m { gap: 2px }  .set-t { font: 500 16px/1.25 var(--font-t) }
    // .set-s { font: 400 12px/1.3 var(--font-t); color: var(--ink-3) }
    final words = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: FrostedChromeMetrics.settingLineGap,
      children: [
        frostedCapCentred(Text(title, style: t.textTheme.titleMedium)),
        if (sub case final sub?)
          Text(sub, style: t.textTheme.bodySmall.line(15.6)),
      ],
    );
    // At least 52 with its hairline (a row under another), 8 inside it.
    return Container(
      constraints: const BoxConstraints(
        minHeight: FrostedChromeMetrics.settingRow,
      ),
      // Drawn over the row, taking no room: the words keep the middle.
      foregroundDecoration: _Ruled.of(context)
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: t.colorScheme.border,
                  width: FrostedChromeMetrics.outline,
                ),
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(
        vertical: FrostedChromeMetrics.settingInset,
      ),
      child: FrostedRowContent(
        child: Row(
          spacing: FrostedChromeMetrics.settingGap,
          children: [
            Expanded(
              child: excludeWords ? ExcludeSemantics(child: words) : words,
            ),
            ...end,
          ],
        ),
      ),
    );
  }
}

/// A setting beside its switch (`.set-row` with a `.tgl`): the title in
/// the body over a quiet 12 line, the [FrostedSwitch] at the end; the whole
/// row is the switch's label and flips it. The page owns [value]; a null
/// [onChanged] dims the whole row, words and switch as one, and leaves it
/// inert, unless [readOnly] reports the setting at full strength. Stands in a [FrostedSettingsGroup],
/// which draws the hairlines between rows. A screen reader hears one
/// switch named [label], its line as the hint.
///
/// ```dart
/// FrostedSwitchRow(label: 'Face ID', note: 'To open the app and approve payments', value: faceId, onChanged: (v) => setState(() => faceId = v))
/// ```
class FrostedSwitchRow extends StatelessWidget {
  /// Creates a [FrostedSwitchRow].
  const FrostedSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.note,
    this.readOnly = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The row's words.
  final String label;

  /// The quiet line under the label (To open the app and approve payments).
  final String? note;

  /// Whether it is on.
  final bool value;

  /// Called with the new state; null leaves it inert.
  final ValueChanged<bool>? onChanged;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Reports the setting without taking input; see [FrostedSwitch.readOnly].
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final live = onChanged != null;
    // Off to use, the row dims as one thing: its words with its switch.
    final row = FrostedDim(
      off: !live && !readOnly,
      child: _SetRow(
        title: label,
        sub: note,
        excludeWords: true,
        end: [
          FrostedSwitch(
            focusNode: focusNode,
            autofocus: autofocus,
            value: value,
            onChanged: onChanged,
            label: label,
            readOnly: readOnly,
          ),
        ],
      ),
    );
    // The label flips the switch, as the source's <label class="set-row">
    // does; the words merge into the switch's one node.
    return MergeSemantics(
      child: Semantics(
        hint: note,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: live ? () => onChanged!(!value) : null,
          child: MouseRegion(
            cursor: live ? SystemMouseCursors.click : MouseCursor.defer,
            child: row,
          ),
        ),
      ),
    );
  }
}

/// A setting that opens a page (`.set-row` with a `.set-v` and a chevron):
/// the title in the body over a quiet 12 line, its current [value] in the
/// secondary ink at the end (Monthly spending limit, $2,000) before a 16
/// chevron. A null [onPressed] leaves it inert; [enabled] false dims the whole row
/// to the source's `.set-row--off` share, a limit the frozen card cannot
/// change. Stands in a [FrostedSettingsGroup]. A screen reader hears a link
/// named [title] with [value].
///
/// ```dart
/// FrostedValueRow(title: 'Monthly spending limit', subtitle: r'$1,259.82 spent in October', value: r'$2,000', onPressed: openLimit)
/// ```
class FrostedValueRow extends StatelessWidget {
  /// Creates a [FrostedValueRow].
  const FrostedValueRow({
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.value,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The row's words.
  final String title;

  /// The quiet line under the title.
  final String? subtitle;

  /// The setting's current value, at the end.
  final String? value;

  /// What a press does; null leaves it still.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  /// Whether the row takes taps; false dims it to `.set-row--off`'s .45.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    Widget row = _SetRow(
      title: title,
      sub: subtitle,
      end: [
        // .set-v { font: 400 14px/1.3 var(--font-t); color: var(--ink-2);
        //   white-space: nowrap }: the value keeps its own width and the
        //   words (.set-m { flex: 1 }) take the rest, so a title wraps only
        //   when the value leaves it no room.
        if (value case final value?)
          frostedCapCentred(
            Text(
              value,
              maxLines: 1,
              softWrap: false,
              textAlign: TextAlign.end,
              style: t.textTheme.bodyMedium.line(18.2),
            ),
          ),
        const _Chevron(),
      ],
    );
    row = FrostedDim(off: !enabled, child: row);
    return FrostedPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: enabled ? onPressed : null,
      label: title,
      value: value,
      role: FrostedPressRole.link,
      radius: FrostedCorners.r14,
      child: row,
    );
  }
}

/// Settings rows in a tile (`.set-tile`): the title in the tile's head 4
/// over the list, each row under another ruled off by a hairline at its
/// top, inside its own 52. Takes
/// [FrostedSwitchRow]s and [FrostedValueRow]s in order.
///
/// ```dart
/// FrostedSettingsGroup(title: 'Security', children: [FrostedSwitchRow(label: 'Face ID', note: 'To open the app and approve payments', value: faceId, onChanged: setFaceId), FrostedValueRow(title: 'Change passcode', onPressed: openPasscode)])
/// ```
class FrostedSettingsGroup extends StatelessWidget {
  /// Creates a [FrostedSettingsGroup].
  const FrostedSettingsGroup({required this.children, this.title, super.key});

  /// The rows, in order.
  final List<Widget> children;

  /// The group's name in the tile's head (Security, Notifications).
  final String? title;

  @override
  Widget build(BuildContext context) => FrostedCard(
    // As much under the last row's content as over the head (design6 P).
    child: FrostedFlushEnd(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title case final title?)
            _TileHead(title, gap: FrostedChromeMetrics.settingsHeadGap),
          for (var i = 0; i < children.length; i++)
            i == 0 ? children[i] : _Ruled(child: children[i]),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Form rows and sections
// ---------------------------------------------------------------------------

/// A labelled row of a form (`.set-row`): the label in the body over a
/// quiet [detail], at least 52 tall with 8 above and below, 12 between its
/// parts; before them an optional [leading] glyph on a 32 quiet token
/// (DERIVED: the source's rows carry none), after them the setting's
/// [value] in the secondary ink or a [trailing] control (a [FrostedSwitch]),
/// and a 16 chevron when [onPressed] opens a page. A row with a control reads
/// as its words and the control; one without reads as one line, or one
/// link when it opens.
///
/// ```dart
/// FrostedFormRow(label: 'Currency', value: 'USD', onPressed: pickCurrency)
/// ```
class FrostedFormRow extends StatelessWidget {
  /// Creates a [FrostedFormRow].
  const FrostedFormRow({
    required this.label,
    this.detail,
    this.leading,
    this.value,
    this.trailing,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The row's words.
  final String label;

  /// A quieter line under the label.
  final String? detail;

  /// A glyph before the label, from the Lucide set.
  final IconData? leading;

  /// The setting's current value, at the end.
  final String? value;

  /// A control at the end (a [FrostedSwitch]).
  final Widget? trailing;

  /// Makes the row one link.
  final VoidCallback? onPressed;

  /// The node that holds this part's keyboard focus; null keeps one of its own.
  final FocusNode? focusNode;

  /// Whether this part takes keyboard focus when first shown.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // .set-row { gap: 12px; min-height: 52px; padding: 8px 0 }
    // .set-t { font: 500 16px/1.25 }  .set-s { font: 400 12px/1.3; ink-3 }
    // .set-v { font: 400 14px/1.3; ink-2 }  .set-row .i-chevron-right { 16px }
    final row = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: FrostedChromeMetrics.formRow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: FrostedChromeMetrics.formRowInset,
        ),
        child: FrostedRowContent(
          child: Row(
            spacing: FrostedChromeMetrics.formRowGap,
            children: [
              if (leading case final leading?)
                FrostedIconMark(
                  leading,
                  quiet: true,
                  size: FrostedMarkSize.small,
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: FrostedChromeMetrics.settingLineGap,
                  children: [
                    frostedCapCentred(
                      Text(label, style: t.textTheme.titleMedium),
                    ),
                    if (detail case final detail?)
                      Text(detail, style: t.textTheme.bodySmall.line(15.6)),
                  ],
                ),
              ),
              // The value keeps its own width (nowrap); the words take the
              // rest.
              if (value case final value?)
                frostedCapCentred(
                  Text(
                    value,
                    maxLines: 1,
                    softWrap: false,
                    textAlign: TextAlign.end,
                    style: t.textTheme.bodyMedium.line(18.2),
                  ),
                ),
              ?trailing,
              if (onPressed != null && trailing == null) const _Chevron(),
            ],
          ),
        ),
      ),
    );
    if (onPressed != null) {
      return FrostedPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: label,
        value: value,
        role: FrostedPressRole.link,
        radius: FrostedCorners.r14,
        child: row,
      );
    }
    // A row that holds no control of its own reads as one line.
    return trailing == null ? MergeSemantics(child: row) : row;
  }
}

/// Two fields sharing a line (`.form-2`): each half the width, 12 apart
/// (a goal's Target beside its Date).
///
/// ```dart
/// FrostedFieldPair(FrostedAmountField(label: 'Target', small: true, value: target, onChanged: setTarget), FrostedTextField(label: 'Date', hint: 'Month and year', value: date, onChanged: setDate))
/// ```
class FrostedFieldPair extends StatelessWidget {
  /// Creates a [FrostedFieldPair].
  const FrostedFieldPair(this.first, this.second, {super.key});

  /// The field at the start.
  final Widget first;

  /// The field at the end.
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: FrostedChromeMetrics.fieldsGap,
    children: [
      Expanded(child: first),
      Expanded(child: second),
    ],
  );
}

/// A form (`.form`): its fields, rows and pickers 16 apart in a column,
/// in a tile with [title] in its head 16 over them (`.form-tile`), or
/// [bare] on a sheet's body (`.sheet-b--form`). A [FrostedSwapButton] among the
/// children is the gap between its two pickers: none is added round it.
///
/// ```dart
/// FrostedFormSection(title: 'New goal', children: [name, FrostedFieldPair(target, date), icons])
/// ```
class FrostedFormSection extends StatelessWidget {
  /// Creates a [FrostedFormSection].
  const FrostedFormSection({
    required this.children,
    this.title,
    this.bare = false,
    super.key,
  });

  /// The fields, in order.
  final List<Widget> children;

  /// The form's name in the tile's head.
  final String? title;

  /// No tile: the form stands on the page or a sheet's body.
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // .form-tile .tile-h { margin-bottom: 16px }  .form { gap: 16px }
        if (title case final title? when !bare)
          _TileHead(title, gap: FrostedChromeMetrics.formGap),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 &&
              children[i] is! FrostedSwapButton &&
              children[i - 1] is! FrostedSwapButton)
            const SizedBox(height: FrostedChromeMetrics.formGap),
          children[i],
        ],
      ],
    );
    return bare ? column : FrostedCard(child: column);
  }
}

/// A row's chevron with its ink on the group's trailing keyline (design6 P:
/// a trailing glyph's ink ends on the keyline, its box may hang past it).
/// Lucide draws the chevron in the middle third of its box, so the box lays
/// out two thirds wide and the glyph overhangs its end by the last third,
/// mirrored in a right-to-left language.
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    const size = FrostedChromeMetrics.settingGlyph;
    return SizedBox(
      width: size * 2 / 3,
      height: size,
      child: OverflowBox(
        alignment: AlignmentDirectional.centerStart,
        minWidth: size,
        maxWidth: size,
        child: Icon(
          FrostedGlyphs.forward,
          size: size,
          color: context.frostedTheme.colorScheme.textTertiary,
        ),
      ),
    );
  }
}
