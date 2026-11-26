/// The search field and the tappable search entry that opens one.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/face.dart';
import '../internal/field.dart';
import '../internal/styled.dart';
import '../internal/tap_band.dart';
import '../internal/text_entry.dart';
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
/// Escape clears a query. When empty, Escape dismisses the enclosing popup or leaves the field. Focus turns the rule to
/// the accent, 1.5 px in from the outline, with no ring outside it.
/// `showCancel` adds a quiet Cancel beside the focused field; [scopes] (two
/// or more) print a strip of [MinimalFilter]s under it.
///
/// The field stands centred in a band at the tap floor, and so does the
/// scope strip, so the clear glyph, Cancel and every scope keep their whole
/// touch target.
///
/// ```dart
/// MinimalSearchField(hintText: 'Search habits', onChanged: filter, clearable: true)
/// ```
class MinimalSearchField extends StatefulWidget {
  /// A search field.
  const MinimalSearchField({
    super.key,
    this.hintText,
    this.presentation = MinimalSearchPresentation.inline,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.autofocus = false,
    this.focusNode,
    this.enabled = true,
    this.showCancel = false,
    this.clearable = false,
    this.onCancel,
    this.onFocusChange,
    this.scopes = const <String>[],
    this.scopeIndex = 0,
    this.onScopeChanged,
    this.shortcut,
  });

  /// What an empty field says.
  final String? hintText;

  /// Inline in a page, or in a bar with a Cancel.
  final MinimalSearchPresentation presentation;

  /// The query; null keeps its own.
  final TextEditingController? controller;

  /// Reports each edit of the query.
  final ValueChanged<String>? onChanged;

  /// Reports the query when the keyboard's action is pressed; the field
  /// then gives up the focus.
  final ValueChanged<String>? onSubmitted;

  /// Runs when the keyboard's action finishes editing, in place of the
  /// field's default, which gives up the focus. A search that stays
  /// focused after Enter (a palette's, one that adds another) takes Enter
  /// here and leaves [onSubmitted] unset: Flutter restarts the text input
  /// of a field told of a submit that still holds the focus, and in a
  /// browser it then takes no typing.
  final VoidCallback? onEditingComplete;

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
  final ValueChanged<bool>? onFocusChange;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('hintText', hintText, defaultValue: null))
      ..add(
        EnumProperty<MinimalSearchPresentation>(
          'presentation',
          presentation,
          defaultValue: MinimalSearchPresentation.inline,
        ),
      )
      ..add(
        DiagnosticsProperty<TextEditingController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has('onChanged', onChanged),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<String>>.has(
          'onSubmitted',
          onSubmitted,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'enabled: false'))
      ..add(FlagProperty('showCancel', value: showCancel, ifTrue: 'showCancel'))
      ..add(FlagProperty('clearable', value: clearable, ifTrue: 'clearable'))
      ..add(ObjectFlagProperty<VoidCallback>.has('onCancel', onCancel))
      ..add(
        ObjectFlagProperty<ValueChanged<bool>>.has(
          'onFocusChange',
          onFocusChange,
        ),
      )
      ..add(IterableProperty<String>('scopes', scopes))
      ..add(IntProperty('scopeIndex', scopeIndex, defaultValue: 0))
      ..add(
        ObjectFlagProperty<ValueChanged<int>>.has(
          'onScopeChanged',
          onScopeChanged,
        ),
      )
      ..add(StringProperty('shortcut', shortcut, defaultValue: null));
  }
}

class _MinimalSearchFieldState extends State<MinimalSearchField>
    with MinimalFieldOwner<MinimalSearchField> {
  @override
  TextEditingController? get externalController => widget.controller;

  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void focusChanged(bool focused) => widget.onFocusChange?.call(focused);

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

    Widget input = MinimalBareTextField(
      controller: controller,
      focusNode: focusNode,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      style: t.body,
      hint: widget.hintText ?? MinimalLocalizations.of(context).search,
      hintStyle: t.body.c(t.mutedForeground),
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
      foregroundDecoration: minimalFocusEdge(t, shown: focused),
      builder: (context, _) => Row(
        children: [
          MinimalIcon(
            LucideIcons.search,
            size: MinimalIconSize.i16,
            color: focused ? t.mutedForeground : t.textTertiary,
          ),
          const MinimalGap(MinimalSpacing.s8),
          // The input's node reaches its outline: outermost in the slot,
          // so no box round the line stops a tap past it.
          Expanded(
            child: MinimalFieldTarget(
              child: Focus(
                canRequestFocus: false,
                skipTraversal: true,
                includeSemantics: false,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent ||
                      event.logicalKey != LogicalKeyboardKey.escape) {
                    return KeyEventResult.ignored;
                  }
                  // Check the controller at the keypress, including an edit
                  // that has not drawn its next frame yet.
                  if (controller.text.isEmpty &&
                      ModalRoute.of(context) is PopupRoute<dynamic>) {
                    return KeyEventResult.ignored;
                  }
                  _escape();
                  return KeyEventResult.handled;
                },
                child: input,
              ),
            ),
          ),
          if (showClear) ...[
            const MinimalGap(MinimalSpacing.s4),
            // Its target spans the box inside the rim: in the taller
            // toolbar box a tap above or below the glyph clears too.
            minimalInlineTargets(
              context,
              height: height - 2 * t.hairline,
              MinimalPressable(
                onPressed: () {
                  _clear();
                  focusNode.requestFocus();
                },
                tapAlignment: AlignmentDirectional.centerEnd,
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
                    // The clear button's only mark: 3:1 at least.
                    color: t.mutedForeground,
                  ),
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
        Opacity(
          opacity: widget.enabled ? 1 : 0.45,
          child: Row(
            children: [
              // A tap anywhere on the box or the band round it focuses the
              // field, its glyph and its padding too (the field's own tap,
              // placing the caret, and the clear glyph's win the arena where
              // they land).
              Expanded(
                // At a finger the box stands in a band as tall as the floor,
                // laid out: a tap in it lands on the box's nearest edge.
                child: MinimalTapBand(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // A pointer's convenience: the field's own node is the
                    // screen reader's.
                    excludeFromSemantics: true,
                    onTap: widget.enabled ? focusNode.requestFocus : null,
                    child: field,
                  ),
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
        if (widget.scopes.length >= 2)
          Semantics(
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
      ],
    );
  }
}

/// The air above and below a [face] tall face that brings it up to the tap
/// floor; none at a pointer, or for a face already as tall.
double _airRound(BuildContext context, double face) =>
    math.max(0, (minimalTapFloor(context) - face) / 2);

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
/// band at the tap floor so both controls keep their whole touch target.
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

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final detail = this.detail;
    final shortcut = this.shortcut;
    final onFilter = this.onFilter;
    // At a finger the entry and its square are laid out at the tap floor:
    // their compact faces keep their size, with the air round them taking
    // the tap. A two-line entry keeps a one-line entry's air.
    final air = _airRound(
      context,
      minimalGrownHeight(context, MinimalChromeMetrics.control),
    );
    final side = _airRound(context, MinimalChromeMetrics.control);
    final filter =
        filterAction ??
        (onFilter == null
            ? null
            : MinimalPressable(
                tapTarget: false,
                outset: EdgeInsets.symmetric(vertical: -air, horizontal: -side),
                onPressed: onFilter,
                semanticLabel: MinimalLocalizations.of(context)
                    .filters(active: filtersActive),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: air,
                    horizontal: side,
                  ),
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
                          color: filtersActive
                              ? t.foreground
                              : t.mutedForeground,
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
                ),
              ));
    final entry = MinimalPressable(
      focusNode: focusNode,
      autofocus: autofocus,
      onPressed: onPressed,
      enabled: onPressed != null,
      tapTarget: false,
      outset: EdgeInsets.symmetric(vertical: -air),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: air),
        child: Container(
          // Grown with larger text, as the field it opens is.
          constraints: BoxConstraints(
            minHeight: minimalGrownHeight(
              context,
              MinimalChromeMetrics.control,
            ),
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
                      style: t.body.c(t.mutedForeground),
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
      ),
    );
    if (filter == null) return entry;
    // The square stands as tall as the entry beside it (two lines with a
    // detail), so the pair reads as one unit; a caller's own control keeps
    // its size, centred. The square's own air stands in the gap.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: entry),
          MinimalGap(
            filterAction == null
                ? math.max(0, MinimalChromeMetrics.barActionGap - side)
                : MinimalChromeMetrics.barActionGap,
          ),
          if (filterAction == null) filter else Center(child: filter),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(StringProperty('detail', detail, defaultValue: null))
      ..add(ObjectFlagProperty<VoidCallback>.has('onPressed', onPressed))
      ..add(ObjectFlagProperty<VoidCallback>.has('onFilter', onFilter))
      ..add(
        FlagProperty(
          'filtersActive',
          value: filtersActive,
          ifTrue: 'filtersActive',
        ),
      )
      ..add(StringProperty('shortcut', shortcut, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}
