part of '../alignment.dart';

/// Whether each tooltip on a screen is on the node of the control it tips.
///
/// A screen reader reads a control's tooltip with its name and role, as one
/// node: Flutter's `Tooltip` merges its message into its child's node. A
/// tip set on a node over the control (a `Semantics(tooltip: ...)` round a
/// button that keeps its own node) is a node of its own: the reader stops
/// on the tip apart from the button, and on the button without its tip.
///
/// - **The tip on the control's own node**: a node that says a tooltip and
///   is no control itself (it takes no tap, and is no button, link, field,
///   slider or toggle) holds no control under it: `the tip "Delete" at 12,
///   40 (40 × 40) is on a node over a button "Delete", not on its own`.
///
/// It reads the semantics tree, which a widget test has unless it turns it
/// off ([WidgetTester.ensureSemantics] turns it on). A test pumps a screen,
/// then:
///
/// ```dart
/// const DesignTooltipNodeCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignTooltipNodeCheck {
  /// A check for [look].
  const DesignTooltipNodeCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks every tooltip shown under [context].
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignTooltipNodeCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final ratio = View.of(context).devicePixelRatio;
    final area = _global(root).inflate(1);
    return DesignAlignmentReport(look, [
      for (final (node, rect) in _placedNodes(semantics, ratio))
        if (!node.isMergedIntoParent && area.contains(rect.center))
          ?_tipApart(node, rect),
    ]);
  }
}

// What is wrong with [node]'s tooltip, placed at [rect]: null when it has
// none, is a control's own, or tips no control under it.
String? _tipApart(SemanticsNode node, Rect rect) {
  final d = node.getSemanticsData();
  final tip = d.tooltip.replaceAll('\n', ' ').trim();
  if (tip.isEmpty || _actsNode(d)) return null;
  SemanticsNode? control;
  void find(SemanticsNode n) {
    if (control != null || n.isMergedIntoParent) return;
    if (_actsNode(n.getSemanticsData())) {
      control = n;
      return;
    }
    n.visitChildren((child) {
      find(child);
      return control == null;
    });
  }

  node.visitChildren((child) {
    find(child);
    return control == null;
  });
  final tipped = control;
  if (tipped == null) return null;
  final shown = tip.length > 32 ? '${tip.substring(0, 31)}…' : tip;
  return 'the tip "$shown" at ${_px(rect.left)}, ${_px(rect.top)} '
      '(${_px(rect.width)} × ${_px(rect.height)}) is on a node over '
      '${_controlName(tipped.getSemanticsData())}, not on its own: a screen '
      'reader reads the tip apart from the control; merge it into the '
      "control's node, as Flutter's Tooltip and RawTooltip do";
}

// Whether [d] is a control: it takes a tap or a step, or says a control's
// role or state.
bool _actsNode(SemanticsData d) {
  final f = d.flagsCollection;
  return d.hasAction(SemanticsAction.tap) ||
      d.hasAction(SemanticsAction.longPress) ||
      d.hasAction(SemanticsAction.increase) ||
      d.hasAction(SemanticsAction.decrease) ||
      f.isButton ||
      f.isLink ||
      f.isTextField ||
      f.isSlider ||
      f.isInMutuallyExclusiveGroup ||
      f.isChecked != CheckedState.none ||
      f.isToggled != Tristate.none;
}

// A control's role and words, for a message.
String _controlName(SemanticsData d) {
  final f = d.flagsCollection;
  final role = f.isTextField
      ? 'a text field'
      : f.isLink
      ? 'a link'
      : f.isSlider
      ? 'a slider'
      : f.isToggled != Tristate.none
      ? 'a switch'
      : f.isInMutuallyExclusiveGroup
      ? 'a radio'
      : f.isChecked != CheckedState.none
      ? 'a checkbox'
      : f.isButton
      ? 'a button'
      : 'a control';
  final words = d.label.replaceAll('\n', ' ').trim();
  if (words.isEmpty) return role;
  return '$role "${words.length > 32 ? '${words.substring(0, 31)}…' : words}"';
}
