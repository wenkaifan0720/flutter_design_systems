/// Flutter's [RadioGroup] with its two keyboard faults fixed as Flutter's own
/// fixes fix them, until a Flutter release that ui_core needs has them.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Fixes the keys of the [RadioGroup] round it as Flutter's own fixes do,
/// until a Flutter release that ui_core needs has them:
///
/// - **One Tab stop when the chosen radio can't take focus** (it is turned
///   off, say). Tab and Shift+Tab stop on the first radio in reading order
///   that Tab can reach. Flutter's group lets Tab pass over every radio.
/// - **Left and Right follow the radios' text direction.** When every radio
///   that can be chosen is in right-to-left text, Left chooses the next radio
///   in reading order and Right the previous one, so in a right-to-left row
///   each chooses the radio on its side. If the radios' text directions
///   differ, Left and Right keep their left-to-right mapping. Down chooses
///   the next radio and Up the previous one, in either direction. Flutter's
///   group maps Left and Right as in left-to-right text, always.
///
/// Put it inside the [RadioGroup] as the group's child, round the radios: a
/// look's radio is a [RawRadio] given `RadioGroup.maybeOf<T>(context)` as its
/// `groupRegistry`, the face drawn in its `builder`. It adds no layout,
/// semantics or focus of its own, and the group still says it is a radio
/// group and answers Space.
///
/// A look's radio, inside the group (here a `String`'s, its face drawn by the
/// look's `radioFace`):
///
/// ```dart
/// MergeSemantics(
///   child: RawRadio<String>(
///     value: 'Day',
///     mouseCursor: WidgetStateMouseCursor.clickable,
///     toggleable: false,
///     focusNode: focusNode, // the caller's, else one its State owns
///     autofocus: false,
///     groupRegistry: RadioGroup.maybeOf<String>(context),
///     enabled: true,
///     builder: (context, radio) => Semantics(
///       label: 'Day',
///       child: ExcludeSemantics(
///         child: radioFace(
///           {
///             ...radio.states,
///             if (radio.downPosition != null) WidgetState.pressed,
///           },
///           radio.value ?? false,
///         ),
///       ),
///     ),
///   ),
/// )
/// ```
///
/// `radio.states` holds disabled, hovered, focused and selected: add pressed
/// while `radio.downPosition` is set. [RawRadio] says the radio is checked and
/// one of a group, and takes the tap and the focus; the look's face draws and
/// takes neither. Its words go on a [Semantics] round the face, merged with
/// the radio's into one node. [RawRadio] takes a press only where the face is
/// hit, so give the face a box that is hit all over, a [Listener] with
/// [HitTestBehavior.opaque] round it, or a fill: else a press between its
/// painted parts (between the ring and the words) misses the radio. A group
/// that takes no choice: [RadioGroup] takes no null `onChanged`, so give it
/// one that does nothing and turn each radio off (`enabled: false`).
///
/// ```dart
/// RadioGroup<String>(groupValue: chosen, onChanged: choose, child: RadioGroupKeyboardFix<String>(child: Column(children: [dayRadio, weekRadio])))
/// ```
class RadioGroupKeyboardFix<T> extends StatefulWidget {
  /// Fixes the keys of the radios in [child].
  const RadioGroupKeyboardFix({super.key, required this.child});

  /// The radios, laid out by the look.
  final Widget child;

  @override
  State<RadioGroupKeyboardFix<T>> createState() =>
      _RadioGroupKeyboardFixState<T>();
}

class _RadioGroupKeyboardFixState<T> extends State<RadioGroupKeyboardFix<T>> {
  RadioGroupRegistry<T>? _registry;

  late final _ArrowKeys<T> _arrowKeys = _ArrowKeys<T>(this);

  @override
  void dispose() {
    _arrowKeys.dispose();
    super.dispose();
  }

  // The radios the enclosing group holds, under this widget: the group's own
  // set is private, so they are found among the elements below, each a
  // RadioClient that registered with the group's registry (as RawRadio and
  // Radio do while they can be chosen).
  Set<RadioClient<T>> get _radios {
    final registry = _registry;
    final radios = <RadioClient<T>>{};
    if (registry == null || !mounted) return radios;
    void visit(Element element) {
      if (element is StatefulElement) {
        final state = element.state;
        // A State that mixes in RadioClient is no subtype of it to promote to.
        final radio = state is RadioClient<T> ? state as RadioClient<T> : null;
        if (radio != null && radio.registry == registry) radios.add(radio);
      }
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
    return radios;
  }

  @override
  Widget build(BuildContext context) {
    _registry = RadioGroup.maybeOf<T>(context);
    assert(
      _registry != null,
      'A RadioGroupKeyboardFix<$T> goes inside a RadioGroup<$T>.',
    );
    return Shortcuts.manager(
      manager: _arrowKeys,
      child: FocusTraversalGroup(
        policy: _TabStopPolicy<T>(() => _radios, () => _registry?.groupValue),
        child: widget.child,
      ),
    );
  }
}

// The Tab stop: flutter/flutter#197072, fixed by
// https://github.com/flutter/flutter/pull/197073. Flutter 3.50's RadioGroup
// keeps the chosen radio as its one Tab stop even when Tab can't reach it,
// so Tab passes over the group. This policy is the pull request's
// _SkipUnselectedRadioPolicy, on a traversal group inside RadioGroup's: the
// radios are this group's members, and RadioGroup's own policy finds none of
// them among its own and keeps its order.
//
// Remove it, and the FocusTraversalGroup that holds it, when ui_core's
// Flutter floor is a stable release with #197073. Its tests
// (radio_group_keyboard_fix_test.dart, "Radio group Tab stop") are the pull
// request's and pass without it there.
class _TabStopPolicy<T> extends ReadingOrderTraversalPolicy {
  _TabStopPolicy(this._radios, this._groupValue);

  final Set<RadioClient<T>> Function() _radios;
  final T? Function() _groupValue;

  // Whether focus traversal from the current node can reach the node. Besides
  // the node's own state, a focus scope that skips traversal hides the nodes
  // inside it from traversal that starts outside it.
  static bool _isTraversalCandidate(FocusNode node, FocusNode currentNode) {
    if (node == currentNode) {
      return true;
    }
    if (node.parent == null || !node.canRequestFocus || node.skipTraversal) {
      return false;
    }
    for (final FocusNode ancestor in node.ancestors) {
      if (ancestor is FocusScopeNode &&
          ancestor.skipTraversal &&
          ancestor != currentNode &&
          !currentNode.ancestors.contains(ancestor)) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<FocusNode> sortDescendants(
    Iterable<FocusNode> descendants,
    FocusNode currentNode,
  ) {
    final Iterable<FocusNode> nodesInReadOrder = super.sortDescendants(
      descendants,
      currentNode,
    );
    final radios = _radios();
    final groupValue = _groupValue();
    RadioClient<T>? selected;
    for (final radio in radios) {
      if (radio.radioValue == groupValue) {
        selected = radio;
        break;
      }
    }

    // If Tab can't reach the selected radio, for example because it is
    // disabled, treat the group as if none of the radios are selected, so that
    // the first of its own radios becomes the Tab stop. The descendants hold
    // only this group's own members. If Tab can reach a radio inside a nested
    // focus traversal group or focus scope instead, defer to that group's or
    // scope's policy.
    if (selected != null &&
        !_isTraversalCandidate(selected.focusNode, currentNode)) {
      final Set<FocusNode> members = descendants.toSet();
      final bool nestedCandidate = radios.any(
        (RadioClient<T> radio) =>
            !members.contains(radio.focusNode) &&
            _isTraversalCandidate(radio.focusNode, currentNode),
      );
      if (!nestedCandidate) {
        selected = null;
      }
    }

    if (selected == null) {
      // None of the radio are selected. Select the first radio in read order.
      final radioFocusNodes = <FocusNode, RadioClient<T>>{};
      for (final RadioClient<T> radio in radios) {
        radioFocusNodes[radio.focusNode] = radio;
      }

      for (final node in nodesInReadOrder) {
        selected = radioFocusNodes[node];
        if (selected != null) {
          break;
        }
      }
    }

    if (selected == null) {
      // None of the radio is selected or focusable, defaults to reading order
      return nodesInReadOrder;
    }

    // Nodes that are not selected AND not currently focused, since we can't
    // remove the focused node from the sorted result.
    final Set<FocusNode> nodeToSkip = radios
        .where(
          (RadioClient<T> radio) =>
              selected != radio && radio.focusNode != currentNode,
        )
        .map<FocusNode>((RadioClient<T> radio) => radio.focusNode)
        .toSet();
    final Iterable<FocusNode> skipsNonSelected = descendants.where(
      (FocusNode node) => !nodeToSkip.contains(node),
    );
    return super.sortDescendants(skipsNonSelected, currentNode);
  }
}

// The arrows: Left and Right in right-to-left text, fixed on Flutter's branch
// 4b0bb03252 ("RadioGroup: swap Left and Right in right-to-left text"; its
// pull request is not yet open). Flutter 3.50's RadioGroup maps Left to the
// previous radio and Right to the next, in either text direction. These
// shortcuts, inside RadioGroup's, take the four arrows while a radio has
// focus, as RadioGroup's do, and move as the fixed _selectRadioInDirection
// does. Space stays RadioGroup's.
//
// Remove them, and the Shortcuts that holds them, when ui_core's Flutter
// floor is a stable release with that fix. Their tests
// (radio_group_keyboard_fix_test.dart, "Radio group arrow keys") are the
// branch's and pass without them there.
class _ArrowKeys<T> extends ShortcutManager {
  _ArrowKeys(this._fix) {
    shortcuts = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.arrowLeft): VoidCallbackIntent(
        _selectLeftRadio,
      ),
      const SingleActivator(LogicalKeyboardKey.arrowRight): VoidCallbackIntent(
        _selectRightRadio,
      ),
      const SingleActivator(LogicalKeyboardKey.arrowDown): VoidCallbackIntent(
        _selectNextRadio,
      ),
      const SingleActivator(LogicalKeyboardKey.arrowUp): VoidCallbackIntent(
        _selectPreviousRadio,
      ),
    };
  }

  final _RadioGroupKeyboardFixState<T> _fix;

  @override
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    final bool radioHasFocus = _fix._radios.any(
      (RadioClient<T> radio) => radio.focusNode.hasFocus,
    );
    if (!radioHasFocus) {
      // Ignore the event if no radio is focused. This prevents this handler
      // from unintentionally consuming an event meant for a non-radio widget
      // that currently has focus.
      return KeyEventResult.ignored;
    }
    return super.handleKeypress(context, event);
  }

  void _selectNextRadio() => _selectRadioInDirection(true);

  void _selectPreviousRadio() => _selectRadioInDirection(false);

  void _selectLeftRadio() => _selectRadioInDirection(false, horizontal: true);

  void _selectRightRadio() => _selectRadioInDirection(true, horizontal: true);

  static bool _isRightToLeft(FocusNode node) {
    return node.context
            ?.getInheritedWidgetOfExactType<Directionality>()
            ?.textDirection ==
        TextDirection.rtl;
  }

  void _selectRadioInDirection(bool forward, {bool horizontal = false}) {
    final Set<RadioClient<T>> radios = _fix._radios;
    final RadioGroupRegistry<T>? registry = _fix._registry;
    if (radios.length < 2 || registry == null) {
      return;
    }
    RadioClient<T>? currentRadio;
    for (final radio in radios) {
      if (radio.focusNode.hasFocus) {
        currentRadio = radio;
        break;
      }
    }
    if (currentRadio == null) {
      // The focused node is either a non interactive radio or other controls.
      return;
    }
    final FocusNode currentFocus = currentRadio.focusNode;
    final nodes = <FocusNode>[
      for (final radio in radios)
        if (radio.enabled) radio.focusNode,
    ];
    if (nodes.isEmpty) {
      return;
    }
    // In right-to-left text, reading order runs from right to left, so the left
    // arrow key selects the next radio and the right arrow key the previous
    // one. If the radios' text directions differ, reading order can run both
    // ways within a row, so the left and right arrow keys keep their
    // left-to-right mapping.
    final bool reverseHorizontal = horizontal && nodes.every(_isRightToLeft);
    if (reverseHorizontal && !currentRadio.enabled) {
      // A disabled radio can hold focus in directional navigation. Keep its
      // position so Left and Right can find the adjacent enabled radio.
      nodes.add(currentFocus);
    }
    final List<FocusNode> sorted = ReadingOrderTraversalPolicy.sort(nodes)
        .toList();
    final bool moveForward = reverseHorizontal ? !forward : forward;
    final Iterable<FocusNode> nodesInEffectiveOrder = moveForward
        ? sorted
        : sorted.reversed;

    final Iterator<FocusNode> iterator = nodesInEffectiveOrder.iterator;
    FocusNode? nextFocus;
    while (iterator.moveNext()) {
      if (iterator.current == currentFocus) {
        if (iterator.moveNext()) {
          nextFocus = iterator.current;
        }
        break;
      }
    }
    // Current focus is at the end, the next focus should wrap around.
    nextFocus ??= nodesInEffectiveOrder.first;
    final RadioClient<T> radioToSelect = radios.firstWhere(
      (RadioClient<T> radio) => radio.focusNode == nextFocus,
    );
    registry.onChanged(radioToSelect.radioValue);
    nextFocus.requestFocus();
  }
}
