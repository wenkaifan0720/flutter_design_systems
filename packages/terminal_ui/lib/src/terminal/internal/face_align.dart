import 'package:flutter/widgets.dart';

/// Where a tap target's face stands in its target when its caller leaves
/// it centred: a list row's action stands on the row's first line, its face
/// at the top of a target taller than a line.
class TermFaceAlign extends InheritedWidget {
  /// Faces under [child] stand by [alignment].
  const TermFaceAlign({
    super.key,
    required this.alignment,
    required super.child,
  });

  /// Where the face stands.
  final AlignmentGeometry alignment;

  /// The alignment above [context], or null where none is.
  static AlignmentGeometry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TermFaceAlign>()?.alignment;

  @override
  bool updateShouldNotify(TermFaceAlign oldWidget) =>
      oldWidget.alignment != alignment;
}
