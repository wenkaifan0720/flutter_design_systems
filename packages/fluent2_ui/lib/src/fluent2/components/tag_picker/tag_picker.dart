import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/hit_slop.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../dropdown/dropdown.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';

/// A tag picker's size: 32 tall empty, 34 with its tags (20), or 40 and
/// 42 (its tags 24).
enum Fluent2MultiSelectSize {
  /// The medium size.
  medium,

  /// The large size.
  large,
}

/// Fluent 2's TagPicker: a field-faced control (32 tall, 12 in at each
/// side, the brand underline while it holds focus) holding the chosen
/// [options] as filled tags (20 tall, Fluent's grey, caption1 in
/// the second ink, a 12 dismiss glyph that turns brand under the
/// pointer; a press on a tag takes it away), then a text input that
/// filters the options not yet chosen into a listbox under the field (the
/// list closes when nothing matches). Enter or a press adds the active
/// option; a comma adds what was typed when it names an option; Backspace
/// or Left in an empty input moves to the last tag, where Backspace or
/// Delete takes it away and the arrows walk the tags; Escape closes the
/// list. Null [onChanged] draws it disabled. Read as a text field named
/// [label], each tag a button "Remove …" with a Remove action. The
/// behaviour is the design kit's DesignTagInput; Fluent 2 paints the
/// field, the tags and the list.
///
/// ```dart
/// Fluent2MultiSelect(label: 'Invite', options: people, selected: invited, onChanged: (v) => setState(() => invited = v))
/// ```
class Fluent2MultiSelect<T> extends StatefulWidget {
  /// A select of [options] that takes several, shown as tags.
  const Fluent2MultiSelect({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.label,
    this.hint,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2MultiSelectSize.medium,
    this.invalid = false,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// The options, in order.
  final List<Fluent2Option<T>> options;

  /// The chosen options' values, in the order chosen.
  final List<T> selected;

  /// Called with the values chosen after each change; null puts it out of use.
  final ValueChanged<List<T>>? onChanged;

  /// What a screen reader calls the field; null reads the surrounding form
  /// field's label.
  final String? label;

  /// The input's empty words; null is "Add people" in the app's language.
  final String? hint;

  /// Fluent's `appearance`: which of its faces it wears.
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2MultiSelectSize size;

  /// Whether it shows Fluent's invalid state, its edge in the danger colour.
  final bool invalid;

  /// The control's focus node; null makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether the control takes focus when it first builds.
  final bool autofocus;

  @override
  State<Fluent2MultiSelect<T>> createState() => _Fluent2MultiSelectState<T>();
}

class _Fluent2MultiSelectState<T> extends State<Fluent2MultiSelect<T>> {
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'tag picker'));
  final _text = TextEditingController();

  // Focus anywhere in the control, the input or a tag: the frame's
  // underline.
  bool _within = false;

  bool get _live => widget.onChanged != null;

  @override
  void dispose() {
    _ownFocus?.dispose();
    _text.dispose();
    super.dispose();
  }

  List<Fluent2Option<T>> get _chosen => [
    for (final v in widget.selected)
      widget.options.firstWhere(
        (o) => o.value == v,
        orElse: () => Fluent2Option<T>(v, '$v'),
      ),
  ];

  // The kit hands back the tags it now holds: keep a disabled option out.
  void _change(List<Fluent2Option<T>> next) {
    final change = widget.onChanged;
    if (change == null) return;
    final kept = [
      for (final o in next)
        if (o.enabled || widget.selected.contains(o.value)) o.value,
    ];
    if (listEquals(kept, widget.selected)) return;
    change(kept);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final scope = Fluent2FieldScope.maybeOf(context);
    final live = _live;
    final large = widget.size == Fluent2MultiSelectSize.large;
    final type = t.body1;
    final vertical = large ? Fluent2Spacing.s : Fluent2Spacing.sNudge;
    final gap = large ? Fluent2Spacing.sNudge : Fluent2Spacing.xs;
    final name = widget.label ?? scope?.label;
    final words = Fluent2Localizations.of(context);
    return DesignTagInput<Fluent2Option<T>>(
      values: _chosen,
      options: widget.options,
      onChanged: _change,
      displayStringForOption: (o) => o.label,
      controller: _text,
      focusNode: _focus,
      semanticLabel: name,
      deleteLabel: words.removeAction,
      fieldBuilder: (context, field) => Semantics(
        label: name,
        child: Fluent2FieldEditor(
          autofocus: widget.autofocus,
          controller: field.controller,
          focusNode: field.focusNode,
          enabled: live,
          onSubmitted: (_) {
            field.submit();
            field.focusNode.requestFocus();
          },
          style: type.c(
            live ? c.neutralForeground1 : c.neutralForegroundDisabled,
          ),
          hint: widget.selected.isEmpty
              ? (widget.hint ?? words.addPeople)
              : null,
          hintStyle: type.c(
            live
                ? fluent2PlaceholderInk(t, widget.appearance)
                : c.neutralForegroundDisabled,
          ),
        ),
      ),
      optionBuilder: (context, o, states) => Fluent2OptionFace(
        label: o.label,
        icon: o.icon,
        secondary: o.secondary,
        selected: false,
        highlighted: states.contains(WidgetState.focused),
        states: o.enabled ? states : {...states, WidgetState.disabled},
      ),
      surfaceBuilder: (context, list) => Padding(
        padding: const EdgeInsets.only(top: Fluent2Spacing.xs),
        child: Fluent2PopoverSurface(child: list),
      ),
      tagBuilder: (context, o, tag) => LayoutBuilder(
        builder: (context, box) => _Tag(
          label: o.label,
          removeLabel: words.remove(o.label),
          large: large,
          maxWidth: box.maxWidth,
          focused: tag.focused,
          onRemove: live ? tag.onDeleted : null,
        ),
      ),
      layoutBuilder: (context, tags, field) => Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: (inside) => setState(() => _within = inside),
        child: Fluent2HitSlop(
          child: Fluent2FieldFrame(
            appearance: widget.appearance,
            focused: _within,
            enabled: live,
            invalid: widget.invalid || (scope?.invalid ?? false),
            textNode: true,
            minHeight: large ? 40 : 32,
            cursor: SystemMouseCursors.text,
            padding: const EdgeInsetsDirectional.only(
              start: Fluent2Spacing.m,
              end: Fluent2Spacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final room = box.maxWidth;
                      // Fluent's TagPickerGroup: 6 (8 large) over and under its
                      // tags inside the stroke, so the field stands 34 (42)
                      // tall with a row of tags. The input stays the Wrap's
                      // last child, so it keeps its place (and its focus) as
                      // tags come and go.
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: tags.isEmpty ? 0 : vertical,
                        ),
                        child: Wrap(
                          spacing: gap,
                          runSpacing: gap,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ...tags,
                            SizedBox(
                              width: tags.isEmpty
                                  ? room
                                  : (room < 120 ? room : 120),
                              // Beside tags the words are their own node:
                              // under a finger as tall as the tags' 48
                              // targets, so the line grows no taller.
                              height: tags.isEmpty
                                  ? null
                                  : Fluent2Layout.padded(context)
                                  ? Fluent2Layout.touchHitTarget
                                  : (large ? 24 : 20),
                              child: field,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: Fluent2Spacing.xxs),
                // The pointer's way to the list: the field holds the keyboard
                // and speaks for it, so the chevron is no tab stop or node.
                ExcludeFocus(
                  child: ExcludeSemantics(
                    child: Fluent2Pressable(
                      semantics: false,
                      onPressed: live
                          ? () => _focus.hasFocus
                                ? _focus.unfocus()
                                : _focus.requestFocus()
                          : null,
                      child: Icon(
                        Fluent2Icons.chevronDown,
                        size: 20,
                        color: live
                            ? c.neutralStrokeAccessible
                            : c.neutralForegroundDisabled,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A chosen option: Fluent's filled Tag at extra-small (20 tall, 5 in,
/// caption1) or small (24, body1), the whole tag a button that takes it
/// away. The keyboard reaches it through the kit's arrows, not Tab, so the
/// press takes no focus of its own and the ring follows [focused].
class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.removeLabel,
    required this.large,
    required this.maxWidth,
    required this.focused,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final bool large;
  final double maxWidth;
  final bool focused;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final face = _face(context);
    if (!focused) return face;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        face,
        const Positioned.fill(
          child: IgnorePointer(
            child: Fluent2FocusRing(radius: Fluent2Radius.medium),
          ),
        ),
      ],
    );
  }

  Widget _face(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = onRemove != null;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ExcludeFocus(
        child: Fluent2Pressable(
          onPressed: onRemove,
          label: removeLabel,
          radius: Fluent2Radius.medium,
          ring: false,
          builder: (context, states) => Container(
            // Fluent's 24 (20), and taller with a large text size, so the
            // words are never sliced.
            constraints: BoxConstraints(minHeight: large ? 24 : 20),
            padding: const EdgeInsetsDirectional.only(start: 5),
            decoration: BoxDecoration(
              color: live ? fluent2Well(t) : fluent2WellDisabled(t),
              borderRadius: BorderRadius.circular(Fluent2Radius.medium),
              border: live
                  ? null
                  : Border.all(color: fluent2Step(t, c.neutralStrokeDisabled)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fluent's picker tags are its small (24) and extra-small
                // (20) Tags: caption1, the words 2 in from each side, their
                // capitals on the tag's middle (Fluent's 2 of room under
                // its line box, `primaryText`'s padding, aims at the same).
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Fluent2Spacing.xxs,
                    ),
                    child: fluent2CapCentred(
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption1.c(
                          live
                              ? c.neutralForeground2
                              : c.neutralForegroundDisabled,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 2, end: 5),
                  child: Icon(
                    large ? Fluent2Icons.dismiss16 : Fluent2Icons.dismiss12,
                    size: large ? 16 : 12,
                    color: !live
                        ? c.neutralForegroundDisabled
                        : states.press.pick(
                            c.neutralForeground2,
                            c.compoundBrandForeground1Hover,
                            c.compoundBrandForeground1Pressed,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
