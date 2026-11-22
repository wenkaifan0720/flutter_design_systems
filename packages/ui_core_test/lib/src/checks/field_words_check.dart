part of '../alignment.dart';

/// Whether a text field's help and error are read as part of the field.
///
/// A screen reader reads a field by its node: its name, its value, its hint.
/// Material's `TextField` reads its error as the field's hint and keeps its
/// help and error inside the field's node, so a reader on the field hears
/// them, and one tabbing through the form never lands on them alone. A
/// field whose help or error is a node beside it (or no node) leaves the
/// reader on the field without them: they hear "Email, text field", not
/// that it is wrong or why.
///
/// - **Read with the field**: each of [words] (a field's help, its error)
///   is said on a text field's node or a node inside it, and not again on a
///   node beside it (a live region beside it, which a platform without
///   announcements reads as the error appears, is the announcement, and
///   passes): `the words
///   "Enter a valid email" are read on a node of their own at 16, 132,
///   apart from the text field "Email"`.
/// - **Read at all**: each of [words] is said somewhere: `the words "We
///   never share it" are read nowhere`.
///
/// Give [words] the help and the error a field on the screen shows. A
/// [RawInputDecorator] given them as its `helperText` and `errorText` reads
/// them on its control's node; what a look draws of them it leaves out of
/// the tree (its parts' `helper` and `error`, or an [ExcludeSemantics]). It
/// reads the semantics tree, which a widget test has unless it turns it off
/// ([WidgetTester.ensureSemantics] turns it on). A test pumps a field
/// showing its help, or its error, then:
///
/// ```dart
/// const DesignFieldWordsCheck(
///   look: 'Comic',
///   words: ['We never share it', 'Enter a valid email'],
/// ).check(tester.element(find.byType(SignUpForm))).verify();
/// ```
@immutable
class DesignFieldWordsCheck {
  /// A check of [words] for [look].
  const DesignFieldWordsCheck({required this.look, required this.words});

  /// The look's name, for messages.
  final String look;

  /// The help and the error of the fields on the screen.
  final List<String> words;

  /// Checks [words] on the screen [context] is in.
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignFieldWordsCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final placed = _placedNodes(semantics, View.of(context).devicePixelRatio);
    final fields = [
      for (final (node, rect) in placed)
        if (!node.isMergedIntoParent &&
            node.getSemanticsData().flagsCollection.isTextField)
          (node, rect),
    ];
    bool inField(SemanticsNode node) {
      for (SemanticsNode? n = node; n != null; n = n.parent) {
        if (n.getSemanticsData().flagsCollection.isTextField) return true;
      }
      return false;
    }

    final found = <String>[];
    for (final word in words) {
      // Where it is read: on a field, or apart from every field.
      var withField = false;
      (SemanticsNode, Rect)? apart;
      for (final (node, rect) in placed) {
        if (node.isMergedIntoParent) continue;
        final d = node.getSemanticsData();
        final says = [
          d.label,
          d.hint,
          d.value,
          d.tooltip,
        ].any((w) => w.contains(word));
        if (!says) continue;
        if (inField(node)) {
          withField = true;
        } else if (apart == null ||
            (_live(apart.$1) && !d.flagsCollection.isLiveRegion)) {
          // A live region beside the field is the error's announcement
          // where the platform takes none; any other copy reads it twice.
          apart = (node, rect);
        }
      }
      final again = apart != null && !_live(apart.$1);
      if (withField && !again) continue;
      if (withField) {
        final rect = apart!.$2;
        found.add(
          'the words "$word" are read on the text field and again on a node '
          'of their own at ${_px(rect.left)}, ${_px(rect.top)}: a screen '
          'reader reads them twice; leave the drawn words out of the tree '
          '(a live region that announces an error is the one copy allowed)',
        );
        continue;
      }
      if (apart == null) {
        found.add('the words "$word" are read nowhere');
        continue;
      }
      final rect = apart.$2;
      final field = fields.isEmpty
          ? null
          : fields.reduce(
              (a, b) =>
                  (b.$2.center - rect.center).distance <
                      (a.$2.center - rect.center).distance
                  ? b
                  : a,
            );
      final name = field?.$1.getSemanticsData().label.split('\n').first;
      found.add(
        'the words "$word" are read on a node of their own at '
        '${_px(rect.left)}, ${_px(rect.top)}, apart from '
        '${field == null ? 'any text field' : 'the text field${name == null || name.isEmpty ? '' : ' "$name"'}'}: '
        "a field's help and error are read with it (a RawInputDecorator's "
        'helperText and errorText, the drawn words left out of the tree)',
      );
    }
    return DesignAlignmentReport(look, found);
  }

  static bool _live(SemanticsNode node) =>
      node.getSemanticsData().flagsCollection.isLiveRegion;
}
