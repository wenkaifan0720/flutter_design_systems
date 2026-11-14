import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'menu.dart';
import 'pressable.dart';
import 'tag.dart';

/// The property register's measure: the glyph column, the label column
/// (scaled with the text so a label never wraps under its value), the air
/// between them, the status dot, the row's type, and the create-form
/// pill's corners, side padding and type.
abstract final class _PropertyMetrics {
  static const double valueType = 13.5;
  static const double monoType = 13;
  static const double glyphColumn = 22;
  static const double labelColumn = 92;
  static const double columnGap = 6;
  static const double dot = 8;
  static const double pillPad = 9;
  static const double pillType = 12.5;
}

/// An issue-style list of a record's properties — `Status  ● Active`,
/// `Reminder  07:00` — one [MinimalProperty] per 36 px row, each over a
/// hairline, with a hairline above the first. It holds the page's measure
/// (it is not full-bleed): stand it in the screen's padding.
///
/// ```dart
/// MinimalDescriptionList(properties: [MinimalProperty(icon: LucideIcons.bell, label: 'Reminder', value: '07:00', mono: true)])
/// ```
class MinimalDescriptionList extends StatelessWidget {
  /// Rows of [properties].
  const MinimalDescriptionList({super.key, required this.properties});

  /// The rows, top to bottom.
  final List<MinimalProperty> properties;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: t.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: properties,
      ),
    );
  }
}

/// One row of a [MinimalDescriptionList]: the property's glyph, its name in
/// the quiet ink on a fixed label column, then its value in the ink.
///
/// [mono] prints the value as data (a time, an id, a date), and the
/// figures of its [detail] with it; [tone] leads the value with a status
/// dot; [detail] follows it in the quiet ink after a middle dot (`12d ·
/// best 21d`); [child] replaces the value with any widget (an avatar and a
/// name). A property with no value prints [placeholder] in the faint ink.
/// [onPressed] makes the row the control that edits it; [items] instead opens
/// the property's choices as a [MinimalMenu] anchored to the row, which is
/// what a status, a priority or an assignee usually wants.
///
/// A screen reader hears the label, the value and the detail. A [child]
/// speaks for itself after the label unless [semanticValue] says it in
/// words.
///
/// ```dart
/// MinimalProperty(icon: LucideIcons.circleDot, label: 'Status', value: 'Active', tone: MinimalTone.success, onPressed: pickStatus)
/// ```
class MinimalProperty extends StatelessWidget {
  /// A property: [label] and its [value].
  const MinimalProperty({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.detail,
    this.mono = false,
    this.tone,
    this.child,
    this.placeholder,
    this.semanticValue,
    this.onPressed,
    this.items,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         onPressed == null || items == null,
         'onPressed or items, not both',
       );

  /// Its glyph.
  final IconData icon;

  /// What it is.
  final String label;

  /// Its value; null for none yet.
  final String? value;

  /// The value as a screen reader says it, in place of [value] or of what
  /// a [child] announces.
  final String? semanticValue;

  /// A quiet tail after the value, set off by a middle dot: `best 21d`.
  final String? detail;

  /// Print [value] in mono (a time, an id, a date).
  final bool mono;

  /// A status dot before the value, in the tone's colour.
  final MinimalTone? tone;

  /// The value as a widget, in place of [value].
  final Widget? child;

  /// What an empty property prints.
  final String? placeholder;

  /// Edit the property; null for a row that only reads.
  final VoidCallback? onPressed;

  /// The property's choices, opened as a menu from the value, on its
  /// leading edge; the current one carries `selected: true`.
  final List<MinimalMenuItem>? items;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // The menu opens from the value, the part that changes: on its leading
    // edge and at least as wide (design6 P, a list that opens from a field).
    BuildContext? valueContext;
    final onPressed =
        this.onPressed ??
        _menuOpener(() => valueContext ?? context, items, label);
    final scaler = MediaQuery.textScalerOf(context);
    final type = t.bodySmall.copyWith(fontSize: _PropertyMetrics.valueType);
    final monoType = t.mono.copyWith(fontSize: _PropertyMetrics.monoType);
    final tone = this.tone;
    final value = this.value;
    final detail = this.detail;
    final child = this.child;
    // A child with no words of our own speaks for itself.
    final childSpeaks = child != null && semanticValue == null;

    final Widget shown;
    if (child != null) {
      // A child's text prints in the value's register unless it says
      // otherwise.
      shown = DefaultTextStyle.merge(
        style: type.c(t.foreground),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: child,
      );
    } else if (value == null) {
      shown = Text(
        placeholder ?? MinimalLocalizations.of(context).empty,
        style: type.c(t.textTertiary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      final quiet = type.c(t.mutedForeground);
      shown = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: value, style: mono ? monoType : type),
            if (detail != null) ...[
              TextSpan(text: ' · ', style: quiet),
              // A data row prints the detail's figures as data too:
              // `best 21d`, the word in Geist, the figure in mono.
              for (final (i, word) in detail.split(' ').indexed) ...[
                if (i > 0) TextSpan(text: ' ', style: quiet),
                TextSpan(
                  text: word,
                  style: mono && word.contains(RegExp('[0-9]'))
                      ? monoType.c(t.mutedForeground)
                      : quiet,
                ),
              ],
            ],
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    Widget lead = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _PropertyMetrics.glyphColumn,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: MinimalIcon(icon),
          ),
        ),
        const MinimalGap(_PropertyMetrics.columnGap),
        SizedBox(
          width: scaler.scale(_PropertyMetrics.labelColumn),
          child: minimalCapLabel(
            Text(
              label,
              style: type.c(t.mutedForeground),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const MinimalGap(_PropertyMetrics.columnGap),
        if (tone != null && value != null) ...[
          _Dot(color: t.tone(tone).indicator),
          const MinimalGap(MinimalChromeMetrics.iconGap),
        ],
      ],
    );
    // Only the words below are announced, unless the child speaks: then
    // the label is ours and the rest is the child's.
    if (childSpeaks) lead = ExcludeSemantics(child: lead);

    Widget row = Container(
      constraints: BoxConstraints(minHeight: t.rowHeightCompact),
      // Painted over the row's foot: the label and value are centred on
      // the whole row, the rule's pixel with it.
      foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Row(
        children: [
          lead,
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: MinimalSpacing.s4),
              // Our own words by their capitals; a child places its own.
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                heightFactor: 1,
                child: Builder(
                  builder: (context) {
                    valueContext = context;
                    return child == null ? minimalCapLabel(shown) : shown;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final spoken =
        semanticValue ??
        value ??
        (child != null
            ? null
            : placeholder ?? MinimalLocalizations.of(context).empty);
    final announced = [
      label,
      ?spoken,
      if (value != null && detail != null) detail,
    ].join(', ');
    if (!childSpeaks) row = ExcludeSemantics(child: row);
    if (onPressed == null) {
      return Semantics(container: true, label: announced, child: row);
    }
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      shape: t.shapes.mark,
      // Reaching past the words, the ring stays inside the reach, clear of
      // a card's edge.
      outset: MinimalFieldMetrics.rowReach,
      focusInside: true,
      semanticLabel: announced,
      child: row,
    );
  }
}

/// A create form's property as a 28 px pill — `⟳ Every evening`,
/// `🔔 21:30` — the control that opens the property's menu or picker.
///
/// Every pill is the same outline. [hasValue] is a property that has a value:
/// its glyph and value in the ink. An unset one prints the property's name
/// (`Goal`, `Start date`) and its glyph in the quiet ink. [name] tells a screen reader which property a set pill holds.
/// No [onPressed] means disabled. Line several up in a [MinimalPropertyBar].
///
/// ```dart
/// MinimalPropertyPill(icon: LucideIcons.bell, label: '21:30', name: 'Reminder', mono: true, hasValue: true, onPressed: pickTime)
/// ```
class MinimalPropertyPill extends StatelessWidget {
  /// A pill showing a property.
  const MinimalPropertyPill({
    super.key,
    required this.icon,
    required this.label,
    this.name,
    this.hasValue = false,
    this.mono = false,
    this.onPressed,
    this.items,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
         onPressed == null || items == null,
         'onPressed or items, not both',
       );

  /// Its glyph.
  final IconData icon;

  /// The value when [hasValue], else the property's name.
  final String label;

  /// The property the pill edits, announced before a set value.
  final String? name;

  /// Whether the property has a value: printed in the ink (else the name
  /// in the muted ink).
  final bool hasValue;

  /// Print [label] in mono (a time, a date).
  final bool mono;

  /// Opens its choice; null leaves it still.
  final VoidCallback? onPressed;

  /// The property's choices, opened as a menu anchored to the pill.
  final List<MinimalMenuItem>? items;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final onPressed =
        this.onPressed ?? _menuOpener(() => context, items, this.name ?? label);
    final type = mono
        ? t.mono.copyWith(fontSize: _PropertyMetrics.pillType).medium
        : t.control.copyWith(fontSize: _PropertyMetrics.pillType);
    final name = this.name;
    final announced = hasValue
        ? (name == null ? label : '$name, $label')
        : '$label, not set';
    return MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      enabled: onPressed != null,
      shape: MinimalShapes.inset(t.shapes.small, 1),
      semanticLabel: announced,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(
            minHeight: MinimalChromeMetrics.controlSm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: _PropertyMetrics.pillPad,
            vertical: MinimalSpacing.s2,
          ),
          decoration: minimalFrame(
            MinimalShapes.inset(t.shapes.small, 1),
            // A set value prints in the ink, an unset name in the muted ink;
            // neither is filled (nothing on the page is a tinted pill).
            side: BorderSide(color: t.border, width: t.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalIcon(
                icon,
                size: MinimalIconSize.i14,
                color: hasValue ? t.foreground : t.mutedForeground,
              ),
              const MinimalGap(MinimalChromeMetrics.iconGap),
              Flexible(
                child: minimalCapLabel(
                  Text(
                    label,
                    style: type.c(hasValue ? t.foreground : t.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A create form's row of [MinimalPropertyPill]s, wrapping onto a second
/// line rather than overflowing: the set properties first, then the ones
/// still to choose. Every pill keeps its 44 px target, the first and last
/// lines' included.
///
/// ```dart
/// MinimalPropertyBar(pills: [MinimalPropertyPill(icon: LucideIcons.repeat, label: 'Every evening', hasValue: true, onPressed: pickRepeat), MinimalPropertyPill(icon: LucideIcons.target, label: 'Goal', onPressed: pickGoal)])
/// ```
class MinimalPropertyBar extends StatelessWidget {
  /// A row of [pills].
  const MinimalPropertyBar({super.key, required this.pills});

  /// The pills, start to end.
  final List<MinimalPropertyPill> pills;

  @override
  Widget build(BuildContext context) => MinimalHitTarget(
    line: MinimalChromeMetrics.controlSm,
    child: Wrap(
      spacing: MinimalChromeMetrics.iconGap,
      runSpacing: MinimalChromeMetrics.iconGap,
      children: pills,
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: _PropertyMetrics.dot,
    height: _PropertyMetrics.dot,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Opens [items] as a menu anchored to the widget at [context]; null when
/// there are no items to open.
VoidCallback? _menuOpener(
  BuildContext Function() anchorContext,
  List<MinimalMenuItem>? items,
  String label,
) {
  if (items == null || items.isEmpty) return null;
  return () {
    final context = anchorContext();
    final box = context.findRenderObject()! as RenderBox;
    showMinimalMenu(
      context,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      items: items,
      label: label,
    );
  };
}
