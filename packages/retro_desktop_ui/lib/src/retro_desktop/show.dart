import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'controls.dart';
import 'internal/face.dart';
import 'layout.dart';
import 'glyphs.dart';
import 'theme.dart';
import 'press.dart';
import 'rows.dart';

/// An avatar in the family's mark shape (a circle under rounded corners) with an image and initials fallback.
///
/// ```dart
/// RetroDesktopAvatar('AL', name: 'Alex Lee')
/// ```
class RetroDesktopAvatar extends StatelessWidget {
  /// Creates a [RetroDesktopAvatar].
  const RetroDesktopAvatar(
    this.initials, {
    super.key,
    this.image,
    this.size = 40,
    this.selected = false,
    this.name,
    this.style,
  }) : assert(size > 0);

  /// The letters displayed when an image is unavailable.
  final String initials;

  /// The image to display, with the component's fallback when unavailable.
  final ImageProvider? image;

  /// The size of the visible face; minimum interactive reach is retained.
  final double size;

  /// Whether the part represents the current selection.
  final bool selected;

  /// The name identifying this item.
  final String? name;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final states = <WidgetState>{if (selected) WidgetState.selected};
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) read) =>
        RetroDesktopStyle.first([style, t.avatarTheme], read, states);
    final minimum = slot((s) => s.minimumSize) ?? Size.zero;
    final width = size < minimum.width ? minimum.width : size;
    final height = size < minimum.height ? minimum.height : size;
    final shape =
        RetroDesktopStyle.first(
          [style, t.avatarTheme],
          (s) => s.shape,
          states,
        ) ??
        t.shapes.full;
    final fallback = Padding(
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          initials,
          style: (slot((s) => s.textStyle) ?? t.type.small).copyWith(
            color:
                slot((s) => s.foreground) ??
                (selected ? t.colors.onHighlight : t.colors.text),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: name ?? initials,
      child: ExcludeSemantics(
        child: retroDesktopOwnSize(
          width: width,
          height: height,
          child: retroDesktopFace(
            states: states,
            component: t.avatarTheme,
            scale: RetroDesktopFaceScale.mark,
            style: style,
            padding: EdgeInsets.zero,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: image == null
                  ? fallback
                  : Image(
                      image: image!,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => fallback,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A wrapping collection of people; every name remains available to accessibility.
///
/// ```dart
/// RetroDesktopAvatarGroup(children: const [RetroDesktopAvatar('AL', name: 'Alex Lee'), RetroDesktopAvatar('JM', name: 'Jo Morgan')])
/// ```
class RetroDesktopAvatarGroup extends StatelessWidget {
  /// Creates a [RetroDesktopAvatarGroup].
  const RetroDesktopAvatarGroup({
    super.key,
    required this.children,
    this.spacing = 4,
  });

  /// The child widgets in reading order.
  final List<RetroDesktopAvatar> children;

  /// Space between adjacent items in logical pixels.
  final double spacing;
  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: spacing, runSpacing: spacing, children: children);
}

/// An image or arbitrary caller-supplied artwork in a frame of the family's surface shape.
///
/// ```dart
/// RetroDesktopPicture(label: 'Document preview', child: const Text('Preview'))
/// ```
class RetroDesktopPicture extends StatelessWidget {
  /// Creates a [RetroDesktopPicture].
  const RetroDesktopPicture({
    super.key,
    required this.label,
    this.image,
    this.child,
    this.aspectRatio = 16 / 9,
    this.alignment = Alignment.center,
    this.style,
  }) : assert(image == null || child == null),
       assert(aspectRatio > 0);

  /// The visible or accessible name of this part.
  final String label;

  /// The image to display, with the component's fallback when unavailable.
  final ImageProvider? image;

  /// The widget displayed inside this part.
  final Widget? child;

  /// The width-to-height ratio of the content.
  final double aspectRatio;

  /// Where the content sits within its available space.
  final AlignmentGeometry alignment;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final shape =
        RetroDesktopStyle.first(
          [style, t.cardTheme],
          (s) => s.shape,
          const {},
        ) ??
        t.shapes.medium;
    Widget fallback() => Center(
      child: Icon(
        RetroDesktopGlyphs.fileText,
        size: 32,
        color: t.colors.textTertiary,
      ),
    );
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: retroDesktopFace(
            states: const {},
            component: t.cardTheme,
            scale: RetroDesktopFaceScale.surface,
            style: style,
            padding: EdgeInsets.zero,
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child:
                  child ??
                  (image == null
                      ? fallback()
                      : Image(
                          image: image!,
                          fit: BoxFit.cover,
                          alignment: alignment,
                          errorBuilder: (_, error, stack) => fallback(),
                        )),
            ),
          ),
        ),
      ),
    );
  }
}

/// A bevelled plate in the family's surface shape, optionally pressable or floating above the desktop.
///
/// ```dart
/// RetroDesktopSurface(child: const Text('A desktop plate'))
/// ```
class RetroDesktopSurface extends StatelessWidget {
  /// Creates a [RetroDesktopSurface].
  const RetroDesktopSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.selected = false,
    this.pressed = false,
    this.floating = false,
    this.onPressed,
    this.label,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The widget displayed inside this part.
  final Widget child;

  /// Insets around the content.
  final EdgeInsetsGeometry padding;

  /// Whether the part represents the current selection.
  final bool selected;

  /// Whether the surface is drawn in its pressed state.
  final bool pressed;

  /// Whether this surface draws its raised shadow.
  final bool floating;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The visible or accessible name of this part.
  final String? label;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    Widget face(Set<WidgetState> states) => retroDesktopFace(
      shadows: floating
          ? [
              BoxShadow(
                color: t.colors.shade.withValues(
                  alpha: t.colors.dark ? .95 : .8,
                ),
                offset: const Offset(2, 2),
              ),
            ]
          : null,
      component: t.cardTheme,
      scale: RetroDesktopFaceScale.surface,
      style: style,
      padding: padding,
      states: {
        ...states,
        if (selected) WidgetState.selected,
        if (pressed) WidgetState.pressed,
      },
      child: child,
    );
    return onPressed == null
        ? face(const {})
        : RetroDesktopPressable(
            focusNode: focusNode,
            autofocus: autofocus,
            onPressed: onPressed,
            label: label,
            selected: selected,
            builder: (context, states) => face(states),
          );
  }
}

/// A content plate in the family's surface shape with a leading heading, separate from window chrome.
///
/// ```dart
/// RetroDesktopCard(title: 'Documents', child: const Text('Three documents'))
/// ```
class RetroDesktopCard extends StatelessWidget {
  /// Creates a [RetroDesktopCard].
  const RetroDesktopCard({
    super.key,
    this.style,
    this.title,
    this.child,
    this.children,
  }) : assert(child == null || children == null);

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String? title;

  /// The widget displayed inside this part.
  final Widget? child;

  /// The child widgets in reading order.
  final List<Widget>? children;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final body =
        child ?? RetroDesktopColumn(gap: 8, children: children ?? const []);
    return RetroDesktopSurface(
      style: style,
      child: DesignKeylineRegion(
        label: title,
        child: RetroDesktopColumn(
          gap: 12,
          children: [
            if (title != null)
              Semantics(
                container: true,
                header: true,
                child: Text(title!, style: t.type.sub),
              ),
            body,
          ],
        ),
      ),
    );
  }
}

/// A titled list of rows with optional explanatory text below it.
///
/// ```dart
/// RetroDesktopListSection(title: 'Preferences', children: [RetroDesktopListTile(title: 'Appearance'), RetroDesktopListTile(title: 'Notifications')])
/// ```
class RetroDesktopListSection extends StatelessWidget {
  /// Creates a [RetroDesktopListSection].
  const RetroDesktopListSection({
    super.key,
    this.title,
    this.footer,
    this.style,
    required this.children,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String? title;

  /// Optional content below the main items.
  final String? footer;

  /// The child widgets in reading order.
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              header: true,
              child: Text(title!, style: t.type.small),
            ),
          ),
        RetroDesktopSurface(
          style: style,
          padding: EdgeInsets.zero,
          child: DesignKeylineRegion(
            label: title,
            child: _GroupedRows(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const RetroDesktopDivider(),
                  RetroDesktopRowPlace(
                    key: children[i].key == null
                        ? null
                        : ValueKey<Key?>(children[i].key),
                    first: i == 0,
                    last: i == children.length - 1,
                    child: RetroDesktopList(children: [children[i]]),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(footer!, style: t.type.note),
          ),
      ],
    );
  }
}

// Measure rows before laying out their separators: a builder that returns an
// empty box must not leave a rule behind or change the next row's position.
class _GroupedRows extends RetroDesktopColumn {
  const _GroupedRows({required super.children});

  @override
  RenderRetroDesktopColumn createRenderObject(BuildContext context) =>
      _RenderGroupedRows(Directionality.of(context));
}

class _RenderGroupedRows extends RenderRetroDesktopColumn {
  _RenderGroupedRows(TextDirection direction) : super(0, null, null, direction);

  List<RenderBox> get _items => [
    for (var child = firstChild; child != null; child = childAfter(child))
      child,
  ];

  double _intrinsicHeight(double width, bool maximum) {
    final items = _items;
    double heightOf(RenderBox child) => maximum
        ? child.getMaxIntrinsicHeight(width)
        : child.getMinIntrinsicHeight(width);
    var height = 0.0;
    var hasRow = false;
    for (var i = 0; i < items.length; i += 2) {
      final rowHeight = heightOf(items[i]);
      if (rowHeight > 0 && hasRow) height += heightOf(items[i - 1]);
      height += rowHeight;
      hasRow = hasRow || rowHeight > 0;
    }
    return height;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, false);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, true);

  @override
  void performLayout() {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(double.infinity);
    final natural = BoxConstraints(minWidth: width, maxWidth: width);
    final items = _items;
    for (var i = 0; i < items.length; i += 2) {
      items[i].layout(natural, parentUsesSize: true);
    }
    var y = 0.0;
    var hasRow = false;
    for (var i = 0; i < items.length; i += 2) {
      final row = items[i];
      if (i > 0) {
        final divider = items[i - 1];
        divider.layout(
          hasRow && row.size.height > 0
              ? natural
              : BoxConstraints.tightFor(width: width, height: 0),
          parentUsesSize: true,
        );
        (divider.parentData! as BoxParentData).offset = Offset(
          0,
          y.roundToDouble(),
        );
        y += divider.size.height;
      }
      (row.parentData! as BoxParentData).offset = Offset(0, y.roundToDouble());
      y += row.size.height;
      hasRow = hasRow || row.size.height > 0;
    }
    size = constraints.constrain(Size(width, y.roundToDouble()));
  }
}

/// A one-pixel divider in the current frame colour; [RetroDesktopDivider.etched] is the period's etched separator, a
/// shade line over a light one, as a group box's rule.
///
/// ```dart
/// RetroDesktopDivider(indent: 12, endIndent: 12)
/// ```
class RetroDesktopDivider extends StatelessWidget {
  /// Creates a one-pixel divider.
  const RetroDesktopDivider({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.style,
  }) : _etched = false;

  /// Creates an etched separator: the divider theme's edge colour over its fill.
  const RetroDesktopDivider.etched({
    super.key,
    this.indent = 0,
    this.endIndent = 0,
    this.style,
  }) : _etched = true;

  final bool _etched;

  /// Space before the divider in reading order.
  final double indent;

  /// Space after the divider in reading order.
  final double endIndent;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.dividerTheme], get, const {});
    if (_etched) return _etch(t, slot);
    final side = slot((s) => s.side);
    return Padding(
      padding:
          slot((s) => s.padding) ??
          EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: SizedBox(
        height: side?.width ?? t.strokes.hairline,
        child: ColoredBox(
          // A fifth of the ink, so the line reads on whatever it crosses: the paper's rule colour, drawn on the
          // machine's grey, was lighter than the grey by day and the grey itself by night.
          color:
              side?.color ??
              slot((s) => s.edge) ??
              slot((s) => s.fill) ??
              t.colors.text.withValues(alpha: .2),
        ),
      ),
    );
  }

  Widget _etch(
    RetroDesktopThemeData t,
    T? Function<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle)) slot,
  ) {
    final side = slot((s) => s.side);
    final width = side?.width ?? t.strokes.hairline;
    return Padding(
      padding:
          slot((s) => s.padding) ??
          EdgeInsetsDirectional.only(start: indent, end: endIndent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: width,
            child: ColoredBox(
              color: side?.color ?? slot((s) => s.edge) ?? t.colors.bevelDark,
              child: const SizedBox(width: double.infinity),
            ),
          ),
          SizedBox(
            height: t.strokes.hairline,
            child: ColoredBox(
              color: slot((s) => s.fill) ?? t.colors.bevelLight,
              child: const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

/// The prominence of an amount within a page.
enum RetroDesktopAmountScale {
  /// The formatted amount displayed in the main type.
  display,

  /// The heading displayed above the content.
  title,

  /// Whether the amount participates in a line of text.
  inline,
}

/// A labelled amount, supplied as formatted text so the owner controls currency and locale.
///
/// ```dart
/// RetroDesktopAmount('42', label: 'Storage used', unit: 'MB')
/// ```
class RetroDesktopAmount extends StatelessWidget {
  /// Creates a [RetroDesktopAmount].
  const RetroDesktopAmount(
    this.value, {
    super.key,
    this.label,
    this.unit,
    this.was,
    this.scale = RetroDesktopAmountScale.display,
  });

  /// The current value to display or edit.
  final String value;

  /// The visible or accessible name of this part.
  final String? label;

  /// The unit shown beside the value.
  final String? unit;

  /// The previous amount displayed for comparison.
  final String? was;

  /// The scale applied to this visual value.
  final RetroDesktopAmountScale scale;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return Semantics(
      label: label,
      value:
          '$value${unit == null ? '' : ' $unit'}${was == null ? '' : ', $was'}',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null) Text(label!, style: t.type.note),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                Text(
                  value,
                  style: switch (scale) {
                    RetroDesktopAmountScale.display => t.type.big,
                    RetroDesktopAmountScale.title => t.type.sub,
                    RetroDesktopAmountScale.inline => t.type.figure,
                  },
                ),
                if (unit != null) Text(unit!, style: t.type.body),
                if (was != null)
                  Text(
                    was!,
                    style: t.type.note.copyWith(
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled meter on a known range.
///
/// ```dart
/// RetroDesktopMeter(label: 'Storage used', value: .65)
/// ```
class RetroDesktopMeter extends StatelessWidget {
  /// Creates a [RetroDesktopMeter].
  const RetroDesktopMeter({
    super.key,
    this.style,
    required this.label,
    required this.value,
    this.min = 0,
    this.max = 1,
  }) : assert(max > min),
       assert(value >= min && value <= max);

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The visible or accessible name of this part.
  final String label;

  /// The current value to display or edit.
  final double value;

  /// The lower bound of the supported range.
  final double min;

  /// The upper bound of the supported range.
  final double max;
  @override
  Widget build(BuildContext context) => RetroDesktopLinearProgressIndicator(
    label: label,
    style: style,
    value: (value - min) / (max - min),
  );
}
