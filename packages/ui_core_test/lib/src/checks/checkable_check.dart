part of '../alignment.dart';

/// Whether each checkbox, radio and switch under a screen says what it is,
/// as Flutter's `Checkbox`, `Radio` and `Switch` do.
///
/// A screen reader names a node by its role. A checkbox, a radio or a
/// switch built on a pressable keeps the pressable's button flag unless it
/// clears it, and a node with both is given a button's role beside its
/// state, not the role of what it is.
///
/// - **No button beside a state**: a node that says it is checked or
///   toggled (a checkbox, a radio, a switch, a check row) does not also say
///   it is a button: `a radio "B": says it is a button beside its checked
///   state, as Flutter's Radio does not`.
/// - **A radio's state**: a node in a group of which one is chosen (a
///   radio) says whether it is checked: `a radio "B": says no checked
///   state`.
///
/// It reads the semantics tree, which a widget test has unless it turns it
/// off ([WidgetTester.ensureSemantics] turns it on). A test pumps a screen,
/// then:
///
/// ```dart
/// const DesignCheckableCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignCheckableCheck {
  /// A check for [look].
  const DesignCheckableCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks every checkbox, radio and switch shown under [context].
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignCheckableCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final ratio = View.of(context).devicePixelRatio;
    final area = _global(root).inflate(1);
    return DesignAlignmentReport(look, [
      for (final (node, rect) in _placedNodes(semantics, ratio))
        if (!node.isMergedIntoParent && area.contains(rect.center))
          ?_checkableProblem(node.getSemanticsData()),
    ]);
  }
}

// What is wrong with [d] as a checkbox, a radio or a switch; null when
// nothing is, or it is none of them.
String? _checkableProblem(SemanticsData d) {
  final f = d.flagsCollection;
  final radio = f.isInMutuallyExclusiveGroup;
  final checked = f.isChecked != CheckedState.none;
  final toggled = f.isToggled != Tristate.none;
  if (!radio && !checked && !toggled) return null;
  final name = _checkableName(d);
  if (radio && !checked) return '$name: says no checked state';
  if (f.isButton) {
    final like = radio
        ? "Flutter's Radio"
        : toggled
        ? "Flutter's Switch"
        : "Flutter's Checkbox";
    return '$name: says it is a button beside its '
        '${toggled ? 'toggled' : 'checked'} state, as $like does not';
  }
  return null;
}

// A checkable node's role and words.
String _checkableName(SemanticsData d) {
  final f = d.flagsCollection;
  final role = f.isInMutuallyExclusiveGroup
      ? 'a radio'
      : f.isToggled != Tristate.none
      ? 'a switch'
      : 'a checkbox';
  final words = d.label.replaceAll('\n', ' ').trim();
  if (words.isEmpty) return role;
  return '$role "${words.length > 32 ? '${words.substring(0, 31)}…' : words}"';
}
