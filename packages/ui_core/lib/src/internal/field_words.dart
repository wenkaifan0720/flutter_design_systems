/// What a [RawInputDecorator] says round its control, for a control of ui_core's
/// that carries those words on a node of its own: a number field's entry,
/// whose node spans the entry alone so that a tap through the semantics
/// tree on a step button reaches no node in the button's place, and a tag
/// input's entry, whose node stands beside the tags' own and merges a field
/// the look builds round its text ([DesignFieldWordsEntry]). Inside ui_core;
/// not exported.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Whether the platform reads a node's required flag aloud. In Flutter
/// 3.47 the web does: it writes `aria-required` on the node's element, a
/// text field's input included. Android's, iOS's, macOS's, Windows' and
/// Linux's embedders carry the flag and say nothing of it, so a required
/// field keeps its words there.
abstract final class DesignRequiredFlag {
  /// Whether the flag is heard: on the web. A test sets it.
  static bool heard = kIsWeb;
}

/// The field's name (its label, and that it is required), its hint (the
/// error, then the help), whether it is required and whether it is invalid,
/// for the control under it that carries them.
class DesignFieldWords extends InheritedWidget {
  /// The words of the field round [child].
  const DesignFieldWords({
    super.key,
    required this.name,
    required this.hint,
    required this.invalid,
    this.required = false,
    required super.child,
  });

  /// The field's label, with the words a required field adds; null when it
  /// has no label.
  final String? name;

  /// The field's error, then its help; null when it has neither.
  final String? hint;

  /// Whether the field shows an error.
  final bool invalid;

  /// Whether the field must be filled: the node that carries the words
  /// sets the required flag.
  final bool required;

  /// The words of the nearest field round [context], or null outside one.
  static DesignFieldWords? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesignFieldWords>();

  @override
  bool updateShouldNotify(DesignFieldWords oldWidget) =>
      name != oldWidget.name ||
      hint != oldWidget.hint ||
      invalid != oldWidget.invalid ||
      required != oldWidget.required;
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

/// What a field round a control says on its own node (a
/// [RawInputDecorator]'s label and hint), for a node that carries other
/// words over it not to say the same again.
abstract interface class DesignFieldSays {
  /// The label it says; null: none.
  String? get saysLabel;

  /// The hint it says; null: none.
  String? get saysHint;
}

/// The node a tag input's entry carries its field's words on, as a lone text
/// field's node does: [name] and [hint], invalid and required, on one node
/// with the text entry under it. It merges what it holds, so the words and
/// the text field read together even where the look's entry has a node of
/// its own (a text field built on a [RawInputDecorator], a boundary); words
/// the entry says already (its own label, a hint that is the help) are not
/// said twice. An entry that holds a control besides its text (a clear key)
/// is not merged, so each control keeps its own node and action.
class DesignFieldWordsEntry extends SingleChildRenderObjectWidget {
  /// The words of the field round the entry [child].
  const DesignFieldWordsEntry({
    super.key,
    required this.name,
    required this.hint,
    required this.invalid,
    required this.required,
    required super.child,
  });

  /// The field's name ([DesignFieldWords.name]).
  final String? name;

  /// Its error, then its help ([DesignFieldWords.hint]).
  final String? hint;

  /// Whether it shows an error.
  final bool invalid;

  /// Whether it must be filled.
  final bool required;

  @override
  RenderDesignFieldWordsEntry createRenderObject(BuildContext context) =>
      RenderDesignFieldWordsEntry(
        name,
        hint,
        invalid,
        required,
        Directionality.maybeOf(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderDesignFieldWordsEntry renderObject,
  ) {
    renderObject
      ..name = name
      ..hint = hint
      ..invalid = invalid
      ..required = required
      ..textDirection = Directionality.maybeOf(context)
      // What the entry holds may change (a label of its own, a clear key)
      // while the words stay: describe it again.
      ..markNeedsSemanticsUpdate();
  }
}

/// The render object of [DesignFieldWordsEntry].
class RenderDesignFieldWordsEntry extends RenderProxyBox {
  /// The node for a field's name and hint round its child: invalid and
  /// required as given, its words read in the text direction given.
  RenderDesignFieldWordsEntry(
    this._name,
    this._hint,
    this._invalid,
    this._required,
    this._textDirection,
  );

  String? _name;
  set name(String? value) {
    if (value == _name) return;
    _name = value;
    markNeedsSemanticsUpdate();
  }

  String? _hint;
  set hint(String? value) {
    if (value == _hint) return;
    _hint = value;
    markNeedsSemanticsUpdate();
  }

  bool _invalid;
  set invalid(bool value) {
    if (value == _invalid) return;
    _invalid = value;
    markNeedsSemanticsUpdate();
  }

  bool _required;
  set required(bool value) {
    if (value == _required) return;
    _required = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (!_holdsAnotherControl()) config.isMergingSemanticsOfDescendants = true;
    final (:label, :hint) = _said();
    final name = _name;
    if (name != null && name.isNotEmpty && !label) config.label = name;
    final help = _hint;
    if (help != null && help.isNotEmpty && !hint) config.hint = help;
    if (config.label.isNotEmpty || config.hint.isNotEmpty) {
      config.textDirection = _textDirection;
    }
    config.validationResult = _invalid
        ? SemanticsValidationResult.invalid
        : SemanticsValidationResult.none;
    if (_required) config.isRequired = true;
  }

  // Whether the entry says the name, or the hint, already: on a field of
  // its own round its text, in a Semantics label or hint, or in words it
  // shows.
  ({bool label, bool hint}) _said() {
    final name = _name?.trim().toLowerCase() ?? '';
    final help = _hint?.trim().toLowerCase() ?? '';
    var label = false;
    var hint = false;
    bool says(String? text, String words) =>
        words.isNotEmpty &&
        text != null &&
        text.split('\n').any((line) => line.trim().toLowerCase() == words);
    void visit(RenderObject n) {
      if ((label && hint) || (n is RenderExcludeSemantics && n.excluding)) {
        return;
      }
      if (n case final DesignFieldSays field) {
        label = label || says(field.saysLabel, name);
        hint = hint || says(field.saysHint, help);
      }
      if (n is RenderSemanticsAnnotations) {
        label = label || says(n.properties.label, name);
        hint = hint || says(n.properties.hint, help);
        if (n.excludeSemantics) return;
      }
      if (n is RenderParagraph) {
        label =
            label ||
            says(n.text.toPlainText(includeSemanticsLabels: true), name);
      }
      n.visitChildrenForSemantics(visit);
    }

    visitChildrenForSemantics(visit);
    return (label: label, hint: hint);
  }

  // Whether the entry holds a control besides its text entry and the press
  // round it (a clear key): merged, its action would fold into the entry's.
  bool _holdsAnotherControl() {
    bool holdsEntry(RenderObject n) {
      if (n is RenderEditable) return true;
      var found = false;
      n.visitChildrenForSemantics((c) => found = found || holdsEntry(c));
      return found;
    }

    var found = false;
    void visit(RenderObject n) {
      if (found || (n is RenderExcludeSemantics && n.excluding)) return;
      if (n is RenderEditable) return;
      if (_acts(n) && !holdsEntry(n)) {
        found = true;
        return;
      }
      n.visitChildrenForSemantics(visit);
    }

    visitChildrenForSemantics(visit);
    return found;
  }

  // A node a press acts on, or one with a state of its own.
  static bool _acts(RenderObject n) {
    if (n is RenderSemanticsGestureHandler) {
      return n.onTap != null || n.onLongPress != null;
    }
    if (n is RenderSemanticsAnnotations) {
      final p = n.properties;
      return p.button == true ||
          p.link == true ||
          p.toggled != null ||
          p.checked != null ||
          p.onTap != null ||
          p.onLongPress != null ||
          p.onIncrease != null ||
          p.onDecrease != null;
    }
    return false;
  }
}
