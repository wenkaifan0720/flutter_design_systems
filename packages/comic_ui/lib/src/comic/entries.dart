/// Input controls built from Comic's captions, fields and pressable panels.
library;

import 'package:ui_core/ui_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'glyphs.dart';
import 'internal/field_icon.dart';
import 'internal/reach.dart';
import 'internal/track.dart';

import 'controls.dart';
import 'component_themes.dart';
import 'tell.dart';
import 'styled.dart';
import 'localizations.dart';
import 'press.dart';
import 'raised.dart';
import 'theme.dart';
import 'internal/cap_label.dart';

/// A multiline field, using Flutter's editor and Comic's selection menu.
///
/// ```dart
/// ComicTextArea(label: 'Notes', onChanged: save)
/// ```
class ComicTextArea extends StatelessWidget {
  /// Creates a multiline field.
  const ComicTextArea({
    super.key,
    this.style,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 4,
    this.minLines,
    this.focusNode,
    this.autofocus = false,
  });

  /// Field label, prompt and supporting messages.
  final String? label, hint, helper, error, initialValue;

  /// The caller's controller, if any.
  final TextEditingController? controller;

  /// Receives edits.
  final ValueChanged<String>? onChanged;

  /// Whether the field is editable.
  final bool enabled;

  /// The most lines the area shows before it scrolls.
  final int maxLines;

  /// The fewest lines it shows; null shows [maxLines] from the start.
  final int? minLines;

  /// The caller's focus node, if any.
  final FocusNode? focusNode;

  /// Whether the area asks for the focus when it first appears.
  final bool autofocus;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;
  @override
  Widget build(BuildContext context) => ComicTextField(
    style: style,
    label: label,
    hint: hint,
    helper: helper,
    error: error,
    controller: controller,
    initialValue: initialValue,
    onChanged: onChanged,
    enabled: enabled,
    maxLines: maxLines,
    minLines: minLines,
    focusNode: focusNode,
    autofocus: autofocus,
  );
}

/// A search field with a clear control and standard submit behavior.
///
/// ```dart
/// ComicSearchField(hint: 'Search issues', onChanged: search)
/// ```
class ComicSearchField extends StatefulWidget {
  /// Creates a search field.
  const ComicSearchField({
    super.key,
    this.style,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.clearLabel,
    this.name,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.onEditingComplete,
    this.decorate,
  });

  /// The search prompt.
  final String hint;

  /// The caller's controller; otherwise this widget owns one.
  final TextEditingController? controller;

  /// Receives every edit, including clearing.
  final ValueChanged<String>? onChanged;

  /// Receives keyboard submission.
  final ValueChanged<String>? onSubmitted;

  /// Overrides the localized clear action label.
  final String? clearLabel;

  /// Accessible name, independent from the placeholder.
  final String? name;

  /// Whether editing is available.
  final bool enabled;

  /// Caller-owned focus and initial focus request.
  final FocusNode? focusNode;

  /// Requests focus when the control first appears.
  final bool autofocus;

  /// Editor traversal and semantic decorator.
  final VoidCallback? onEditingComplete;

  /// Wraps the editable input with application-specific content.
  final Widget Function(Widget input)? decorate;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;
  @override
  State<ComicSearchField> createState() => _ComicSearchFieldState();
}

class _ComicSearchFieldState extends State<ComicSearchField> {
  final _focus = FocusNode();
  TextEditingController? _owned;
  TextEditingController get _controller =>
      widget.controller ?? (_owned ??= TextEditingController());
  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant ComicSearchField old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _owned)?.removeListener(_changed);
      _controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    _owned?.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ComicTextField(
    style: widget.style,
    controller: _controller,
    focusNode: widget.focusNode ?? _focus,
    label: widget.name,
    showLabel: false,
    nameOnly: true,
    enabled: widget.enabled,
    autofocus: widget.autofocus,
    onEditingComplete: widget.onEditingComplete,
    decorate: widget.decorate,
    hint: widget.hint,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    textInputAction: TextInputAction.search,
    leading: const Icon(ComicGlyphs.search),
    trailing: _controller.text.isEmpty
        ? null
        : ComicIconButton(
            ComicGlyphs.x,
            style: comicInFieldIcon,
            label:
                widget.clearLabel ??
                DesignLocalizations.of(context).clearButtonTooltip,
            onPressed: !widget.enabled
                ? null
                : () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    (widget.focusNode ?? _focus).requestFocus();
                  },
          ),
  );
}

/// One value and its readable name in a select.
@immutable
class ComicSelectOption<T> {
  /// Creates an option.
  const ComicSelectOption(this.value, this.label, {this.enabled = true});

  /// Its returned value.
  final T value;

  /// Its visible name.
  final String label;

  /// Whether it can be selected.
  final bool enabled;
}

/// A field that opens Comic's keyboard-accessible menu.
///
/// ```dart
/// ComicSelect<String>(label: 'Format', options: const [ComicSelectOption('print', 'Print')], value: 'print', onChanged: change)
/// ```
class ComicSelect<T> extends StatelessWidget {
  /// Creates a select, disabled when [onChanged] is absent.
  const ComicSelect({
    super.key,
    this.style,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.focusNode,
    this.autofocus = false,
  });

  /// Available values.
  final List<ComicSelectOption<T>> options;

  /// The selected value, or null for the prompt.
  final T? value;

  /// Receives a selection.
  final ValueChanged<T>? onChanged;

  /// Optional visible field label.
  final String? label;

  /// Overrides the localized empty prompt.
  final String? hint;

  /// Supporting text, replaced by [error] when present.
  final String? helper, error;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;

  /// The caller's focus node, if any; the part makes its own when null.
  final FocusNode? focusNode;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final matches = options.where((option) => option.value == value);
    final text = matches.isEmpty
        ? hint ?? ComicLocalizations.of(context).choose
        : matches.first.label;
    final t = ComicTheme.of(context);
    // From 600 up the field keeps to its own width (at most 320) at its column's start; its list matches the field.
    return comicDropdownWidth(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null) ...[
            Text(label!, style: t.type.title),
            const SizedBox(height: 6),
          ],
          ComicMenuAnchor<T>(
            matchAnchorWidth: true,
            items: [
              for (final option in options)
                ComicMenuItem(
                  option.value,
                  option.label,
                  selected: option.value == value,
                  enabled: option.enabled,
                ),
            ],
            onSelected: onChanged,
            builder: (context, open) => ComicSelectField(
              focusNode: focusNode,
              autofocus: autofocus,
              style: style,
              value: text,
              onPressed: onChanged == null ? null : open,
            ),
          ),
          if (error != null || helper != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: error != null,
              child: Text(error ?? helper!, style: t.type.small),
            ),
          ],
        ],
      ),
    );
  }
}

/// A labelled checkbox row with a full-width target.
///
/// ```dart
/// ComicCheckRow(label: 'Keep a copy', value: true, onChanged: change)
/// ```
class ComicCheckRow extends StatelessWidget {
  /// Creates a checkbox row.
  const ComicCheckRow({
    super.key,
    this.style,
    required this.label,
    required this.value,
    this.onChanged,
    this.focusNode,
    this.isError = false,
    this.note,
    this.autofocus = false,
  });

  /// Its visible and spoken label.
  final String label;

  /// An optional explanation.
  final String? note;

  /// Whether it is checked.
  final bool value;

  /// Caller-owned focus and invalid state.
  final FocusNode? focusNode;

  /// The validation error shown and announced by the field.
  final bool isError;

  /// Changes the value; absent means disabled.
  final ValueChanged<bool>? onChanged;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;

  /// Whether the part asks for the focus when it first appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) => ComicPressable(
    autofocus: autofocus,
    label: label,
    checked: value,
    hint: note,
    focusNode: focusNode,
    error: isError,
    button: false,
    onPressed: onChanged == null ? null : () => onChanged!(!value),
    overlay: ComicStyleOf([
      style,
      ComicTheme.of(context).checkboxTheme,
    ], const {}).overlay,
    builder: (context, states) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ExcludeFocus(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RowMark(
                  child: ComicCheckbox(
                    label: label,
                    isError: isError,
                    style: ComicStyleOf([
                      style,
                      ComicTheme.of(context).checkboxTheme,
                    ], states).freeze(),
                    value: value,
                    onChanged: onChanged == null ? null : (_) {},
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: ComicTheme.of(context).type.title),
                if (note != null)
                  Text(note!, style: ComicTheme.of(context).type.small),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// One radio choice and its optional explanation.
@immutable
class ComicRadio<T> {
  /// Creates an option for [ComicRadioGroup].
  const ComicRadio(this.value, this.label, {this.note, this.enabled = true});

  /// Its returned value.
  final T value;

  /// Its name and optional explanation.
  final String label;

  /// The explanation below the name.
  final String? note;

  /// Whether this option can be selected.
  final bool enabled;
}

/// A group of exclusive choices, drawn as small inked caption boxes.
///
/// ```dart
/// ComicRadioGroup<String>(label: 'Format', options: const [ComicRadio('print', 'Print'), ComicRadio('digital', 'Digital')], value: 'print', onChanged: change)
/// ```
class ComicRadioGroup<T> extends StatefulWidget {
  /// Creates an exclusive choice group.
  const ComicRadioGroup({
    super.key,
    this.style,
    required this.label,
    required this.options,
    this.value,
    this.onChanged,
  });

  /// The group's name.
  final String label;

  /// Options in reading order.
  final List<ComicRadio<T>> options;

  /// The current value.
  final T? value;

  /// Receives a choice; absent means disabled.
  final ValueChanged<T>? onChanged;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;
  @override
  State<ComicRadioGroup<T>> createState() => _ComicRadioGroupState<T>();
}

class _ComicRadioGroupState<T> extends State<ComicRadioGroup<T>> {
  final _nodes = <FocusNode>[];
  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    while (_nodes.length < widget.options.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.options.length) {
      _nodes.removeLast().dispose();
    }
    final selected = widget.options.indexWhere(
      (option) => option.enabled && option.value == widget.value,
    );
    final entry = selected >= 0
        ? selected
        : widget.options.indexWhere((option) => option.enabled);
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != entry;
    }
    final t = ComicTheme.of(context);
    return Semantics(
      label: widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(child: Text(widget.label, style: t.type.title)),
          for (var i = 0; i < widget.options.length; i++)
            // The row's side room stands outward, its wash round the ring, the ring on the column's edge.
            ComicOutward(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ComicPressable(
                focusNode: _nodes[i],
                label: widget.options[i].label,
                button: false,
                inGroup: true,
                checked: widget.options[i].value == widget.value,
                onPressed:
                    widget.onChanged == null || !widget.options[i].enabled
                    ? null
                    : () {
                        _nodes[i].requestFocus();
                        if (widget.options[i].value != widget.value) {
                          widget.onChanged!(widget.options[i].value);
                        }
                      },
                keys: (_, event) {
                  if (event is! KeyDownEvent || widget.onChanged == null) {
                    return KeyEventResult.ignored;
                  }
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  final key = event.logicalKey;
                  final back =
                      key == LogicalKeyboardKey.arrowUp ||
                      key ==
                          (rtl
                              ? LogicalKeyboardKey.arrowRight
                              : LogicalKeyboardKey.arrowLeft);
                  final forward =
                      key == LogicalKeyboardKey.arrowDown ||
                      key ==
                          (rtl
                              ? LogicalKeyboardKey.arrowLeft
                              : LogicalKeyboardKey.arrowRight);
                  if (!back && !forward) return KeyEventResult.ignored;
                  final enabled = [
                    for (var j = 0; j < widget.options.length; j++)
                      if (widget.options[j].enabled) j,
                  ];
                  if (enabled.isNotEmpty) {
                    final next =
                        enabled[(enabled.indexOf(i) + (back ? -1 : 1)) %
                            enabled.length];
                    _nodes[next].requestFocus();
                    widget.onChanged!(widget.options[next].value);
                  }
                  return KeyEventResult.handled;
                },
                overlay: ComicStyleOf([
                  widget.style,
                  t.radioTheme,
                ], const {}).overlay,
                builder: (context, states) {
                  final look = ComicStyleOf([
                    widget.style,
                    t.radioTheme,
                  ], states);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        // An empty ring on the ground; chosen, the same ring holds a dot in the ring's own ink, so
                        // the chosen one is the one with something in it, by day and by night.
                        AnimatedComicShape(
                          shape: look.shape ?? const CircleBorder(),
                          builder: (context, shape) {
                            final rim = comicRim(t, look, t.colors.nightLine);
                            final outline =
                                shape ?? const RoundedRectangleBorder();
                            return Container(
                              width: 24,
                              height: 24,
                              decoration: ShapeDecoration(
                                color: look.fill ?? const Color(0x00000000),
                                shape: outline.copyWith(side: rim),
                              ),
                              child: widget.options[i].value == widget.value
                                  ? Padding(
                                      // The dot is the ring moved in: concentric, 3 px of ground between them.
                                      padding: EdgeInsets.all(rim.width + 3),
                                      child: ComicStateDecoration(
                                        decoration: ShapeDecoration(
                                          color: look.foreground ?? rim.color,
                                          shape: comicInsetShape(
                                            outline,
                                            rim.width + 3,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.options[i].label,
                                style: t.type.body
                                    .merge(look.textStyle)
                                    .copyWith(color: look.foreground),
                              ),
                              if (widget.options[i].note != null)
                                Text(
                                  widget.options[i].note!,
                                  style: t.type.small,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A segment's value, label and optional glyph.
@immutable
class ComicButtonSegment<T> {
  /// Creates a segment.
  const ComicButtonSegment(this.value, this.label, {this.icon, this.name});

  /// Its returned value.
  final T value;

  /// Its visible name.
  final String label;

  /// Optional glyph.
  final IconData? icon;

  /// Accessible name when it differs from the visible label.
  final String? name;
}

/// Exclusive choices in one trough at a field's height: every segment one width, no dividers, the chosen one a thumb
/// (the trough's outline moved in by its rim and 4 px, concentric under every corner family) that slides to the next
/// choice. A segment's words never move when it is chosen; only their ink changes.
///
/// ```dart
/// ComicSegmentedButton<String>(label: 'View', segments: const [ComicButtonSegment('all', 'All'), ComicButtonSegment('saved', 'Saved')], value: 'all', onChanged: change)
/// ```
class ComicSegmentedButton<T> extends StatefulWidget {
  /// Creates a segmented choice.
  const ComicSegmentedButton({
    super.key,
    this.style,
    required this.label,
    required this.segments,
    this.value,
    this.onChanged,
    this.rowSegmentWidth = 104,
  });

  /// Its accessible group name.
  final String label;

  /// Options in reading order.
  final List<ComicButtonSegment<T>> segments;

  /// Current value.
  final T? value;

  /// Receives changes; absent means disabled.
  final ValueChanged<T>? onChanged;

  /// Width per segment in an unbounded row; the track's rim and inset come
  /// out of it.
  final double rowSegmentWidth;

  /// Per-state appearance above the component theme.
  final ComicStyle? style;
  @override
  State<ComicSegmentedButton<T>> createState() => _ComicSegmentedState<T>();
}

class _ComicSegmentedState<T> extends State<ComicSegmentedButton<T>> {
  final List<FocusNode> _nodes = [];
  void _sync() {
    while (_nodes.length < widget.segments.length) {
      _nodes.add(FocusNode());
    }
    while (_nodes.length > widget.segments.length) {
      _nodes.removeLast().dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ComicSegmentedButton<T> old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  KeyEventResult _keys(int index, KeyEvent event) {
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        widget.onChanged == null ||
        _nodes.isEmpty) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl,
        key = event.logicalKey;
    final next = key == LogicalKeyboardKey.home
        ? 0
        : key == LogicalKeyboardKey.end
        ? _nodes.length - 1
        : key == LogicalKeyboardKey.arrowRight
        ? (index + (rtl ? -1 : 1)) % _nodes.length
        : key == LogicalKeyboardKey.arrowLeft
        ? (index + (rtl ? 1 : -1)) % _nodes.length
        : null;
    if (next == null) return KeyEventResult.ignored;
    _nodes[next].requestFocus();
    if (widget.segments[next].value != widget.value) {
      widget.onChanged!(widget.segments[next].value);
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.segments.indexWhere(
      (segment) => segment.value == widget.value,
    );
    for (var i = 0; i < _nodes.length; i++) {
      _nodes[i].skipTraversal = i != (selected < 0 ? 0 : selected);
    }
    final t = ComicTheme.of(context), c = t.colors;
    final layers = [widget.style, t.segmentedButtonTheme];
    final track = ComicStyleOf(layers, const {});
    final rim = comicRim(t, track, c.nightLine);
    // One trough at a field's height and rim, the segments side by side in it with no dividers, one width each; the
    // chosen one is a thumb, the trough's own outline moved in by its rim and 4 px, and it slides.
    final outer = track.shape ?? t.shapes.capsule;
    final inner = ComicTrack.cellShape(outer, rim);
    final lit = ComicStyleOf(layers, const {WidgetState.selected});
    return Semantics(
      label: widget.label,
      container: true,
      explicitChildNodes: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: ComicTrack(
          shape: outer,
          rim: rim,
          fill: track.fill ?? (c.dark ? c.card : c.control),
          thumb: lit.fill ?? c.caption,
          lit: selected < 0 ? null : selected,
          cellWidth: widget.rowSegmentWidth,
          cells: [
            for (var i = 0; i < widget.segments.length; i++)
              _segment(context, t, layers, inner, i),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    ComicThemeData t,
    List<ComicStyle?> layers,
    OutlinedBorder inner,
    int i,
  ) {
    final c = t.colors;
    final segment = widget.segments[i];
    final chosen = segment.value == widget.value;
    return ComicPressable(
      label: segment.name ?? segment.label,
      selected: chosen,
      focusNode: _nodes[i],
      keys: (_, event) => _keys(i, event),
      wash: false,
      ring: false,
      sink: false,
      onPressed: widget.onChanged == null
          ? null
          : () {
              _nodes[i].requestFocus();
              if (segment.value != widget.value) {
                widget.onChanged!(segment.value);
              }
            },
      builder: (context, states) {
        final look = ComicStyleOf(layers, states);
        final ink =
            look.foreground ??
            (chosen
                ? c.onCaption
                : c.dark
                ? c.text
                : c.onPaper);
        return ComicTrackFace(
          states: states,
          shape: inner,
          overlay: look.overlay?.resolve(states),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (segment.icon != null) ...[
                Icon(segment.icon, size: look.iconSize ?? 18, color: ink),
                const SizedBox(width: 6),
              ],
              CapLabel(
                child: Text(
                  segment.label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: t.type.title
                      .merge(look.textStyle)
                      .copyWith(color: ink),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A file in a [ComicFileUpload]'s list: its name, its size in words, how far it has gone up, and what went wrong.
@immutable
class ComicDroppedFile {
  /// Creates a file row.
  const ComicDroppedFile(this.name, {this.size, this.progress, this.error});

  /// The file's name.
  final String name;

  /// Its size, already in words: '2.4 MB'.
  final String? size;

  /// Upload progress from 0 to 1; null when done or not started.
  final double? progress;

  /// Why it failed; null when it didn't.
  final String? error;
}

/// Where files come in: a well that invites a drop, a button that opens the caller's picker, and the files chosen so
/// far, each with its progress, its error and a way to take it off. The package reads no file system: [onChoose] opens
/// the app's own picker, and [onDrop] takes whatever an in-app drag lets go over the well (a desktop or web app wires
/// its platform's drop to it).
///
/// ```dart
/// ComicFileUpload(label: 'Cover art', files: files, onChoose: pick, onRemove: remove)
/// ```
class ComicFileUpload extends StatefulWidget {
  /// Creates a file drop.
  const ComicFileUpload({
    super.key,
    required this.label,
    this.hint,
    this.files = const [],
    this.onChoose,
    this.onDrop,
    this.onRemove,
    this.error,
  });

  /// What the files are for.
  final String label;

  /// What's accepted: 'PNG or JPG, up to 10 MB'.
  final String? hint;

  /// The files chosen so far.
  final List<ComicDroppedFile> files;

  /// Opens the app's picker; null disables the well.
  final VoidCallback? onChoose;

  /// Takes what an in-app drag drops on the well.
  final ValueChanged<Object>? onDrop;

  /// Takes a file off the list, by its position.
  final ValueChanged<int>? onRemove;

  /// What's wrong with the whole drop.
  final String? error;

  @override
  State<ComicFileUpload> createState() => _ComicFileDropState();
}

class _ComicFileDropState extends State<ComicFileUpload> {
  bool _over = false;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final words = ComicLocalizations.of(context);
    final rim = BorderSide(
      color: widget.error != null || comicFieldInError(context)
          ? c.tones.danger
          : c.nightLine,
      width: t.rim(2.5),
    );
    final corner = comicCornerInset(t.shapes.small, Directionality.of(context));
    final well = DragTarget<Object>(
      onWillAcceptWithDetails: (_) {
        if (widget.onDrop == null) return false;
        setState(() => _over = true);
        return true;
      },
      onLeave: (_) => setState(() => _over = false),
      onAcceptWithDetails: (details) {
        setState(() => _over = false);
        widget.onDrop?.call(details.data);
      },
      builder: (context, _, _) => DecoratedBox(
        decoration: ShapeDecoration(
          color: _over ? c.currentUserTint : c.inset,
          shape: t.shapes.medium.copyWith(side: rim),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(ComicGlyphs.upload, size: 28, color: c.text),
              ),
              const SizedBox(height: 8),
              Text(
                words.dropFiles,
                textAlign: TextAlign.center,
                style: t.type.title,
              ),
              if (widget.hint != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.hint!,
                  textAlign: TextAlign.center,
                  style: t.type.small,
                ),
              ],
              const SizedBox(height: 12),
              ComicButton(words.chooseFiles, onPressed: widget.onChoose),
            ],
          ),
        ),
      ),
    );
    return Semantics(
      label: widget.label,
      container: true,
      explicitChildNodes: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The field label's face, as a text field's and a select's: the
          // look's small capitals are a section's, not a field's.
          ExcludeSemantics(child: Text(widget.label, style: t.type.title)),
          const SizedBox(height: 6),
          well,
          if (widget.error != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                widget.error!,
                style: t.type.small.copyWith(color: c.tones.danger),
              ),
            ),
          ],
          for (final (i, file) in widget.files.indexed) ...[
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: ShapeDecoration(
                color: c.card,
                shape: t.shapes.small.copyWith(
                  // An inked contour, as every box on the page has (a hairline read as a web page's).
                  side: BorderSide(
                    color: file.error != null ? c.tones.danger : c.nightLine,
                    width: t.rim(2),
                  ),
                ),
              ),
              child: Padding(
                // The row's corner takes its bite out of the leading padding.
                padding: EdgeInsetsDirectional.fromSTEB(
                  12 + corner,
                  6 + corner,
                  4,
                  6 + corner,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.type.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (file.error != null)
                            Text(
                              file.error!,
                              style: t.type.small.copyWith(
                                color: c.tones.danger,
                              ),
                            )
                          else if (file.size != null)
                            Text(file.size!, style: t.type.small),
                          if (file.progress != null) ...[
                            const SizedBox(height: 4),
                            ComicLinearProgressIndicator(
                              value: file.progress,
                              label: file.name,
                              height: 8,
                            ),
                          ],
                        ],
                      ),
                    ),
                    // The remove stands bare in the row's frame, clear of the progress bar beside it.
                    if (widget.onRemove != null) ...[
                      const SizedBox(width: 8),
                      ComicIconButton(
                        ComicGlyphs.x,
                        style: comicInFieldIcon,
                        label: words.removeFile(file.name),
                        onPressed: () => widget.onRemove!(i),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
