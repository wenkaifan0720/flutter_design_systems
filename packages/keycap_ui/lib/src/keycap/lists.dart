/// Keycap's lists and cards are wells cut into the case: what is raised is
/// pressed, what is sunk is read. A group's rows sit on one well's floor,
/// ruled apart; a pressed row's floor darkens under the finger.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'cap.dart';
import 'internal/row_toggle.dart';
import 'internal/spring_value.dart';
import 'theme.dart';

/// The capitals printed on the case over a group, as a keyboard prints a
/// cluster's name; a screen reader hears it as a heading.
///
/// ```dart
/// const KeycapSectionHeader('Editor')
/// ```
class KeycapSectionHeader extends StatelessWidget {
  /// A header reading [text].
  const KeycapSectionHeader(this.text, {super.key, this.trailing, this.style});

  /// The header's words (printed in capitals).
  final String text;

  /// A text key or a count at its end.
  final Widget? trailing;

  /// Overrides: [DesignStyle.foreground], [DesignStyle.textStyle],
  /// [DesignStyle.padding].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = DesignStyleOf([style], const {});
    final legend = Semantics(
      header: true,
      label: text,
      excludeSemantics: true,
      child: Text(
        text.toUpperCase(),
        // One line, two at a larger text size, as a list row's title.
        maxLines: MediaQuery.textScalerOf(context).scale(16) > 16 ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.legend
            .merge(layered.textStyle)
            .copyWith(color: layered.foreground),
      ),
    );
    return Padding(
      padding:
          layered.padding(Directionality.of(context)) ??
          EdgeInsetsDirectional.only(
            start: KeycapSpacing.regular,
            // A printed key's words (12 in from its edge) end on the rows'.
            end: trailing == null
                ? KeycapSpacing.regular
                : KeycapSpacing.regular - 12,
            top: KeycapSpacing.small,
            bottom: KeycapSpacing.small,
          ),
      child: trailing == null
          ? legend
          : Row(
              children: [
                Expanded(child: legend),
                const SizedBox(width: KeycapSpacing.small),
                trailing!,
              ],
            ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

/// A rule between rows.
///
/// ```dart
/// const KeycapDivider(indent: 16)
/// ```
class KeycapDivider extends StatelessWidget {
  /// A rule.
  const KeycapDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.vertical = false,
  });

  /// Room before it.
  final double indent;

  /// Room after it.
  final double endIndent;

  /// Whether it stands upright, between columns.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final c = KeycapTheme.of(context).colors;
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final color = contrast ? c.inkMuted : c.hairline;
    return Padding(
      padding: vertical
          ? EdgeInsets.only(top: indent, bottom: endIndent)
          : EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: vertical
          ? SizedBox(width: 1, child: ColoredBox(color: color))
          : SizedBox(height: 1, child: ColoredBox(color: color)),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('indent', indent, defaultValue: 0))
      ..add(DoubleProperty('endIndent', endIndent, defaultValue: 0));
  }
}

// Where a row stands in its group: its focus band's corners follow the
// well's on the ends.
class _RowPlace extends InheritedWidget {
  const _RowPlace({
    required this.first,
    required this.last,
    required super.child,
  });

  final bool first;
  final bool last;

  static _RowPlace? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RowPlace>();

  @override
  bool updateShouldNotify(_RowPlace old) =>
      old.first != first || old.last != last;
}

/// A group of rows on one well's floor, ruled apart, with a [header]
/// printed over it and a [footer] under it.
///
/// ```dart
/// KeycapListGroup(header: 'Account', children: [KeycapListTile(title: 'Name', trailingText: 'Mira Okafor')])
/// ```
class KeycapListGroup extends StatelessWidget {
  /// A group of [children].
  const KeycapListGroup({
    super.key,
    required this.children,
    this.header,
    this.headerTrailing,
    this.footer,
    this.style,
  });

  /// The rows: usually [KeycapListTile]s.
  final List<Widget> children;

  /// The capitals over the group.
  final String? header;

  /// A key at the header's end.
  final Widget? headerTrailing;

  /// A note under the group.
  final String? footer;

  /// Overrides for the well, over [KeycapThemeData.wellStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header != null)
          KeycapSectionHeader(header!, trailing: headerTrailing),
        KeycapWell(
          page: true,
          style: style,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, row) in children.indexed) ...[
                if (i > 0)
                  const KeycapDivider(
                    indent: KeycapSpacing.regular,
                    endIndent: KeycapSpacing.regular,
                  ),
                _RowPlace(
                  first: i == 0,
                  last: i == children.length - 1,
                  child: row,
                ),
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: KeycapSpacing.regular,
              end: KeycapSpacing.regular,
              top: KeycapSpacing.small,
            ),
            child: Text(footer!, style: theme.textTheme.secondary),
          ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('header', header, defaultValue: null))
      ..add(IntProperty('rows', children.length));
  }
}

/// A row on a well's floor: a [leading] glyph, a [title] and a [subtitle],
/// and at its end a [trailing] control, [trailingText], or a chevron when it
/// opens something. Pressed, its floor darkens; [selected], it is lit in
/// the modifier tint.
///
/// ```dart
/// KeycapListTile(title: 'Shortcuts', leading: const Icon(LucideIcons.keyboard), onTap: openShortcuts)
/// ```
class KeycapListTile extends StatelessWidget {
  /// A row.
  const KeycapListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.value,
    this.onTap,
    this.selected = false,
    this.showChevron,
    this.isDestructiveAction = false,
    this.enabled = true,
    this.maxTitleLines,
    this.maxSubtitleLines = 1,
    this.semanticLabel,
    this.style,
  });

  /// The row's words.
  final String title;

  /// The most lines [title] wraps to; when null, one (cut with an
  /// ellipsis, as the subtitle is), and two once the reader has made text
  /// larger, so large words still read.
  final int? maxTitleLines;

  /// A supporting line.
  final String? subtitle;

  /// A glyph at its start.
  final Widget? leading;

  /// A control at its end (a switch, a checkbox).
  final Widget? trailing;

  /// A value at its end, printed on the row (a time, a count, a status
  /// such as "Just now"): read, not pressed.
  final String? trailingText;

  /// The value a row that opens a choice holds ("Inbox", "Every minute"),
  /// printed on a small alpha cap at its end ([KeycapValueCap]) that goes
  /// down as the row is pressed. Only for a row whose [onTap] opens a
  /// choice; a row that navigates or shows a status uses [trailingText].
  final String? value;

  /// Called when the row is pressed; null for a row that is only read.
  final VoidCallback? onTap;

  /// Whether the row is the chosen one (the note open beside the list).
  final bool selected;

  /// Whether a chevron says the row opens something; by [onTap] when null.
  final bool? showChevron;

  /// Whether pressing it destroys something.
  final bool isDestructiveAction;

  /// Whether the row is on.
  final bool enabled;

  /// The most lines [subtitle] wraps to.
  final int maxSubtitleLines;

  /// What a screen reader says for the row, when its words are not enough.
  final String? semanticLabel;

  /// Overrides, over [KeycapThemeData.listTileStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final place = _RowPlace.of(context);
    Widget row(Set<WidgetState> states) {
      final layered = DesignStyleOf([style, theme.listTileStyle], states);
      final off = !enabled;
      final ink =
          layered.foreground ??
          (off
              ? c.inkDisabled
              : isDestructiveAction
              ? c.dangerInk
              : c.ink);
      final chevron =
          showChevron ?? (onTap != null && trailing == null && value == null);
      // Density changes a row's height, never where its words start: they
      // line up with the group's header and a card's content at every density.
      const pad = KeycapSpacing.regular;
      final words = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DesignCapCenter(
            capHeightFactor: theme.capHeightFactor,
            child: Text(
              title,
              maxLines:
                  maxTitleLines ??
                  (MediaQuery.textScalerOf(context).scale(16) > 16 ? 2 : 1),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.body
                  .merge(layered.textStyle)
                  .copyWith(
                    color: ink,
                    fontWeight: selected ? FontWeight.w500 : null,
                  ),
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: maxSubtitleLines,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.secondary.copyWith(
                color: off ? c.inkDisabled : c.inkMuted,
              ),
            ),
        ],
      );
      return ConstrainedBox(
        constraints: BoxConstraints(minHeight: theme.controlHeight + 8),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: pad,
            end: pad,
            top: KeycapSpacing.small + 2,
            bottom: KeycapSpacing.small + 2,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                IconTheme.merge(
                  data: IconThemeData(
                    size: 20,
                    color: off
                        ? c.inkDisabled
                        : isDestructiveAction
                        ? c.dangerInk
                        : c.inkMuted,
                  ),
                  child: leading!,
                ),
                const SizedBox(width: KeycapSpacing.medium + 2),
              ],
              Expanded(
                child: value == null
                    ? words
                    : _WordsAndValue(
                        words: words,
                        value: KeycapValueCap(
                          label: value!,
                          pressed: states.contains(WidgetState.pressed),
                          enabled: enabled && onTap != null,
                        ),
                      ),
              ),
              if (trailingText != null) ...[
                const SizedBox(width: KeycapSpacing.medium),
                Flexible(
                  flex: 0,
                  child: Text(
                    trailingText!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.secondary.copyWith(
                      color: off ? c.inkDisabled : c.inkMuted,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...[
                const SizedBox(width: KeycapSpacing.medium),
                trailing!,
              ],
              if (chevron) ...[
                const SizedBox(width: KeycapSpacing.small),
                // Toward the row's end: the left in right-to-left.
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? LucideIcons.chevronLeft
                      : LucideIcons.chevronRight,
                  size: 18,
                  color: off ? c.inkDisabled : c.inkMuted,
                ),
              ],
            ],
          ),
        ),
      );
    }

    Widget floor(Set<WidgetState> states, Widget child) {
      final pressed = states.contains(WidgetState.pressed);
      final focused = states.contains(WidgetState.focused);
      // On a page (a group's), the page's floors; in a small well, the
      // well's.
      final page = KeycapWell.isPage(context);
      final lit = page
          ? c.pageSelected
          : Color.lerp(
              c.well,
              c.modifier.top,
              c.brightness == Brightness.light ? 0.30 : 0.75,
            )!;
      final down = page ? c.pagePressed : c.wellPressed;
      final color = pressed
          ? down
          : selected
          ? lit
          : down.withValues(alpha: 0);
      final outer = KeycapMetrics.wellRadius - KeycapMetrics.focusWidth;
      const inner = 4.0;
      final first = place?.first ?? true;
      final last = place?.last ?? true;
      return KeycapSpringValue(
        value: focused ? 1 : 0,
        spring: KeycapMotion.colour,
        spatial: false,
        builder: (context, f, child) => CustomPaint(
          foregroundPainter: _RowFocus(
            c.focus.withValues(alpha: c.focus.a * f.clamp(0.0, 1.0)),
            BorderRadius.vertical(
              top: Radius.circular(first ? outer : inner),
              bottom: Radius.circular(last ? outer : inner),
            ),
          ),
          child: child,
        ),
        child: KeycapSpringColor(
          color: color,
          darken: KeycapMotion.press,
          lighten: KeycapMotion.release,
          builder: (context, color, child) =>
              ColoredBox(color: color, child: child),
          child: child,
        ),
      );
    }

    final label = semanticLabel;
    if (onTap == null || !enabled) {
      return MergeSemantics(
        child: Semantics(
          label: label,
          child: floor({if (!enabled) WidgetState.disabled}, row(const {})),
        ),
      );
    }
    return RawButton(
      onPressed: onTap,
      selected: selected,
      semanticSelected: selected ? true : null,
      semanticLabel: label,
      semanticValue: value,
      // A switch row says it is on or off, not that it is a button.
      toggled: KeycapRowToggle.of(context),
      builder: (context, states, _) => floor(states, row(states)),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

class _RowFocus extends CustomPainter {
  _RowFocus(this.color, this.radius);

  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (color.a == 0) return;
    const w = KeycapMetrics.focusWidth;
    final rect = (Offset.zero & size).deflate(w + w / 2);
    canvas.drawRRect(
      radius.toRRect(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RowFocus old) =>
      old.color != color || old.radius != radius;
}

/// A card: a well cut into the case, holding one thing (a note, a
/// summary). With [onTap] its floor darkens as it is pressed and a focus
/// band lights inside its edge.
///
/// ```dart
/// KeycapCard(onTap: open, child: Text(note.title))
/// ```
class KeycapCard extends StatelessWidget {
  /// A card round [child].
  const KeycapCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.semanticLabel,
    this.style,
  });

  /// What the card holds.
  final Widget child;

  /// The room round it; [defaultPadding] when null.
  final EdgeInsetsGeometry? padding;

  /// Called when the card is pressed.
  final VoidCallback? onTap;

  /// What a screen reader says for a pressable card.
  final String? semanticLabel;

  /// Overrides, over [KeycapThemeData.wellStyle].
  final KeycapStyle? style;

  /// The room inside a card.
  static const EdgeInsets defaultPadding = EdgeInsets.all(
    KeycapSpacing.regular,
  );

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    Widget well(Set<WidgetState> states) {
      final layered = DesignStyleOf([style, theme.wellStyle], states);
      return KeycapWell(
        page: true,
        style: style,
        floor: states.contains(WidgetState.pressed) ? c.pagePressed : null,
        rim: states.contains(WidgetState.focused) ? c.focus : null,
        padding:
            layered.padding(Directionality.of(context)) ??
            padding ??
            defaultPadding,
        child: child,
      );
    }

    if (onTap == null) return well(const {});
    return RawButton(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => well(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      FlagProperty('pressable', value: onTap != null, ifTrue: 'pressable'),
    );
  }
}

/// The small alpha cap a row that opens a choice carries at its end, its
/// legend the value the row holds ("Inbox"). It is pressed with its row:
/// [pressed] takes it down onto its switch. The row is the tap target; the
/// cap is what says the row is a key to press.
///
/// ```dart
/// KeycapValueCap(label: 'Inbox', pressed: states.contains(WidgetState.pressed))
/// ```
class KeycapValueCap extends StatelessWidget {
  /// A cap reading [label].
  const KeycapValueCap({
    super.key,
    required this.label,
    this.pressed = false,
    this.enabled = true,
  });

  /// The value.
  final String label;

  /// Whether its row is held down.
  final bool pressed;

  /// Whether its row can be pressed.
  final bool enabled;

  /// The cap's height: a small key, under a row's.
  static const double height = 32;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final face = keycapKeyFace(theme, KeycapKind.alpha, {
      if (pressed) WidgetState.pressed,
      if (!enabled) WidgetState.disabled,
    }).copyWith(radius: KeycapMetrics.smallKeyRadius);
    final tall = KeycapMetrics.grown(
      context,
      height,
      theme.textTheme.secondary,
    );
    final walls = KeycapMetrics.walls(tall);
    return ExcludeSemantics(
      child: SizedBox(
        height: tall,
        child: AnimatedKeycapCap(
          face: face,
          walls: walls,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(
              start: KeycapSpacing.small + 2,
              end: KeycapSpacing.small,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: DesignCapCenter(
                    capHeightFactor: theme.capHeightFactor,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.secondary.copyWith(
                        color: face.legend,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: KeycapSpacing.tight),
                // The select's sign: what opens a choice ends in it.
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: enabled
                      ? theme.colors.inkMuted
                      : theme.colors.inkDisabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('pressed', value: pressed, ifTrue: 'pressed'));
  }
}

/// A row's words with its value cap at their end, or under them when the two
/// don't fit side by side without breaking a word (large text on a phone):
/// beside the cap the words take the room left, never less than their
/// longest word.
class _WordsAndValue extends MultiChildRenderObjectWidget {
  _WordsAndValue({required Widget words, required Widget value})
    : super(children: [words, value]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWordsAndValue(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWordsAndValue renderObject,
  ) => renderObject.textDirection = Directionality.of(context);
}

class _WordsAndValueData extends ContainerBoxParentData<RenderBox> {}

class _RenderWordsAndValue extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _WordsAndValueData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _WordsAndValueData> {
  _RenderWordsAndValue(this._textDirection);

  // The row's gap between its words and what ends it, and the step under
  // the words when the cap goes below them.
  static const double _gap = KeycapSpacing.medium;
  static const double _under = KeycapSpacing.tight;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _words => firstChild!;
  RenderBox get _value => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WordsAndValueData) {
      child.parentData = _WordsAndValueData();
    }
  }

  double get _valueWidth => _value.getMaxIntrinsicWidth(double.infinity);

  bool _beside(double width) =>
      !width.isFinite ||
      _words.getMinIntrinsicWidth(double.infinity) + _gap + _valueWidth <=
          width;

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _words.getMinIntrinsicWidth(double.infinity),
    _value.getMinIntrinsicWidth(double.infinity),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _words.getMaxIntrinsicWidth(double.infinity) + _gap + _valueWidth;

  double _height(double width, double Function(RenderBox, double) of) {
    if (_beside(width)) {
      final value = math.min(_valueWidth, width);
      return math.max(
        of(_words, math.max(0, width - _gap - value)),
        of(_value, value),
      );
    }
    return of(_words, width) + _under + of(_value, width);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMinIntrinsicHeight(w));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(width, (c, w) => c.getMaxIntrinsicHeight(w));

  /// Lays both out by [layout] and returns the size and the two offsets.
  (Size, Offset, Offset) _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox, BoxConstraints) layout,
  ) {
    final width = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final rtl = _textDirection == TextDirection.rtl;
    final value = layout(_value, BoxConstraints(maxWidth: width));
    if (_beside(width)) {
      final words = layout(
        _words,
        BoxConstraints.tightFor(width: math.max(0, width - _gap - value.width)),
      );
      final size = constraints.constrain(
        Size(width, math.max(words.height, value.height)),
      );
      return (
        size,
        Offset(
          rtl ? size.width - words.width : 0,
          (size.height - words.height) / 2,
        ),
        Offset(
          rtl ? 0 : size.width - value.width,
          (size.height - value.height) / 2,
        ),
      );
    }
    final words = layout(_words, BoxConstraints.tightFor(width: width));
    final size = constraints.constrain(
      Size(width, words.height + _under + value.height),
    );
    return (
      size,
      Offset.zero,
      Offset(rtl ? size.width - value.width : 0, words.height + _under),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, (c, b) => c.getDryLayout(b)).$1;

  @override
  void performLayout() {
    final (size, words, value) = _arrange(constraints, (c, b) {
      c.layout(b, parentUsesSize: true);
      return c.size;
    });
    this.size = size;
    (_words.parentData! as _WordsAndValueData).offset = words;
    (_value.parentData! as _WordsAndValueData).offset = value;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
