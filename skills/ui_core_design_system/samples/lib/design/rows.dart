import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'face.dart';
import 'theme.dart';

/// A row of a list that opens something, with controls of its own at its
/// end (a water key, a "…" menu).
///
/// The row's press and its controls are separate targets side by side, each
/// with its own semantics node: [RawButton] merges what it holds into its
/// own node, so a control inside it would be read, and pressed, as the row.
/// The face is painted round all of them and reads the row's states through
/// a [WidgetStatesController], so the whole row shows its press and focus.
class TendListRow extends StatefulWidget {
  /// A row saying [title], opened by [onPressed].
  const TendListRow({
    super.key,
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.trailing = const [],
  });

  /// The row's name.
  final String title;

  /// A line under the name.
  final String? subtitle;

  /// What a press on the row does; null turns the row off.
  final VoidCallback? onPressed;

  /// Controls at the row's end, beside its press.
  final List<Widget> trailing;

  @override
  State<TendListRow> createState() => _TendListRowState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed));
  }
}

class _TendListRowState extends State<TendListRow> {
  // The row button's states, read by the face painted round the whole row.
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    final c = theme.colors;
    final subtitle = widget.subtitle;
    return ValueListenableBuilder<Set<WidgetState>>(
      valueListenable: _states,
      builder: (context, states, child) => AnimatedTendSurface(
        face: TendFace(
          fill: states.contains(WidgetState.pressed)
              ? Color.alphaBlend(c.ink.withValues(alpha: .08), c.surface)
              : c.surface,
          rule: states.contains(WidgetState.focused) ? c.ink : c.rule,
          ruleWidth: states.contains(WidgetState.focused) ? 2 : 1,
          foreground: c.ink,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radius),
        ),
        child: child,
      ),
      child: Row(
        children: [
          Expanded(
            child: RawButton(
              onPressed: widget.onPressed,
              statesController: _states,
              builder: (context, states, _) => Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.label.copyWith(fontSize: 16, color: c.ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.body.copyWith(
                          fontSize: 13,
                          color: c.mutedInk,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          ...widget.trailing,
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

/// What a region shows when it has nothing to show, or could not load it: a
/// glyph, a heading, a sentence and, where there is one, an action. The
/// empty view and the failed view of a region are one frame, told apart by
/// their glyph, words and tone ([error]).
class TendNotice extends StatelessWidget {
  /// A notice under [icon] saying [title] and [message].
  const TendNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.error = false,
  });

  /// The glyph above the words.
  final IconData icon;

  /// The heading.
  final String title;

  /// The sentence under it.
  final String message;

  /// What the reader can do about it ("Try again").
  final Widget? action;

  /// Whether it tells of a failure: the glyph takes the danger tone.
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = TendTheme.of(context);
    final c = theme.colors;
    final act = action;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: error ? c.danger : c.mutedInk),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              title,
              style: theme.title.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.body.copyWith(color: c.mutedInk),
            textAlign: TextAlign.center,
          ),
          if (act != null) ...[const SizedBox(height: 16), act],
        ],
      ),
    );
  }
}
