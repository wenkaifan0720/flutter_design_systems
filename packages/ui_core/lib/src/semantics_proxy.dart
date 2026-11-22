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
/// the node a [RawTabGroup] makes round its tabs. A layout that looks
/// through render objects which add only semantics (one that hosts nested
/// flows through them, and knows them by type, as it knows Flutter's
/// [RenderMergeSemantics]) names this one type for all of them.
///
/// A look never makes one; an app's own may extend it to be looked through
/// the same way.
abstract class RenderDesignSemanticsProxy extends RenderProxyBox {
  /// A proxy round [child].
  RenderDesignSemanticsProxy([super.child]);
}
