part of '../alignment.dart';

/// Whether anything on a screen overflows its row or column, the fault
/// large text brings out: words that fit at 1x outgrow their row at 2x.
///
/// A [Row], a [Column] or a [Flex] whose children need more room along it
/// than it has paints them past its end (Flutter's yellow and black stripes
/// in a debug build) or cuts them: either way part of a control or of its
/// words can't be seen. Each overflowing row and column is named by the
/// first words or control it holds: `a row holding "No time logged this
/// week" overflows its 134 px by 21 px at its foot`. Offstage and unpainted
/// boxes are left out, as are rows and columns inside a scroll view's
/// cache past what it shows.
///
/// Run it at the text sizes a look claims, 2x among them, as a reader with
/// large text sets the system's: pump the screen with
/// `MediaQuery(data: MediaQuery.of(context).copyWith(textScaler:
/// TextScaler.linear(2)))` round it, then:
///
/// ```dart
/// const DesignOverflowCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
///
/// It reads layout boxes, and no pixels: it holds in a release build and
/// where an app's own error handler swallows Flutter's overflow report.
@immutable
class DesignOverflowCheck {
  /// A check for [look].
  const DesignOverflowCheck({required this.look, this.tolerance = 0.5});

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, children may stand past their row.
  final double tolerance;

  /// Checks every row and column under [context] that is laid out and
  /// painted.
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final found = <String>[];
    void visit(RenderObject node) {
      if (node is RenderFlex && node.hasSize) {
        if (_overflowOf(node) case final problem?) found.add(problem);
      }
      _visitShown(node, visit);
    }

    visit(root);
    return DesignAlignmentReport(look, found);
  }

  // What overflows in [flex], "a row holding "Save" overflows its 120 px by
  // 34 px at its end"; null when its children fit.
  String? _overflowOf(RenderFlex flex) {
    final horizontal = flex.direction == Axis.horizontal;
    final extent = horizontal ? flex.size.width : flex.size.height;
    var least = 0.0;
    var most = 0.0;
    var any = false;
    flex.visitChildren((child) {
      if (child is! RenderBox || !child.hasSize) return;
      final at = (child.parentData! as FlexParentData).offset;
      final start = horizontal ? at.dx : at.dy;
      final end = start + (horizontal ? child.size.width : child.size.height);
      least = any ? math.min(least, start) : start;
      most = any ? math.max(most, end) : end;
      any = true;
    });
    if (!any) return null;
    final before = -least;
    final after = most - extent;
    if (before <= tolerance && after <= tolerance) return null;
    final ends = [
      if (before > tolerance)
        'by ${_px(before)} px at its ${horizontal ? 'left' : 'top'}',
      if (after > tolerance)
        'by ${_px(after)} px at its ${horizontal ? 'right' : 'foot'}',
    ];
    final kind = horizontal ? 'a row' : 'a column';
    return '$kind holding ${_holding(flex)} overflows its ${_px(extent)} px '
        '${ends.join(' and ')}';
  }

  // What [flex] holds, for a message: its first control, else its first
  // words.
  static String _holding(RenderFlex flex) {
    String? found;
    void visit(RenderObject n) {
      if (found != null) return;
      if (n is RenderBox && n.hasSize && _isControl(n)) {
        found = _nameOf(n);
        return;
      }
      if (n is RenderParagraph) {
        final t = n.text.toPlainText(includeSemanticsLabels: false).trim();
        if (t.isNotEmpty && !isIconGlyph(t)) {
          found = '"${t.length > 30 ? '${t.substring(0, 29)}…' : t}"';
          return;
        }
      }
      _visitShown(n, visit);
    }

    visit(flex);
    return found ?? 'no words';
  }
}
