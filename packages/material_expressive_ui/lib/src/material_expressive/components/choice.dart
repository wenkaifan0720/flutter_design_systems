/// Choice tiles: a large tonal tile per option, for a decision a page is
/// about (how readings arrive, which rooms a home has, your usual café),
/// alone or in a group that chooses one (radio semantics) or several
/// (checkbox semantics). Owner: front-doors `sys`.
///
/// Not a Compose component: Material 3 Expressive draws these decisions as
/// selectable surfaces (Clock's alarm rows, Phone's in-call controls), which
/// this builds from the system's own parts. The tile is an
/// [ExpressivePressable] on the list item's geometry (`ListTokens`), its
/// container `surfaceContainerHigh` at rest and `primaryContainer` when
/// selected on the fast effects spring; selecting morphs its corners from
/// `large` toward `extraLargeIncreased` (pressed squeezes to `medium`) on
/// the fast spatial spring, fills the leading glyph and raises the title to
/// its emphasized style — emphasized type on a selected label is
/// expressive by default (CONTRACT §3), not a hero. A selected tile also
/// shows a check, so the choice never reads from colour alone.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../icons.dart';
import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/styled_content.dart';
import '../internal/tokens/list_tokens.g.dart';
import '../motion.dart';
import '../spacing.dart';
import '../states.dart';
import '../theme.dart';

TextStyle _lerpStyle(TextStyle a, TextStyle b, double t) =>
    TextStyle.lerp(a, b, t)!;

/// One large tonal choice: [icon], [title] and an optional
/// [supportingText] line, selected or not. Tap it to choose; in a group
/// ([ExpressiveChoiceGroup]) the group decides what a tap does.
///
/// ```dart
/// ExpressiveChoiceTile(icon: ExpressiveSymbols.sync, title: 'Bluetooth arm cuff', supportingText: 'Readings arrive on their own', selected: source == 'cuff', onPressed: () => setState(() => source = 'cuff'))
/// ```
class ExpressiveChoiceTile extends StatelessWidget {
  /// A choice tile titled [title], [selected] or not: one of a set,
  /// announced as a radio button.
  const ExpressiveChoiceTile({
    required this.title,
    this.icon,
    this.supportingText,
    this.selected = false,
    this.onPressed,
    this.style,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _multi = false;

  /// A choice tile of a set that takes any number: announced as a
  /// checkbox.
  const ExpressiveChoiceTile.multi({
    required this.title,
    this.icon,
    this.supportingText,
    this.selected = false,
    this.onPressed,
    this.style,
    super.key,
    this.focusNode,
    this.autofocus = false,
  }) : _multi = true;

  const ExpressiveChoiceTile._({
    required this.title,
    this.icon,
    this.supportingText,
    this.selected = false,
    this.onPressed,
    this.style,
    required this._multi,
  }) : focusNode = null,
       autofocus = false;

  /// Stateful visual overrides before the option theme.
  final ExpressiveComponentThemeData? style;

  /// The choice, in `titleMedium` (emphasized when selected).
  final String title;

  /// A leading glyph: one of [ExpressiveSymbols], filled when selected.
  final IconData? icon;

  /// A second line under the title.
  final String? supportingText;

  /// Whether the choice is made.
  final bool selected;

  /// What a tap does; null disables the tile.
  final VoidCallback? onPressed;

  // Checkbox (any number) rather than radio (one of a set) semantics.
  final bool _multi;

  /// The focus node of its press target; null lets the target keep its own.
  final FocusNode? focusNode;

  /// Whether it takes focus when first built.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final direction = Directionality.of(context);
    final c = t.colors;
    final enabled = onPressed != null;
    final container = selected ? c.primaryContainer : c.surfaceContainerHigh;
    final content = selected ? c.onPrimaryContainer : c.onSurface;
    final supporting = selected ? c.onPrimaryContainer : c.onSurfaceVariant;
    return ExpressivePressable(
      focusNode: focusNode,
      autofocus: autofocus,
      style: style,
      componentStyle: t.optionTheme,
      shapes: ExpressivePressShapes(
        shape: t.shapes.large,
        pressed: t.shapes.medium,
        selected: t.shapes.extraLargeIncreased,
      ),
      motion: ExpressiveMotionKey.fastSpatial,
      colorMotion: ExpressiveMotionKey.fastEffects,
      color: container,
      contentColor: content,
      role: _multi ? ExpressivePressRole.checkbox : ExpressivePressRole.radio,
      selected: selected,
      onPressed: onPressed,
      child: Builder(
        builder: (context) {
          final scope = ExpressiveStyleScope.maybeOf(context)!;
          final resolved = scope.style;
          final states = scope.states;
          final foreground = resolved.foregroundColor?.resolve(states);
          final labelStyle = resolved.textStyle?.resolve(states);
          Widget glyph(IconData value, double token, {bool filled = false}) =>
              ExpressiveIcon(
                value,
                selected: filled,
                size: resolved.iconSize?.resolve(states) ?? token,
                color: foreground ?? content,
              );
          final leading = icon == null
              ? null
              : glyph(icon!, ListTokens.itemLeadingIconSize, filled: selected);
          final trailing = ExpressiveSpringValue(
            value: selected ? 1 : 0,
            motion: ExpressiveMotionKey.fastSpatial,
            builder: (context, shown, child) => shown <= 0
                ? const SizedBox.shrink()
                : Opacity(
                    opacity: shown.clamp(0.0, 1.0),
                    child: Transform.scale(scale: shown, child: child),
                  ),
            child: glyph(
              ExpressiveSymbols.checkCircle,
              ListTokens.itemTrailingIconSize,
              filled: true,
            ),
          );
          final words = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExpressiveSpringTween<TextStyle>(
                value:
                    (selected
                            ? t.type.titleMediumEmphasized
                            : t.type.titleMedium)
                        .merge(labelStyle),
                motion: ExpressiveMotionKey.fastEffects,
                lerp: _lerpStyle,
                // Alone, the title sits on the option's middle: centred by its
                // capitals; over a supporting line it is placed.
                builder: (context, textStyle, _) {
                  final text = Text(
                    title,
                    style: textStyle.copyWith(color: foreground ?? content),
                  );
                  return supportingText == null
                      ? expressiveFaceLabel(text)
                      : text;
                },
              ),
              if (supportingText != null)
                Text(
                  supportingText!,
                  style: t.type.bodyMedium
                      .merge(labelStyle)
                      .copyWith(color: foreground ?? supporting),
                ),
            ],
          );
          return Opacity(
            opacity: enabled || foreground != null
                ? 1
                : ListTokens.itemDisabledLabelTextOpacity,
            child: ExpressiveStyledContent(
              minimumSize: const Size(0, ListTokens.itemTwoLineContainerHeight),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: ExpressiveSpacing.s20,
                vertical: ExpressiveSpacing.s16,
              ),
              center: false,
              keylineSides: true,
              child: _ChoiceLayout(
                hasLeading: leading != null,
                showHeader: leading != null || selected,
                textDirection: direction,
                children: [?leading, words, trailing],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ChoiceParentData extends ContainerBoxParentData<RenderBox> {}

/// The narrow tile moves its glyphs above its words. Keep that layout in a
/// render object so intrinsic-height parents can measure either arrangement.
class _ChoiceLayout extends MultiChildRenderObjectWidget {
  const _ChoiceLayout({
    required this.hasLeading,
    required this.showHeader,
    required this.textDirection,
    required super.children,
  });

  final bool hasLeading;
  final bool showHeader;
  final TextDirection textDirection;

  @override
  _RenderChoiceLayout createRenderObject(BuildContext context) =>
      _RenderChoiceLayout(hasLeading, showHeader, textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderChoiceLayout renderObject,
  ) {
    renderObject
      ..hasLeading = hasLeading
      ..showHeader = showHeader
      ..textDirection = textDirection;
  }
}

class _RenderChoiceLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ChoiceParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ChoiceParentData> {
  _RenderChoiceLayout(this._hasLeading, this._showHeader, this._textDirection);

  bool _hasLeading;
  set hasLeading(bool value) {
    if (value == _hasLeading) return;
    _hasLeading = value;
    markNeedsLayout();
  }

  bool _showHeader;
  set showHeader(bool value) {
    if (value == _showHeader) return;
    _showHeader = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _words => getChildrenAsList()[_hasLeading ? 1 : 0];
  Iterable<RenderBox> get _glyphs =>
      getChildrenAsList().where((child) => child != _words);

  double get _gaps => _glyphs.length * ExpressiveSpacing.s16;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ChoiceParentData) {
      child.parentData = _ChoiceParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _words.getMinIntrinsicWidth(height),
    _glyphs.fold<double>(
      0,
      (w, child) => w + child.getMaxIntrinsicWidth(height),
    ),
  );

  @override
  double computeMaxIntrinsicWidth(double height) =>
      getChildrenAsList().fold<double>(
        0,
        (w, child) => w + child.getMaxIntrinsicWidth(height),
      ) +
      _gaps;

  double _intrinsicHeight(double width, {required bool minimum}) {
    final narrow = width < 160;
    final glyphsWidth = _glyphs.fold<double>(
      0,
      (w, child) => w + child.getMaxIntrinsicWidth(double.infinity),
    );
    final wordsWidth = narrow
        ? width
        : math.max(0.0, width - glyphsWidth - _gaps);
    double height(RenderBox child, double available) => minimum
        ? child.getMinIntrinsicHeight(available)
        : child.getMaxIntrinsicHeight(available);
    final glyphHeight = _glyphs.fold<double>(
      0,
      (h, child) => math.max(h, height(child, width)),
    );
    final wordsHeight = height(_words, wordsWidth);
    return narrow
        ? wordsHeight + (_showHeader ? glyphHeight + ExpressiveSpacing.s8 : 0)
        : math.max(glyphHeight, wordsHeight);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _intrinsicHeight(width, minimum: true);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _intrinsicHeight(width, minimum: false);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final loose = constraints.loosen();
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : computeMaxIntrinsicWidth(constraints.maxHeight);
    final narrow = width < 160;
    final glyphSizes = <RenderBox, Size>{};
    for (final child in _glyphs) {
      glyphSizes[child] = dry
          ? child.getDryLayout(loose)
          : (child..layout(loose, parentUsesSize: true)).size;
    }
    final wordsWidth = narrow
        ? width
        : math.max(
            0.0,
            width -
                glyphSizes.values.fold<double>(0, (w, s) => w + s.width) -
                _gaps,
          );
    final wordsConstraints = BoxConstraints(
      minWidth: wordsWidth,
      maxWidth: wordsWidth,
      maxHeight: loose.maxHeight,
    );
    final words = _words;
    final wordsSize = dry
        ? words.getDryLayout(wordsConstraints)
        : (words..layout(wordsConstraints, parentUsesSize: true)).size;
    final glyphHeight = glyphSizes.values.fold<double>(
      0,
      (h, s) => math.max(h, s.height),
    );
    final headerHeight = _showHeader ? glyphHeight + ExpressiveSpacing.s8 : 0.0;
    final result = constraints.constrain(
      Size(
        width,
        narrow
            ? headerHeight + wordsSize.height
            : math.max(glyphHeight, wordsSize.height),
      ),
    );
    if (!dry) {
      void position(RenderBox child, double x, double y) {
        (child.parentData! as _ChoiceParentData).offset = Offset(
          _textDirection == TextDirection.ltr
              ? x
              : result.width - x - child.size.width,
          y,
        );
      }

      if (narrow) {
        position(words, 0, headerHeight);
        final children = getChildrenAsList();
        if (_hasLeading) {
          position(
            children.first,
            0,
            (glyphHeight - children.first.size.height) / 2,
          );
        }
        position(
          children.last,
          width - children.last.size.width,
          (glyphHeight - children.last.size.height) / 2,
        );
      } else {
        var x = 0.0;
        for (final child in getChildrenAsList()) {
          position(child, x, (result.height - child.size.height) / 2);
          x += child.size.width + ExpressiveSpacing.s16;
        }
      }
    }
    return result;
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}

/// One option of an [ExpressiveChoiceGroup].
@immutable
class ExpressiveChoiceOption<T> {
  /// An option standing for [value], titled [title].
  const ExpressiveChoiceOption({
    required this.value,
    required this.title,
    this.icon,
    this.supportingText,
    this.enabled = true,
  });

  /// What choosing this option reports.
  final T value;

  /// The tile's title.
  final String title;

  /// The tile's leading glyph.
  final IconData? icon;

  /// The tile's second line.
  final String? supportingText;

  /// Whether the option can be chosen.
  final bool enabled;
}

/// Choice tiles as a group, [ExpressiveSpacing.s8] apart: `.single` chooses
/// one ([value], radio semantics) and reports it on the tap itself, so a
/// first-run step can advance on it; `.multi` chooses any number
/// ([values], checkbox semantics), a tap toggling one. [semanticLabel]
/// names the group (the question it answers).
///
/// ```dart
/// ExpressiveChoiceGroup<String>.single(value: source, onChanged: (v) => setState(() => source = v), semanticLabel: 'How readings arrive', options: const [ExpressiveChoiceOption(value: 'cuff', title: 'Bluetooth arm cuff', icon: ExpressiveSymbols.sync), ExpressiveChoiceOption(value: 'hand', title: 'Enter by hand', icon: ExpressiveSymbols.edit)])
/// ```
class ExpressiveChoiceGroup<T> extends StatelessWidget {
  /// One of [options]: [_onChanged] reports the tapped option's value.
  const ExpressiveChoiceGroup.single({
    required this.options,
    required this._value,
    required ValueChanged<T> this._onChanged,
    this.semanticLabel,
    this.style,
    super.key,
  }) : _multi = false,
       _values = null,
       _onChangedAll = null;

  /// Any of [options]: [onChanged] reports the new set.
  const ExpressiveChoiceGroup.multi({
    required this.options,
    required Set<T> this._values,
    required ValueChanged<Set<T>> onChanged,
    this.semanticLabel,
    this.style,
    super.key,
  }) : _multi = true,
       _value = null,
       _onChanged = null,
       _onChangedAll = onChanged;

  /// Stateful visual overrides for each option tile.
  final ExpressiveComponentThemeData? style;

  /// The options, in order.
  final List<ExpressiveChoiceOption<T>> options;

  // Any number of the options, rather than one.
  final bool _multi;

  /// What a screen reader calls the group.
  final String? semanticLabel;

  final T? _value;
  final Set<T>? _values;
  final ValueChanged<T>? _onChanged;
  final ValueChanged<Set<T>>? _onChangedAll;

  bool _chosen(T value) => _multi ? _values!.contains(value) : _value == value;

  void _tap(T value) {
    if (!_multi) {
      _onChanged!(value);
    } else {
      final next = Set<T>.of(_values!);
      if (!next.remove(value)) next.add(value);
      _onChangedAll!(next);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: semanticLabel,
    explicitChildNodes: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: ExpressiveSpacing.s8,
      children: <Widget>[
        for (final option in options)
          ExpressiveChoiceTile._(
            style: style,
            title: option.title,
            icon: option.icon,
            supportingText: option.supportingText,
            multi: _multi,
            selected: _chosen(option.value),
            onPressed: option.enabled ? () => _tap(option.value) : null,
          ),
      ],
    ),
  );
}
