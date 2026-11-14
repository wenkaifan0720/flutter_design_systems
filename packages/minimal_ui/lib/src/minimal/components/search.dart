/// The search field and the tappable search entry that opens one.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/field.dart';
import '../internal/text_entry.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'button.dart';
import 'code.dart';
import 'filter_bar.dart';
import 'pressable.dart';

/// Where a [MinimalSearchField] stands: `inline` in a list's header, on the
/// page; `toolbar` floating over the body (a [MinimalScaffold]'s `floating:`
/// slot), a taller field on a card with a menu's shadow.
enum MinimalSearchPresentation {
  /// In a list's header, on the page.
  inline,

  /// Floating over the body, on a card.
  toolbar,
}

/// Search as Minimal draws it: a 32 px field on a hairline at the control
/// radius — the search glyph, the query, and at the end the [shortcut]'s
/// key caps while the field is empty, the clear glyph once it holds text.
/// Escape clears a query, then leaves the field. Focus turns the rule to
/// the accent; keyboard focus also draws the kit's solid 2 px ring.
/// `showCancel` adds a quiet Cancel beside the focused field; [scopes] (two
/// or more) print a strip of [MinimalFilter]s under it.
///
/// The field stands centred in a 44 px band (the row's height), and so does
/// the scope strip, so the clear glyph, Cancel and every scope keep their
/// whole 44 px touch target.
///
/// ```dart
/// MinimalSearchField(hint: 'Search habits', onChanged: filter, clearable: true)
/// ```
class MinimalSearchField extends StatefulWidget {
  /// A search field.
  const MinimalSearchField({
    super.key,
    this.hint,
    this.presentation = MinimalSearchPresentation.inline,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.showCancel = false,
    this.clearable = false,
    this.onCancel,
    this.onFocusChanged,
    this.scopes = const <String>[],
    this.scopeIndex = 0,
    this.onScopeChanged,
    this.shortcut,
  });

  /// What an empty field says.
  final String? hint;

  /// Inline in a page, or in a bar with a Cancel.
  final MinimalSearchPresentation presentation;

  /// The query; null keeps its own.
  final TextEditingController? controller;

  /// Reports each edit of the query.
  final ValueChanged<String>? onChanged;

  /// Reports the query when the keyboard's action is pressed.
  final ValueChanged<String>? onSubmitted;

  /// Whether it takes focus when it first shows.
  final bool autofocus;

  /// Its focus; null keeps its own.
  final FocusNode? focusNode;

  /// Whether it takes input.
  final bool enabled;

  /// A Cancel beside the field while it has focus: clears, leaves the field
  /// and calls [onCancel].
  final bool showCancel;

  /// The clear cap while the field holds text (the toolbar always has it).
  final bool clearable;

  /// The toolbar's Cancel: it clears the query and gives up focus first.
  final VoidCallback? onCancel;

  /// Reports when it gains or loses focus.
  final ValueChanged<bool>? onFocusChanged;

  /// What the search runs over (`All`, `Open`, `Done`): two or more print a
  /// tab row under the field.
  final List<String> scopes;

  /// The scope chosen, of the scopes under the field.
  final int scopeIndex;

  /// Reports the scope chosen.
  final ValueChanged<int>? onScopeChanged;

  /// The keys that summon search, printed as [MinimalKbd] caps (one per
  /// space-separated key) while the field is empty and unfocused: `/`,
  /// `⌘ K`, `Ctrl K`. A hint, not a binding: leave it null on a phone,
  /// where there are no keys to press.
  final String? shortcut;

  @override
  State<MinimalSearchField> createState() => _MinimalSearchFieldState();
}

class _MinimalSearchFieldState extends State<MinimalSearchField>
    with MinimalFieldOwner<MinimalSearchField> {
  @override
  TextEditingController? get externalController => widget.controller;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void focusChanged(bool focused) => widget.onFocusChanged?.call(focused);

  @override
  void didUpdateWidget(MinimalSearchField old) {
    super.didUpdateWidget(old);
    syncField(oldController: old.controller, oldFocusNode: old.focusNode);
  }

  void _clear() {
    controller.clear();
    widget.onChanged?.call('');
  }

  void _cancel() {
    _clear();
    focusNode.unfocus();
    widget.onCancel?.call();
  }

  void _escape() {
    if (controller.text.isNotEmpty) {
      _clear();
    } else {
      focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final toolbar = widget.presentation == MinimalSearchPresentation.toolbar;
    final focused = focusNode.hasFocus;
    final hasText = controller.text.isNotEmpty;
    final shortcut = widget.shortcut;
    final showClear =
        hasText && widget.enabled && (toolbar || widget.clearable);
    // The text field's height at the theme's density, so the two line up,
    // grown as the text field's is with larger text: the query keeps its
    // air above and below.
    final height = minimalGrownHeight(
      context,
      t.density.height(
        toolbar ? MinimalChromeMetrics.controlLg : MinimalChromeMetrics.control,
      ),
    );

    Widget input = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      style: t.body,
      cursorColor: t.primary,
      cursorWidth: MinimalFieldMetrics.cursor,
      decoration: minimalBareDecoration(
        hint: widget.hint ?? MinimalLocalizations.of(context).search,
        hintStyle: t.body.c(t.textTertiary),
      ),
    );
    // The line by its capitals, as every label beside it: caret, hint and
    // taps move with it.
    input = minimalCapLabel(input);
    if (Material.maybeOf(context) == null) {
      input = Material(type: MaterialType.transparency, child: input);
    }

    // The rim lerps to each state: focus, rest.
    final field = MinimalFace(
      constraints: BoxConstraints(minHeight: height),
      padding: EdgeInsetsDirectional.only(
        start: MinimalFieldMetrics.inset,
        end: showClear ? MinimalSpacing.s2 : MinimalFieldMetrics.inset,
      ),
      decoration: minimalFrame(
        t.shapes.small,
        // Disabled, it sinks onto the quiet fill, as a text field does.
        fill: widget.enabled ? t.card : t.sunken,
        side: BorderSide(color: focused ? t.ring : t.border, width: t.hairline),
        shadows: toolbar ? t.shadowMd : null,
      ),
      foregroundDecoration: minimalFieldRing(t, shown: keyboardFocused),
      builder: (context, _) => Row(
        children: [
          MinimalIcon(
            LucideIcons.search,
            size: MinimalIconSize.i16,
            color: focused ? t.mutedForeground : t.textTertiary,
          ),
          const MinimalGap(MinimalSpacing.s8),
          Expanded(
            child: CallbackShortcuts(
              bindings: <ShortcutActivator, VoidCallback>{
                const SingleActivator(LogicalKeyboardKey.escape): _escape,
              },
              child: input,
            ),
          ),
          if (showClear) ...[
            const MinimalGap(MinimalSpacing.s4),
            MinimalPressable(
              onPressed: () {
                _clear();
                focusNode.requestFocus();
              },
              semanticLabel: MinimalLocalizations.of(context).clearSearch,
              shape: t.shapes.mark,
              // As tall as the box inside its rim at most: a compact
              // field (28) keeps its height with the glyph in it.
              child: SizedBox.square(
                dimension: math.min(
                  MinimalChromeMetrics.controlSm,
                  height - 2 * t.hairline,
                ),
                child: MinimalIcon(
                  LucideIcons.circleX,
                  size: MinimalIconSize.i16,
                  color: t.textTertiary,
                ),
              ),
            ),
          ] else if (shortcut != null && !focused) ...[
            const MinimalGap(MinimalSpacing.s8),
            MinimalKbd.chord(shortcut),
          ],
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Band(
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.45,
            child: Row(
              children: [
                // A tap anywhere on the box focuses the field, its glyph and
                // its padding too (the field's own tap, placing the caret,
                // and the clear glyph's win the arena where they land).
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // A pointer's convenience: the field's own node is the
                    // screen reader's.
                    excludeFromSemantics: true,
                    onTap: widget.enabled ? focusNode.requestFocus : null,
                    child: field,
                  ),
                ),
                if (widget.showCancel && focused) ...[
                  const MinimalGap(MinimalSpacing.s4),
                  MinimalButton(
                    MinimalLocalizations.of(context).cancel,
                    variant: MinimalButtonVariant.ghost,
                    size: toolbar
                        ? MinimalButtonSize.large
                        : MinimalButtonSize.medium,
                    onPressed: _cancel,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.scopes.length >= 2)
          _Band(
            line: MinimalFilter.height,
            child: Semantics(
              label: MinimalLocalizations.of(context).searchScope,
              container: true,
              child: MinimalFilterBar(
                divider: false,
                padding: EdgeInsetsDirectional.zero,
                children: [
                  for (final (i, label) in widget.scopes.indexed)
                    MinimalFilter(
                      label,
                      selected: i == widget.scopeIndex,
                      onPressed: widget.enabled && widget.onScopeChanged != null
                          ? () => widget.onScopeChanged!(i)
                          : null,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// A 44 px band (the row's height) with [child] centred in it, its hit
/// test padded out to the band, so a control shorter than the band keeps
/// the whole 44 px target: a box only hit-tests the points inside its own
/// size, and the band is what gives the padding room. [line] is the height
/// of one line of controls when the child can wrap; null takes the
/// child's own.
class _Band extends StatelessWidget {
  const _Band({required this.child, this.line});

  final Widget child;
  final double? line;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: MinimalLayout.minHitTarget),
    child: Center(
      child: MinimalHitTarget(line: line, child: child),
    ),
  );
}

/// The filter square's active mark: a small ink dot in its corner.
abstract final class _SearchMetrics {
  static const double filterDot = 6;
  static const double filterDotInset = 5;
}

/// A search that opens elsewhere: it looks like the field — the glyph, the
/// [label] as its placeholder, an optional [detail] line, the [shortcut]
/// caps — but is one tappable control that opens the search page or
/// palette. An optional filter square stands beside it, as tall as the
/// entry; while filters are on, its hairline and glyph turn to the full ink
/// and an ink dot marks its corner. Like the field, it stands in a
/// 44 px band so both controls keep their whole touch target.
///
/// ```dart
/// MinimalSearchEntry(label: 'Search habits', shortcut: '/', onPressed: openSearch)
/// ```
class MinimalSearchEntry extends StatelessWidget {
  /// A row that opens search.
  const MinimalSearchEntry({
    super.key,
    required this.label,
    this.detail,
    this.onPressed,
    this.onFilter,
    this.filtersActive = false,
    this.filterAction,
    this.shortcut,
    this.focusNode,
    this.autofocus = false,
  });

  /// What it searches.
  final String label;

  /// A second line under the label (the current scope, a count).
  final String? detail;

  /// Opens search.
  final VoidCallback? onPressed;

  /// Opens the filters: a button at its end; null hides it.
  final VoidCallback? onFilter;

  /// Whether a filter is on: the button shows it.
  final bool filtersActive;

  /// Replaces the filter square with the caller's own control.
  final Widget? filterAction;

  /// The keys that summon search, printed as [MinimalKbd] caps at the end;
  /// leave it null on a phone, where there are no keys to press.
  final String? shortcut;

  /// Its focus node, for a caller that moves focus to it; null keeps one
  /// of its own.
  final FocusNode? focusNode;

  /// Whether it takes keyboard focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final detail = this.detail;
    final shortcut = this.shortcut;
    final onFilter = this.onFilter;
    final filter =
        filterAction ??
        (onFilter == null
            ? null
            : MinimalPressable(
                onPressed: onFilter,
                semanticLabel: MinimalLocalizations.of(context)
                    .filters(active: filtersActive),
                child: Container(
                  width: MinimalChromeMetrics.control,
                  constraints: const BoxConstraints(
                    minHeight: MinimalChromeMetrics.control,
                  ),
                  decoration: minimalFrame(
                    t.shapes.small,
                    fill: t.card,
                    side: BorderSide(
                      color: filtersActive ? t.foreground : t.border,
                      width: t.hairline,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MinimalIcon(
                        LucideIcons.slidersHorizontal,
                        size: MinimalIconSize.i16,
                        color: filtersActive ? t.foreground : t.mutedForeground,
                      ),
                      if (filtersActive)
                        PositionedDirectional(
                          top: _SearchMetrics.filterDotInset,
                          end: _SearchMetrics.filterDotInset,
                          child: Container(
                            width: _SearchMetrics.filterDot,
                            height: _SearchMetrics.filterDot,
                            decoration: BoxDecoration(
                              color: t.foreground,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ));
    final entry = MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      enabled: onPressed != null,
      child: Container(
        // Grown with larger text, as the field it opens is.
        constraints: BoxConstraints(
          minHeight: minimalGrownHeight(context, MinimalChromeMetrics.control),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(
          MinimalFieldMetrics.inset,
          MinimalSpacing.s4,
          MinimalSpacing.s8,
          MinimalSpacing.s4,
        ),
        // Disabled (nothing to open), it sinks onto the quiet fill, as a
        // disabled field does.
        decoration: minimalFrame(
          t.shapes.small,
          fill: onPressed != null ? t.card : t.sunken,
          side: BorderSide(color: t.border, width: t.hairline),
        ),
        child: Row(
          children: [
            MinimalIcon(
              LucideIcons.search,
              size: MinimalIconSize.i16,
              color: t.textTertiary,
            ),
            const MinimalGap(MinimalSpacing.s8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: t.body.c(t.textTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (detail != null)
                    Text(
                      detail,
                      style: t.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (shortcut != null) ...[
              const MinimalGap(MinimalSpacing.s8),
              MinimalKbd.chord(shortcut),
            ],
          ],
        ),
      ),
    );
    return _Band(
      child: filter == null
          ? entry
          // The square stands as tall as the entry beside it (two lines
          // with a detail), so the pair reads as one unit; a caller's own
          // control keeps its size, centred.
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: entry),
                  const MinimalGap(MinimalChromeMetrics.barActionGap),
                  if (filterAction == null) filter else Center(child: filter),
                ],
              ),
            ),
    );
  }
}
