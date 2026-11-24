/// The one type of every render object ui_core puts round a control only to
/// add semantics, so a layout can look through them all by one name.
library;

import 'package:flutter/rendering.dart';

import 'form_field.dart' show RawInputDecorator;
import 'pressable.dart' show RawButton;
import 'tabs.dart' show RawTabGroup;

/// A render object ui_core puts round a control only to add semantics: it
/// lays out, paints and takes hits exactly as its child, and adds nothing to
/// the picture.
///
/// ui_core's own extend it: what a [RawButton] given its own words puts
/// round its face, what a [RawInputDecorator] puts round its control, and
/// the node a [RawTabGroup] makes round its tabs.
///
/// It is a [RenderSemanticsAnnotations], the render object of Flutter's
/// `Semantics` widget, with empty [properties]: each subclass describes its
/// node in [describeSemanticsConfiguration], after `super`. So a layout that
/// looks through the render objects which add only semantics by Flutter's
/// types ([RenderSemanticsAnnotations], [RenderMergeSemantics],
/// [RenderExcludeSemantics], [RenderBlockSemantics],
/// [RenderIndexedSemantics]) looks through these too, with no import of
/// ui_core; one that names this type finds ui_core's alone.
///
/// A look never makes one; an app's own may extend it to be looked through
/// the same way.
abstract class RenderSemanticsProxy extends RenderSemanticsAnnotations {
  /// A proxy round [child].
  RenderSemanticsProxy([RenderBox? child])
    : super(
        child: child,
        properties: const SemanticsProperties(),
        container: false,
      );
}
