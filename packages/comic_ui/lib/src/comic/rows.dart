// Rows and lists. Each row draws its own 2 px rule on its top edge; in a list the first has none.
import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'layout.dart';
import 'theme.dart';
import 'press.dart';
import 'component_themes.dart';
import 'internal/row_frame.dart';
import 'styled.dart';
import 'internal/cap_label.dart';

/// A row with a rule on its top edge. [strong] is the 3 px contour a total stands under.
///
/// ```dart
/// ComicRuled(child: Text('A row'))
/// ```
class ComicRuled extends StatelessWidget {
  /// Creates a [ComicRuled].
  const ComicRuled({
    super.key,
    required this.child,
    this.rule = true,
    this.strong = false,
  });

  /// Content placed inside this widget.
  final Widget child;

  /// [rule]: whether to draw a separating rule. [strong]: uses the emphasized rule or ink treatment.
  final bool rule, strong;
  @override
  Widget build(BuildContext context) {
    if (!rule) return child;
    final t = ComicTheme.of(context), c = t.colors;
    return _Ruled(
      color: strong ? c.nightLine : c.divider,
      thickness: strong ? t.rim(3) : t.rule(2),
      lights: RowFrame.lightsOf(context),
      reach: RowFrame.reachOf(context) + RowFrame.endsOf(context),
      child: child,
    );
  }
}

class _Ruled extends SingleChildRenderObjectWidget {
  const _Ruled({
    required this.color,
    required this.thickness,
    required this.lights,
    required this.reach,
    required super.child,
  });
  final Color color;
  final double thickness;
  final RowLights? lights;
  final EdgeInsets reach;

  @override
  _RenderRuled createRenderObject(BuildContext context) =>
      _RenderRuled(color, thickness, lights, reach);

  @override
  void updateRenderObject(BuildContext context, _RenderRuled renderObject) {
    renderObject
      ..color = color
      ..thickness = thickness
      ..lights = lights
      ..reach = reach;
  }
}

class _RenderRuled extends RenderShiftedBox {
  _RenderRuled(this._color, this._thickness, this._lights, this._reach)
    : super(null);

  // In a group, the rule stands aside where a lit row meets it, and the row's press reaches past its edges.
  RowLights? _lights;
  set lights(RowLights? value) {
    if (value == _lights) return;
    if (attached) _lights?.removeListener(markNeedsPaint);
    _lights = value;
    if (attached) _lights?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  EdgeInsets _reach;
  set reach(EdgeInsets value) {
    if (value == _reach) return;
    _reach = value;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _lights?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _lights?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final reach = Rect.fromLTRB(
      -_reach.left,
      -_reach.top,
      size.width + _reach.right,
      size.height + _reach.bottom,
    );
    if (!reach.contains(position)) return false;
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  Color _color;
  double _thickness;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    markNeedsPaint();
  }

  set thickness(double value) {
    if (_thickness == value) return;
    _thickness = value;
    markNeedsLayout();
  }

  EdgeInsets get _inset => EdgeInsets.only(top: _thickness);
  double _height(double height) => height == 0 ? 0 : height + _thickness;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _height(child?.getMinIntrinsicHeight(width) ?? 0);
  @override
  double computeMaxIntrinsicHeight(double width) =>
      _height(child?.getMaxIntrinsicHeight(width) ?? 0);
  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(math.max(0, height - _thickness)) ?? 0;
  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(math.max(0, height - _thickness)) ?? 0;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    final size = child.getDryLayout(constraints.deflate(_inset));
    return constraints.constrain(Size(size.width, _height(size.height)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.deflate(_inset), parentUsesSize: true);
    final height = child.size.height;
    (child.parentData! as BoxParentData).offset = Offset(
      0,
      height == 0 ? 0 : _thickness,
    );
    size = constraints.constrain(Size(child.size.width, _height(height)));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final span = _lights?.spanOf(this);
    final aside =
        span != null && _lights!.touches(span.$1, span.$1 + _thickness);
    if ((child?.size.height ?? 0) > 0 && !aside) {
      context.canvas.drawRect(
        Rect.fromLTWH(offset.dx, offset.dy, size.width, _thickness),
        Paint()..color = _color,
      );
    }
    super.paint(context, offset);
  }
}

/// Stacks rows and shares a panel's slack evenly among them, so a list in a taller panel doesn't end on a hole. Wrap it in
/// `ComicGrow` when it should take that slack.
///
/// ```dart
/// ComicList(children: [ComicKvRow('Fat', '12 g', isFirst: true), ComicKvRow('Salt', '1 g')])
/// ```
class ComicList extends StatelessWidget {
  /// Creates a [ComicList].
  const ComicList({super.key, required this.children, this.gap = 0});

  /// Child widgets in their display order.
  final List<Widget> children;

  /// Space between adjacent children in logical pixels.
  final double gap;
  @override
  Widget build(BuildContext context) => ComicColumn(
    gap: gap,
    children: [for (final c in children) ComicGrow(child: c)],
  );
}

/// A label at the start, a value at the end, on one baseline, and [share] if there's a third figure, in the lettering or the
/// number face by its size. Neither word crushes the other.
///
/// ```dart
/// ComicKvRow('Protein', '26 g', share: '52%')
/// ```
class ComicKvRow extends StatelessWidget {
  /// Creates a [ComicKvRow].
  const ComicKvRow(
    this.label,
    this.value, {
    super.key,
    this.note,
    this.share,
    this.isFirst = false,
    this.quiet = false,
    this.selected = false,
  });

  /// [label]: the visible or spoken name of the component. [value]: the current value represented by the control or record.
  final String label, value;

  /// [note]: secondary explanatory text. [share]: the amount or share represented by this entry.
  final String? note, share;

  /// Omits a separating rule before the first entry.
  final bool isFirst;

  /// A part of the row above: indented and quiet.
  final bool quiet;

  /// The row that matters: its share stands on the lamp.
  final bool selected;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    return ComicRuled(
      rule: !isFirst,
      child: Padding(
        padding: EdgeInsets.fromLTRB(quiet ? 14 : 0, 7, 0, 7),
        child: ComicFitRow(
          fill: 0,
          gap: 10,
          align: ComicFitAlign.baseline,
          fillShare: .3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: quiet
                      ? t.type.text(
                          16,
                          1.3,
                          weight: FontWeight.w600,
                          color: c.textSecondary,
                        )
                      : t.type.title.leading(1.3),
                ),
                if (note != null) Text(note!, style: t.type.meta),
              ],
            ),
            Text(
              value,
              textAlign: TextAlign.end,
              style: t.type.data.copyWith(fontSize: 16).leading(1.3).tabular,
            ),
            if (share != null)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: selected
                      ? DecoratedBox(
                          decoration: ShapeDecoration(
                            color: c.caption,
                            shape: t.shapes.capsule.copyWith(
                              side: BorderSide(
                                color: c.nightLine,
                                width: t.rim(2),
                              ),
                            ),
                          ),
                          // 4 px of paper inside the rim, past the capsule's curve.
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 7,
                            ),
                            child: Text(
                              share!,
                              style: t.type.data.copyWith(color: c.onCaption),
                            ),
                          ),
                        )
                      : Text(share!, style: t.type.data),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The row a list of numbers ends on, under the full contour: a word, a big lettered value.
///
/// ```dart
/// ComicTotalRow('Your share', '€145 each')
/// ```
class ComicTotalRow extends StatelessWidget {
  /// Creates a [ComicTotalRow].
  const ComicTotalRow(this.label, this.value, {super.key, this.note});

  /// [label]: the visible or spoken name of the component. [value]: the current value represented by the control or record.
  final String label, value;

  /// Secondary explanatory text.
  final String? note;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicRuled(
      strong: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: ComicFitRow(
          fill: 0,
          gap: 10,
          fillShare: .3,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: t.type.data.copyWith(fontSize: 16)),
                if (note != null) Text(note!, style: t.type.meta),
              ],
            ),
            Text(
              value.toUpperCase(),
              style: t.type.letter(32, lineHeight: .95),
            ),
          ],
        ),
      ),
    );
  }
}

/// The list row: a mark, a title and its meta, a figure or state beside them, an action. Any row of a list that holds more than
/// a label and a value is this one, with or without the action. A compact action stays beside the words when their
/// measured widths leave a readable text column; long actions and enlarged text stack. Rows with both a trailing
/// value and an action keep the action below on narrow screens.
///
/// ```dart
/// ComicListTile(title: 'Bring the tent', subtitle: 'Sat 09:00', leading: ComicPerson(initials: 'AB', size: 28), trailing: const ComicTag('Packed'), action: ComicButton('Open', size: ComicButtonSize.small, onPressed: () {}))
/// ```
class ComicListTile extends StatelessWidget {
  /// Creates a [ComicListTile].
  const ComicListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.note,
    this.leading,
    this.trailing,
    this.action,
    this.onPressed,
    this.isFirst = false,
    this.label,
    this.selected = false,
    this.destructive = false,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// The primary heading.
  final String title;

  /// False: a row that opens something can't be pressed for now, its words faded. A row with no [onPressed] is a
  /// plain row of words, not a disabled one.
  final bool enabled;

  /// Overrides the spoken row name.
  final String? label;

  /// Selection and destructive emphasis.
  final bool selected, destructive;

  /// [subtitle]: secondary information printed with the entry. [note]: secondary explanatory text.
  final String? subtitle, note;

  /// A `ComicPerson`, a `ComicMark`, a `ComicCheckbox`, a `ComicMedia(width: 56)`: its own width stays.
  final Widget? leading;

  /// A figure or a `ComicTag` beside the title, or below when it needs more room.
  final Widget? trailing;

  /// A `ComicButton(size: ComicButtonSize.small)` or `ComicButton`, one or two words.
  final Widget? action;

  /// The whole row opens something.
  final VoidCallback? onPressed;

  /// No rule above: the first row of a list.
  final bool isFirst;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    // Keep nested actions outside the row's named activation node.
    if (onPressed != null && action != null) {
      // The row and its action share one line: inside a group the row keeps a fill of its own beside the action.
      final main = ComicListTile(
        title: title,
        subtitle: subtitle,
        note: note,
        leading: leading,
        trailing: trailing,
        onPressed: onPressed,
        isFirst: isFirst,
        label: label,
        selected: selected,
        destructive: destructive,
        enabled: enabled,
      );
      return _ListActionRow(
        minimumContent:
            (leading == null ? 144 : 212) *
            MediaQuery.textScalerOf(context).scale(16) /
            16,
        content: RowFrame.off(child: main),
        action: action!,
      );
    }
    // Read below the selected fill's ComicLetteringScope, so a selected row's words take the fill's letters.
    final words = Builder(
      builder: (context) {
        final t = ComicTheme.of(context);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CapLabel(
              child: Text(
                title,
                style: t.type.title.copyWith(
                  color: destructive && !selected
                      ? t.colors.tones.danger
                      : t.colors.text,
                ),
              ),
            ),
            if (subtitle != null) Text(subtitle!, style: t.type.meta),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text(note!, style: t.type.meta),
            ],
          ],
        );
      },
    );
    final grouped = RowFrame.maybeOf(context);
    // A group's first and last rows take up the padding the group leaves to them, so their fill reaches its corners.
    // In a group the first row pads as the last does, so the room above the first row's words equals the room under
    // the last's; a list's first row on the page stands closer to the head above it.
    final ends = grouped == null ? EdgeInsets.zero : RowFrame.endsOf(context);
    Widget row = Padding(
      padding: EdgeInsets.only(
        top: (isFirst && grouped == null ? 2 : 11) + ends.top,
        bottom: 11 + ends.bottom,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          if (action == null && trailing != null) {
            return _ListActionRow(
              minimumContent:
                  (leading == null ? 144 : 212) *
                  MediaQuery.textScalerOf(context).scale(16) /
                  16,
              gap: c.maxWidth >= 520 ? 12 : 10,
              content: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(child: words),
                ],
              ),
              action: trailing!,
            );
          }
          if (action != null && trailing == null) {
            return _ListActionRow(
              minimumContent:
                  (leading == null ? 144 : 212) *
                  MediaQuery.textScalerOf(context).scale(16) /
                  16,
              content: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(child: words),
                ],
              ),
              action: action!,
            );
          }
          final wide = c.maxWidth >= 520;
          final side = trailing == null
              ? null
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: c.maxWidth * (wide ? .3 : .4),
                  ),
                  child: trailing,
                );
          final mark = leading == null
              ? const <Widget>[]
              : <Widget>[leading!, const SizedBox(width: 12)];
          if (wide) {
            return Row(
              children: [
                ...mark,
                Expanded(child: words),
                if (side != null) ...[const SizedBox(width: 12), side],
                if (action != null) ...[const SizedBox(width: 12), action!],
              ],
            );
          }
          return Row(
            crossAxisAlignment: action == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              ...mark,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: words),
                        if (side != null) ...[const SizedBox(width: 10), side],
                      ],
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 10),
                      action!,
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    // In a group a row reaches past the group's padding to a few pixels inside its rim, as an open menu's rows do:
    // its fill and press marks take the group's corner less that inset, concentric, and its words keep the padding.
    // The rules beside a lit row (pressed or chosen) stand aside. Alone, a selected row pads inside its fill.
    final fill = grouped ?? t.shapes.small;
    final reach = grouped == null
        ? EdgeInsets.zero
        : RowFrame.reachOf(context) + ends;
    final lights = grouped == null ? null : RowFrame.lightsOf(context);
    if (grouped != null) {
      row = Padding(
        padding: EdgeInsets.only(left: reach.left, right: reach.right),
        child: row,
      );
    }
    if (onPressed != null) {
      final face = enabled ? row : Opacity(opacity: .45, child: row);
      row = ComicPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: enabled ? onPressed : null,
        label: label ?? title,
        hint: subtitle,
        value: note,
        selected: selected ? true : null,
        outline: grouped == null ? null : WidgetStatePropertyAll(grouped),
        builder: (context, states) => lights == null
            ? face
            : RowLit(
                lights: lights,
                lit: selected || states.pressed,
                child: face,
              ),
      );
    } else if (selected && lights != null) {
      row = RowLit(lights: lights, lit: true, child: row);
    }
    if (selected) {
      row = ComicStateDecoration(
        decoration: ShapeDecoration(color: t.colors.caption, shape: fill),
        child: grouped != null
            ? ComicLetteringScope(t.colors.onCaption, child: row)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ComicLetteringScope(t.colors.onCaption, child: row),
              ),
      );
    }
    if (grouped != null) row = RowReach(reach: reach, child: row);
    return ComicRuled(rule: !isFirst, child: row);
  }
}

// Measure the action itself before deciding whether a reading column fits.
// This keeps compact phone actions inline without squeezing long or scaled text.
class _ListActionRow extends MultiChildRenderObjectWidget {
  _ListActionRow({
    required this.minimumContent,
    this.gap = 12,
    required Widget content,
    required Widget action,
  }) : super(children: [content, action]);
  final double minimumContent;
  final double gap;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderListActionRow(minimumContent, gap, Directionality.of(context));
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderListActionRow renderObject,
  ) {
    renderObject
      ..minimumContent = minimumContent
      ..gap = gap
      ..direction = Directionality.of(context)
      ..markNeedsLayout();
  }
}

class _ListActionData extends ContainerBoxParentData<RenderBox> {}

class _RenderListActionRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ListActionData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ListActionData> {
  _RenderListActionRow(this.minimumContent, this.gap, this.direction);
  double minimumContent;
  double gap;
  TextDirection direction;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ListActionData) {
      child.parentData = _ListActionData();
    }
  }

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final content = firstChild!, action = lastChild!;
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 520.0;
    Size measure(RenderBox child, BoxConstraints inner) {
      if (dry) return child.getDryLayout(inner);
      child.layout(inner, parentUsesSize: true);
      return child.size;
    }

    // A long action can use the full row when stacked, so do not cap it at
    // the space an inline action would happen to have.
    final actionSize = measure(action, BoxConstraints(maxWidth: width));
    final inline = width - actionSize.width - gap >= minimumContent;
    final contentSize = measure(
      content,
      BoxConstraints.tightFor(
        width: inline ? width - actionSize.width - gap : width,
      ),
    );
    final height = inline
        ? math.max(contentSize.height, actionSize.height)
        : contentSize.height + 10 + actionSize.height;
    final size = constraints.constrain(Size(width, height));
    if (!dry) {
      final contentX = inline && direction == TextDirection.rtl
          ? actionSize.width + gap
          : 0.0;
      final actionX = inline
          ? (direction == TextDirection.rtl ? 0.0 : width - actionSize.width)
          : (direction == TextDirection.rtl ? width - actionSize.width : 0.0);
      (content.parentData! as _ListActionData).offset = Offset(
        contentX,
        inline ? (size.height - contentSize.height) / 2 : 0,
      );
      (action.parentData! as _ListActionData).offset = Offset(
        actionX,
        inline
            ? (size.height - actionSize.height) / 2
            : contentSize.height + 10,
      );
    }
    return size;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);
  @override
  void performLayout() => size = _layout(constraints, dry: false);
  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A row with a time or a short figure in the lettering in a fixed column, then a title and a meta: an agenda, a schedule. [selected]
/// is the row that matters now, a step off the panel.
///
/// ```dart
/// ComicTimedRow('19:30', title: 'Doors', subtitle: 'Bring a coat', trailing: ComicPerson(initials: 'AB', size: 30))
/// ```
class ComicTimedRow extends StatelessWidget {
  /// Creates a [ComicTimedRow].
  const ComicTimedRow(
    this.time, {
    super.key,
    required this.title,
    this.subtitle,
    this.below,
    this.trailing,
    this.isFirst = false,
    this.selected = false,
    this.inset = 0,
  });

  /// [time]: the time printed with this content. [title]: the primary heading.
  final String time, title;

  /// Secondary information printed with the entry.
  final String? subtitle;

  /// Something small under the words: a sound effect for the fun of it.
  final Widget? below;

  /// Content after the main words.
  final Widget? trailing;

  /// [isFirst]: omits a separating rule before the first entry. [selected]: whether this mark is emphasized.
  final bool isFirst, selected;

  /// How far it stands in from its panel, so a [selected] row's fill can run to the contour.
  final double inset;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final row = Padding(
      padding: EdgeInsets.fromLTRB(
        inset,
        desk ? 11 : 10,
        inset,
        desk ? 11 : 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: desk ? 62 : 58,
            child: Text(
              time.toUpperCase(),
              style: t.type.letter(20, lineHeight: 1.05, tracking: .04),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: t.type.title.leading(1.3)),
                if (subtitle != null) Text(subtitle!, style: t.type.meta),
                ?below,
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
    return ComicRuled(
      rule: !isFirst,
      child: selected ? ColoredBox(color: c.inset, child: row) : row,
    );
  }
}

/// A setting: a label, a line under it, a `ComicSwitch` at the end. The whole row presses, and the label never crushes.
///
/// ```dart
/// ComicSwitchRow(label: 'Reminders', note: 'The evening before', value: on, onChanged: (v) => setState(() => on = v))
/// ```
class ComicSwitchRow extends StatelessWidget {
  /// Creates a [ComicSwitchRow].
  const ComicSwitchRow({
    super.key,
    this.style,
    required this.label,
    this.note,
    required this.value,
    this.onChanged,
    this.isFirst = false,
    this.focusNode,
    this.autofocus = false,
  });

  /// Per-state appearance of the inner switch.
  final ComicStyle? style;

  /// The visible or spoken name of the component.
  final String label;

  /// Secondary explanatory text.
  final String? note;

  /// [value]: the current value represented by the control or record. [isFirst]: omits a separating rule before the first entry.
  final bool value, isFirst;

  /// Reports a new value; null disables changes.
  final ValueChanged<bool>? onChanged;

  /// Caller-owned focus for the row as one switch.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    return ComicPressable(
      autofocus: autofocus,
      label: label,
      hint: note,
      toggled: value,
      button: false,
      focusNode: focusNode,
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      overlay: ComicStyleOf([style, t.switchTheme], const {}).overlay,
      builder: (context, states) => ComicRuled(
        rule: !isFirst,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: t.type.title),
                    if (note != null) Text(note!, style: t.type.meta),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ExcludeFocus(
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: ComicSwitch(
                      style: ComicStyleOf([
                        style,
                        t.switchTheme,
                      ], states).freeze(),
                      value: value,
                      onChanged: onChanged == null ? null : (_) {},
                      label: label,
                    ),
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

/// Figures in equal cells on a contour: a lettered value, a quiet word under it. Four across on a phone if they fit their words,
/// else two; one row on a desktop. An empty list draws nothing. Stand it at the foot of a panel or a splash ([bare] takes off its
/// top rule to stand it free).
///
/// ```dart
/// ComicFacts(const [('162 km', 'by road'), ('Sleeps 6', '3 bedrooms'), ('€145', 'each')])
/// ```
class ComicFacts extends StatelessWidget {
  /// Creates a [ComicFacts].
  const ComicFacts(
    this.items, {
    super.key,
    this.bare = false,
    this.centred = false,
  });

  /// Items displayed in their supplied order.
  final List<(String, String)> items;

  /// Omits the surrounding frame.
  final bool bare;

  /// Centre each cell's words, as figures read in a row of four.
  final bool centred;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final t = ComicTheme.of(context);
    final c = t.colors;
    final big = t.desk ? 28.0 : 20.0;
    final figure = t.type.letter(big, lineHeight: 1, tracking: .04);
    final word = t.type.text(
      t.desk ? 14 : 12,
      1.2,
      weight: FontWeight.w700,
      color: c.textSecondary,
    );
    return LayoutBuilder(
      builder: (context, box) {
        var need = 0.0;
        final scaler = MediaQuery.textScalerOf(context);
        for (final e in items) {
          need = math.max(
            need,
            comicWidestWord(e.$1.toUpperCase(), figure, textScaler: scaler),
          );
          need = math.max(
            need,
            comicWidestWord(e.$2, word, textScaler: scaler),
          );
        }
        final w = box.hasBoundedWidth ? box.maxWidth : t.width;
        final across = items.length > 2 && need + 22 > w / items.length
            ? 2
            : items.length;
        Widget cell(int i, bool edge) {
          final (value, note) = items[i];
          return DecoratedBox(
            decoration: BoxDecoration(
              border: edge
                  ? null
                  : BorderDirectional(
                      start: BorderSide(color: c.nightLine, width: t.rule(2.5)),
                    ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                (t.desk ? 18 : 10) + (edge ? 0 : t.rule(2.5)),
                t.desk ? 12 : 9,
                t.desk ? 18 : 10,
                t.desk ? 13 : 10,
              ),
              child: Column(
                crossAxisAlignment: centred
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toUpperCase(),
                    style: figure,
                    textAlign: centred ? TextAlign.center : null,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    centred ? note.toUpperCase() : note,
                    style: centred
                        ? t.type.text(
                            t.desk ? 12 : 11,
                            1.2,
                            weight: FontWeight.w800,
                            color: c.textSecondary,
                            tracking: .06,
                          )
                        : word,
                    textAlign: centred ? TextAlign.center : null,
                  ),
                ],
              ),
            ),
          );
        }

        return DecoratedBox(
          decoration: BoxDecoration(
            color: c.card,
            border: bare
                ? null
                : Border(
                    top: BorderSide(color: c.nightLine, width: t.rim(3)),
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.only(top: bare ? 0 : t.rim(3)),
            child: ComicColumn(
              children: [
                for (var row = 0; row * across < items.length; row++)
                  ComicRuled(
                    rule: row > 0,
                    child: ComicEqualRow(
                      flex: List.filled(across, 1),
                      children: [
                        for (var i = row * across; i < (row + 1) * across; i++)
                          i < items.length
                              ? cell(i, i == row * across)
                              : const SizedBox.shrink(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A labelled group in a form: a label, then the control, a line of help under it.
///
/// ```dart
/// ComicFormField('Your name', child: ComicTextField(hint: 'Name'))
/// ```
class ComicFormField extends StatelessWidget {
  /// Creates a [ComicFormField].
  const ComicFormField(
    this.label, {
    super.key,
    required this.child,
    this.help,
    this.error,
    this.required = false,
    this.enabled = true,
    this.focusNode,
  });

  /// The visible or spoken name of the component.
  final String label;

  /// Content placed inside this widget.
  final Widget child;

  /// Supporting guidance displayed with the control.
  final String? help;

  /// What is wrong, in the danger tone in place of [help].
  final String? error;

  /// Whether it must be filled: a mark beside the label, and said aloud.
  final bool required;

  /// Whether the control takes input.
  final bool enabled;

  /// The control's focus: a press on the label asks for it.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context), c = t.colors;
    // No room of its own above the label: a form field stands where its column puts it, as a text field or a
    // select beside it does, so a form keeps one rhythm whichever part each row is.
    return DesignField(
      labelText: label,
      helperText: help,
      errorText: error,
      required: required,
      enabled: enabled,
      focusNode: focusNode,
      requiredHint: DesignLocalizations.of(context).requiredHint,
      builder: (context, parts) => ComicColumn(
        children: [
          ExcludeSemantics(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: enabled ? focusNode?.requestFocus : null,
              child: Text.rich(
                TextSpan(
                  // The text field's and the select's own label: one label style in a form.
                  text: label,
                  children: [
                    if (required)
                      TextSpan(
                        text: ' *',
                        style: TextStyle(color: c.tones.danger),
                      ),
                  ],
                ),
                style: t.type.title.copyWith(
                  color: enabled ? c.text : c.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // The control shows the error too: a field's rim in the danger tone, not only the line under it.
          comicFieldTrouble(error: error != null, child: parts.control),
          if (error != null || help != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ExcludeSemantics(
                child: Text(
                  error ?? help!,
                  style: error == null
                      ? t.type.small
                      : t.type.small.copyWith(color: c.tones.danger),
                ),
              ),
            ),
        ],
      ),
      child: child,
    );
  }
}
