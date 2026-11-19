import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../link/link.dart';

/// What can be done to the rows picked in a list or a table: while
/// [count] is more than 0 a band on the page's grey, an action-blue rule
/// along its top, says how many are picked ("2 items selected", or
/// [label]), then the [actions] in words (secondary [CivicButton]s:
/// "Renew", "Cancel permits"), then a link that clears the picking
/// ([onClear]). It opens and closes on Civic's panel spring as the first
/// row is picked and the last let go; the count is said again to a screen
/// reader each time it changes.
///
/// Stand it over or under the list it acts on, in the page's flow, not
/// over the rows. An act that cannot be undone asks first (a
/// [CivicDialog]).
///
/// Reads [CivicStyle]'s fill (the band), edge (the rule) and textStyle
/// (the count): its `style:`, then [CivicThemeData.actionBarStyle].
///
/// ```dart
/// CivicActionBar(
///   count: picked.length,
///   onClear: () => setState(picked.clear),
///   actions: [
///     CivicButton.secondary(onPressed: renew, child: const Text('Renew')),
///   ],
/// )
/// ```
class CivicActionBar extends StatefulWidget {
  /// An action bar for [count] picked rows.
  const CivicActionBar({
    super.key,
    required this.count,
    required this.actions,
    this.onClear,
    this.label,
    this.clearLabel,
    this.style,
  }) : assert(count >= 0);

  /// How many rows are picked; at 0 the bar closes.
  final int count;

  /// What can be done to them, in words.
  final List<Widget> actions;

  /// Lets go of every row; null: no clear link.
  final VoidCallback? onClear;

  /// The count in words; null: "2 items selected" in the reader's language.
  final String? label;

  /// The clear link's words; null: "Clear" in the reader's language.
  final String? clearLabel;

  /// Overrides for this bar's look.
  final CivicStyle? style;

  @override
  State<CivicActionBar> createState() => _CivicActionBarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('count', count))
      ..add(IntProperty('actions', actions.length))
      ..add(ObjectFlagProperty<VoidCallback>.has('onClear', onClear))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('clearLabel', clearLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicActionBarState extends State<CivicActionBar> {
  // The count it last showed, kept while it closes so its words hold.
  late int _shown = widget.count;

  @override
  void didUpdateWidget(CivicActionBar old) {
    super.didUpdateWidget(old);
    if (widget.count > 0) _shown = widget.count;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([widget.style, t.actionBarStyle], const {});
    final l = DesignLocalizations.of(context);
    final open = widget.count > 0;
    final words =
        (open ? widget.label : null) ?? l.selectedRowCountTitle(_shown);
    final onClear = widget.onClear;
    final band = DecoratedBox(
      decoration: BoxDecoration(
        color: so.fill ?? t.surface,
        border: Border(
          top: BorderSide(
            color: so.edge ?? t.action,
            width: CivicMetrics.edge * 2,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: CivicSpacing.s16,
          vertical: CivicSpacing.s16,
        ),
        child: Wrap(
          spacing: CivicSpacing.s16,
          runSpacing: CivicSpacing.s12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Semantics(
              liveRegion: open,
              child: Text(
                words,
                style: text.label
                    .copyWith(color: t.textPrimary)
                    .merge(so.textStyle),
              ),
            ),
            ...widget.actions,
            if (onClear != null)
              CivicLink(
                onPressed: onClear,
                child: Text(widget.clearLabel ?? l.clearButtonTooltip),
              ),
          ],
        ),
      ),
    );
    return CivicSpringValue(
      value: open ? 1 : 0,
      spring: CivicMotion.panel,
      child: band,
      builder: (context, shown, band) {
        final at = shown.clamp(0.0, 1.0);
        if (!open && at < 0.001) return const SizedBox(width: double.infinity);
        return IgnorePointer(
          ignoring: !open,
          child: ExcludeFocus(
            excluding: !open,
            child: ExcludeSemantics(
              excluding: !open,
              child: ClipRect(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  heightFactor: at,
                  // The band spans its column as it opens.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [Opacity(opacity: at, child: band!)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
