/// Clay's lists: a section's header, a raised slab of rows, a row, a card,
/// and the small tinted ball a row's glyph sits in.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'surface.dart';
import 'theme.dart';

/// A section's header over a group: its [text] in the label face, the
/// secondary ink, on the rows' keyline; a [trailing] action (a text button)
/// at its end.
///
/// ```dart
/// const ClaySectionHeader('Morning')
/// ```
class ClaySectionHeader extends StatelessWidget {
  /// A header reading [text].
  const ClaySectionHeader(this.text, {super.key, this.trailing, this.style});

  /// The words.
  final String text;

  /// An action at its end.
  final Widget? trailing;

  /// This header's own style, over [ClayThemeData.sectionHeaderStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final layered = RawStyleOf([style, theme.sectionHeaderStyle], const {});
    final words = theme.textTheme.label
        .copyWith(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          fontVariations: clayWeight(FontWeight.w600),
          color: layered.foreground ?? theme.colors.inkSecondary,
        )
        .merge(layered.textStyle);
    return Semantics(
      header: true,
      child: Padding(
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsetsDirectional.only(
              start: ClaySpacing.roomy,
              end: ClaySpacing.small,
              top: ClaySpacing.regular,
              bottom: ClaySpacing.small,
            ),
        child: trailing == null
            ? Text(text, style: words)
            : Row(
                children: [
                  Expanded(child: Text(text, style: words)),
                  trailing!,
                ],
              ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

/// A group of rows on one raised slab of white clay, rounded 24, a faint
/// groove between rows, with an optional [header] above and [footer] under.
///
/// ```dart
/// ClayGroup(header: 'Reminders', children: [ClayListTile(title: 'Morning check-in', trailingText: '8:00')])
/// ```
class ClayGroup extends StatelessWidget {
  /// A slab holding [children].
  const ClayGroup({
    super.key,
    required this.children,
    this.header,
    this.headerTrailing,
    this.footer,
    this.dividerIndent,
    this.style,
  });

  /// The rows.
  final List<Widget> children;

  /// A header over the slab.
  final String? header;

  /// An action at the header's end.
  final Widget? headerTrailing;

  /// A note under the slab.
  final String? footer;

  /// Where the grooves between rows start; by default the first row's words.
  final double? dividerIndent;

  /// This group's own style, over [ClayThemeData.groupStyle]: `fill` the
  /// slab.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.groupStyle], const {});
    final first = children.isEmpty ? null : children.first;
    final indent =
        dividerIndent ??
        (first is ClayListTile && first.leading != null
            ? ClayListTile.leadingExtent
            : ClaySpacing.roomy);
    final radius = clayRadiusOf(layered.shape, ClayRadius.large);
    return RawKeylineRegion(
      label: header ?? 'Group',
      indents: [indent],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            ClaySectionHeader(header!, trailing: headerTrailing),
          ClaySurface(
            face: ClayFace.raised(c, color: layered.fill, radius: radius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, row) in children.indexed) ...[
                  // Inset at both ends, so no groove runs into the slab's
                  // rounded edge.
                  if (i > 0)
                    ClayGroove(indent: indent, endIndent: ClaySpacing.roomy),
                  row,
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: ClaySpacing.roomy,
                end: ClaySpacing.roomy,
                top: ClaySpacing.small,
              ),
              child: Text(footer!, style: theme.textTheme.secondary),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('header', header, defaultValue: null))
      ..add(StringProperty('footer', footer, defaultValue: null))
      ..add(IntProperty('rows', children.length));
  }
}

/// The faint groove between two rows on a slab: a 1 px line of the well's
/// colour from [indent] to [endIndent], pressed into the clay rather than
/// drawn on it.
///
/// ```dart
/// const ClayGroove(indent: 20)
/// ```
class ClayGroove extends StatelessWidget {
  /// A groove from [indent] to [endIndent].
  const ClayGroove({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.style,
  });

  /// Where it starts.
  final double indent;

  /// How far before the end it stops.
  final double endIndent;

  /// Its own style, over [ClayThemeData.grooveStyle]: `side` its colour
  /// and thickness (or `edge` its colour alone).
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final night = c.brightness == Brightness.dark;
    final layered = RawStyleOf([style, theme.grooveStyle], const {});
    final side = layered.side;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: Container(
        height: side?.width ?? 1,
        color:
            side?.color ??
            layered.edge ??
            (night ? c.well.withValues(alpha: 0.7) : c.well),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('indent', indent))
      ..add(DoubleProperty('endIndent', endIndent));
  }
}

/// A row: [title], a [subtitle] under it, a [leading] glyph or badge, and at
/// its end a [trailingText] value, a [trailing] control or a chevron when it
/// opens something. A press opens a soft well under the row, inset 6 px all
/// round; [selected] warms that plate toward the accent and keeps it.
///
/// ```dart
/// ClayListTile(title: 'Reminders', subtitle: 'Every day at 8:00', onTap: () {})
/// ```
class ClayListTile extends StatelessWidget {
  /// A row titled [title].
  const ClayListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.trailingText,
    this.onTap,
    this.selected = false,
    this.checked,
    this.toggled,
    this.showChevron,
    this.isDestructiveAction = false,
    this.enabled = true,
    this.semanticLabel,
    this.style,
  });

  /// The row's words.
  final String title;

  /// A second line under them.
  final String? subtitle;

  /// A glyph or a badge before them.
  final Widget? leading;

  /// A control at the row's end (a switch, a checkbox).
  final Widget? trailing;

  /// A value at the row's end.
  final String? trailingText;

  /// Called when the row is pressed; null: the row is not a control.
  final VoidCallback? onTap;

  /// Whether the row is the one shown beside the list (a list beside its
  /// detail).
  final bool selected;

  /// Whether the row is itself a checkbox (a trailing `ClayCheckbox` its
  /// press ticks), and ticked: a screen reader hears a checkbox and its
  /// state, not a button. Null: an ordinary row.
  final bool? checked;

  /// Whether the row is itself a switch (a trailing `ClaySwitch` its press
  /// turns), and on: a screen reader hears a switch and its state, not a
  /// button. Null: an ordinary row.
  final bool? toggled;

  /// Whether a chevron shows at the end; by default when [onTap] is set and
  /// no [trailing] control is.
  final bool? showChevron;

  /// Whether the row destroys something: its words in the danger ink.
  final bool isDestructiveAction;

  /// Whether the row is on.
  final bool enabled;

  /// What a screen reader says for the row, when not its words.
  final String? semanticLabel;

  /// This row's own style, over [ClayThemeData.listTileStyle].
  final ClayStyle? style;

  /// Where a row's contents start and end inside it: what else shares a
  /// card with rows (a ring, a heading) stands this far in, on their line.
  static const double inset = ClaySpacing.regular;

  /// Where a row's words start when it has a leading glyph: the margin, a
  /// 36 px badge and the gap after it.
  static const double leadingExtent = inset + 36 + ClaySpacing.medium;

  /// The inset a row's plate keeps from the row's edges, all round.
  static const double plateInset = ClaySpacing.tight;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    Widget body(Set<WidgetState> states) {
      final layered = RawStyleOf(
        [style, theme.listTileStyle],
        {...states, if (selected) WidgetState.selected},
      );
      final disabled = !enabled;
      final pressed = states.contains(WidgetState.pressed);
      final hovered = states.contains(WidgetState.hovered);
      final focused = states.contains(WidgetState.focused);
      final ink =
          layered.foreground ??
          (disabled
              ? c.inkDisabled
              : isDestructiveAction
              ? c.dangerInk
              : c.ink);
      final muted = disabled ? c.inkDisabled : c.inkSecondary;
      final chevron = showChevron ?? (onTap != null && trailing == null);
      final rowHeight = subtitle == null
          ? theme.rowHeight
          : theme.rowHeight + 12;
      final largeText = MediaQuery.textScalerOf(context).scale(10) >= 15;
      final plateRadius = ClayRadius.large - plateInset;
      final chosen = selected && !disabled;
      final well = ClayFace.well(c, radius: plateRadius);
      final ClayFace plate;
      if (pressed) {
        plate = well;
      } else if (chosen) {
        // The chosen row's plate: the clay warmed toward the accent, level
        // with the slab.
        plate = ClayFace.flat(
          c,
          color: clayChosenFill(c),
          radius: plateRadius,
        ).copyWith(elevation: 0, shadowOpacity: 0, lightOpacity: 0.5);
      } else {
        // At rest no plate; under the pointer or the keys, a breath of the
        // well with no depth yet.
        plate = well.copyWith(
          color: well.color.withValues(alpha: hovered || focused ? 0.55 : 0),
          lightOpacity: 0,
          shadeOpacity: 0,
        );
      }
      final shown = plate.copyWith(focus: focused ? 1 : 0, focusColor: c.focus);
      return Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(plateInset),
              child: AnimatedClaySurface(face: shown),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: rowHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: inset,
                vertical: ClaySpacing.small + 2,
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  final titleStyle = theme.textTheme.body
                      .copyWith(
                        color: ink,
                        fontWeight: FontWeight.w500,
                        fontVariations: clayWeight(FontWeight.w500),
                      )
                      .merge(layered.textStyle);
                  final heading = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (leading != null) ...[
                        IconTheme.merge(
                          data: IconThemeData(
                            size: 20,
                            color: disabled ? c.inkDisabled : c.inkSecondary,
                          ),
                          child: SizedBox(
                            width: 36,
                            child: Center(child: leading),
                          ),
                        ),
                        const SizedBox(width: ClaySpacing.medium),
                      ],
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RawCapCenter(
                              capHeightFactor: clayCapHeightFactor,
                              child: Text(title, style: titleStyle),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: theme.textTheme.secondary.copyWith(
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                  double titleFloorOf(double width) {
                    final painter = TextPainter(
                      text: TextSpan(text: title, style: titleStyle),
                      textDirection: Directionality.of(context),
                      textScaler: MediaQuery.textScalerOf(context),
                      maxLines: 1,
                    )..layout();
                    final w = painter.width;
                    painter.dispose();
                    final lead = leading == null ? 0 : 36 + ClaySpacing.medium;
                    return math.min(lead + w + 1, width / 2);
                  }

                  final chevronMark = Transform.flip(
                    flipX: Directionality.of(context) == TextDirection.rtl,
                    child: SizedBox(
                      width: 8,
                      height: 14,
                      child: CustomPaint(
                        painter: ClayChevronRightPainter(
                          disabled ? c.inkDisabled : c.inkSecondary,
                        ),
                      ),
                    ),
                  );
                  final valueStyle = theme.textTheme.body.copyWith(
                    color: muted,
                  );
                  // Under large text, on a row narrower than twelve of its
                  // words' ems (a phone's), the row's end (its value, its
                  // control) stands under its words at the row's end, as
                  // list rows stack at large text: the words keep the row's
                  // width rather than break a word a line beside it. A list's
                  // rows share their width, so they all stack or none do. On
                  // a wider row (a desk's pane) the end stays beside its
                  // words where both fit, and a part too wide for that goes
                  // under them. The chevron stays beside.
                  final scaler = MediaQuery.textScalerOf(context);
                  final em = scaler.scale(titleStyle.fontSize ?? 16);
                  final narrow = box.maxWidth < 12 * em;
                  if (largeText &&
                      narrow &&
                      (trailing != null || trailingText != null)) {
                    final under = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (trailingText != null)
                          Flexible(
                            child: Text(
                              trailingText!,
                              textAlign: TextAlign.end,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: valueStyle,
                            ),
                          ),
                        if (trailing != null) ...[
                          if (trailingText != null)
                            const SizedBox(width: ClaySpacing.medium),
                          Flexible(child: trailing!),
                        ],
                      ],
                    );
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              heading,
                              const SizedBox(height: ClaySpacing.small),
                              Align(
                                alignment: AlignmentDirectional.centerEnd,
                                child: under,
                              ),
                            ],
                          ),
                        ),
                        if (chevron) ...[
                          const SizedBox(width: ClaySpacing.small),
                          chevronMark,
                        ],
                      ],
                    );
                  }
                  final end = [
                    if (trailingText != null)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: box.maxWidth.isFinite
                              ? box.maxWidth * 0.45
                              : double.infinity,
                        ),
                        child: Text(
                          trailingText!,
                          textAlign: TextAlign.end,
                          maxLines: largeText ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: valueStyle,
                        ),
                      ),
                    if (trailing != null) ...[
                      if (trailingText != null)
                        const SizedBox(width: ClaySpacing.medium),
                      // Under large text it may take a line of its own: it
                      // is bounded by the row's width, never its natural one.
                      if (largeText)
                        Flexible(child: trailing!)
                      else
                        // The title keeps its one line beside it (up to half
                        // the row): a wide part shrinks rather than crush the
                        // title into a column of letters.
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: math.max(
                              0,
                              box.maxWidth -
                                  titleFloorOf(box.maxWidth) -
                                  ClaySpacing.medium -
                                  (chevron ? ClaySpacing.regular : 0),
                            ),
                          ),
                          child: trailing,
                        ),
                    ],
                    if (chevron) ...[
                      if (trailingText != null || trailing != null)
                        const SizedBox(width: ClaySpacing.small),
                      chevronMark,
                    ],
                  ];
                  if (largeText && trailing != null) {
                    return _HeadingAndEnd(
                      heading: heading,
                      end: Row(mainAxisSize: MainAxisSize.min, children: end),
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: heading),
                      if (end.isNotEmpty)
                        SizedBox(
                          width: trailing != null || trailingText != null
                              ? ClaySpacing.medium
                              : ClaySpacing.small,
                        ),
                      ...end,
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    if (onTap == null) {
      return Semantics(
        container: true,
        selected: selected ? true : null,
        label: semanticLabel,
        child: body({if (!enabled) WidgetState.disabled}),
      );
    }
    return RawButton(
      onPressed: enabled ? onTap : null,
      selected: selected,
      semanticSelected: selected ? true : null,
      checked: checked,
      toggled: toggled,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => body(states),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(StringProperty('subtitle', subtitle, defaultValue: null))
      ..add(StringProperty('trailingText', trailingText, defaultValue: null))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(DiagnosticsProperty<bool>('checked', checked, defaultValue: null))
      ..add(DiagnosticsProperty<bool>('toggled', toggled, defaultValue: null))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'))
      ..add(
        FlagProperty(
          'isDestructiveAction',
          value: isDestructiveAction,
          ifTrue: 'destructive',
        ),
      );
  }
}

/// A rounded chevron pointing to the end (a row that opens something).
class ClayChevronRightPainter extends CustomPainter {
  /// A chevron of [color].
  ClayChevronRightPainter(this.color);

  /// Its colour.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.2, size.height * 0.12)
        ..lineTo(size.width * 0.8, size.height * 0.5)
        ..lineTo(size.width * 0.2, size.height * 0.88),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(ClayChevronRightPainter old) => old.color != color;
}

/// A small ball of tinted clay holding a glyph: a habit's mark, a setting's
/// kind. [tint] picks one of the look's pastels; at night they are deep.
///
/// ```dart
/// const ClayIconTile(tint: ClayTint.mint, child: Icon(IconData(0x41)))
/// ```
class ClayIconTile extends StatelessWidget {
  /// A tile of [tint] holding [child].
  const ClayIconTile({
    super.key,
    required this.child,
    this.tint = ClayTint.lilac,
    this.color,
    this.size = 36,
    this.style,
  });

  /// The glyph.
  final Widget child;

  /// Which pastel it is moulded in.
  final ClayTint tint;

  /// A colour of its own instead of [tint].
  final Color? color;

  /// Its side.
  final double size;

  /// This tile's own style, over [ClayThemeData.iconTileStyle]: `fill` the
  /// ball (over [tint] and [color]), `foreground` the glyph.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.iconTileStyle], const {});
    final fill = layered.fill ?? color ?? c.tint(tint);
    return SizedBox.square(
      dimension: size,
      child: ClaySurface(
        face: ClayFace.raised(c, color: fill, radius: size * 0.36),
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(
              size: size * 0.5,
              color: layered.foreground ?? c.onColor(fill),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<ClayTint>('tint', tint))
      ..add(DoubleProperty('size', size));
  }
}

/// A Clay card: a raised slab of white clay, rounded 24, padded 20, holding
/// [child]. With [onTap] it is a control: a press squashes it in.
///
/// ```dart
/// ClayCard(onTap: () {}, child: const Text('Drink water'))
/// ```
class ClayCard extends StatelessWidget {
  /// A card holding [child].
  const ClayCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(ClaySpacing.roomy),
    this.color,
    this.semanticLabel,
    this.style,
  });

  /// What the card holds.
  final Widget child;

  /// Called when the card is pressed; null: it is not a control.
  final VoidCallback? onTap;

  /// The room round [child].
  final EdgeInsetsGeometry padding;

  /// Its clay's colour (a pastel); white clay by default.
  final Color? color;

  /// What a screen reader says for a pressable card.
  final String? semanticLabel;

  /// This card's own style, over [ClayThemeData.cardStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    Widget face(Set<WidgetState> states) {
      final layered = RawStyleOf([style, theme.cardStyle], states);
      final fill = color ?? layered.fill ?? c.clay;
      final radius = clayRadiusOf(layered.shape, ClayRadius.large);
      return AnimatedClaySurface(
        face: ClayFace.raised(c, color: fill, radius: radius).copyWith(
          press: states.contains(WidgetState.pressed) ? 0.6 : 0,
          lift: states.contains(WidgetState.hovered) ? 0.6 : 0,
          focus: states.contains(WidgetState.focused) ? 1 : 0,
        ),
        child: Padding(
          padding: layered.padding(Directionality.of(context)) ?? padding,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: c.onColor(fill)),
            child: child,
          ),
        ),
      );
    }

    if (onTap == null) return face(const {});
    return RawButton(
      onPressed: onTap,
      semanticLabel: semanticLabel,
      builder: (context, states, _) => face(states),
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

/// A row's heading at its start and its [end] part at its end, beside it
/// when the two fit on one line, else under it, still at the end: the
/// heading keeps its start either way.
class _HeadingAndEnd extends MultiChildRenderObjectWidget {
  _HeadingAndEnd({required Widget heading, required Widget end})
    : super(children: [heading, end]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeadingAndEnd(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeadingAndEnd renderObject,
  ) {
    renderObject.textDirection = Directionality.of(context);
  }
}

class _HeadingAndEndData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeadingAndEnd extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeadingAndEndData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeadingAndEndData> {
  _RenderHeadingAndEnd(this._textDirection);

  // Between the heading and the part beside it, and above the part under it.
  static const double _gap = ClaySpacing.medium;
  static const double _runGap = ClaySpacing.small;

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeadingAndEndData) {
      child.parentData = _HeadingAndEndData();
    }
  }

  RenderBox get _heading => firstChild!;
  RenderBox get _end => lastChild!;

  // Lays the two out (or measures them dry) and says where each goes.
  (Size, Offset, Offset) _arrange(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints constraints) size,
  ) {
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    final end = size(_end, loose);
    final heading = size(_heading, loose);
    // Unbounded, the two stand side by side at their own widths.
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : heading.width + _gap + end.width;
    final beside = heading.width + _gap + end.width <= width;
    final rtl = _textDirection == TextDirection.rtl;
    double startOf(double w) => rtl ? width - w : 0;
    double endOf(double w) => rtl ? 0 : width - w;
    if (beside) {
      final height = math.max(heading.height, end.height);
      return (
        constraints.constrain(Size(width, height)),
        Offset(startOf(heading.width), (height - heading.height) / 2),
        Offset(endOf(end.width), (height - end.height) / 2),
      );
    }
    return (
      constraints.constrain(Size(width, heading.height + _runGap + end.height)),
      Offset(startOf(heading.width), 0),
      Offset(endOf(end.width), heading.height + _runGap),
    );
  }

  @override
  void performLayout() {
    final (box, heading, end) = _arrange(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    size = box;
    (_heading.parentData! as _HeadingAndEndData).offset = heading;
    (_end.parentData! as _HeadingAndEndData).offset = end;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, (child, c) => child.getDryLayout(c)).$1;

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _heading.getMinIntrinsicWidth(height),
    _end.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _heading.getMaxIntrinsicWidth(height) +
      _gap +
      _end.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _arrange(
    BoxConstraints(maxWidth: width),
    (child, c) => child.getDryLayout(c),
  ).$1.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
