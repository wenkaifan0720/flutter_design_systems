import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../component_themes.dart';
import '../theme.dart';
import 'styled.dart';

/// Geometry the form controls share — the text field, the search field,
/// the form, picker, choice and date rows — named once so a field and a
/// row cannot drift apart. Not exported: pages never need it.
abstract final class MinimalFieldMetrics {
  /// The air between a row's glyph and its label: the reference mock's
  /// property row (`.wb-row`, gap 10 px), shared with every row.
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
  final padding = so.padding?.resolve(direction);
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

/// The keyboard focus ring a text field draws outside its box: a solid
/// [MinimalThemeData.ring] (the danger in error) at `t.focusWidth`,
/// the same ring [MinimalPressable] draws, round [shape] (else
/// `shapes.small`). Always a border, transparent when not [shown]: a
/// Container that gains or loses a foreground decoration re-parents its
/// child, and the text field would be rebuilt (and lose its input) on the
/// first focus.
Decoration minimalFieldRing(
  MinimalThemeData t, {
  required bool shown,
  bool error = false,
  OutlinedBorder? shape,
}) => minimalFrame(
  shape ?? t.shapes.small,
  side: BorderSide(
    color: !shown
        ? const Color(0x00000000)
        : error
        ? t.destructive
        : t.ring,
    width: t.focusWidth,
    strokeAlign: BorderSide.strokeAlignOutside,
  ),
);

/// The controller and focus node a text field owns when its caller passes
/// none, re-wired when the caller swaps them, and the state rebuilt on
/// every edit, focus change and switch between pointer and keyboard (the
/// ring shows for the keyboard only). Shared by the boxed field and the
/// search field.
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

  /// Whether the field holds focus that the keyboard brought: when its
  /// ring shows.
  bool get keyboardFocused =>
      focusNode.hasFocus &&
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    focusNode.addListener(_focusChanged);
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _focusChanged() {
    _refresh();
    focusChanged(focusNode.hasFocus);
  }

  void _modeChanged(FocusHighlightMode mode) {
    if (focusNode.hasFocus) _refresh();
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
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
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

/// A boxed field's value area as one screen-reader node — the text input
/// and the name a caller puts on it — whose bounds are the
/// [MinimalLayout.minHitTarget] band a tap lands in (the box and the margin
/// [MinimalHitTarget] hands on), not the one line of text it paints: the
/// target a screen reader outlines, and an accessibility audit measures,
/// is the one a finger has.
class MinimalFieldTarget extends SingleChildRenderObjectWidget {
  /// One screen-reader node around [child], the size of its touch target.
  const MinimalFieldTarget({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFieldTarget();
}

class _RenderFieldTarget extends RenderProxyBox {
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  /// The painted value area, grown about its centre to the 44 px band.
  @override
  Rect get semanticBounds {
    const min = MinimalLayout.minHitTarget;
    final width = size.width < min ? min : size.width;
    final height = size.height < min ? min : size.height;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: width,
      height: height,
    );
  }
}
