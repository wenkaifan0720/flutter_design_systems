import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../theme.dart';
import 'face.dart';

/// A Ledger field as a ledger rules it: its label in the small capitals,
/// then the [line] it is written on, ruled under in the ink (the
/// accountant's double rule while it has focus, the danger red when wrong,
/// the light rule when it cannot be used), then its help or its error. The
/// rule is painted over the line's foot, so focus and error never move a
/// pixel of the page. Its ink changes in Ledger's one motion, and focus
/// draws the second line in from the reading start as a pen does. Plumbing
/// of the text field and the select; pages never place one.
class LedgerFieldFrame extends StatelessWidget {
  /// A field's frame round its [line].
  const LedgerFieldFrame({
    required this.parts,
    required this.line,
    this.focusNode,
    this.displayLabel,
    this.labelCursor = SystemMouseCursors.click,
    this.ruled = true,
    this.style,
    super.key,
  });

  /// Whether the frame rules under the whole line; false leaves the line to
  /// rule its own parts (a code's slots, each on its own short rule).
  final bool ruled;

  /// What [DesignField] made: the words, the state, the control's node.
  final DesignFieldParts parts;

  /// The visible caption when the control supplies its own accessible name.
  final String? displayLabel;

  /// The written line: the control, in its box.
  final Widget line;

  /// Focused by a tap on the label.
  final FocusNode? focusNode;

  /// The cursor over the label while a tap on it focuses the field: a text
  /// field's caret cursor, a select's click.
  final MouseCursor labelCursor;

  /// The field's own style, over `components.textField`: its `edge` inks
  /// the rule, its `fill` lays a paper behind the line and its `padding`
  /// stands round it.
  final DesignStyle? style;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(FlagProperty('ruled', value: ruled, ifTrue: 'ruled'))
      ..add(DiagnosticsProperty<DesignFieldParts>('parts', parts))
      ..add(StringProperty('displayLabel', displayLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<MouseCursor>('labelCursor', labelCursor))
      ..add(
        DiagnosticsProperty<DesignStyle>('style', style, defaultValue: null),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wrong = parts.errorText != null;
    final so = DesignStyleOf(
      [style, t.components.textField],
      {
        if (!parts.enabled) WidgetState.disabled,
        if (wrong) WidgetState.error,
        if (parts.focused) WidgetState.focused,
      },
    );
    final rule =
        so.edge ??
        (!parts.enabled
            ? t.border
            : wrong
            ? t.danger
            : t.headRule);
    final room = so.padding(Directionality.of(context));
    final paper = so.fill;
    Widget line = this.line;
    if (room != null) line = Padding(padding: room, child: line);
    if (paper != null) line = ColoredBox(color: paper, child: line);
    final label = displayLabel ?? parts.labelText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: _labelGap),
            child: ExcludeSemantics(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: parts.enabled ? focusNode?.requestFocus : null,
                child: MouseRegion(
                  cursor: parts.enabled && focusNode != null
                      ? labelCursor
                      : MouseCursor.defer,
                  child: Text.rich(
                    TextSpan(
                      text: label.toUpperCase(),
                      children: [
                        if (parts.required)
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: wrong ? t.over : t.accent),
                          ),
                      ],
                    ),
                    style: t.label.colored(
                      parts.enabled ? t.textSecondary : t.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!ruled)
          LedgerFieldRuled(node: focusNode, child: line)
        else
          LedgerFace(
            style: LedgerFaceStyle(ink: rule),
            duration: LedgerMotion.base,
            builder: (context, s, line) => Stack(
              children: [
                line!,
                // The rules are paint over the line's foot: a tap there
                // reaches the line (a ColoredBox would take it).
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  height: 1,
                  child: IgnorePointer(child: ColoredBox(color: s.ink)),
                ),
                // Focus doubles the rule: a second line over the first, the
                // focus rule's gap apart, as a ledger rules a total.
                LedgerEase(
                  value: parts.focused && parts.enabled ? 1 : 0,
                  duration: LedgerMotion.base,
                  builder: (context, drawn, _) => PositionedDirectional(
                    start: 0,
                    end: 0,
                    bottom: 1 + LedgerChromeMetrics.focusGap,
                    height: 1,
                    child: IgnorePointer(
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: drawn.clamp(0.0, 1.0),
                        child: ColoredBox(color: s.ink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            child: LedgerFieldRuled(node: focusNode, child: line),
          ),
        if (parts.error case final error?)
          _ground(
            Padding(
              padding: const EdgeInsets.only(top: _noteGap),
              child: DefaultTextStyle(
                style: t.bodySmall.sized(12).line(16).colored(t.over),
                child: error,
              ),
            ),
          )
        else if (parts.helper case final help?)
          _ground(
            Padding(
              padding: const EdgeInsets.only(top: _noteGap),
              child: DefaultTextStyle(
                style: t.bodySmall.sized(12).line(16).colored(t.textTertiary),
                child: help,
              ),
            ),
          ),
      ],
    );
  }

  // The field's ground under its help or error: a press there focuses the
  // field, as a press on its label does, so a tap reaches all of the box a
  // screen reader outlines. It adds nothing a screen reader hears.
  Widget _ground(Widget note) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: parts.enabled ? focusNode?.requestFocus : null,
    child: note,
  );

  static const double _labelGap = 2;
  static const double _noteGap = 6;
}

/// Marks the field whose frame rules focus on [node]: a [LedgerPressable]
/// on the same node (the select's line) leaves its own focus rule out, so
/// the field's line is the one doubled. Plumbing; pages never place one.
class LedgerFieldRuled extends InheritedWidget {
  /// Focus on [node] ruled by the field over [child].
  const LedgerFieldRuled({required this.node, required super.child, super.key});

  /// The field's focus node.
  final FocusNode? node;

  /// Whether a field above [context] rules focus for [node].
  static bool rules(BuildContext context, FocusNode? node) =>
      node != null &&
      context.dependOnInheritedWidgetOfExactType<LedgerFieldRuled>()?.node ==
          node;

  @override
  bool updateShouldNotify(LedgerFieldRuled oldWidget) => oldWidget.node != node;
}
