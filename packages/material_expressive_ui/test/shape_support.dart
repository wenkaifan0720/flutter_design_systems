// What the shape tests share: corners measured from the painted outline, the
// part a surface belongs to, and the overlays every family opens.
import 'dart:io';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' show InkResponse;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The four corner radii of [shape] laid on [rect], read from its outer path
/// (so any border, custom or not, is measured the same way): the distance
/// along each corner's diagonal to the first point inside, as a radius.
/// Within 0.5 px of the corner reads as square.
List<double> measureCorners(
  ShapeBorder shape,
  Rect rect, {
  TextDirection textDirection = TextDirection.ltr,
}) {
  final path = shape.getOuterPath(rect, textDirection: textDirection);
  return measurePathCorners(path, rect);
}

/// The four corner radii of [path] in [rect], measured as [measureCorners]
/// measures a shape's outline: what a painter drew, read back.
List<double> measurePathCorners(Path path, Rect rect) {
  final limit = math.min(rect.width, rect.height) / 2;
  double corner(Offset at, Offset inward) {
    for (var d = .05; d <= limit; d += .05) {
      if (path.contains(at + inward * d)) {
        // A circle of radius r meets the diagonal r·(1 − 1/√2) in.
        return d <= .5 ? 0 : d / (1 - 1 / math.sqrt2);
      }
    }
    return limit;
  }

  return [
    corner(rect.topLeft, const Offset(1, 1)),
    corner(rect.topRight, const Offset(-1, 1)),
    corner(rect.bottomRight, const Offset(-1, -1)),
    corner(rect.bottomLeft, const Offset(1, -1)),
  ];
}

const _plumbing = {
  'ExpressiveSurface',
  'ExpressivePressable',
  'ExpressiveSpringShape',
  'ExpressiveSpringColor',
  'ExpressiveSpringSize',
  'ExpressiveSpringValue',
  'ExpressiveSpringTween',
  'ExpressiveStyleScope',
  'ExpressiveSemanticsGroup',
  'ExpressiveMinimumInteractiveSize',
  'ExpressiveTheme',
  'ExpressiveHost',
  'ExpressivePreview',
  'ExpressiveText',
  'ExpressiveIcon',
};

/// The nearest public Expressive part above [element], and the one above
/// that (`ExpressiveListGroup > ExpressiveListItem`).
String ownerOf(Element element) {
  final names = <String>[];
  element.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString().split('<').first;
    if (name.startsWith('Expressive') && !_plumbing.contains(name)) {
      if (names.isEmpty || names.last != name) names.add(name);
    }
    return names.length < 2;
  });
  if (names.isEmpty) {
    return element.widget.runtimeType.toString();
  }
  return names.reversed.join(' > ');
}

/// Whether [element] sits under a widget whose type name is in [names].
bool under(Element element, Set<String> names) {
  var found = false;
  element.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString().split('<').first;
    found = names.contains(name);
    return !found;
  });
  return found;
}

/// A painted surface: its shape, box and whether anything shows.
typedef PaintedSurface = ({
  Element element,
  ShapeBorder shape,
  Rect rect,
  bool visible,
});

ShapeBorder? _decorationShape(Decoration decoration) => switch (decoration) {
  ShapeDecoration(:final shape) => shape,
  BoxDecoration(shape: BoxShape.circle) => const CircleBorder(),
  BoxDecoration(:final borderRadius?) => RoundedRectangleBorder(
    borderRadius: borderRadius,
  ),
  BoxDecoration() => const RoundedRectangleBorder(),
  _ => null,
};

bool _decorationVisible(Decoration decoration) => switch (decoration) {
  ShapeDecoration(:final color, :final gradient, :final image, :final shape) =>
    (color?.a ?? 0) > 0 ||
        gradient != null ||
        image != null ||
        (shape is OutlinedBorder && shape.side.style != BorderStyle.none),
  BoxDecoration(:final color, :final gradient, :final image, :final border) =>
    (color?.a ?? 0) > 0 || gradient != null || image != null || border != null,
  _ => false,
};

/// Every shape a part paints or clips to, beyond the surfaces: decorated
/// boxes and clips (a tab indicator, a thumb, an image's mask).
List<PaintedSurface> paintedShapes(WidgetTester tester) => [
  ...paintedSurfaces(tester),
  for (final element
      in find
          .byWidgetPredicate(
            (w) =>
                w is DecoratedBox ||
                w is ClipRRect ||
                w is ClipPath ||
                w is ClipOval ||
                w is PhysicalShape,
          )
          .evaluate())
    if (element.renderObject case final RenderBox box
        when box.hasSize && !box.size.isEmpty && box.attached)
      if (switch (element.widget) {
            DecoratedBox(:final decoration) => _decorationShape(decoration),
            ClipRRect(:final borderRadius) => RoundedRectangleBorder(
              borderRadius: borderRadius,
            ),
            ClipPath(:final ShapeBorderClipper clipper) => clipper.shape,
            ClipOval() => const CircleBorder(),
            PhysicalShape(:final ShapeBorderClipper clipper) => clipper.shape,
            _ => null,
          }
          case final shape?)
        (
          element: element,
          shape: shape,
          rect: box.localToGlobal(Offset.zero) & box.size,
          visible: switch (element.widget) {
            DecoratedBox(:final decoration) => _decorationVisible(decoration),
            _ => true,
          },
        ),
];

/// Every Expressive surface on stage with a size.
List<PaintedSurface> paintedSurfaces(WidgetTester tester) => [
  for (final element
      in find
          .byWidgetPredicate((w) => w.runtimeType.toString() == '_SurfacePaint')
          .evaluate())
    if (element.renderObject case final RenderBox box
        when box.hasSize && !box.size.isEmpty && box.attached)
      (
        element: element,
        shape: (element.widget as dynamic).shape as ShapeBorder,
        rect: box.localToGlobal(Offset.zero) & box.size,
        visible:
            ((element.widget as dynamic).fill as Color).a > 0 ||
            ((element.widget as dynamic).side as BorderSide).style !=
                BorderStyle.none,
      ),
];

/// An ink response: its box, and the shape its highlight is clipped to
/// (null: unbounded, a circle of [radius]).
typedef InkPart = ({
  Element element,
  Rect rect,
  ShapeBorder? clip,
  double? radius,
});

List<InkPart> inkParts(WidgetTester tester) => [
  for (final element
      in find.byWidgetPredicate((w) => w is InkResponse).evaluate())
    if (element.renderObject case final RenderBox box
        when box.hasSize && !box.size.isEmpty && box.attached)
      (
        element: element,
        rect: box.localToGlobal(Offset.zero) & box.size,
        clip: (element.widget as InkResponse).containedInkWell
            ? (element.widget as InkResponse).customBorder ??
                  ((element.widget as InkResponse).borderRadius == null
                      ? const RoundedRectangleBorder()
                      : RoundedRectangleBorder(
                          borderRadius:
                              (element.widget as InkResponse).borderRadius!,
                        ))
            : null,
        radius: (element.widget as InkResponse).radius,
      ),
];

/// The look's public widgets, read from its source.
Set<String> exportedWidgets() {
  final classes = <String, String>{};
  for (final file in Directory(
    'lib/src/material_expressive',
  ).listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') || file.path.contains('/internal/')) {
      continue;
    }
    for (final match in RegExp(
      r'^class (\w+)(?:<[^\n{]+>)?\s+extends\s+(\w+)',
      multiLine: true,
    ).allMatches(file.readAsStringSync())) {
      classes[match[1]!] = match[2]!;
    }
  }
  bool isWidget(String name) {
    final parent = classes[name]!;
    return parent.endsWith('Widget') ||
        parent.endsWith('Transition') ||
        parent == 'InheritedTheme' ||
        classes.containsKey(parent) && isWidget(parent);
  }

  return {
    for (final name in classes.keys)
      if (!name.startsWith('_') && isWidget(name)) name,
  };
}

/// Public widgets that paint nothing of their own, so have no shape to
/// keep: scopes and tweens other parts are built from.
const paintNothingWidgets = <String, String>{
  'AnimatedExpressiveTheme': 'a theme scope that eases between themes',
  'ExpressiveLocalizationsScope': 'an inherited set of strings',
  'ExpressiveMediaGround': "a theme scope (the host's dark scheme)",
  'ExpressiveSpringSize': 'a spring tween other parts animate with',
};
