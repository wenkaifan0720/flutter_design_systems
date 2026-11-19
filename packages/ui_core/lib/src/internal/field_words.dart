/// What a [DesignField] says round its control, for a control of ui_core's
/// that carries those words on a node of its own: a number field's entry,
/// whose node spans the entry alone so that a tap through the semantics
/// tree on a step button reaches no node in the button's place. Inside
/// ui_core; not exported.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The field's name (its label, and that it is required), its hint (the
/// error, then the help) and whether it is invalid, for the control under
/// it that carries them.
class DesignFieldWords extends InheritedWidget {
  /// The words of the field round [child].
  const DesignFieldWords({
    super.key,
    required this.name,
    required this.hint,
    required this.invalid,
    required super.child,
  });

  /// The field's label, with the words a required field adds; null when it
  /// has no label.
  final String? name;

  /// The field's error, then its help; null when it has neither.
  final String? hint;

  /// Whether the field shows an error.
  final bool invalid;

  /// The words of the nearest field round [context], or null outside one.
  static DesignFieldWords? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesignFieldWords>();

  @override
  bool updateShouldNotify(DesignFieldWords oldWidget) =>
      name != oldWidget.name ||
      hint != oldWidget.hint ||
      invalid != oldWidget.invalid;
}

/// Marks [child] as the control that carries its field's words, so the
/// field says them on no node of its own.
class DesignFieldWordsCarried extends SingleChildRenderObjectWidget {
  /// Marks [child].
  const DesignFieldWordsCarried({super.key, required super.child});

  @override
  RenderDesignFieldWordsCarried createRenderObject(BuildContext context) =>
      RenderDesignFieldWordsCarried();
}

/// The render object of [DesignFieldWordsCarried]: a field that finds one
/// under it says its words on no node of its own.
class RenderDesignFieldWordsCarried extends RenderProxyBox {}
