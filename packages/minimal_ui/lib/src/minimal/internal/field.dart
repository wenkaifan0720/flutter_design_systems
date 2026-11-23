import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../theme.dart';
import 'styled.dart';
import 'tap_band.dart';

/// Geometry the form controls share — the text field, the search field,
/// the form, picker, choice and date rows — named once so a field and a
/// row cannot drift apart. Not exported: pages never need it.
abstract final class MinimalFieldMetrics {
  /// The horizontal gap between a row icon and its label.
  static const double rowIconGap = MinimalChromeMetrics.rowIconGap;

  /// A boxed field's side inset, before the glyph and after the value.
  static const double inset = MinimalChromeMetrics.fieldInset;

  /// How far a flush form row's press wash and focus ring reach past its
  /// words on either side (`MinimalPressable.outset`): its words line up
  /// with the form's labels at rest, and its feedback still stands clear of
  /// them. Inside the page's 18 px gutter and a card's 14 px inset, so it
  /// never runs past the surface the form stands on.
  static const EdgeInsets rowReach = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s12,
  );

  /// How far a focused field's accent edge reaches in from its outline: its
  /// rim and half a pixel more. A field shows focus by its own edge, never
  /// by a ring outside it, so the accent stays within the 1.5 px a thin
  /// line can carry and the field keeps its size and its words' places.
  static const double focusEdge = 1.5;

  /// The text cursor's width: a hair heavier than the 1 px rule it sits
  /// beside, so it reads at a glance.
  static const double cursor = 1.5;

  /// A mono value's size and line: a time, an id, a count in a field or a
  /// pill, a step over the 12 px mono meta.
  static const double valueType = 13;

  /// A mono value's line height.
  static const double valueLeading = 20;
}

/// How far a boxed text field's words stand in from its leading edge
/// (`MinimalTextField`): its rim, its side inset at the theme's density, and
/// past a leading glyph with [icon]. Where a select's open list starts its
/// options' words, so they meet the field's value.
double minimalFieldWordsStart(
  BuildContext context,
  MinimalStyle? fieldStyle, {
  bool icon = false,
}) {
  final t = context.minimalTheme;
  final so = MinimalStyleOf([fieldStyle, t.components.textField], const {});
  final direction = Directionality.of(context);
  final padding = so.padding(direction);
  final inset = padding == null
      ? t.density
            .padding(const EdgeInsets.only(left: MinimalFieldMetrics.inset))
            .left
      : direction == TextDirection.ltr
      ? padding.left
      : padding.right;
  return so.rim(t.border, t.rim).width +
      inset +
      (icon ? MinimalIconSize.i16 + MinimalSpacing.s8 : 0);
}

/// The mono value style: [MinimalThemeData.mono] at the value size on its own
/// line height — what a field, a date pill and a calendar day print.
extension MinimalFieldType on MinimalThemeData {
  /// The mono face at a value's size, on its own line height.
  TextStyle get monoValue => mono.copyWith(
    fontSize: MinimalFieldMetrics.valueType,
    height: MinimalFieldMetrics.valueLeading / MinimalFieldMetrics.valueType,
  );
}

/// A focused field's edge: the accent over the field's rim, reaching
/// [MinimalFieldMetrics.focusEdge] in from [shape]'s outline and never past
/// it. However focus came (a tap, a click, Tab), the field shows it the same
/// way, with no ring outside, and an invalid field takes the accent while it
/// has focus. Always a border, transparent when not [shown]: a Container
/// that gains or loses a foreground decoration re-parents its child, and
/// the text field would be rebuilt (and lose its input) on the first focus.
Decoration minimalFocusEdge(
  MinimalThemeData t, {
  required bool shown,
  OutlinedBorder? shape,
}) => minimalFrame(
  shape ?? t.shapes.small,
  side: BorderSide(
    color: shown ? t.ring : const Color(0x00000000),
    width: MinimalFieldMetrics.focusEdge,
  ),
);

/// The controller and focus node a text field owns when its caller passes
/// none, re-wired when the caller swaps them, and the state rebuilt on
/// every edit and focus change. Shared by the boxed field and the search
/// field.
mixin MinimalFieldOwner<W extends StatefulWidget> on State<W> {
  TextEditingController? _ownedController;
  FocusNode? _ownedFocus;

  /// The caller's controller, if it passed one.
  TextEditingController? get externalController;

  /// The caller's focus node, if it passed one.
  FocusNode? get externalFocusNode;

  /// Called when the field gains or loses focus.
  void focusChanged(bool focused) {}

  /// The field's controller: the one given, else one it owns.
  TextEditingController get controller =>
      externalController ?? (_ownedController ??= TextEditingController());

  /// The field's focus node: the one given, else one it owns.
  FocusNode get focusNode => externalFocusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    focusNode.addListener(_focusChanged);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _focusChanged() {
    _refresh();
    focusChanged(focusNode.hasFocus);
  }

  /// Re-wires the listeners after the widget changed its controller or its
  /// focus node; call it from `didUpdateWidget` with the old widget's.
  void syncField({
    required TextEditingController? oldController,
    required FocusNode? oldFocusNode,
  }) {
    if (oldController != externalController) {
      (oldController ?? _ownedController)?.removeListener(_refresh);
      if (externalController == null) {
        // The field keeps what the caller's controller held, whether it
        // owned a controller before or not.
        final owned = _ownedController ??= TextEditingController();
        if (oldController != null) owned.value = oldController.value;
      }
      controller.addListener(_refresh);
    }
    if (oldFocusNode != externalFocusNode) {
      (oldFocusNode ?? _ownedFocus)?.removeListener(_focusChanged);
      focusNode.addListener(_focusChanged);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    focusNode.removeListener(_focusChanged);
    _ownedController?.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }
}

/// Whether the MinimalFormField round a control shows an error. A text
/// field or an input group under one paints the error register (the danger
/// rule and ring) as if it carried the error itself; the message is the
/// form field's.
class MinimalFieldErrorScope extends InheritedWidget {
  /// [wrong] for the controls in [child].
  const MinimalFieldErrorScope({
    super.key,
    required this.wrong,
    required super.child,
  });

  /// Whether the form field shows an error.
  final bool wrong;

  /// Whether a form field round [context] shows an error.
  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<MinimalFieldErrorScope>()
          ?.wrong ??
      false;

  @override
  bool updateShouldNotify(MinimalFieldErrorScope oldWidget) =>
      wrong != oldWidget.wrong;
}

/// Whether the list a combobox's field opens is showing, for the text
/// input inside the field to say so to a screen reader (expanded).
class MinimalFieldOpenScope extends InheritedWidget {
  /// [open] for the text input in [child].
  const MinimalFieldOpenScope({
    super.key,
    required this.open,
    required super.child,
  });

  /// Whether the field's list is showing.
  final bool open;

  /// Whether the list of a combobox round [context] is showing; null
  /// outside a combobox.
  static bool? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MinimalFieldOpenScope>()?.open;

  @override
  bool updateShouldNotify(MinimalFieldOpenScope oldWidget) =>
      open != oldWidget.open;
}

/// A boxed field's value area as one screen-reader node — the text input
/// and the name a caller puts on it — whose bounds are the band a tap lands
/// in (the box grown to the band's tap floor, [minimalBandFloor],
/// which the band round the box lays out), not the one line of text it
/// paints: the target a screen reader outlines, and an accessibility audit
/// measures, is the one a finger or a pointer has.
class MinimalFieldTarget extends SingleChildRenderObjectWidget {
  /// One screen-reader node around [child], the size of its touch target.
  /// With [node] false it makes no node of its own and only reaches taps
  /// across the band: inside a field whose decorator gives the input its
  /// node (beside a clear glyph or an eye), where a node of its own would
  /// stand between the input and the field's words.
  const MinimalFieldTarget({super.key, this.node = true, super.child});

  /// Whether it makes the input's node, the size of the band.
  final bool node;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFieldTarget(minimalBandFloor(context), node: node);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderFieldTarget)
        ..floor = minimalBandFloor(context)
        ..node = node;
}

class _RenderFieldTarget extends RenderProxyBox {
  _RenderFieldTarget(this._floor, {required this._node});

  bool _node;
  set node(bool v) {
    if (v == _node) return;
    _node = v;
    markNeedsSemanticsUpdate();
  }

  double _floor;
  set floor(double v) {
    if (v == _floor) return;
    _floor = v;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (!_node) return;
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  /// The painted value area, grown about its centre to the floor's band.
  @override
  Rect get semanticBounds {
    final min = _floor;
    final width = size.width < min ? min : size.width;
    final height = size.height < min ? min : size.height;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: height,
    );
  }

  /// A tap anywhere in [semanticBounds] reaches the input: one the line
  /// itself does not take (past it, or on the sliver its capitals' shift
  /// leaves at an edge) lands on the line's middle at the same place along
  /// it, so the area a tap reaches is the one a screen reader outlines (as
  /// far as the field's box, and the band round it, let it through).
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position) && super.hitTest(result, position: position)) {
      return true;
    }
    if (!semanticBounds.contains(position)) return false;
    // Half a pixel in from either end (a box holds its far edge no more),
    // then further in while the line's own box, shifted by its capitals or
    // its caret's room, leaves the end bare.
    for (final edge in const [0.5, 4.0, 8.0]) {
      if (size.width < 2 * edge) break;
      final inside = Offset(
        position.dx.clamp(edge, size.width - edge),
        size.height / 2,
      );
      final hit = result.addWithRawTransform(
        transform: MatrixUtils.forceToPoint(inside),
        position: inside,
        hitTest: (result, _) => super.hitTest(result, position: inside),
      );
      if (hit) return true;
    }
    return false;
  }
}
