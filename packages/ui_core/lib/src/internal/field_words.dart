/// What a [RawInputDecorator] says round its control, for a control of ui_core's
/// that carries those words on a node of its own: a number field's entry,
/// whose node spans the entry alone so that a tap through the semantics
/// tree on a step button reaches no node in the button's place, and a tag
/// input's entry, whose node stands beside the tags' own and merges a field
/// the look builds round its text ([RawFieldWordsEntry]). Inside ui_core;
/// not exported.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tap_target.dart';

/// Whether the platform reads a node's required flag aloud. In Flutter
/// 3.47 the web does: it writes `aria-required` on the node's element, a
/// text field's input included. Android's, iOS's, macOS's, Windows' and
/// Linux's embedders carry the flag and say nothing of it, so a required
/// field keeps its words there.
abstract final class RawRequiredFlag {
  /// Whether the flag is heard: on the web. A test sets it.
  static bool heard = kIsWeb;
}

/// The field's name (its label, and that it is required), its hint (the
/// error, then the help), whether it is required and whether it is invalid,
/// for the control under it that carries them.
class RawFieldWords extends InheritedWidget {
  /// The words of the field round [child].
  const RawFieldWords({
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
  static RawFieldWords? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RawFieldWords>();

  @override
  bool updateShouldNotify(RawFieldWords oldWidget) =>
      name != oldWidget.name ||
      hint != oldWidget.hint ||
      invalid != oldWidget.invalid ||
      required != oldWidget.required;
}

/// Marks [child] as the control that carries its field's words, so the
/// field says them on no node of its own.
class RawFieldWordsCarried extends SingleChildRenderObjectWidget {
  /// Marks [child].
  const RawFieldWordsCarried({super.key, required super.child});

  @override
  RenderFieldWordsCarried createRenderObject(BuildContext context) =>
      RenderFieldWordsCarried();
}

/// The render object of [RawFieldWordsCarried]: a field that finds one
/// under it says its words on no node of its own.
class RenderFieldWordsCarried extends RenderProxyBox {}

/// What a field round a control says on its own node (a
/// [RawInputDecorator]'s label and hint), for a node that carries other
/// words over it not to say the same again.
abstract interface class RawFieldSays {
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
class RawFieldWordsEntry extends SingleChildRenderObjectWidget {
  /// The words of the field round the entry [child].
  const RawFieldWordsEntry({
    super.key,
    required this.name,
    required this.hint,
    required this.invalid,
    required this.required,
    required super.child,
  });

  /// The field's name ([RawFieldWords.name]).
  final String? name;

  /// Its error, then its help ([RawFieldWords.hint]).
  final String? hint;

  /// Whether it shows an error.
  final bool invalid;

  /// Whether it must be filled.
  final bool required;

  @override
  RenderFieldWordsEntry createRenderObject(BuildContext context) =>
      RenderFieldWordsEntry(
        name,
        hint,
        invalid,
        required,
        Directionality.maybeOf(context),
        RawTapTargets.of(context).floorOn(),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderFieldWordsEntry renderObject,
  ) {
    renderObject
      ..name = name
      ..hint = hint
      ..invalid = invalid
      ..required = required
      ..textDirection = Directionality.maybeOf(context)
      ..floor = RawTapTargets.of(context).floorOn()
      // What the entry holds may change (a label of its own, a clear key)
      // while the words stay: describe it again.
      ..markNeedsSemanticsUpdate();
  }
}

/// The render object of [RawFieldWordsEntry].
///
/// Its node spans the entry's reach ([reach]), which may be larger than the
/// entry's box: a short entry beside its tags (a bare text line) is still a
/// touch target tall, as a lone text field is. A tap in the reach that no
/// tag takes reaches the entry ([RawFieldWordsRoom]).
class RenderFieldWordsEntry extends RenderProxyBox {
  /// The node for a field's name and hint round its child: invalid and
  /// required as given, its words read in the text direction given, at
  /// least [floor] large.
  RenderFieldWordsEntry(
    this._name,
    this._hint,
    this._invalid,
    this._required,
    this._textDirection,
    this._floor,
  );

  Size _floor;

  /// The least size of the entry's node and of the area a tap on it
  /// reaches ([RawTapTargets.floorOn]).
  Size get floor => _floor;
  set floor(Size value) {
    if (value == _floor) return;
    _floor = value;
    markNeedsSemanticsUpdate();
  }

  /// The area the entry's node spans and a tap reaches, in its own units:
  /// its box, and any larger node a descendant it merges declares (a look's
  /// own lane round its line), grown to [floor] about its middle; kept
  /// inside the [RawFieldWordsRoom] round the tags and the entry, and off
  /// every tag's box, so a tag keeps its own taps and its own node.
  Rect get reach {
    if (!hasSize) return Rect.zero;
    final own = Offset.zero & size;
    final declared = _declared(own);
    // Where nothing round it says how far a tap reaches, the node keeps to
    // what it is given.
    final room = _room;
    if (room == null || !room.hasSize) return declared;
    final toEntry = _transformFrom(room);
    if (toEntry == null) return declared;
    final bounds = MatrixUtils.transformRect(toEntry, Offset.zero & room.size);
    final tags = <Rect>[
      for (final tag in room.tags)
        if (tag.hasSize && tag.attached)
          if (_transformFrom(tag) case final toTag?)
            MatrixUtils.transformRect(toTag, Offset.zero & tag.size),
    ];
    // Across first: the room's width less the tags on the entry's line.
    var start = bounds.left;
    var end = bounds.right;
    for (final t in tags) {
      if (t.bottom <= own.top || t.top >= own.bottom) continue;
      if (t.right <= own.left) start = math.max(start, t.right);
      if (t.left >= own.right) end = math.min(end, t.left);
    }
    final across = _place(own.left, own.right, floor.width, start, end);
    // Then down: the room's height less the tags above and below that span.
    var top = bounds.top;
    var bottom = bounds.bottom;
    for (final t in tags) {
      if (t.right <= across.$1 || t.left >= across.$2) continue;
      if (t.bottom <= own.top) top = math.max(top, t.bottom);
      if (t.top >= own.bottom) bottom = math.min(bottom, t.top);
    }
    final down = _place(own.top, own.bottom, floor.height, top, bottom);
    return Rect.fromLTRB(
      across.$1,
      down.$1,
      across.$2,
      down.$2,
    ).expandToInclude(declared);
  }

  // A span from [from] to [to] grown to [least] about its middle, slid
  // inside [min] to [max] (cut to them where it can't fit); never smaller
  // than the span itself.
  static (double, double) _place(
    double from,
    double to,
    double least,
    double min,
    double max,
  ) {
    final length = math.max(to - from, least);
    var a = (from + to) / 2 - length / 2;
    var b = a + length;
    if (a < min) {
      b = math.min(max, b + (min - a));
      a = min;
    }
    if (b > max) {
      a = math.max(min, a - (b - max));
      b = max;
    }
    return (math.min(a, from), math.max(b, to));
  }

  // The transform from [box]'s units to this one's; null where none is.
  Matrix4? _transformFrom(RenderObject box) {
    final toBox = getTransformTo(box);
    return toBox.invert() == 0 ? null : toBox;
  }

  // The nodes this one merges that declare a larger area than their box (a
  // look's lane round its line): their union with [own], in its units.
  Rect _declared(Rect own) {
    if (_holdsAnotherControl()) return own;
    var area = own;
    void visit(RenderObject n) {
      if (n is RenderExcludeSemantics && n.excluding) return;
      if (n is RenderBox && n.hasSize) {
        final bounds = n.semanticBounds;
        if (bounds != Offset.zero & n.size) {
          final toEntry = n.getTransformTo(this);
          area = area.expandToInclude(
            MatrixUtils.transformRect(toEntry, bounds),
          );
        }
      }
      n.visitChildrenForSemantics(visit);
    }

    visitChildrenForSemantics(visit);
    return area;
  }

  RenderFieldWordsRoom? get _room {
    for (var node = parent; node != null; node = node.parent) {
      if (node is RenderFieldWordsRoom) return node;
    }
    return null;
  }

  Rect? _reported;

  @override
  Rect get semanticBounds => reach;

  @override
  void paint(PaintingContext context, Offset offset) {
    // The tags and the room move without this entry laying out again: its
    // node follows its reach.
    final reach = this.reach;
    if (_reported != reach) {
      _reported = reach;
      markNeedsSemanticsUpdate();
    }
    super.paint(context, offset);
  }

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
      if (n case final RawFieldSays field) {
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

/// The tags and the entry of a tag input in a field, as it lays them out:
/// a tap in the entry's reach ([RenderFieldWordsEntry.reach]) that
/// nothing under it takes goes to the entry, on its middle row across from
/// the tap.
class RawFieldWordsRoom extends SingleChildRenderObjectWidget {
  /// The room round [child], the tags and the entry.
  const RawFieldWordsRoom({super.key, required super.child});

  @override
  RenderFieldWordsRoom createRenderObject(BuildContext context) =>
      RenderFieldWordsRoom();
}

/// One tag in a [RawFieldWordsRoom]: the entry's reach stays off it.
class RawFieldWordsTag extends SingleChildRenderObjectWidget {
  /// Marks [child] as a tag.
  const RawFieldWordsTag({super.key, required super.child});

  @override
  RenderProxyBox createRenderObject(BuildContext context) => _RenderTag();
}

class _RenderTag extends RenderProxyBox {}

/// The render object of [RawFieldWordsRoom].
class RenderFieldWordsRoom extends RenderProxyBox {
  /// The tags under it, in paint order.
  List<RenderBox> get tags {
    final found = <RenderBox>[];
    void visit(RenderObject n) {
      if (n is RenderFieldWordsRoom) return;
      if (n is _RenderTag) {
        found.add(n);
        return;
      }
      n.visitChildren(visit);
    }

    visitChildren(visit);
    return found;
  }

  // The entry under it: the first one not in a room of its own.
  RenderFieldWordsEntry? _entry() {
    RenderFieldWordsEntry? found;
    void visit(RenderObject n) {
      if (found != null || n is RenderFieldWordsRoom) return;
      if (n is RenderFieldWordsEntry) {
        found = n;
        return;
      }
      n.visitChildren(visit);
    }

    visitChildren(visit);
    return found;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (super.hitTest(result, position: position)) return true;
    if (!size.contains(position)) return false;
    final entry = _entry();
    if (entry == null || !entry.hasSize || !entry.attached) return false;
    final toRoom = entry.getTransformTo(this);
    if (!MatrixUtils.transformRect(toRoom, entry.reach).contains(position)) {
      return false;
    }
    final toEntry = Matrix4.copy(toRoom);
    if (toEntry.invert() == 0) return false;
    // Onto the entry's middle row, where its text line stands, across from
    // the tap.
    final at = MatrixUtils.transformPoint(toEntry, position);
    final onEntry = Offset(
      at.dx.clamp(0.0, math.max(0.0, entry.size.width - 0.5)),
      entry.size.height / 2,
    );
    return result.addWithRawTransform(
      transform: toEntry,
      position: position,
      hitTest: (result, _) => entry.hitTest(result, position: onEntry),
    );
  }
}
