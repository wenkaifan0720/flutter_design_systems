part of '../alignment.dart';

/// Whether a dialog's or a sheet's actions stand in one row, or else in one
/// column of one width with the confirming action on top.
///
/// Actions side by side read as a choice among equals; once they don't fit
/// they stack, each on a line of its own and all of one width, the
/// confirming action on top and the dismissive one at the foot, as Material
/// and iOS stack them (and `RawActionBar` lays them out).
///
/// - **One row or one column**: never some side by side and one under them:
///   `actions "Cancel", "Discard", "Save changes": "Cancel" and "Discard"
///   stand side by side and "Save changes" on a line under them; they stand
///   in one row, or each on a line of its own`.
/// - **The confirming one on top**: stacked, the last given in [actions]
///   (the confirming one) stands highest and the first (the dismissive one)
///   lowest: `actions "Cancel", "Save" stacked: "Cancel" stands on top;
///   the confirming "Save" goes on top and "Cancel" at the foot`.
/// - **One width**: stacked, every action is as wide as the widest: `actions
///   "Cancel", "Save changes" stacked: 96 px and 160 px wide; a stack is one
///   column of one width`.
///
/// Give [actions] their labels as a screen reader reads them, in the order
/// the dialog takes them: the dismissive one first, the confirming one
/// last. Each is found as the control whose node says that label, the one
/// drawn last where several do: the dialog's, over a page whose own
/// controls say the same words. Where
/// side by side, their order is the look's (some put the confirming one
/// first). It reads layout boxes and the semantics labels on them. A test
/// opens the dialog at the widths and text sizes it runs at, then:
///
/// ```dart
/// const DesignDialogActionsCheck(
///   look: 'Comic',
///   actions: ['Cancel', 'Discard', 'Save changes'],
/// ).check(tester.element(find.byType(TaskForm))).verify();
/// ```
@immutable
class DesignDialogActionsCheck {
  /// A check of [actions] for [look].
  const DesignDialogActionsCheck({
    required this.look,
    required this.actions,
    this.tolerance = 0.5,
  });

  /// The look's name, for messages.
  final String look;

  /// The actions' labels, the dismissive one first and the confirming one
  /// last. Fewer than two have no layout to check.
  final List<String> actions;

  /// How far, in logical pixels, two actions on one line may stand apart up
  /// and down, and two stacked ones differ in width.
  final double tolerance;

  /// Checks the actions open in the app [context] is in (a dialog is in an
  /// overlay over the screen).
  DesignAlignmentReport check(BuildContext context) {
    if (actions.length < 2) return DesignAlignmentReport(look, const []);
    final boxes = <String, Rect>{};
    var top = context as Element;
    top.visitAncestorElements((up) {
      top = up;
      return true;
    });
    final root = top.findRenderObject();
    void visit(RenderObject n) {
      if (n is RenderBox && n.hasSize && _isControl(n)) {
        final label = _labelOf(n);
        if (label != null && actions.contains(label)) {
          // Drawn in order: the last is on top (a dialog's, over the page).
          boxes[label] = _global(n);
          return;
        }
      }
      _visitShown(n, visit);
    }

    if (root != null) visit(root);
    final named = 'actions ${actions.map((a) => '"$a"').join(', ')}';
    final missing = [
      for (final a in actions)
        if (!boxes.containsKey(a)) '"$a"',
    ];
    if (missing.isNotEmpty) {
      return DesignAlignmentReport(look, [
        '$named: ${missing.join(', ')} not found as a control saying it',
      ]);
    }
    // Lines: actions whose middles stand within half the shortest's height.
    final rects = [for (final a in actions) boxes[a]!];
    final shortest = rects.map((r) => r.height).reduce(math.min);
    final lines = <List<int>>[];
    for (var i = 0; i < rects.length; i++) {
      final line = lines.where(
        (l) =>
            (rects[l.first].center.dy - rects[i].center.dy).abs() <
            shortest / 2,
      );
      if (line.isEmpty) {
        lines.add([i]);
      } else {
        line.first.add(i);
      }
    }
    if (lines.length == 1) return DesignAlignmentReport(look, const []);
    final found = <String>[];
    final shared = lines.where((l) => l.length > 1).toList();
    if (shared.isNotEmpty) {
      final row = shared.first.map((i) => '"${actions[i]}"').join(' and ');
      final alone = [
        for (final l in lines)
          if (l.length == 1) '"${actions[l.single]}"',
      ];
      found.add(
        '$named: $row stand side by side and '
        '${alone.isEmpty ? 'the rest' : alone.join(' and ')} on a line of '
        'their own; they stand in one row, or each on a line of its own',
      );
      return DesignAlignmentReport(look, found);
    }
    final highest = rects.indexed
        .reduce((a, b) => b.$2.top < a.$2.top ? b : a)
        .$1;
    final lowest = rects.indexed
        .reduce((a, b) => b.$2.top > a.$2.top ? b : a)
        .$1;
    final confirm = actions.length - 1;
    if (highest != confirm || lowest != 0) {
      found.add(
        '$named stacked: "${actions[highest]}" stands on top and '
        '"${actions[lowest]}" at the foot; the confirming '
        '"${actions[confirm]}" goes on top and "${actions.first}" at the foot',
      );
    }
    final widths = rects.map((r) => r.width);
    if (widths.reduce(math.max) - widths.reduce(math.min) > tolerance) {
      found.add(
        '$named stacked: ${widths.map((w) => '${_px(w)} px').join(', ')} '
        'wide; a stack is one column of one width',
      );
    }
    return DesignAlignmentReport(look, found);
  }

  // The label [control]'s own node says.
  static String? _labelOf(RenderBox control) {
    String? label;
    void visit(RenderObject n) {
      if (label != null) return;
      if (n is RenderSemanticsAnnotations &&
          (n.properties.label ?? '').isNotEmpty) {
        label = n.properties.label;
        return;
      }
      if (n is RenderParagraph) {
        final t = n.text.toPlainText(includeSemanticsLabels: false).trim();
        if (t.isNotEmpty && !isIconGlyph(t)) {
          label = t;
          return;
        }
      }
      if (!identical(n, control) && n is RenderBox && _isControl(n)) return;
      _visitShown(n, visit);
    }

    visit(control);
    return label;
  }
}
