part of '../alignment.dart';

/// Whether a group of radios answers the keyboard as Flutter's
/// [RadioGroup] does, and says what each radio is.
///
/// - **One tab stop**: Tab from before the group lands on its chosen radio
///   (on its first one that can be chosen when none is), and a second Tab
///   leaves the group: `Tab from before the group lands on "A", not on the
///   chosen "B"`, `a second Tab stays in the group, on "B"`.
/// - **Arrows choose**: Down and Up move to the next and the previous radio
///   that can be chosen, round from the last to the first, and choose it
///   (a radio already chosen is taken as chosen by the key);
///   so do the arrow pointing the way the group reads and the one pointing
///   back (Right and Left, Left and Right right to left): `Down from "A"
///   moves to "C", not to "B"`, `Down moves to "B" but does not choose it`.
///   A radio turned off is passed over.
/// - **What each radio says**: [DesignCheckableCheck] over the group.
///
/// The radios are the group's own nodes in a group of which one is chosen,
/// read in reading order: the nodes its widgets make, not another's drawn
/// over it (a sheet's group over a page's). A group none of whose nodes
/// stand in the semantics tree (behind a modal route's barrier) is out of
/// reach and passes unread. Focus outside the group's widgets is outside
/// the group, whatever lies under it on screen. The check moves the focus and sends keys, so the
/// group's `onChanged` must hold the choice, as an app's does (a
/// [StatefulBuilder] round it in a test). [before] is a focusable control
/// just before the group, and the check takes the tester's
/// `sendKeyEvent` and `pump`:
///
/// ```dart
/// final report = await const DesignRadioGroupCheck(look: 'Comic').check(
///   tester.element(find.byKey(const ValueKey('plan'))),
///   before: before,
///   sendKeyEvent: tester.sendKeyEvent,
///   pump: tester.pump,
/// );
/// report.verify();
/// ```
///
/// It drives the keys and reads the focus and the semantics tree, and no
/// pixels.
@immutable
class DesignRadioGroupCheck {
  /// A check for [look].
  const DesignRadioGroupCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks the radios under [group], starting from [before].
  Future<DesignAlignmentReport> check(
    BuildContext group, {
    required FocusNode before,
    required Future<bool> Function(LogicalKeyboardKey key) sendKeyEvent,
    required Future<void> Function() pump,
  }) async {
    final found = <String>[];
    // The way the group reads, before the keys move anything.
    final rtl = Directionality.maybeOf(group) == TextDirection.rtl;
    final reader = _RadioReader(group);
    var radios = reader.radios();
    if (radios.length < 2) {
      if (reader.outOfTree) return DesignAlignmentReport(look, const []);
      return DesignAlignmentReport(look, [
        'a group of ${radios.length} radios: a group holds two or more',
      ]);
    }
    for (final r in radios) {
      final problem = _checkableProblem(r.data);
      if (problem != null) found.add(problem);
    }

    Future<void> key(LogicalKeyboardKey k) async {
      await sendKeyEvent(k);
      await pump();
    }

    Future<void> enter() async {
      before.requestFocus();
      await pump();
      await key(LogicalKeyboardKey.tab);
    }

    // One tab stop.
    final chosen = radios.indexWhere((r) => r.checked && r.enabled);
    final first = radios.indexWhere((r) => r.enabled);
    final start = chosen >= 0 ? chosen : first;
    await enter();
    var at = reader.focused(radios);
    if (at != start) {
      found.add(
        'Tab from before the group lands '
        '${_where(radios, at)}, not on '
        '${chosen >= 0 ? 'the chosen' : 'the first'} ${radios[start].name}',
      );
    }
    if (at >= 0) {
      await key(LogicalKeyboardKey.tab);
      final still = reader.focused(radios);
      if (still >= 0) {
        found.add('a second Tab stays in the group, on ${radios[still].name}');
      }
    }

    // Arrows choose, round the group.
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    String keyName(LogicalKeyboardKey k) => switch (k) {
      LogicalKeyboardKey.arrowDown => 'Down',
      LogicalKeyboardKey.arrowUp => 'Up',
      LogicalKeyboardKey.arrowLeft => 'Left',
      LogicalKeyboardKey.arrowRight => 'Right',
      _ => k.keyLabel,
    };
    for (final (k, step) in [
      (LogicalKeyboardKey.arrowDown, 1),
      (LogicalKeyboardKey.arrowUp, -1),
      (forward, 1),
      (back, -1),
    ]) {
      await enter();
      radios = reader.radios();
      final from = reader.focused(radios);
      if (from < 0) break;
      var expected = from;
      do {
        expected = (expected + step) % radios.length;
      } while (!radios[expected].enabled && expected != from);
      await key(k);
      radios = reader.radios();
      final to = reader.focused(radios);
      if (to != expected) {
        found.add(
          '${keyName(k)} from ${radios[from].name} moves '
          '${_where(radios, to)}, not to ${radios[expected].name}',
        );
      } else if (!radios[to].checked) {
        found.add(
          '${keyName(k)} moves to ${radios[to].name} but does not choose it',
        );
      }
    }
    return DesignAlignmentReport(look, found);
  }

  static String _where(List<_Radio> radios, int at) =>
      at >= 0 ? 'on ${radios[at].name}' : 'outside the group';
}

// One radio as the semantics tree says it.
class _Radio {
  const _Radio(this.data, this.rect);

  final SemanticsData data;
  final Rect rect;

  bool get checked => data.flagsCollection.isChecked == CheckedState.isTrue;

  bool get enabled => data.flagsCollection.isEnabled != Tristate.isFalse;

  String get name {
    final words = data.label.replaceAll('\n', ' ').trim();
    return words.isEmpty ? 'a radio' : '"$words"';
  }
}

// Reads a group's radios and which one has the focus.
class _RadioReader {
  _RadioReader(this.group);

  final BuildContext group;

  Rect get _area {
    final box = group.findRenderObject();
    return box is RenderBox && box.hasSize ? _global(box) : Rect.zero;
  }

  // The nodes the group's own render objects make (a node merged into
  // another read as the one it merges into), as a debug build maps the
  // render tree to the semantics tree; null where it is not mapped (a
  // release build: then by the group's place on screen).
  Set<SemanticsNode>? _ownNodes() {
    final root = group.findRenderObject();
    if (root == null) return null;
    if (kReleaseMode) return null;
    final own = <SemanticsNode>{};
    void visit(RenderObject r) {
      final node = r.debugSemantics;
      if (node != null) {
        var read = node;
        while (read.isMergedIntoParent && read.parent != null) {
          read = read.parent!;
        }
        if (read.attached) own.add(read);
      }
      r.visitChildren(visit);
    }

    visit(root);
    return own;
  }

  // Whether none of the group's nodes stand in the semantics tree: behind
  // a modal route's barrier, nothing reaches it.
  bool get outOfTree {
    final own = _ownNodes();
    return own != null && own.isEmpty;
  }

  // The group's radios in reading order.
  List<_Radio> radios() {
    final box = group.findRenderObject();
    final semantics = box?.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignRadioGroupCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final area = _area.inflate(1);
    final ratio = View.of(group).devicePixelRatio;
    final rtl = Directionality.maybeOf(group) == TextDirection.rtl;
    final own = _ownNodes();
    final found = [
      for (final (node, rect) in _placedNodes(semantics, ratio))
        if (!node.isMergedIntoParent &&
            (own != null ? own.contains(node) : area.contains(rect.center)) &&
            node.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup)
          _Radio(node.getSemanticsData(), rect),
    ];
    // Lines top to bottom, each the way it reads.
    found.sort((a, b) {
      if ((a.rect.center.dy - b.rect.center.dy).abs() >
          math.min(a.rect.height, b.rect.height) / 2) {
        return a.rect.center.dy.compareTo(b.rect.center.dy);
      }
      final x = a.rect.center.dx.compareTo(b.rect.center.dx);
      return rtl ? -x : x;
    });
    return found;
  }

  // The radio the focus is on: -1 when the focus is outside the group.
  int focused(List<_Radio> radios) {
    final context = FocusManager.instance.primaryFocus?.context;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return -1;
    if (context is Element && !_within(context)) return -1;
    final rect = _global(box);
    if (!_area.inflate(1).contains(rect.center)) return -1;
    for (var i = 0; i < radios.length; i++) {
      final r = radios[i].rect;
      if (r.contains(rect.center) || rect.contains(r.center)) return i;
    }
    return -1;
  }

  // Whether [element] is the group's or stands under it.
  bool _within(Element element) {
    if (identical(element, group)) return true;
    var under = false;
    element.visitAncestorElements((e) {
      under = identical(e, group);
      return !under;
    });
    return under;
  }
}
