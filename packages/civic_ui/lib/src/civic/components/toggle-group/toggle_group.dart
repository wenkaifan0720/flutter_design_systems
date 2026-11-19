import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/choice_face.dart';
import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../internal/fit_row.dart';
import '../../theme.dart';

/// One choice of a [CivicToggleGroup] or a [CivicSegmentedControl]: its
/// [value], the [label] it says and an optional [icon] before the words.
@immutable
class CivicSegment<T> {
  /// A choice saying [label].
  const CivicSegment({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
  });

  /// What choosing it gives the group.
  final T value;

  /// Its words. Always shown: a glyph alone says nothing to many readers.
  final String label;

  /// A glyph before the words.
  final IconData? icon;

  /// Whether it can be chosen.
  final bool enabled;

  /// What a screen reader says for it where its words say less ("Small"
  /// for "S"); null says [label].
  final String? semanticLabel;
}

/// Several choices that each turn on or off: a row of faces in the
/// button's material, each saying what it does, those turned on solid in
/// the action colour with a tick before their words. Use it for settings
/// that act at once and combine (Show closed, Show drafts); for one answer
/// of several use [CivicSegmentedControl] or radios, for a question on a
/// form use checkboxes.
///
/// Tab reaches the group once; the arrow keys move along it, Space and
/// Enter turn the face on or off. Where the faces do not fit the width
/// (a phone, large text) they stack, each the whole width, so no word is
/// ever cut.
///
/// Reads [CivicStyle]'s fill, foreground and edge by state (selected among
/// them), padding and textStyle: its `style:`, then
/// [CivicThemeData.toggleStyle]. The faces' solid edge, the tick and the
/// focus are the look's.
///
/// ```dart
/// CivicToggleGroup<String>(
///   labelText: 'Show',
///   segments: const [
///     CivicSegment(value: 'closed', label: 'Closed'),
///     CivicSegment(value: 'drafts', label: 'Drafts'),
///   ],
///   selected: shown,
///   onSelectionChanged: (next) => setState(() => shown = next),
/// )
/// ```
class CivicToggleGroup<T> extends StatelessWidget {
  /// A group of toggles.
  const CivicToggleGroup({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.emptySelectionAllowed = true,
    this.style,
  });

  /// The choices, in reading order.
  final List<CivicSegment<T>> segments;

  /// The values turned on.
  final Set<T> selected;

  /// Called with the values on after a press; null disables the group.
  final ValueChanged<Set<T>>? onSelectionChanged;

  /// What the group sets; a screen reader names the group with it.
  final String? labelText;

  /// How to use it.
  final String? helperText;

  /// What to fix; null while the choice is fine.
  final String? errorText;

  /// Whether every face may be turned off.
  final bool emptySelectionAllowed;

  /// Overrides for the faces' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => _CivicChoiceGroup<T>(
    segments: segments,
    selected: selected,
    onSelectionChanged: onSelectionChanged,
    multiSelectionEnabled: true,
    emptySelectionAllowed: emptySelectionAllowed,
    selectFollowsFocus: false,
    joined: false,
    labelText: labelText,
    helperText: helperText,
    errorText: errorText,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('selected', selected))
      ..add(
        ObjectFlagProperty<ValueChanged<Set<T>>>.has(
          'onSelectionChanged',
          onSelectionChanged,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The toggle group and the segmented control, as one: the faces, their
/// layout and their frame. Plumbing.
class _CivicChoiceGroup<T> extends StatelessWidget {
  const _CivicChoiceGroup({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    required this.multiSelectionEnabled,
    required this.emptySelectionAllowed,
    required this.selectFollowsFocus,
    required this.joined,
    this.labelText,
    this.helperText,
    this.errorText,
    this.style,
  });

  final List<CivicSegment<T>> segments;
  final Set<T> selected;
  final ValueChanged<Set<T>>? onSelectionChanged;
  final bool multiSelectionEnabled;
  final bool emptySelectionAllowed;
  final bool selectFollowsFocus;
  final bool joined;
  final String? labelText;
  final String? helperText;
  final String? errorText;
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final byValue = {for (final s in segments) s.value: s};
    final change = onSelectionChanged;
    final group = DesignToggleGroup<T>(
      options: [for (final s in segments) s.value],
      selected: selected,
      onSelectionChanged: change,
      multiSelectionEnabled: multiSelectionEnabled,
      emptySelectionAllowed: emptySelectionAllowed,
      selectFollowsFocus: selectFollowsFocus,
      isEnabled: (v) => byValue[v]?.enabled ?? false,
      labelOf: (v) => byValue[v]?.semanticLabel ?? byValue[v]?.label ?? '$v',
      semanticLabel: labelText,
      minimumSize: const Size(48, 48),
      layoutBuilder: (context, items) {
        final row = CivicFitRow(
          spacing: joined ? 2 : CivicSpacing.s8,
          equal: joined,
          stretch: joined,
          children: items,
        );
        // A segmented control is one band: its outer corners round, its
        // seams square.
        return joined
            ? ClipRRect(
                borderRadius: BorderRadius.circular(CivicMetrics.corner),
                child: row,
              )
            : row;
      },
      itemBuilder: (context, value, states) {
        final segment = byValue[value];
        final icon = segment?.icon;
        final face = CivicChoiceFace(
          states: states,
          styles: [style, t.toggleStyle],
          radius: joined ? 0 : CivicMetrics.corner,
          leading: icon == null ? null : Icon(icon),
          child: Text(segment?.label ?? '$value'),
        );
        // A band's faces fill their equal shares, seam to seam.
        return DesignTapTarget(
          child: joined ? SizedBox(width: double.infinity, child: face) : face,
        );
      },
    );
    if (labelText == null && helperText == null && errorText == null) {
      return group;
    }
    return DesignField(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      mergeSemantics: false,
      enabled: change != null,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, isLegend: false),
      child: group,
    );
  }
}

/// One answer of a few (two to five, said in a word or two each), all shown
/// at once as one band of faces: the chosen face solid in the action colour
/// with a tick before its words, the others the action's tint. Use it to
/// switch what a page shows (Week, Month, Year); for a question on a form
/// use radios, which hold a hint for each answer.
///
/// Tab reaches the band once, at the answer chosen; the arrow keys choose
/// as they move, as a platform's segmented control does. Where the answers
/// do not fit the width they stack, each the whole width.
///
/// Reads [CivicStyle]'s fill, foreground and edge by state (selected among
/// them), padding and textStyle: its `style:`, then
/// [CivicThemeData.toggleStyle].
///
/// ```dart
/// CivicSegmentedControl<String>(
///   labelText: 'Period',
///   segments: const [
///     CivicSegment(value: 'week', label: 'Week'),
///     CivicSegment(value: 'month', label: 'Month'),
///   ],
///   value: period,
///   onChanged: (next) => setState(() => period = next),
/// )
/// ```
class CivicSegmentedControl<T> extends StatelessWidget {
  /// A segmented control.
  const CivicSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.style,
  });

  /// The answers, in reading order.
  final List<CivicSegment<T>> segments;

  /// The answer chosen; null while none is.
  final T? value;

  /// Called with the answer chosen; null disables the control.
  final ValueChanged<T>? onChanged;

  /// What the control sets; a screen reader names the group with it.
  final String? labelText;

  /// How to use it.
  final String? helperText;

  /// What to fix; null while the answer is fine.
  final String? errorText;

  /// Overrides for the faces' look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final change = onChanged;
    final value = this.value;
    return _CivicChoiceGroup<T>(
      segments: segments,
      selected: {?value},
      onSelectionChanged: change == null
          ? null
          : (next) {
              if (next.isNotEmpty) change(next.first);
            },
      multiSelectionEnabled: false,
      emptySelectionAllowed: false,
      selectFollowsFocus: true,
      joined: true,
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      style: style,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value, defaultValue: null))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
