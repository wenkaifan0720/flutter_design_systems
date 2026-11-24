import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/option.dart';
import '../../internal/overhang.dart';
import '../../internal/paint.dart';
import '../../theme.dart';
import '../link/link.dart';

/// One answer in a [CivicSummaryList]: what was asked ([label]), the answer
/// ([value]), and the way back to change it.
@immutable
class CivicSummaryRow {
  /// A row: [label] asked, [value] answered.
  const CivicSummaryRow({
    required this.label,
    required this.value,
    this.actionLabel,
    this.actionSemanticLabel,
    this.onActionPressed,
    this.actionUrl,
  });

  /// What was asked, in a few words: Name, Date of birth.
  final String label;

  /// The answer, as the reader gave it.
  final Widget value;

  /// The action's word, in the reader's language: Change.
  final String? actionLabel;

  /// What a screen reader hears for the action: Change your name. Null
  /// joins [actionLabel] and [label].
  final String? actionSemanticLabel;

  /// Called by the action; null shows no action.
  final VoidCallback? onActionPressed;

  /// The address of the question's page the action goes back to: with
  /// one, Change is read as a link to it ([CivicLink.url]); without one,
  /// as a button that runs [onActionPressed] in place.
  final Uri? actionUrl;
}

/// The answers a reader gave, set out to check before sending: what was
/// asked in bold, the answer beside it (under it, below 600), a Change link
/// at the end that goes back to the question, each row over a rule. The
/// signature of a Civic check-your-answers page, and of any record of
/// facts (an application's details, an account's).
///
/// Reads [CivicStyle]'s edge (the rules), foreground (the words) and
/// padding (a row's): its `style:`, then [CivicThemeData.summaryListStyle].
///
/// ```dart
/// CivicSummaryList(rows: [
///   CivicSummaryRow(
///     label: 'Name',
///     value: const Text('Amara Okafor'),
///     actionLabel: 'Change',
///     actionSemanticLabel: 'Change name',
///     onActionPressed: () => router.go('/apply/name'),
///     actionUrl: Uri.parse('/apply/name'),
///   ),
/// ])
/// ```
class CivicSummaryList extends StatelessWidget {
  /// A list of answers.
  const CivicSummaryList({super.key, required this.rows, this.style});

  /// The answers.
  final List<CivicSummaryRow> rows;

  /// Overrides for this list's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = RawStyleOf([style, t.summaryListStyle], const {});
    final words = so.foreground;
    final text = words == null
        ? context.civicText
        : context.civicText.copyWith(
            label: context.civicText.label.copyWith(color: words),
            body: context.civicText.body.copyWith(color: words),
          );
    // An action's words stand centred in a tap target taller than their
    // line, by [half] over and under them. That room comes out of the row's
    // own padding ([take]), so the target is laid out whole: every box
    // round it holds all of it, and a tap anywhere on it lands.
    final line =
        MediaQuery.textScalerOf(context).scale(text.body.fontSize ?? 19) *
        (text.body.height ?? 1.25);
    final floor = RawTapTargets.of(context).floorOn().height;
    final half = ((floor - line - CivicMetrics.bar) / 2).clamp(0.0, floor);
    final pad =
        so.padding(Directionality.of(context)) ??
        const EdgeInsets.symmetric(vertical: CivicSpacing.s12);
    final take = math.min(half, math.min(pad.top, pad.bottom));
    // In an app the answers stand on a card, white on the ground, hairlines
    // between them; on the site, and in a summary card, on rules.
    final card = CivicCardScope.cards(context);
    final list = LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 560;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, row) in rows.indexed)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: card && i == rows.length - 1
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: so.edge ?? (card ? t.hairline : t.rule),
                          ),
                        ),
                ),
                child: Padding(
                  padding: pad.copyWith(
                    top: wide ? pad.top - take : pad.top,
                    bottom: pad.bottom - take,
                  ),
                  child: _row(row, wide, text, half, take),
                ),
              ),
          ],
        );
      },
    );
    if (!card) return list;
    return ClipRRect(
      borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
      child: ColoredBox(
        color: t.background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CivicSpacing.s16),
          child: CivicCardScope(child: list),
        ),
      ),
    );
  }

  Widget _row(
    CivicSummaryRow row,
    bool wide,
    CivicTextTheme text,
    double half,
    double take,
  ) {
    final key = Semantics(
      container: true,
      child: Text(row.label, style: text.label),
    );
    final value = Semantics(
      container: true,
      child: DefaultTextStyle(style: text.body, child: row.value),
    );
    final act = row.onActionPressed;
    final action = act == null || row.actionLabel == null
        ? null
        : CivicLink(
            onPressed: act,
            url: row.actionUrl,
            semanticLabel:
                row.actionSemanticLabel ?? '${row.actionLabel} ${row.label}',
            child: Text(row.actionLabel!),
          );
    // What the row's padding could not give stands over the room round the
    // target (a style's padding thinner than the target's spare room).
    Widget reach(Widget action, {required double top}) =>
        top == 0 && half == take
        ? action
        : CivicOverhang(top: top, bottom: half - take, child: action);
    if (wide) {
      // The question, the answer and the action share their first line; the
      // question and the answer keep the room the action's target takes
      // over and under its words.
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: CivicSpacing.s16,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: take),
              child: key,
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: take),
              child: value,
            ),
          ),
          if (action != null)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 80),
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                widthFactor: 1,
                // The focus flood stands the edge's width past a link's
                // words: inset by as much, it ends where the rules end.
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: CivicMetrics.edge,
                  ),
                  child: reach(action, top: half - take),
                ),
              ),
            ),
        ],
      );
    }
    // Stacked, the action's words stand right under the answer and the rule
    // as far under them as over the question: its target stands over the
    // answer above it (inside the row, so a tap there lands on it) and
    // takes the room under it from the row's padding.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: CivicSpacing.s4,
      children: [
        key,
        value,
        if (action != null) reach(action, top: half),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('rows', rows.length))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// A [CivicSummaryList] under a title band, for a page that checks more
/// than one thing (each person, each vehicle): the title in bold on the
/// band's grey, actions at its end, the list under it on a white card, its
/// corners rounded, no stroke round it. Civic's card: it holds a record,
/// never decoration.
///
/// Reads [CivicStyle]'s fill (the title band): its `style:`, then
/// [CivicThemeData.summaryListStyle]'s.
///
/// ```dart
/// CivicSummaryCard(
///   title: 'Vehicle 1',
///   actions: [CivicLink(onPressed: remove, child: const Text('Remove'))],
///   child: CivicSummaryList(rows: rows),
/// )
/// ```
class CivicSummaryCard extends StatelessWidget {
  /// A card titled [title].
  const CivicSummaryCard({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
    this.style,
  });

  /// The title.
  final String title;

  /// What it holds: a summary list.
  final Widget child;

  /// Links at the title's end.
  final List<Widget> actions;

  /// Overrides for this card's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = RawStyleOf([style, t.summaryListStyle], const {});
    // A card: white on the page's ground, its corners rounded, no stroke.
    return ClipRRect(
      borderRadius: BorderRadius.circular(CivicMetrics.cardCorner),
      child: ColoredBox(
        color: t.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ColoredBox(
              color: so.fill ?? t.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: CivicSpacing.s16,
                  vertical: CivicSpacing.s12,
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: CivicSpacing.s16,
                  runSpacing: CivicSpacing.s8,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(title, style: text.headingS),
                    ),
                    if (actions.isNotEmpty)
                      Wrap(spacing: CivicSpacing.s16, children: actions),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: CivicSpacing.s16),
              // The card is the list's: it stands no second one.
              child: CivicCardScope(child: child),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('title', title))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
