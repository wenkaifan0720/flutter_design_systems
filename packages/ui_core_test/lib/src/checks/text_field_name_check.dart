part of '../alignment.dart';

/// Whether each text field on a screen has a name a screen reader says: a
/// label, else a hint or a tooltip, on the field's own node.
///
/// A screen reader announces a field by its name and its role. A field with
/// none is read as "text field" alone, and a reader cannot tell the amount
/// from the note. Flutter's `TextField` takes its decoration's `labelText`
/// (else its `hintText`) as its name. A field loses it when its label is a
/// node of its own beside it: a `GestureDetector` round the label (to focus
/// the field on a tap) without `excludeFromSemantics`, or a label outside
/// the [RawInputDecorator] that would merge it. A hint is a weak name (it goes
/// once the reader types, as HTML's placeholder does), but it is one, so it
/// passes.
///
/// It reads the semantics tree, which a widget test has unless it turns it
/// off ([WidgetTester.ensureSemantics] turns it on), and no pixels. A test
/// pumps a screen, then:
///
/// ```dart
/// const DesignTextFieldNameCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignTextFieldNameCheck {
  /// A check for [look].
  const DesignTextFieldNameCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks every text field shown under [context].
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignTextFieldNameCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final ratio = View.of(context).devicePixelRatio;
    final area = _global(root).inflate(1);
    return DesignAlignmentReport(look, [
      for (final (node, rect) in _placedNodes(semantics, ratio))
        if (!node.isMergedIntoParent && area.contains(rect.center))
          ?_unnamedField(node.getSemanticsData(), rect),
    ]);
  }
}

// What is wrong with [d], placed at [rect], as a text field: null when it
// has a name, or is no text field.
String? _unnamedField(SemanticsData d, Rect rect) {
  if (!d.flagsCollection.isTextField) return null;
  if ([d.label, d.hint, d.tooltip].any((w) => w.trim().isNotEmpty)) {
    return null;
  }
  final value = d.value.replaceAll('\n', ' ').trim();
  final showing = value.isEmpty
      ? ''
      : ' showing "${value.length > 24 ? '${value.substring(0, 23)}…' : value}"';
  return 'a text field$showing at ${_px(rect.left)}, ${_px(rect.top)} '
      '(${_px(rect.width)} × ${_px(rect.height)}): says no name, so a '
      'screen reader reads it as "text field" alone; give it a label on its '
      "own node (TextField's labelText, a RawInputDecorator's label, or a "
      'Semantics label round it), not one beside it';
}
