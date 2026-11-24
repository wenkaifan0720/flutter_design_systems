import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// What reaches a look's controls: a finger, or a pointer (a mouse, a
/// trackpad, a stylus that hovers).
///
/// Material's `MaterialTapTargetSize` decides the same by platform: padded
/// on Android, iOS and Fuchsia, shrink-wrapped on desktops.
enum RawInput {
  /// A finger: a target at least [RawTapTargets.touch].
  touch,

  /// A pointer: a target at least [RawTapTargets.pointer].
  pointer;

  /// The input [platform] is reached by: [touch] on Android, iOS and
  /// Fuchsia, [pointer] on macOS, Windows and Linux.
  static RawInput forPlatform(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => touch,
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => pointer,
  };
}

/// The least area a tap must reach on a control, by what reaches it: 44 by
/// 44 for a finger (Apple's Human Interface Guidelines), 24 by 24 for a
/// pointer (WCAG 2.2, success criterion 2.5.8, level AA).
///
/// A look may raise either (Android's 48 for a finger, 44 for a pointer
/// that a look keeps roomy) and declares its floors with a
/// [RawTapTargetScope] round the app, in its theme; [TapTargetPadding]
/// lays a control out at the floor, and `DesignTapTargetCheck` holds every
/// screen to it. Density never moves the floor: a compact face stands in
/// the same target, with more room round it.
///
/// ```dart
/// RawTapTargetScope(
///   targets: const RawTapTargets(touch: Size.square(48)),
///   child: app,
/// )
/// ```
///
/// See also:
///
///  * [TapTargetPadding], which lays a control out at the floor.
///  * [RawDensity], which tightens a control's face, never its target.
@immutable
class RawTapTargets with Diagnosticable {
  /// Floors for [touch] and [pointer]; [input] null reads the platform's.
  const RawTapTargets({
    this.touch = const Size.square(44),
    this.pointer = const Size.square(24),
    this.input,
  });

  /// The floors with no look's own: 44 for a finger, 24 for a pointer, the
  /// input by platform.
  static const RawTapTargets fallback = RawTapTargets();

  /// The least area a finger's tap reaches.
  final Size touch;

  /// The least area a pointer's click reaches.
  final Size pointer;

  /// What reaches the controls; null: by the platform
  /// ([RawInput.forPlatform]).
  final RawInput? input;

  /// What reaches the controls on [platform] (the running one when null).
  RawInput inputOn([TargetPlatform? platform]) =>
      input ?? RawInput.forPlatform(platform ?? defaultTargetPlatform);

  /// The floor for [input].
  Size floorFor(RawInput input) => switch (input) {
    RawInput.touch => touch,
    RawInput.pointer => pointer,
  };

  /// The floor for what reaches the controls on [platform] (the running one
  /// when null).
  Size floorOn([TargetPlatform? platform]) => floorFor(inputOn(platform));

  /// The floors in effect at [context]: the nearest [RawTapTargetScope]'s,
  /// else [fallback].
  static RawTapTargets of(BuildContext context) => maybeOf(context) ?? fallback;

  /// The nearest [RawTapTargetScope]'s floors, or null when there is none.
  static RawTapTargets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RawTapTargetScope>()?.targets;

  /// This with the given fields changed.
  RawTapTargets copyWith({Size? touch, Size? pointer, RawInput? input}) =>
      RawTapTargets(
        touch: touch ?? this.touch,
        pointer: pointer ?? this.pointer,
        input: input ?? this.input,
      );

  @override
  bool operator ==(Object other) =>
      other is RawTapTargets &&
      other.touch == touch &&
      other.pointer == pointer &&
      other.input == input;

  @override
  int get hashCode => Object.hash(touch, pointer, input);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Size>('touch', touch, defaultValue: fallback.touch),
      )
      ..add(
        DiagnosticsProperty<Size>(
          'pointer',
          pointer,
          defaultValue: fallback.pointer,
        ),
      )
      ..add(EnumProperty<RawInput>('input', input, defaultValue: null));
  }
}

/// Declares the [targets] a look's controls stand at for the subtree, as a
/// theme does; [RawTapTargets.of] reads them.
class RawTapTargetScope extends InheritedTheme {
  /// Declares [targets] for [child].
  const RawTapTargetScope({
    super.key,
    required this.targets,
    required super.child,
  });

  /// The floors under it.
  final RawTapTargets targets;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      RawTapTargetScope(targets: targets, child: child);

  @override
  bool updateShouldNotify(RawTapTargetScope oldWidget) =>
      targets != oldWidget.targets;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<RawTapTargets>('targets', targets));
  }
}

/// Lays [child] out at least [minSize] (the floor for what reaches the
/// controls, [RawTapTargets.of], when null), placed by [alignment], and
/// sends a tap anywhere in that area to the child's centre: the control's
/// layout, the area a tap reaches and the box a screen reader outlines are
/// one.
///
/// [alignment] is where the face stands in its target; the target grows
/// away from the edges it names. Centred, as Material's is, by default. A
/// face that starts on a column's keyline (a bare checkbox, a round key)
/// takes [AlignmentDirectional.centerStart], so its drawn face, not its
/// target, stands on the keyline and the target grows toward the end, the
/// top and the bottom; a field's trailing key takes
/// [AlignmentDirectional.centerEnd]. Both mirror right to left.
///
/// The face stands on whole device pixels: an offset that falls between
/// them (a 27 pt face centred in 44 stands 8.5 in) is rounded toward the
/// start edge (and the top), so a pixel look's 1 px bevels and a hairline
/// stay sharp, and right to left mirrors left to right exactly.
///
/// The control's semantics node spans the target too: what the child says
/// merges into one node the target's size, so a screen reader outlines, and
/// Flutter's tap-target guidelines (`meetsGuideline`) measure, the area a
/// tap reaches. Material's padded tap target (`MaterialTapTargetSize.padded`)
/// does the same. A control that widens only its own hit test past its box (a hit
/// slop) takes taps over its parent's bounds alone, since hit testing
/// reaches a child only inside its parent, while a screen reader outlines,
/// and Flutter's tap-target guidelines pass, the wider box.
///
/// The child is laid out under the constraints the target is given, as if
/// nothing stood round it; the target grows round it as far as they let.
///
/// ```dart
/// TapTargetPadding(
///   child: RawButton(onPressed: onPressed, builder: face),
/// )
/// ```
///
/// A face on the column's start edge:
///
/// ```dart
/// TapTargetPadding(
///   alignment: AlignmentDirectional.centerStart,
///   child: RawButton(onPressed: onPressed, builder: face),
/// )
/// ```
///
/// See also:
///
///  * [RawTapTargets], the floors a look declares.
///  * `DesignTapTargetCheck`, which holds a screen to them.
class TapTargetPadding extends SingleChildRenderObjectWidget {
  /// Lays [child] out at least [minSize], placed by [alignment].
  const TapTargetPadding({
    super.key,
    this.minSize,
    this.alignment = AlignmentDirectional.center,
    required Widget super.child,
  });

  /// The least size; null: the floor for what reaches the controls
  /// ([RawTapTargets.floorOn]).
  final Size? minSize;

  /// Where the face stands in its target, which grows away from the edges
  /// this names; [AlignmentDirectional.center] by default.
  final AlignmentGeometry alignment;

  Size _floor(BuildContext context) =>
      minSize ?? RawTapTargets.of(context).floorOn();

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderTapTargetPadding(
        _floor(context),
        alignment: alignment,
        textDirection: Directionality.maybeOf(context),
        devicePixelRatio: _ratio(context),
      );

  static double _ratio(BuildContext context) =>
      MediaQuery.maybeDevicePixelRatioOf(context) ??
      View.maybeOf(context)?.devicePixelRatio ??
      1;

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTapTargetPadding renderObject,
  ) => renderObject
    ..minSize = _floor(context)
    ..alignment = alignment
    ..textDirection = Directionality.maybeOf(context)
    ..devicePixelRatio = _ratio(context);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Size>('minSize', minSize, defaultValue: null))
      ..add(
        DiagnosticsProperty<AlignmentGeometry>(
          'alignment',
          alignment,
          defaultValue: AlignmentDirectional.center,
        ),
      );
  }
}

/// [TapTargetPadding]'s render object: its child laid out as given, itself at
/// least [minSize], the child placed by [alignment], a hit anywhere in it
/// sent to the child's centre.
class RenderTapTargetPadding extends RenderShiftedBox {
  /// The visible face inside a laid-out [box], in its local coordinates.
  /// Follows single-child wrappers to their tap target, using layout
  /// offsets so an animated press transform does not move the indicator.
  /// A box without such a target is its own face.
  static Rect faceRectOf(RenderBox box) {
    RenderObject node = box;
    var offset = Offset.zero;
    while (true) {
      RenderObject? next;
      var count = 0;
      node.visitChildren((child) {
        next = child;
        count++;
      });
      final child = next;
      if (count != 1 || child == null) return Offset.zero & box.size;
      final data = child.parentData;
      if (data is BoxParentData) offset += data.offset;
      if (node is RenderTapTargetPadding &&
          child is RenderBox &&
          child.hasSize) {
        return offset & child.size;
      }
      node = child;
    }
  }

  /// A target at least [minSize], [child] placed by [alignment] (resolved
  /// for [textDirection]) on whole pixels at [devicePixelRatio].
  RenderTapTargetPadding(
    Size minSize, {
    AlignmentGeometry alignment = AlignmentDirectional.center,
    TextDirection? textDirection,
    double devicePixelRatio = 1,
    RenderBox? child,
  }) : assert(minSize.isFinite, 'a tap target is finite: $minSize'),
       assert(devicePixelRatio > 0, 'a pixel ratio is positive'),
       _minSize = minSize,
       // A private named parameter (this._alignment) would need Dart 3.12's
       // language, which an app the kit is copied into may not have.
       // ignore: prefer_initializing_formals
       _alignment = alignment,
       // ignore: prefer_initializing_formals
       _textDirection = textDirection,
       _devicePixelRatio = devicePixelRatio,
       super(child);

  /// Device pixels to a logical one: the child stands on whole device
  /// pixels.
  double get devicePixelRatio => _devicePixelRatio;
  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    assert(value > 0, 'a pixel ratio is positive');
    if (_devicePixelRatio == value) return;
    _devicePixelRatio = value;
    markNeedsLayout();
  }

  // Where a child [face] large stands in a target [size] large: placed by
  // the alignment, then onto whole device pixels toward the start edge (and
  // the top). A face flush with an edge stays flush.
  Offset _place(Size size, Size face) {
    final free = size - face as Offset;
    final raw = _resolved.alongOffset(free);
    final r = devicePixelRatio;
    double down(double v) => (v * r + 1e-6).floorToDouble() / r;
    double snap(double v, double room, {required bool fromEnd}) {
      if (v <= 0 || v >= room) return v;
      return fromEnd ? room - down(room - v) : down(v);
    }

    return Offset(
      snap(raw.dx, free.dx, fromEnd: textDirection == TextDirection.rtl),
      snap(raw.dy, free.dy, fromEnd: false),
    );
  }

  /// Where the child stands in the target.
  AlignmentGeometry get alignment => _alignment;
  AlignmentGeometry _alignment;
  set alignment(AlignmentGeometry value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsLayout();
  }

  /// The direction [alignment] is resolved in; a directional alignment
  /// needs one.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  Alignment get _resolved {
    final at = alignment;
    // Centred across, it reads the same either way.
    if (at is AlignmentDirectional && at.start == 0) return Alignment(0, at.y);
    assert(
      at is Alignment || textDirection != null,
      'a tap target aligned to its start or end needs a Directionality',
    );
    return at.resolve(textDirection);
  }

  /// The least size.
  Size get minSize => _minSize;
  Size _minSize;
  set minSize(Size value) {
    assert(value.isFinite, 'a tap target is finite: $value');
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(child?.getMinIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(child?.getMinIntrinsicHeight(width) ?? 0, minSize.height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(child?.getMaxIntrinsicWidth(height) ?? 0, minSize.width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(child?.getMaxIntrinsicHeight(width) ?? 0, minSize.height);

  Size _sized(BoxConstraints constraints, Size face) => constraints.constrain(
    Size(
      math.max(face.width, minSize.width),
      math.max(face.height, minSize.height),
    ),
  );

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.constrain(minSize);
    return _sized(constraints, child.getDryLayout(constraints));
  }

  @override
  double? computeDryBaseline(
    BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final child = this.child;
    if (child == null) return null;
    final at = child.getDryBaseline(constraints, baseline);
    if (at == null) return null;
    final face = child.getDryLayout(constraints);
    return at + _place(_sized(constraints, face), face).dy;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.constrain(minSize);
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = _sized(constraints, child.size);
    (child.parentData! as BoxParentData).offset = _place(size, child.size);
  }

  // The control's one node spans the target, as a Material padded
  // control's does (its Semantics stands outside its padding): what the
  // child says merges into it.
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (child == null) return;
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    final child = this.child;
    if (child == null || !size.contains(position)) return false;
    final centre = child.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(centre),
      position: centre,
      hitTest: (result, position) => child.hitTest(result, position: centre),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Size>('minSize', minSize))
      ..add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment))
      ..add(DoubleProperty('devicePixelRatio', devicePixelRatio))
      ..add(
        EnumProperty<TextDirection>(
          'textDirection',
          textDirection,
          defaultValue: null,
        ),
      );
  }
}

/// How compact a look's controls stand, as Material's `VisualDensity`: each
/// step of [vertical] takes [heightStep] from a control's height and each
/// step of [horizontal] [paddingStep] from its padding at either side, from
/// -4 (tightest) to 4 (roomiest).
///
/// Density tightens a control's face, never its tap target
/// ([RawTapTargets]): a compact face stands in the same target, with
/// more room round it.
///
/// ```dart
/// final height = RawDensity.compact.height(44); // 36
/// ```
///
/// See also:
///
///  * [RawTapTargets], the floors density leaves alone.
@immutable
class RawDensity with Diagnosticable {
  /// Steps from the look's own, each between -4 and 4.
  const RawDensity({
    this.horizontal = 0,
    this.vertical = 0,
    this.heightStep = 4,
    this.paddingStep = 2,
  }) : assert(horizontal >= -4 && horizontal <= 4),
       assert(vertical >= -4 && vertical <= 4),
       assert(heightStep >= 0 && paddingStep >= 0);

  /// The look's own.
  static const RawDensity standard = RawDensity();

  /// One step in: a step off a control's height.
  static const RawDensity comfortable = RawDensity(
    horizontal: -1,
    vertical: -1,
  );

  /// Two steps in: two steps off a control's height and its padding.
  static const RawDensity compact = RawDensity(horizontal: -2, vertical: -2);

  /// The density [platform] expects, as Material's: [compact] on macOS,
  /// Windows and Linux, [standard] on Android, iOS and Fuchsia.
  static RawDensity defaultDensityForPlatform(TargetPlatform platform) =>
      switch (RawInput.forPlatform(platform)) {
        RawInput.touch => standard,
        RawInput.pointer => compact,
      };

  /// [defaultDensityForPlatform] for the running platform.
  static RawDensity get adaptivePlatformDensity =>
      defaultDensityForPlatform(defaultTargetPlatform);

  /// The horizontal step.
  final double horizontal;

  /// The vertical step.
  final double vertical;

  /// What a step of [vertical] adds to a control's height.
  final double heightStep;

  /// What a step of [horizontal] adds to a control's padding at either side.
  final double paddingStep;

  /// What it adds to a control's height.
  double get heightDelta => vertical * heightStep;

  /// What it adds to a control's padding at either side.
  double get paddingDelta => horizontal * paddingStep;

  /// [height] at this density, at least [least].
  double height(double height, {double least = 16}) =>
      math.max(least, height + heightDelta);

  /// [padding] at this density, its sides at least [least] (or as they
  /// were, when less).
  EdgeInsets padding(EdgeInsets padding, {double least = 4}) {
    if (horizontal == 0 && vertical == 0) return padding;
    double across(double v) => math.max(math.min(least, v), v + paddingDelta);
    double down(double v) =>
        math.max(math.min(least / 2, v), v + heightDelta / 4);
    return EdgeInsets.fromLTRB(
      across(padding.left),
      down(padding.top),
      across(padding.right),
      down(padding.bottom),
    );
  }

  /// This with the given fields changed.
  RawDensity copyWith({
    double? horizontal,
    double? vertical,
    double? heightStep,
    double? paddingStep,
  }) => RawDensity(
    horizontal: horizontal ?? this.horizontal,
    vertical: vertical ?? this.vertical,
    heightStep: heightStep ?? this.heightStep,
    paddingStep: paddingStep ?? this.paddingStep,
  );

  /// Between [a] and [b].
  static RawDensity lerp(RawDensity a, RawDensity b, double t) {
    if (identical(a, b)) return a;
    double l(double x, double y) => x + (y - x) * t;
    return RawDensity(
      horizontal: l(a.horizontal, b.horizontal),
      vertical: l(a.vertical, b.vertical),
      heightStep: l(a.heightStep, b.heightStep),
      paddingStep: l(a.paddingStep, b.paddingStep),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RawDensity &&
      other.horizontal == horizontal &&
      other.vertical == vertical &&
      other.heightStep == heightStep &&
      other.paddingStep == paddingStep;

  @override
  int get hashCode =>
      Object.hash(horizontal, vertical, heightStep, paddingStep);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('horizontal', horizontal, defaultValue: 0))
      ..add(DoubleProperty('vertical', vertical, defaultValue: 0))
      ..add(DoubleProperty('heightStep', heightStep, defaultValue: 4))
      ..add(DoubleProperty('paddingStep', paddingStep, defaultValue: 2));
  }
}
