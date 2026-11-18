import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/bare_field.dart';
import '../../internal/cap.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../internal/panel.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../forms/forms.dart';
import '../pressable/pressable.dart';
import '../../internal/measure.dart';

String _plain(Object option) => '$option';

// ---------------------------------------------------------------------------
// Combobox
// ---------------------------------------------------------------------------

/// A search's list while it runs, on the panel: the words that it is
/// loading, where the empty list says nothing matches.
Widget _searching(BuildContext context) {
  final t = context.frostedTheme;
  return Padding(
    padding: const EdgeInsets.all(FrostedSpacing.s24),
    child: Text(
      DesignLocalizations.of(context).loadingLabel,
      textAlign: TextAlign.center,
      style: t.textTheme.titleMedium.c(t.colorScheme.textTertiary),
    ),
  );
}

/// A failed search's list, on the panel: what went wrong, in the empty
/// list's words, over a Try again row, under the wash while the keys hold
/// it.
Widget _searchFailed(BuildContext context, DesignSearchError failure) {
  final t = context.frostedTheme;
  final words = DesignLocalizations.of(context);
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          FrostedSpacing.s24,
          FrostedSpacing.s24,
          FrostedSpacing.s24,
          FrostedSpacing.s12,
        ),
        child: Text(
          words.searchFailedMessage,
          textAlign: TextAlign.center,
          style: t.textTheme.titleMedium.c(t.colorScheme.textTertiary),
        ),
      ),
      Semantics(
        button: true,
        label: words.retryButtonLabel,
        onTap: failure.retry,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: failure.retry,
          child: FrostedPanelRow(
            label: words.retryButtonLabel,
            checkable: false,
            states: {if (failure.focused) WidgetState.focused},
          ),
        ),
      ),
    ],
  );
}

/// A text field that narrows a list as you type and takes one of its
/// [options] (Material's Autocomplete, shadcn's Combobox): the field in
/// [FrostedTextField]'s well with a chevron at its end, the options on the
/// look's panel under it (above it when there is more room there), the chosen one on
/// the chosen plate, the one row the arrow keys or the pointer last held
/// under the wash (a pointer moving over a row moves the keys' place there,
/// and the keys go on from it); words no option fits say so on the panel. Opened before the words
/// are edited, the list shows every option, the chosen one held; once they
/// are edited, the options they match. The arrows go round the ends (on a
/// closed list they open it), Return or a press takes the held row, Escape
/// closes the list. With
/// [requireSelection] text that is not an option is put back. [search]
/// fetches matches from elsewhere (a server). ui_core's [DesignCombobox] is
/// the behaviour.
///
/// ```dart
/// FrostedCombobox<String>(label: 'Country', options: countries, value: country, onSelected: (v) => setState(() => country = v))
/// ```
class FrostedCombobox<T extends Object> extends StatelessWidget {
  /// A combobox named [label] over [options].
  const FrostedCombobox({
    required this.label,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.value,
    this.onSelected,
    this.isOptionEnabled,
    this.displayString = _plain,
    this.hint,
    this.helper,
    this.error,
    this.requireSelection = false,
    this.controller,
    this.focusNode,
    this.maxListHeight = 300,
    this.autofocus = false,
    super.key,
  });

  /// The field's name, over its well.
  final String label;

  /// What it offers.
  final Iterable<T> options;

  /// {@template frosted.search}
  /// Fetches the matches for a query, in place of filtering [options].
  /// While it runs the list says it is loading; when it fails, it says so
  /// over a Try again row (Down moves the keys there, Return runs it).
  /// {@endtemplate}
  final FutureOr<Iterable<T>> Function(String query)? search;

  /// {@template frosted.debounceDuration}
  /// How long typing rests before [search] runs: a search per pause, not
  /// per letter. Null runs it at every change.
  /// {@endtemplate}
  final Duration? debounceDuration;

  /// The chosen option.
  final T? value;

  /// Called with the option taken.
  final ValueChanged<T>? onSelected;

  /// {@template frosted.isOptionEnabled}
  /// Whether an option can be taken; null: every one can. One that cannot
  /// stands dimmed in the list: the arrow keys pass over it, and neither a
  /// press nor Return takes it.
  /// {@endtemplate}
  final bool Function(T option)? isOptionEnabled;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// An option's words.
  final String Function(T option) displayString;

  /// The placeholder.
  final String? hint;

  /// {@template frosted.helper}
  /// The help line under the well.
  /// {@endtemplate}
  final String? helper;

  /// {@template frosted.error}
  /// What is wrong, in place of the help line.
  /// {@endtemplate}
  final String? error;

  /// Whether only an option may stand in the field.
  final bool requireSelection;

  /// The text's controller, when the caller holds it.
  final TextEditingController? controller;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The tallest the list stands before it scrolls.
  final double maxListHeight;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    // A select's measure: its column on a phone, at most 320 from 600 up.
    return FrostedControlMeasure(
      child: DesignCombobox<T>(
        options: options,
        search: search,
        debounceDuration: debounceDuration,
        loadingBuilder: _searching,
        errorBuilder: _searchFailed,
        value: value,
        onSelected: onSelected,
        isOptionEnabled: isOptionEnabled,
        // The pointer's row and the keys' row are the same wash in Frosted:
        // one place, so the list never shows two held rows.
        highlightFollowsPointer: true,
        // Under the field, or above it when there is more room there (a
        // field at the foot of a phone's screen had room for one row).
        optionsViewOpenDirection: OptionsViewOpenDirection.mostSpace,
        displayStringForOption: displayString,
        requireSelection: requireSelection,
        controller: controller,
        focusNode: focusNode,
        optionsMaxHeight: maxListHeight,
        semanticLabel: label,
        fieldBuilder: (context, field) => FrostedTextField(
          autofocus: autofocus,
          label: label,
          controller: field.controller,
          focusNode: field.focusNode,
          // Enter takes the option and the field keeps the focus: through
          // onEditingComplete, never onSubmitted, or in a browser the
          // typing after it goes nowhere.
          onEditingComplete: field.submit,
          hint: hint,
          helper: helper,
          error: error,
          trailing: ExcludeSemantics(
            child: Icon(
              FrostedGlyphs.chevronDown,
              size: FrostedIconSize.i18,
              color: t.colorScheme.textTertiary,
            ),
          ),
        ),
        optionBuilder: (context, option, states) =>
            FrostedPanelRow(label: displayString(option), states: states),
        surfaceBuilder: (context, list) => FrostedPanel(child: list),
        emptyBuilder: (context) => Padding(
          padding: const EdgeInsets.all(FrostedSpacing.s24),
          child: Text(
            DesignLocalizations.of(context).noResultsLabel,
            textAlign: TextAlign.center,
            style: t.textTheme.titleMedium.c(t.colorScheme.textTertiary),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<T>('options', options, defaultValue: const []))
      ..add(
        ObjectFlagProperty<FutureOr<Iterable<T>> Function(String query)>.has(
          'search',
          search,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onSelected', onSelected))
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(
        ObjectFlagProperty<String Function(T option)>.has(
          'displayString',
          displayString,
        ),
      )
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(
        FlagProperty(
          'requireSelection',
          value: requireSelection,
          ifTrue: 'requireSelection',
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
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('maxListHeight', maxListHeight, defaultValue: 300));
  }
}

// ---------------------------------------------------------------------------
// Multi-select
// ---------------------------------------------------------------------------

/// Several of a list's [options] taken as chips in one well (shadcn's
/// multi-select, a tag input): each chosen value a chip with its own ✕,
/// the text after them narrowing the list under the well. Return or a
/// press takes the lit option (lit by the keys or, as the combobox's, by a
/// pointer moving over it: one place); Backspace in an empty field lights the last
/// chip and a second removes it; the arrow keys walk the chips. With
/// [onCreate] what is typed becomes a value of its own (a new tag); [maxTags]
/// stops taking more. ui_core's [DesignTagInput] is the behaviour.
///
/// ```dart
/// FrostedMultiSelect<String>(label: 'Tags', options: tags, values: chosen, onChanged: (v) => setState(() => chosen = v))
/// ```
class FrostedMultiSelect<T extends Object> extends StatefulWidget {
  /// A multi-select named [label] holding [values].
  const FrostedMultiSelect({
    required this.label,
    required this.values,
    required this.onChanged,
    this.options = const [],
    this.search,
    this.debounceDuration,
    this.isOptionEnabled,
    this.displayString = _plain,
    this.onCreate,
    this.maxTags,
    this.hint,
    this.helper,
    this.error,
    this.focusNode,
    this.maxListHeight = 300,
    this.autofocus = false,
    super.key,
  });

  /// The field's name, over its well.
  final String label;

  /// What is chosen, in order.
  final List<T> values;

  /// Called with the values after a change.
  final ValueChanged<List<T>> onChanged;

  /// {@macro frosted.autofocus}
  final bool autofocus;

  /// What it offers.
  final Iterable<T> options;

  /// {@macro frosted.search}
  final FutureOr<Iterable<T>> Function(String query)? search;

  /// {@macro frosted.debounceDuration}
  final Duration? debounceDuration;

  /// {@macro frosted.isOptionEnabled}
  final bool Function(T option)? isOptionEnabled;

  /// A value's words.
  final String Function(T value) displayString;

  /// Turns typed text into a value of its own; null takes only [options].
  final T? Function(String text)? onCreate;

  /// The most values it takes.
  final int? maxTags;

  /// The placeholder, while nothing is typed.
  final String? hint;

  /// {@macro frosted.helper}
  final String? helper;

  /// {@macro frosted.error}
  final String? error;

  /// The field's focus.
  final FocusNode? focusNode;

  /// The tallest the list stands before it scrolls.
  final double maxListHeight;

  @override
  State<FrostedMultiSelect<T>> createState() => _FrostedMultiSelectState<T>();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<T>('values', values))
      ..add(
        ObjectFlagProperty<ValueChanged<List<T>>>.has('onChanged', onChanged),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(IterableProperty<T>('options', options, defaultValue: const []))
      ..add(
        ObjectFlagProperty<FutureOr<Iterable<T>> Function(String query)>.has(
          'search',
          search,
        ),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'debounceDuration',
          debounceDuration,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<bool Function(T option)>.has(
          'isOptionEnabled',
          isOptionEnabled,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(T value)>.has(
          'displayString',
          displayString,
        ),
      )
      ..add(
        ObjectFlagProperty<T? Function(String text)>.has('onCreate', onCreate),
      )
      ..add(IntProperty('maxTags', maxTags, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
      ..add(StringProperty('helper', helper, defaultValue: null))
      ..add(StringProperty('error', error, defaultValue: null))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(DoubleProperty('maxListHeight', maxListHeight, defaultValue: 300));
  }
}

class _FrostedMultiSelectState<T extends Object>
    extends State<FrostedMultiSelect<T>> {
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
  }

  @override
  void didUpdateWidget(FrostedMultiSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _own)?.removeListener(_changed);
      _focus.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final error = widget.error;
    final helper = widget.helper;
    // A select's measure: its column on a phone, at most 320 from 600 up.
    return FrostedControlMeasure(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: FrostedChromeMetrics.fieldLabelGap,
        children: [
          FrostedFieldLabel(widget.label),
          DesignTagInput<T>(
            values: widget.values,
            onChanged: widget.onChanged,
            options: widget.options,
            search: widget.search,
            debounceDuration: widget.debounceDuration,
            loadingBuilder: _searching,
            errorBuilder: _searchFailed,
            isOptionEnabled: widget.isOptionEnabled,
            // One held row, as the combobox's.
            highlightFollowsPointer: true,
            displayStringForOption: widget.displayString,
            onCreate: widget.onCreate,
            maxTags: widget.maxTags,
            focusNode: _focus,
            optionsMaxHeight: widget.maxListHeight,
            semanticLabel: widget.label,
            deleteLabel: words.remove,
            fieldBuilder: (context, field) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 96),
              child: FrostedBareField(
                controller: field.controller,
                focusNode: field.focusNode,
                autofocus: widget.autofocus,
                label: widget.label,
                hint: widget.values.isEmpty ? widget.hint : null,
                // Enter adds the tag and the field keeps the focus for the
                // next, as the combobox's.
                onEditingComplete: field.submit,
              ),
            ),
            layoutBuilder: (context, tags, field) {
              // A tag stands in its touch target's lane (48 under a
              // finger); the lane takes what it reaches past the tag from
              // the well's padding and the gap between runs, so one run of
              // tags keeps the field's height wherever the lane allows.
              final tag = frostedGrownHeight(
                context,
                28,
                t.textTheme.labelLarge,
              );
              final past = math.max(
                0.0,
                FrostedBreakpoints.hitTargetOf(context) - tag,
              );
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: FrostedChromeMetrics.field,
                ),
                child: FrostedWell(
                  focused: _focus.hasFocus,
                  error: error != null,
                  // In by a field's inset, so its words (the first tag's
                  // face, the typed words, the hint) start where every
                  // field's words do and its list lies as every field's
                  // list (ui_core's lists sweep: 4 px in short of them).
                  padding: EdgeInsets.symmetric(
                    horizontal: FrostedChromeMetrics.fieldInset,
                    vertical: math.max(0.0, FrostedSpacing.s8 - past / 2),
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _TagFlow(
                      spacing: FrostedSpacing.s6,
                      runSpacing: math.max(0.0, FrostedSpacing.s6 - past),
                      fieldMin: 96,
                      children: [
                        ...tags,
                        // The field fills the rest of the last run, in a
                        // lane a touch target tall that its line answers
                        // across, beside the tags rather than under them.
                        FrostedFieldRoom(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: FrostedBreakpoints.hitTargetOf(
                                context,
                              ),
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              heightFactor: 1,
                              child: field,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            tagBuilder: (context, value, tag) {
              final name = widget.displayString(value);
              final type = t.textTheme.labelLarge;
              final chip = FrostedFace(
                material: FrostedMaterial.paint,
                radius: BorderRadius.circular(FrostedCorners.r10),
                color: tag.focused
                    ? t.colorScheme.accentSubtle
                    : t.glass.fillHigh,
                ring: tag.focused ? t.colorScheme.accent : t.glass.edge,
                padding: const EdgeInsetsDirectional.only(
                  start: FrostedSpacing.s10,
                ).resolve(Directionality.of(context)),
                // Large text grows the tag by its words' extra line: held
                // to its 28 remover, at 200% the words stood out of the
                // glass above and below (self-review round 5).
                child: SizedBox(
                  height: frostedGrownHeight(context, 28, type),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: type.c(t.colorScheme.textPrimary)),
                      // Its node spans the tag's lane, as its tap does.
                      FrostedLaneKey(
                        child: FrostedPressable(
                          onPressed: tag.onDeleted,
                          label: '${words.remove} $name',
                          radius: FrostedCorners.r10,
                          builder: (context, states, _) => SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(
                              FrostedGlyphs.close,
                              size: 14,
                              color: states.contains(WidgetState.hovered)
                                  ? t.colorScheme.textPrimary
                                  : t.colorScheme.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              return FrostedTargetLane(child: chip);
            },
            optionBuilder: (context, option, states) => FrostedPanelRow(
              label: widget.displayString(option),
              states: states,
            ),
            surfaceBuilder: (context, list) => FrostedPanel(child: list),
          ),
          if (error != null)
            FrostedFieldHint(error, error: true)
          else if (helper != null)
            FrostedFieldHint(helper),
        ],
      ),
    );
  }
}

/// Tags in runs, the last child (the field) filling what is left of the
/// last run, or a run of its own where less than [fieldMin] is left: a tag
/// input's line follows its tags. Each run stands as tall as its tallest
/// child, the others centred in it; mirrored right to left.
class _TagFlow extends MultiChildRenderObjectWidget {
  const _TagFlow({
    required this.spacing,
    required this.runSpacing,
    required this.fieldMin,
    required super.children,
  });

  final double spacing;
  final double runSpacing;
  final double fieldMin;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTagFlow(spacing, runSpacing, fieldMin, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderTagFlow)
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..fieldMin = fieldMin
      ..textDirection = Directionality.of(context);
  }
}

class _TagFlowData extends ContainerBoxParentData<RenderBox> {}

class _RenderTagFlow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TagFlowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TagFlowData> {
  _RenderTagFlow(
    this._spacing,
    this._runSpacing,
    this._fieldMin,
    this._textDirection,
  );

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _runSpacing;
  set runSpacing(double value) {
    if (value == _runSpacing) return;
    _runSpacing = value;
    markNeedsLayout();
  }

  double _fieldMin;
  set fieldMin(double value) {
    if (value == _fieldMin) return;
    _fieldMin = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TagFlowData) child.parentData = _TagFlowData();
  }

  /// Each child's size and offset (start-relative, mirrored at the end),
  /// and the flow's size, at [constraints]' width.
  (Size, List<(RenderBox, Size, Offset)>) _flow(
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints c) measure,
  ) {
    final bounded = constraints.hasBoundedWidth;
    final width = bounded ? constraints.maxWidth : double.infinity;
    final runs = <List<(RenderBox, Size, double)>>[[]];
    var x = 0.0;
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final field = child == lastChild;
      final start = x == 0 ? 0.0 : x + _spacing;
      Size size;
      double at;
      if (field) {
        final left = bounded ? width - start : _fieldMin;
        if (x > 0 && left < math.min(_fieldMin, width)) {
          runs.add([]);
          size = measure(child, BoxConstraints.tightFor(width: width));
          at = 0;
        } else {
          size = measure(
            child,
            BoxConstraints.tightFor(width: math.max(0.0, left)),
          );
          at = start;
        }
      } else {
        size = measure(child, BoxConstraints(maxWidth: width));
        if (x > 0 && start + size.width > width) {
          runs.add([]);
          at = 0;
        } else {
          at = start;
        }
      }
      runs.last.add((child, size, at));
      x = at + size.width;
      widest = math.max(widest, x);
    }
    final across = bounded ? width : widest;
    final placed = <(RenderBox, Size, Offset)>[];
    var y = 0.0;
    for (final (i, run) in runs.indexed) {
      if (run.isEmpty) continue;
      if (i > 0 && placed.isNotEmpty) y += _runSpacing;
      final tall = run.fold(0.0, (h, e) => math.max(h, e.$2.height));
      for (final (child, size, at) in run) {
        final dx = _textDirection == TextDirection.rtl
            ? across - at - size.width
            : at;
        placed.add((child, size, Offset(dx, y + (tall - size.height) / 2)));
      }
      y += tall;
    }
    return (constraints.constrain(Size(across, y)), placed);
  }

  @override
  void performLayout() {
    final (size, placed) = _flow(constraints, (child, c) {
      child.layout(c, parentUsesSize: true);
      return child.size;
    });
    for (final (child, _, offset) in placed) {
      (child.parentData! as _TagFlowData).offset = offset;
    }
    this.size = size;
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _flow(constraints, (child, c) => child.getDryLayout(c)).$1;

  Size _intrinsic(RenderBox child, BoxConstraints c) {
    final w = c.hasTightWidth
        ? c.maxWidth
        : math.min(child.getMaxIntrinsicWidth(double.infinity), c.maxWidth);
    return Size(w, child.getMaxIntrinsicHeight(w));
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var widest = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      widest = math.max(
        widest,
        child == lastChild ? _fieldMin : child.getMinIntrinsicWidth(height),
      );
    }
    return widest;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var sum = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (sum > 0) sum += _spacing;
      sum += child == lastChild
          ? _fieldMin
          : child.getMaxIntrinsicWidth(height);
    }
    return sum;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _flow(BoxConstraints(maxWidth: width), _intrinsic).$1.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
