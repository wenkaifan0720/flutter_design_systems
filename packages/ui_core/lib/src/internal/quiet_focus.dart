/// Focus that ui_core gives back by itself (a closed surface returning it),
/// not focus the user gave: a field's list does not open on it. Inside
/// ui_core; not exported.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Focus given back by ui_core, which a field's list does not open on.
abstract final class DesignQuietFocus {
  static FocusNode? _node;

  /// Focuses [node], noted as given back.
  static void restore(FocusNode node) {
    _node = node;
    node.requestFocus();
    // The focus moves in a microtask the request queued; the note lasts
    // until it has.
    scheduleMicrotask(() {
      if (identical(_node, node)) _node = null;
    });
  }

  /// Whether the primary focus is one being given back.
  static bool get isRestoring {
    final node = _node;
    final primary = FocusManager.instance.primaryFocus;
    return node != null &&
        primary != null &&
        (identical(primary, node) || primary.ancestors.contains(node));
  }
}
