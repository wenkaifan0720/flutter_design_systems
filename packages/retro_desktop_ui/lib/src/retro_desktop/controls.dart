// Controls, each drawn on the device's grid from the concept's `.btn`, `.field`, `.chk`, `.chip`, `.prog`, `.tab` and `.group`.
// Jersey chrome and reading text sit in square or pixel-bevelled faces.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/ui_core.dart';

import 'acts.dart' show RetroDesktopButtonSize;
import 'press.dart';
import 'editing.dart';
import 'behavior.dart';
import 'localizations.dart';
import 'component_themes.dart';
import 'internal/face.dart';
import 'shapes.dart';

import 'glyphs.dart';

import 'chrome_metrics.dart';
import 'layout.dart';
import 'pixels.dart';
import 'theme.dart';
import 'internal/caps.dart';

/// A button with one icon, or a [triangle], in the family's control shape, and a [label] for a screen reader.
///
/// ```dart
/// RetroDesktopIconButton(RetroDesktopGlyphs.tag, label: 'Tag', onPressed: () {})
/// ```
class RetroDesktopIconButton extends StatelessWidget {
  /// Creates a [RetroDesktopIconButton].
  const RetroDesktopIconButton(
    this.icon, {
    super.key,
    required this.label,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.selected,
    this.badgeLabel,
    this.style,
    this.size = RetroDesktopButtonSize.medium,
  }) : triangle = null;

  /// The direction of the triangular glyph.
  const RetroDesktopIconButton.triangle(
    AxisDirection this.triangle, {
    super.key,
    required this.label,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
    this.selected,
    this.badgeLabel,
    this.style,
    this.size = RetroDesktopButtonSize.small,
  }) : icon = null;

  /// The glyph shown with the content.
  final IconData? icon;

  /// The direction of the triangular glyph.
  final AxisDirection? triangle;

  /// The visible or accessible name of this part.
  final String label;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  /// Whether the part represents the current selection.
  final bool? selected;

  /// An optional count or status announced with the action.
  final String? badgeLabel;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return retroDesktopOwnSize(
      child: RetroDesktopPressable(
        onPressed: onPressed,
        label: label,
        value: badgeLabel,
        selected: selected,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, states) => retroDesktopFace(
          states: states,
          scale: RetroDesktopFaceScale.button,
          // Beside a button it shows a button's height, square.
          component: size == RetroDesktopButtonSize.small
              ? t.iconButtonTheme
              : t.iconButtonTheme.merge(
                  RetroDesktopStyle(
                    minimumSize: WidgetStatePropertyAll(
                      Size.square(retroDesktopButtonFaceHeight(context)),
                    ),
                  ),
                ),
          style: style,
          padding: EdgeInsets.all(size == RetroDesktopButtonSize.small ? 4 : 6),
          child: triangle == null
              ? Icon(icon)
              : RetroDesktopTriangleMark(triangle!, size: 10),
        ),
      ),
    );
  }
}

/// The concept's small triangle: a tree's disclosure, a popup's arrows, a scroll bar's.
///
/// ```dart
/// RetroDesktopTriangleMark(AxisDirection.right)
/// ```
class RetroDesktopTriangleMark extends StatelessWidget {
  /// Creates a [RetroDesktopTriangleMark].
  const RetroDesktopTriangleMark(this.direction, {super.key, this.size = 12});

  /// The direction in which the triangular mark points.
  final AxisDirection direction;

  /// The size of the visible face; minimum interactive reach is retained.
  final double size;
  @override
  Widget build(BuildContext context) {
    final c = RetroDesktopTheme.of(context).colors;
    // On the middle of whatever room it is given, as an icon's glyph is: a
    // face's least size handed it a square larger than the mark, and the mark
    // stood in its top corner (the way back's ◂).
    return retroDesktopOwnSize(
      width: size,
      height: size,
      alignment: Alignment.center,
      child: RetroDesktopPixelPaint(painter: _TrianglePainter(c, direction)),
    );
  }
}

class _TrianglePainter extends RetroDesktopPixelPainter {
  const _TrianglePainter(this.c, this.direction);
  final RetroDesktopColors c;
  final AxisDirection direction;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    // One solid shape in the words' ink, as the period's menu and popup triangles were: a grey fill in a dark rim
    // read at 8 px as a smudge (the split button's arrow). At night a dark rim would sink into the dark face and
    // leave a speck: the mark is one light shape, whole, in the words' own ink
    // by night too (the secondary grey read as unavailable, the state law).
    final ink = c.text;
    retroDesktopPaintTriangle(px.canvas, s, direction, ink, ink);
  }

  @override
  bool shouldRepaint(_TrianglePainter o) =>
      o.c != c || o.direction != direction;
}

/// A popup button: it shows what is chosen, and its arrows (Platinum's up and down pair, Chisel's one down arrow) say
/// there are others. Press it to open your own list.
///
/// ```dart
/// RetroDesktopPopupButton('Workshop', icon: RetroDesktopGlyphs.notebook, onPressed: () {})
/// ```
class RetroDesktopPopupButton extends StatelessWidget {
  /// Creates a [RetroDesktopPopupButton].
  const RetroDesktopPopupButton(
    this.value, {
    super.key,
    this.icon,
    this.onPressed,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The current value to display or edit.
  final String value;

  /// The glyph shown with the content.
  final IconData? icon;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The focus node this part uses; when null it makes and disposes its own.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return retroDesktopOwnSize(
      child: RetroDesktopPressable(
        focusNode: focusNode,
        autofocus: autofocus,
        onPressed: onPressed,
        label: value,
        builder: (context, states) => retroDesktopFace(
          states: states,
          style: style,
          scale: RetroDesktopFaceScale.button,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: states.contains(WidgetState.pressed)
                ? [t.colors.platinum, t.colors.platinumDark]
                : [t.colors.platinumLight, t.colors.platinum],
          ),
          component: t.buttonTheme.merge(
            RetroDesktopStyle(
              textStyle: WidgetStatePropertyAll(t.type.chrome),
              // A button's height: beside one it shows the same top and bottom.
              minimumSize: WidgetStatePropertyAll(
                Size(0, retroDesktopButtonFaceHeight(context)),
              ),
            ),
          ),
          // Its words start where a field's do: one inset in a column of both.
          // As much under them as over them: on a button's height they stand
          // on its middle (a pixel more under stood them half a pixel high).
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 9, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon), const SizedBox(width: 6)],
              Flexible(child: RetroDesktopCaps(Text(value))),
              const SizedBox(width: 8),
              // The PC's menu button drops down; the Mac's popup opens both
              // ways, so it points both ways.
              if (t.chisel)
                const RetroDesktopTriangleMark(AxisDirection.down, size: 8)
              else
                const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RetroDesktopTriangleMark(AxisDirection.up, size: 8),
                    RetroDesktopTriangleMark(AxisDirection.down, size: 8),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text box: white, sunk into the machine, a 1 lp dark line along its top and left. [leading] stands at its start (an
/// `Icon` takes the field's icon size and ink),
/// [trailing] a `RetroDesktopKbd` or a small button, [lines] above 1 a box for a note.
///
/// ```dart
/// RetroDesktopTextField(hint: 'Search 40 notes', leading: const Icon(RetroDesktopGlyphs.search), trailing: const RetroDesktopKbd('/'))
/// ```
class RetroDesktopTextField extends StatefulWidget {
  /// Creates a [RetroDesktopTextField].
  const RetroDesktopTextField({
    super.key,
    this.controller,
    this.initial,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.leading,
    this.trailing,
    this.lines = 1,
    this.keyboardType,
    this.label,
    this.helper,
    this.error,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.password = false,
    this.revealLabels,
    this.onEditingComplete,
    this.decorate,
    this.failureLine,
    this.nameOnly = false,
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// An optional externally owned controller; the caller disposes it.
  final TextEditingController? controller;

  /// The initial value used when no external controller supplies one.
  final String? initial;

  /// Placeholder text shown while the input has no value.
  final String? hint;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the entered text.
  final ValueChanged<String>? onSubmitted;

  /// A widget at the box's start, usually an `Icon`, which takes the field's
  /// icon size and ink.
  final Widget? leading;

  /// Optional content after the main content in reading order.
  final Widget? trailing;

  /// The number of visible text or placeholder lines.
  final int lines;

  /// The platform keyboard requested for this input.
  final TextInputType? keyboardType;

  /// Static words above and below the editor; labels never float.
  final String? label, helper, error;

  /// Whether the editor accepts input.
  final bool enabled;

  /// Optional externally owned editor focus.
  final FocusNode? focusNode;

  /// Requests focus when mounted.
  final bool autofocus;

  /// The platform keyboard's action.
  final TextInputAction? textInputAction;

  /// Autofill hints for the platform.
  final Iterable<String>? autofillHints;

  /// Transformations applied to user edits.
  final List<TextInputFormatter>? inputFormatters;

  /// Obscures a single-line password.
  final bool obscureText, password;

  /// Accessible names for showing and hiding a password, in that order.
  /// Null uses the installed localizations.
  final (String, String)? revealLabels;

  /// Completes platform editing before the submit callback.
  final VoidCallback? onEditingComplete;

  /// Wraps only the editable, leaving trailing actions as separate controls.
  final Widget Function(Widget editable)? decorate;

  /// Wraps the drawn error when the caller owns its announcement.
  final Widget Function(Widget error)? failureLine;

  /// Draws the label while leaving its accessible name to [decorate].
  final bool nameOnly;
  @override
  State<RetroDesktopTextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<RetroDesktopTextField> {
  bool _hidden = true;
  bool _hovered = false;
  FocusNode? _ownFocus;
  @override
  void dispose() {
    _ownFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final initial = widget.initial;
    final hint = widget.hint;
    final onChanged = widget.onChanged;
    final onSubmitted = widget.onSubmitted;
    final leading = widget.leading;
    final lines = widget.lines;
    final keyboardType = widget.keyboardType;
    final label = widget.label;
    final helper = widget.helper;
    final error = widget.error;
    final enabled = widget.enabled;
    final focusNode = widget.focusNode ?? (_ownFocus ??= FocusNode());
    final autofocus = widget.autofocus;
    final textInputAction = widget.textInputAction;
    final autofillHints = widget.autofillHints;
    final inputFormatters = widget.inputFormatters;
    final onEditingComplete = widget.onEditingComplete;
    final decorate = widget.decorate;
    final failureLine = widget.failureLine;
    final nameOnly = widget.nameOnly;
    final obscureText = widget.obscureText || (widget.password && _hidden);
    final trailing = widget.password
        ? retroDesktopFieldButton(
            context,
            icon: _hidden ? RetroDesktopGlyphs.eye : RetroDesktopGlyphs.eyeOff,
            label: _hidden
                ? widget.revealLabels?.$1 ??
                      DesignLocalizations.of(context).showPasswordLabel
                : widget.revealLabels?.$2 ??
                      DesignLocalizations.of(context).hidePasswordLabel,
            onPressed: enabled
                ? () {
                    setState(() => _hidden = !_hidden);
                    focusNode.requestFocus();
                  }
                : null,
          )
        : widget.trailing;
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (focusNode.hasFocus) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
      if (error != null) WidgetState.error,
    };
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([widget.style, t.textFieldTheme], get, states);
    final ink = slot((s) => s.foreground) ?? c.text;
    // What a person types is set as the words around it are: the label above and a popup's choice beside it.
    final style = t.type.body
        .merge(slot((s) => s.textStyle))
        .copyWith(color: ink);
    // Under a finger the box is the whole reach. Under a pointer a one-line box is drawn as tall as a popup or a
    // button, its line and 6 above and below, and the reach stands around it: a press there lands in the field. What
    // stands at its end (a password's eye, a search's clear, a key cap) fits in that line: a glyph that presses has
    // its reach only pressed, inside the box.
    final lineHeight =
        MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) *
        (style.height ?? 1.3);
    final drawn = lineHeight * lines + (lines > 1 ? 16 : 12);
    final least = RetroDesktopReach.least(context);
    final reaches = lines == 1 && least < RetroDesktopChromeMetrics.touchTarget;
    final tall = reaches ? drawn : math.max(drawn, least);
    final pad = lines > 1 ? 9.0 : (tall - lineHeight) / 2;
    Widget input = Material(
      type: MaterialType.transparency,
      child: Theme(
        data: Theme.of(context).copyWith(visualDensity: VisualDensity.standard),
        child: TextFormField(
          selectionControls: RetroDesktopTextSelectionControls.of(
            Theme.of(context).platform,
          ),
          contextMenuBuilder: RetroDesktopTextContextMenu.editable,
          magnifierConfiguration: RetroDesktopTextSelectionControls.magnifier(
            context,
          ),
          enabled: enabled,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          autocorrect: !widget.password,
          enableSuggestions: !widget.password,
          controller: controller,
          initialValue: controller == null ? initial : null,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onEditingComplete: onEditingComplete,
          style: style,
          keyboardType: keyboardType,
          minLines: lines,
          maxLines: lines,
          cursorColor: ink,
          cursorWidth: t.strokes.regular == 0 ? 1 : t.strokes.regular,
          cursorRadius: Radius.zero,
          cursorOpacityAnimates: false,
          textAlignVertical: lines > 1
              ? TextAlignVertical.top
              : TextAlignVertical.center,
          decoration: InputDecoration(
            // RenderEditable rounds line metrics; keep the whole editor's
            // target minimum even when smaller type rounds a fraction down.
            constraints: BoxConstraints(minHeight: tall),
            isCollapsed: true,
            border: InputBorder.none,
            hintText: label == null && !nameOnly && decorate == null
                ? hint
                : null,
            hint:
                hint != null && (label != null || nameOnly || decorate != null)
                ? ExcludeSemantics(
                    child: Text(
                      hint,
                      style: style.copyWith(color: c.textTertiary),
                      maxLines: lines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : null,
            hintStyle: style.copyWith(color: c.textTertiary),
            hintMaxLines: lines,
            contentPadding: EdgeInsets.symmetric(vertical: pad),
          ),
        ),
      ),
    );
    // One line: its capitals on the box's middle, typed or hinted, the caret
    // and taps with them (ui_core's cap centring), as a button's beside it.
    if (lines == 1) input = RetroDesktopCaps(style: style, input);
    // A focused field keeps its paper: focus is the caret and the appearance's
    // own mark (Platinum's ring outside, Chisel's dotted rectangle inside).
    if (decorate != null) {
      input = decorate(input);
    } else if (label != null && !nameOnly) {
      input = Semantics(
        label: label,
        hint: error ?? helper ?? hint,
        child: input,
      );
    }
    // Its node, named, is the unmoved box's: the face clips its content, and
    // a node moved a fraction of a pixel would lose that fraction of its reach.
    if (lines == 1) input = MergeSemantics(child: input);
    Widget? message;
    if (error != null || helper != null) {
      final drawn = retroDesktopFieldNote(
        t,
        error ?? helper!,
        error: error != null,
      );
      message = error != null
          ? failureLine?.call(drawn) ??
                Semantics(liveRegion: true, child: drawn)
          : ExcludeSemantics(child: drawn);
    }
    final edge = EdgeInsets.only(top: lines > 1 ? 9 : 0);
    Widget editorRow({bool showTrailing = true}) => Row(
      crossAxisAlignment: lines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[
          Padding(
            padding: edge,
            child: IconTheme.merge(
              data: IconThemeData(
                size: slot((s) => s.iconSize) ?? 15,
                color: ink,
              ),
              child: leading,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: input),
        if (showTrailing && trailing != null) ...[
          const SizedBox(width: 8),
          Padding(padding: edge, child: trailing),
        ],
      ],
    );
    final field = retroDesktopFace(
      states: states,
      component: t.textFieldTheme.merge(
        RetroDesktopStyle(fill: WidgetStatePropertyAll(c.paper)),
      ),
      style: widget.style,
      sunken: true,
      padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 6, 0),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: tall),
        child: LayoutBuilder(
          builder: (context, room) => trailing != null && room.maxWidth < 180
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    editorRow(showTrailing: false),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: trailing,
                      ),
                    ),
                  ],
                )
              : editorRow(),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ExcludeSemantics(child: Text(label, style: t.type.body)),
          ),
        MouseRegion(
          // The hovered state reaches the component theme; by default it draws
          // nothing. The pointer is the text cursor over the whole box.
          cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Focus(
            onFocusChange: (_) => setState(() {}),
            canRequestFocus: false,
            skipTraversal: true,
            includeSemantics: false,
            child: Builder(
              builder: (context) {
                final focused = Focus.of(context).hasFocus;
                // The ring stands outside the field's own outline, concentric.
                final ringed = RetroDesktopHighlight(
                  shape: slot((s) => s.shape) ?? t.shapes.small,
                  focused: focused,
                  child: Opacity(opacity: enabled ? 1 : .5, child: field),
                );
                return reaches ? RetroDesktopReach(child: ringed) : ringed;
              },
            ),
          ),
        ),
        if (message != null)
          Padding(padding: const EdgeInsets.only(top: 6), child: message),
      ],
    );
  }
}

/// A keyboard shortcut cap. Its rim and type share the badge component theme.
///
/// ```dart
/// RetroDesktopKbd('Ctrl+S')
/// ```
class RetroDesktopKbd extends StatelessWidget {
  /// Creates a [RetroDesktopKbd].
  const RetroDesktopKbd(this.keys, {super.key, this.style});

  /// The keyboard shortcuts displayed by this part.
  final String keys;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return retroDesktopOwnSize(
      child: retroDesktopFace(
        states: const {},
        style: style,
        scale: RetroDesktopFaceScale.mark,
        component: t.badgeTheme.merge(
          RetroDesktopStyle(
            fill: WidgetStatePropertyAll(t.colors.platinumLight),
            foreground: WidgetStatePropertyAll(t.colors.textSecondary),
            textStyle: WidgetStatePropertyAll(
              t.type.mono(12, 16, weight: FontWeight.w600),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(keys),
      ),
    );
  }
}

/// A checkbox's face alone, live and at rest: for a row that takes the press and carries the box's meaning itself.
/// Internal: hidden from the package's exports.
Widget retroDesktopCheckFace(BuildContext context, bool? value) =>
    _checkFace(context, value, const {}, null);

Widget _checkFace(
  BuildContext context,
  bool? value,
  Set<WidgetState> states,
  RetroDesktopStyle? style,
) {
  final t = RetroDesktopTheme.of(context);
  final ink =
      RetroDesktopStyle.first(
        [style, t.checkboxTheme],
        (s) => s.foreground,
        states,
      ) ??
      t.colors.text;
  // Chisel: a sunken white box, greyed while the pointer holds it. Platinum: a
  // raised, bevelled grey box whose bevel turns over while held. An error rings
  // the box in the look's error ink, as a default button is ringed (the look
  // has no red), outside the face so nothing beside it moves.
  return retroDesktopFace(
    states: states,
    style: style,
    sunken: t.chisel,
    defaultRing: states.contains(WidgetState.error),
    component: t.checkboxTheme.merge(
      RetroDesktopStyle(
        fill: WidgetStatePropertyAll(
          !t.chisel
              ? t.colors.platinumLight
              : states.contains(WidgetState.pressed)
              ? retroDesktopChiselHeldBox(t.colors)
              : t.colors.controlFace,
        ),
      ),
    ),
    padding: EdgeInsets.zero,
    child: SizedBox.square(
      dimension: 14,
      child: CustomPaint(
        painter: _CheckMarkPainter(ink, value, t.strokes.heavy),
      ),
    ),
  );
}

class _CheckMarkPainter extends CustomPainter {
  const _CheckMarkPainter(this.ink, this.value, this.width);
  final Color ink;
  final bool? value;
  final double width;
  @override
  void paint(Canvas canvas, Size size) {
    if (value == false) return;
    if (value == null) {
      canvas.drawRect(
        Rect.fromCenter(
          center: size.center(Offset.zero),
          width: size.width * .65,
          height: width,
        ),
        Paint()..color = ink,
      );
      return;
    }
    final path = Path()
      ..moveTo(size.width * .15, size.height * .5)
      ..lineTo(size.width * .4, size.height * .8)
      ..lineTo(size.width * .9, size.height * .15);
    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_CheckMarkPainter old) =>
      ink != old.ink || value != old.value || width != old.width;
}

/// A tri-state checkbox: false is empty, true is checked and null is mixed.
/// Activation cycles false, true, null, then false; [RetroDesktopCheckRow] is the binary labelled-row form.
///
/// ```dart
/// RetroDesktopCheckbox(value: done, onChanged: (v) => setState(() => done = v), label: 'Option')
/// ```
class RetroDesktopCheckbox extends StatelessWidget {
  /// Creates a [RetroDesktopCheckbox].
  const RetroDesktopCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    required this.label,
    this.isError = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// False is unchecked, true is checked and null draws the mixed mark.
  final bool? value;

  /// Whether the box shows the error state, for a value that needs attention.
  final bool isError;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<bool?>? onChanged;

  /// The visible or accessible name of this part.
  final String label;
  @override
  Widget build(BuildContext context) {
    return retroDesktopOwnSize(
      child: RetroDesktopPressable(
        checked: value ?? false,
        mixed: value == null,
        error: isError,
        focusNode: focusNode,
        autofocus: autofocus,
        label: label,
        button: false,
        onPressed: onChanged == null
            ? null
            : () => onChanged!(
                value == false
                    ? true
                    : value == true
                    ? null
                    : false,
              ),
        builder: (context, states) => _checkFace(context, value, states, style),
      ),
    );
  }
}

/// A setting: a checkbox and its words. The whole row presses, and the words never crush.
///
/// ```dart
/// RetroDesktopCheckRow(label: 'Sync on start', note: 'Over any network', value: on, onChanged: (v) => setState(() => on = v))
/// ```
class RetroDesktopCheckRow extends StatelessWidget {
  /// Creates a [RetroDesktopCheckRow].
  const RetroDesktopCheckRow({
    super.key,
    required this.label,
    this.note,
    required this.value,
    this.onChanged,
    this.error = false,
    this.errorText,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The visible or accessible name of this part.
  final String label;

  /// Supporting text shown with the main content.
  final String? note;

  /// Whether the box is checked.
  final bool value;

  /// Whether the row shows the error state, for a value that needs attention.
  final bool error;

  /// The words under the label when the setting needs attention, after the
  /// warning sign as a field's are; giving them sets [error].
  final String? errorText;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopPressable(
      onPressed: onChanged == null ? null : () => onChanged!(!value),
      label: label,
      checked: value,
      button: false,
      error: error || errorText != null,
      hint: errorText ?? note,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) {
        final words = t.type.body
            .merge(
              RetroDesktopStyle.first(
                [style, t.checkboxTheme],
                (s) => s.textStyle,
                states,
              ),
            )
            .copyWith(
              color: RetroDesktopStyle.first(
                [style, t.checkboxTheme],
                (s) => s.foreground,
                states,
              ),
            );
        return Padding(
          padding: t.density.apply(
            const EdgeInsets.symmetric(vertical: 6),
            Directionality.of(context),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // On the label's first line at any text size (a fixed 3 from the top stood above the words at twice the
              // size).
              RetroDesktopOnCaps(
                style: words,
                child: ExcludeSemantics(
                  child: _checkFace(context, value, states, style),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: words),
                    if (note != null) Text(note!, style: t.type.meta),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: ExcludeSemantics(
                          child: retroDesktopFieldNote(
                            t,
                            errorText!,
                            error: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A short chip: a tag, a filter, a due date. As wide as its word. [leading] stands right before the words on their line
/// (a tag's `#`), [RetroDesktopChip.outlined] is the outlined one that adds, [selected] takes the highlight.
///
/// ```dart
/// RetroDesktopChip('walnut', leading: const Text('#'), onPressed: () {})
/// ```
class RetroDesktopChip extends StatelessWidget {
  /// Creates a chip with a raised face.
  const RetroDesktopChip(
    this.label, {
    super.key,
    this.onPressed,
    this.selected = false,
    this.leading,
    this.icon,
    this.size = RetroDesktopButtonSize.medium,
    this.enabled = true,
    this.filter = false,
    this.onDeleted,
    this.deleteLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : _outlined = false;

  /// Creates the chip that adds: no face, a plain outline.
  const RetroDesktopChip.outlined(
    this.label, {
    super.key,
    this.onPressed,
    this.selected = false,
    this.leading,
    this.icon,
    this.size = RetroDesktopButtonSize.medium,
    this.enabled = true,
    this.filter = false,
    this.onDeleted,
    this.deleteLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : _outlined = true;

  /// Whether the part accepts user interaction.
  final bool enabled;

  /// Whether the chip represents a filter choice.
  final bool filter;

  /// Called when the chip's remove action is activated.
  final VoidCallback? onDeleted;

  /// Overrides the accessible name of the remove action.
  final String? deleteLabel;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The visible or accessible name of this part.
  final String label;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// Whether the part represents the current selection.
  final bool selected;

  /// Stands right before the words, on their line: a tag's `#`. A [Text] takes the words' style and cap line.
  final Widget? leading;

  /// The size of the visible face; minimum interactive reach is retained.
  final RetroDesktopButtonSize size;

  final bool _outlined;

  /// The glyph shown with the content.
  final IconData? icon;
  // As wide as its words, in any column: a stretched button is a bar.
  @override
  Widget build(BuildContext context) => retroDesktopOwnSize(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _draw(context)),
        if (onDeleted != null)
          RetroDesktopIconButton(
            RetroDesktopGlyphs.x,
            label:
                deleteLabel ??
                DesignLocalizations.of(context).deleteButtonTooltip,
            onPressed: enabled ? onDeleted : null,
          ),
      ],
    ),
  );

  Widget _draw(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final small = size == RetroDesktopButtonSize.small;
    // A chip is a small button in the appearance's outline; Chisel sinks a
    // chosen one, as a toggled button on the PC.
    Widget face(Set<WidgetState> states) => retroDesktopFace(
      states: states,
      scale: RetroDesktopFaceScale.button,
      // An outlined chip's line is solid: a dotted line is the look's focus mark.
      bevel: !_outlined,
      sunken: t.chisel && selected && !_outlined,
      component: t.chipTheme.merge(
        RetroDesktopStyle(
          fill: _outlined
              ? const WidgetStatePropertyAll(Color(0x00000000))
              : null,
          textStyle: WidgetStatePropertyAll(
            t.type.text(small ? 12 : 13, 16, weight: FontWeight.w600),
          ),
          iconSize: WidgetStatePropertyAll(small ? 12 : 14),
        ),
      ),
      style: style,
      // An outlined chip draws no bevel: its padding takes the bevel's place, so it
      // stands as tall as a chip beside it.
      padding: EdgeInsets.symmetric(
        horizontal: (small ? 6 : 8) + (_outlined ? t.strokes.hairline : 0),
        vertical: (small ? 2 : 4) + (_outlined ? t.strokes.hairline : 0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon), const SizedBox(width: 4)],
          // One line: a capsule's round ends never meet a wrapped line. A
          // tag's mark leads its words on that line, so the two share one
          // box and one centre (a mark of its own stood a line of its own
          // height: a tag stood a fraction taller than the chips beside it).
          if (leading case final Text mark)
            RetroDesktopCaps(mark)
          else
            ?leading,
          Flexible(
            child: RetroDesktopCaps(
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
    if (onPressed == null && !filter) {
      return Semantics(
        label: label,
        selected: selected,
        excludeSemantics: true,
        child: face({
          if (selected) WidgetState.selected,
          if (!enabled) WidgetState.disabled,
        }),
      );
    }
    return RetroDesktopPressable(
      onPressed: enabled ? onPressed : null,
      label: label,
      selected: selected,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) => face(states),
    );
  }
}

/// An inverted chip for what can't wait: late, overdue, warned. Black on white by day, white on black by night, and never a
/// colour: this look keeps colour for now and the act.
///
/// ```dart
/// RetroDesktopFlag('2 days late')
/// ```
class RetroDesktopFlag extends StatelessWidget {
  /// Creates a [RetroDesktopFlag].
  const RetroDesktopFlag(this.label, {super.key, this.style});

  /// The visible or accessible name of this part.
  final String label;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return retroDesktopOwnSize(
      child: retroDesktopFace(
        states: const {},
        scale: RetroDesktopFaceScale.mark,
        // Paper, ringed in the words' ink: a flag is a label, and an inverted slab reads as chosen (the state law),
        // by night as the brightest thing on the page.
        component: t.badgeTheme.merge(
          RetroDesktopStyle(
            fill: WidgetStatePropertyAll(t.colors.paper),
            foreground: WidgetStatePropertyAll(t.colors.text),
            edge: WidgetStatePropertyAll(t.colors.text),
            textStyle: WidgetStatePropertyAll(t.type.chrome),
          ),
        ),
        style: style,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        // One line: a capsule's round ends never meet a wrapped line.
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PriorityPainter extends RetroDesktopPixelPainter {
  const _PriorityPainter(this.c, this.level);
  final RetroDesktopColors c;
  final int level;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    const heights = [5.0, 8.0, 12.0];
    for (var i = 0; i < 3; i++) {
      final bar = Rect.fromLTWH(i * 4.0, s.height - heights[i], 3, heights[i]);
      if (i < 4 - level) {
        px.fill(bar, c.text);
      } else {
        px.frame(bar, c.dark ? c.textTertiary : c.bevelDarker);
      }
    }
  }

  @override
  bool shouldRepaint(_PriorityPainter o) => o.c != c || o.level != level;
}

/// Three rising bars: a priority, 1 is all three solid, 3 is one. Bars, not colour, so it reads in every preset.
///
/// ```dart
/// RetroDesktopPriority(1)
/// ```
class RetroDesktopPriority extends StatelessWidget {
  /// Creates a [RetroDesktopPriority].
  const RetroDesktopPriority(this.level, {super.key});

  /// 1 to 3.
  final int level;
  @override
  Widget build(BuildContext context) => Semantics(
    label: RetroDesktopLocalizations.of(context).priorityLabel(level),
    child: retroDesktopOwnSize(
      width: 11,
      height: 12,
      child: RetroDesktopPixelPaint(
        painter: _PriorityPainter(
          RetroDesktopTheme.of(context).colors,
          level.clamp(1, 3),
        ),
      ),
    ),
  );
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.theme, this.value, this.style, this.direction);
  final RetroDesktopThemeData theme;
  final double? value;
  final RetroDesktopStyle? style;
  final TextDirection direction;
  @override
  void paint(Canvas canvas, Size size) {
    final c = theme.colors;
    const states = <WidgetState>{};
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, theme.progressTheme], get, states);
    final rect = Offset.zero & size;
    if (rect.isEmpty) return;
    final ink = slot((s) => s.foreground) ?? c.highlight;
    final rtl = direction == TextDirection.rtl;
    if (theme.chisel && slot((s) => s.shape) == null) {
      // The PC's: a sunken trough on the machine's grey, filling with blocks.
      final outer = theme.strokes.regular, inner = theme.strokes.hairline;
      canvas.drawRect(rect, Paint()..color = slot((s) => s.fill) ?? c.platinum);
      retroDesktopPaintChiselRect(
        canvas,
        rect,
        retroDesktopChiselEdge(c, sunken: true),
        outer: outer,
        inner: inner,
      );
      final room = rect.deflate(outer + inner + 1);
      if (room.isEmpty) return;
      final block = math.max(4.0, (room.height * .7).roundToDouble());
      const gap = 2.0;
      final paint = Paint()
        ..color = ink
        ..isAntiAlias = false;
      void at(double from, double to) {
        canvas.drawRect(
          rtl
              ? Rect.fromLTRB(
                  room.right - to,
                  room.top,
                  room.right - from,
                  room.bottom,
                )
              : Rect.fromLTRB(
                  room.left + from,
                  room.top,
                  room.left + to,
                  room.bottom,
                ),
          paint,
        );
      }

      final v = value;
      if (v == null) {
        // Busy with no measure: a short run of blocks, as a marquee stands.
        final start = (room.width / 3).roundToDouble();
        for (var i = 0; i < 4; i++) {
          final x = start + i * (block + gap);
          if (x + block > room.width) break;
          at(x, x + block);
        }
        return;
      }
      final reach = room.width * v.clamp(0.0, 1.0);
      for (var x = 0.0; x < reach; x += block + gap) {
        at(x, math.min(x + block, room.width));
      }
      return;
    }
    // The Mac's: a continuous bar in an outlined, bevelled trough; a striped
    // barber pole when there is no measure.
    final outline = (slot((s) => s.shape) ?? theme.shapes.full).copyWith(
      side:
          slot((s) => s.side) ??
          BorderSide(
            color: slot((s) => s.edge) ?? c.control,
            width: theme.strokes.regular,
          ),
    );
    canvas.drawPath(
      outline.getOuterPath(rect, textDirection: direction),
      Paint()..color = slot((s) => s.fill) ?? c.paper,
    );
    final inner = rect.deflate(outline.side.strokeInset);
    canvas.save();
    canvas.clipPath(outline.getInnerPath(rect, textDirection: direction));
    final width = inner.width * (value ?? 1).clamp(0.0, 1.0);
    final fill = Rect.fromLTWH(
      rtl ? inner.right - width : inner.left,
      inner.top,
      width,
      inner.height,
    );
    final fillShape = RetroDesktopShapes.inset(
      outline,
      outline.side.strokeInset,
    );
    canvas.clipPath(fillShape.getOuterPath(fill, textDirection: direction));
    canvas.drawRect(fill, Paint()..color = ink);
    if (value == null) {
      final stripe = Paint()
        ..color = c.highlightDark
        ..strokeWidth = 4;
      for (
        double x = fill.left - fill.height;
        x < fill.right + fill.height;
        x += 8
      ) {
        canvas.drawLine(
          Offset(x, fill.bottom),
          Offset(x + fill.height, fill.top),
          stripe,
        );
      }
    } else {
      // The fill's own light along its top, as the Mac lit a bar.
      canvas.drawRect(
        Rect.fromLTWH(fill.left, fill.top, fill.width, theme.strokes.hairline),
        Paint()..color = c.bevelLight.withValues(alpha: .35),
      );
    }
    final overlay = slot((s) => s.overlay);
    if (overlay != null) canvas.drawRect(fill, Paint()..color = overlay);
    canvas.restore();
    outline.paint(canvas, rect, textDirection: direction);
  }

  @override
  bool shouldRepaint(_ProgressPainter old) =>
      theme != old.theme ||
      value != old.value ||
      style != old.style ||
      direction != old.direction;
}

/// A progress bar in the appearance's idiom: Chisel's sunken trough filling with
/// blocks, Platinum's continuous bar (a striped barber pole while [value] is
/// null). Reads fill, foreground, edge, side, shape,
/// overlay, padding, minimumSize and textStyle from its style and progress theme.
///
/// ```dart
/// RetroDesktopLinearProgressIndicator(value: .6, label: 'Uploading files')
/// ```
class RetroDesktopLinearProgressIndicator extends StatelessWidget {
  /// Creates a [RetroDesktopLinearProgressIndicator].
  const RetroDesktopLinearProgressIndicator({
    super.key,
    this.value,
    required this.label,
    this.quiet = false,
    this.style,
  }) : assert(value == null || (value >= 0 && value <= 1));

  /// The current value to display or edit.
  final double? value;

  /// The visible or accessible name of this part.
  final String label;

  /// Whether the part uses its quieter presentation.
  final bool quiet;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.progressTheme], get, const {});
    final minimum = slot((s) => s.minimumSize) ?? const Size(0, 14);
    final bar = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minimum.width,
        minHeight: minimum.height,
      ),
      child: SizedBox(
        height: minimum.height,
        child: CustomPaint(
          painter: _ProgressPainter(
            t,
            value,
            style,
            Directionality.of(context),
          ),
        ),
      ),
    );
    return Semantics(
      label: label,
      value: value == null
          ? null
          : RetroDesktopLocalizations.of(context).formatPercent(value!),
      child: ExcludeSemantics(
        child: Padding(
          padding: slot((s) => s.padding) ?? EdgeInsets.zero,
          child: quiet
              ? bar
              : RetroDesktopFitRow(
                  fill: 0,
                  gap: 10 * t.density.horizontal,
                  fillMin: 60,
                  children: [
                    bar,
                    Text(
                      label,
                      style: t.type.caption
                          .merge(slot((s) => s.textStyle))
                          .copyWith(color: slot((s) => s.foreground)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// A disclosure: a triangle, a name, a small line; it opens what it holds in place. With no [child] it's a closed row that
/// presses, to go somewhere else.
///
/// ```dart
/// RetroDesktopDisclosure(note: '18 parts', child: table, title: 'Cut list')
/// ```
class RetroDesktopDisclosure extends StatefulWidget {
  /// Creates a [RetroDesktopDisclosure].
  const RetroDesktopDisclosure({
    required this.title,
    super.key,
    this.note,
    required this.child,
    this.initiallyExpanded = false,
    this.expanded,
    this.onExpansionChanged,
    this.style,
    this.enabled = true,
  });

  /// The heading displayed above the content.
  final String title;

  /// Supporting text shown with the main content.
  final String? note;

  /// The widget displayed inside this part.
  final Widget child;

  /// Whether the disclosure starts expanded when uncontrolled.
  final bool initiallyExpanded;

  /// The controlled disclosure state, or null to manage it internally.
  final bool? expanded;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// Reports a request to expand or collapse the disclosure.
  final ValueChanged<bool>? onExpansionChanged;

  /// Whether the part accepts user interaction.
  final bool enabled;
  @override
  State<RetroDesktopDisclosure> createState() => _DisclosureState();
}

class _DisclosureState extends State<RetroDesktopDisclosure> {
  late var _open = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final open = widget.expanded ?? _open;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final head = RetroDesktopPressable(
      onPressed: !widget.enabled
          ? null
          : () {
              setState(() => _open = !open);
              widget.onExpansionChanged?.call(!open);
            },
      label: widget.title,
      expanded: open,
      builder: (context, states) => retroDesktopFace(
        states: states,
        style: widget.style,
        component: t.disclosureTheme.merge(
          RetroDesktopStyle(
            fill: WidgetStatePropertyAll(const Color(0x00000000)),
            side: const WidgetStatePropertyAll(BorderSide.none),
            textStyle: WidgetStatePropertyAll(
              t.type.pixel(
                18,
                18,
                color: open ? t.colors.text : t.colors.textSecondary,
              ),
            ),
          ),
        ),
        bevel: false,
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // The triangle's ink, not its 12 px box, stands on the keyline:
            // drawn closed it is 3 in from its box's start, open 1. Its words
            // stay put as it turns. It stands on their first line's capitals
            // at any text size (3 from the top floated it above them at twice
            // the size).
            RetroDesktopOnCaps(
              style: t.type.pixel(18, 18),
              child: SizedBox(
                width: 9,
                height: 12,
                child: OverflowBox(
                  alignment: AlignmentDirectional.centerStart,
                  minWidth: 12,
                  maxWidth: 12,
                  child: Transform.translate(
                    offset: Offset((rtl ? 1 : -1) * (open ? 1 : 3), 0),
                    child: RetroDesktopTriangleMark(
                      open
                          ? AxisDirection.down
                          : (rtl ? AxisDirection.left : AxisDirection.right),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                children: [
                  Text(widget.title),
                  if (widget.note != null)
                    Text(
                      widget.note!,
                      style: t.type.caption.copyWith(
                        color: t.colors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // Keep the pressable mounted so expanding preserves keyboard focus.
    return RetroDesktopColumn(
      gap: 10,
      children: [head, if (open) widget.child],
    );
  }
}

/// The shared box of every option: raised, or pressed in and lit when [chosen], with everything in it reading on the
/// highlight by itself: `t.colors.text` and `t.type` answer for the surface.
///
/// ```dart
/// RetroDesktopChoiceBox(onPressed: () {}, child: Text('Today'), selected: true)
/// ```
class RetroDesktopChoiceBox extends StatelessWidget {
  /// Creates a [RetroDesktopChoiceBox].
  const RetroDesktopChoiceBox({
    super.key,
    required this.child,
    this.selected = false,
    this.padding = EdgeInsets.zero,
    this.onPressed,
    this.label,
    this.hint,
    this.many = false,
    this.inGroup = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The widget displayed inside this part.
  final Widget child;

  /// Whether the part represents the current selection.
  final bool selected;

  /// Insets around the content.
  final EdgeInsetsGeometry padding;

  /// Called when the action is activated; null makes the action unavailable.
  final VoidCallback? onPressed;

  /// The visible or accessible name of this part.
  final String? label;

  /// Placeholder text shown while the input has no value.
  final String? hint;

  /// Whether the chip represents multiple items.
  final bool many;

  /// Whether the part shares its frame with adjacent group members.
  final bool inGroup;

  /// An optional externally owned focus node; the caller disposes it.
  final FocusNode? focusNode;

  /// Whether this part takes the focus when it first appears and nothing else has it.
  final bool autofocus;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return RetroDesktopPressable(
      onPressed: onPressed,
      label: label,
      selected: many ? null : selected,
      checked: many ? selected : null,
      inGroup: inGroup,
      button: !many,
      hint: hint,
      focusNode: focusNode,
      autofocus: autofocus,
      builder: (context, states) => _FillTiles.fill(
        context,
        retroDesktopFace(
          states: states,
          component: t.optionTheme,
          style: style,
          padding: padding,
          child: selected ? RetroDesktopOnHighlight(child: child) : child,
        ),
      ),
    );
  }
}

// Marks a RetroDesktopChoices' tiles: each choice box's face fills the height
// its row gives it, rather than its own height centred in the row.
class _FillTiles extends InheritedWidget {
  const _FillTiles({required super.child});
  static Widget fill(BuildContext context, Widget face) =>
      context.dependOnInheritedWidgetOfExactType<_FillTiles>() == null
      ? face
      : _FillHeight(child: face);
  @override
  bool updateShouldNotify(_FillTiles old) => false;
}

/// [child] laid out at the full height it is given, when that is bounded: a
/// tile in a row of tiles (a choice, a folder, a file) fills its row's height
/// rather than standing its own height centred in it. Not exported.
Widget retroDesktopFillHeight(Widget child) => _FillHeight(child: child);

// Lays its child out at the full height it is given, when that is bounded.
class _FillHeight extends SingleChildRenderObjectWidget {
  const _FillHeight({required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFillHeight();
}

class _RenderFillHeight extends RenderProxyBox {
  BoxConstraints _filled(BoxConstraints c) =>
      c.hasBoundedHeight ? c.tighten(height: c.maxHeight) : c;
  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(_filled(constraints)) ?? constraints.smallest;
  @override
  void performLayout() {
    final kid = child;
    if (kid == null) {
      size = constraints.smallest;
      return;
    }
    kid.layout(_filled(constraints), parentUsesSize: true);
    size = kid.size;
  }
}

/// One choice in a [RetroDesktopChoices]: its words, an optional small line, and the value it stands for (its words if left out).
class RetroDesktopChoice {
  /// Creates a [RetroDesktopChoice].
  const RetroDesktopChoice(this.label, {this.note, String? value})
    : value = value ?? label;

  /// The visible or accessible name of this part.
  final String label;

  /// The current value to display or edit.
  final String value;

  /// Supporting text shown with the main content.
  final String? note;
}

/// One choice from a few, as tiles: a filter, a grade, a size, a kind. Give it the words: it puts as many on a row as
/// hold their longest word, and the rest on the next rows, so no tile crushes. Never write this as a `Row` of `Expanded`
/// boxes. The chosen tile is pressed in and lit.
///
/// ```dart
/// RetroDesktopChoices(options: const [RetroDesktopChoice('All'), RetroDesktopChoice('Near mint', note: 'Sharp corners')], onChanged: (v) {}, value: 'All')
/// ```
class RetroDesktopChoices extends StatelessWidget {
  /// Creates a [RetroDesktopChoices].
  const RetroDesktopChoices({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
  });

  /// The selectable options in reading order.
  final List<RetroDesktopChoice> options;

  /// The value of the value option; none, if null.
  final String? value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<String>? onChanged;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = t.type.chrome;
    final notes = options.any((o) => o.note != null);
    return LayoutBuilder(
      builder: (context, box) {
        const pad = 10.0, gap = 6.0;
        var need = notes ? 104.0 : 56.0;
        for (final o in options) {
          // A short label stays on one line; a long one may wrap, between its words.
          final scaler = MediaQuery.textScalerOf(context);
          final holds = o.label.length <= 16
              ? _wholeWidth(o.label, words, scaler)
              : retroDesktopWidestWord(o.label, words, textScaler: scaler);
          need = math.max(need, holds + 2 * pad + 4);
        }
        final w = box.hasBoundedWidth ? box.maxWidth : 390.0;
        var columns = math.max(
          1,
          math.min(options.length, ((w + gap) / (need + gap)).floor()),
        );
        // One left alone on its row reads worse than a row one shorter.
        if (columns > 2 && options.length % columns == 1) columns -= 1;
        // Each tile's face fills its row's height: a row of tiles shows one
        // top and one bottom however its notes wrap.
        final grid = _FillTiles(
          child: RetroDesktopGridOf(
            columns: columns,
            gap: gap,
            runGap: gap,
            children: [
              for (final o in options)
                RetroDesktopChoiceBox(
                  selected: o.value == value,
                  inGroup: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: pad,
                    vertical: 7,
                  ),
                  label: o.label,
                  onPressed: onChanged == null
                      ? null
                      : () => onChanged!(o.value),
                  child: Builder(
                    builder: (context) {
                      final tt = RetroDesktopTheme.of(context);
                      return SizedBox(
                        width: double.infinity,
                        child: Column(
                          crossAxisAlignment: notes
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              o.label,
                              style: tt.type.chrome,
                              textAlign: notes
                                  ? TextAlign.start
                                  : TextAlign.center,
                            ),
                            if (o.note != null) ...[
                              const SizedBox(height: 2),
                              Text(o.note!, style: tt.type.meta),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
        if (!box.hasBoundedWidth || !retroDesktopHugs(context)) return grid;
        // From 600 up the tiles keep to the widest one's width, at the
        // column's start, not spread across it.
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(
            width: math.min(w, columns * need + (columns - 1) * gap),
            child: grid,
          ),
        );
      },
    );
  }
}

/// A number stepper: a small button each side of a sunk value and its unit, and a note under it.
///
/// ```dart
/// RetroDesktopNumberField(value: 2, unit: 'coats', onChanged: (_) { (() {})(); })
/// ```
class RetroDesktopNumberField extends StatelessWidget {
  /// Creates a [RetroDesktopNumberField].
  const RetroDesktopNumberField({
    super.key,
    required this.value,
    this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.unit = '',
    this.label,
    this.note,
    this.style,
  }) : assert(min <= max),
       assert(value >= min && value <= max),
       assert(step > 0);

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The current value to display or edit.
  final int value;

  /// The lower bound of the supported range.
  final int min;

  /// The upper bound of the supported range.
  final int max;

  /// The amount added or subtracted by one step.
  final int step;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<int>? onChanged;

  /// The unit shown beside the value.
  final String unit;

  /// The visible or accessible name of this part.
  final String? label;

  /// Supporting text shown with the main content.
  final String? note;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = RetroDesktopLocalizations.of(context);
    final less = onChanged == null || value <= min
        ? null
        : () => onChanged!((value - step).clamp(min, max));
    final more = onChanged == null || value >= max
        ? null
        : () => onChanged!((value + step).clamp(min, max));
    // One row, one height: the two buttons and the value between them all show a button's face height, the buttons
    // square, so the stepper stands level with a button or a field beside it.
    final faceHeight = retroDesktopButtonFaceHeight(context);
    Widget press(IconData icon, String name, VoidCallback? action) =>
        RetroDesktopPressable(
          onPressed: action,
          label: name,
          builder: (context, states) => retroDesktopFace(
            states: states,
            component: t.stepperTheme.merge(
              RetroDesktopStyle(
                minimumSize: WidgetStatePropertyAll(Size.square(faceHeight)),
              ),
            ),
            style: style,
            padding: const EdgeInsets.all(6),
            child: Icon(icon),
          ),
        );
    final row = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final increase =
            key == LogicalKeyboardKey.arrowUp ||
            key ==
                (rtl
                    ? LogicalKeyboardKey.arrowLeft
                    : LogicalKeyboardKey.arrowRight);
        final decrease =
            key == LogicalKeyboardKey.arrowDown ||
            key ==
                (rtl
                    ? LogicalKeyboardKey.arrowRight
                    : LogicalKeyboardKey.arrowLeft);
        if (!increase && !decrease) return KeyEventResult.ignored;
        (increase ? more : less)?.call();
        return KeyEventResult.handled;
      },
      child: Semantics(
        container: true,
        label: label,
        value:
            '${RetroDesktopLocalizations.of(context).formatNumber(value)}${unit.isEmpty ? '' : ' $unit'}',
        // As wide as its value needs, whatever room it is given: the box holds
        // the widest value the range allows, so it stays put as it counts.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            press(RetroDesktopGlyphs.minus, words.less, less),
            Flexible(
              child: ExcludeSemantics(
                // Disabled, the value and its box dim with the buttons.
                child: AnimatedOpacity(
                  duration: RetroDesktopMotion.of(context).state,
                  curve: RetroDesktopMotion.of(context).standard,
                  opacity: onChanged == null ? .5 : 1,
                  child: retroDesktopFace(
                    states: {if (onChanged == null) WidgetState.disabled},
                    component: t.stepperTheme.merge(
                      RetroDesktopStyle(
                        fill: WidgetStatePropertyAll(t.colors.paper),
                        minimumSize: WidgetStatePropertyAll(
                          Size(0, faceHeight),
                        ),
                      ),
                    ),
                    style: style,
                    sunken: true,
                    padding: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      // A one-digit value still gets a box about as wide as
                      // the buttons beside it, its figures on its middle; the
                      // box as wide as they need, not the row's room.
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 24),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // The longest value the range allows, in its
                                  // widest figures, whatever the face's digits.
                                  for (final end in {min, max})
                                    for (final figure in ['0', '8'])
                                      Visibility.maintain(
                                        visible: false,
                                        child: Text(
                                          words
                                              .formatNumber(end)
                                              .replaceAll(
                                                RegExp('[0-9]'),
                                                figure,
                                              ),
                                          style: t.type.small,
                                        ),
                                      ),
                                  Text(
                                    words.formatNumber(value),
                                    style: t.type.small,
                                  ),
                                ],
                              ),
                              if (unit.isNotEmpty)
                                Text(unit, style: t.type.note),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            press(RetroDesktopGlyphs.plus, words.more, more),
          ],
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(note!, style: t.type.note),
          ),
      ],
    );
  }
}

class _GroupPainter extends RetroDesktopPixelPainter {
  const _GroupPainter(
    this.c,
    this.gapFrom,
    this.gapTo,
    this.shape,
    this.fill,
    this.top,
  );
  final RetroDesktopColors c;
  final double gapFrom, gapTo, top;
  final OutlinedBorder shape;
  final Color? fill;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    // `.group`: 1 lp of shade, 1 of light inside it and outside it, broken where its name stands, on any ground.
    final r = px.snap(Rect.fromLTRB(0, top, s.width, s.height));
    if (fill != null) {
      px.canvas.drawPath(shape.getOuterPath(r), Paint()..color = fill!);
    }
    final ordinary =
        shape is RetroDesktopBorder &&
        (shape as RetroDesktopBorder).cut == 0 &&
        shape.side == BorderSide(color: c.bevelDark);
    if (!ordinary) {
      px.canvas.save();
      px.canvas.clipPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Rect.fromLTRB(-4, -4, s.width + 4, s.height + 4))
          ..addRect(
            Rect.fromLTRB(
              gapFrom,
              r.top - 4,
              gapTo,
              r.top + shape.side.width + 2,
            ),
          ),
      );
      shape.paint(px.canvas, r);
      px.canvas.restore();
      return;
    }
    final w = px.hairX, h = px.hair;
    void across(double y, Color color, double inL, double inR) {
      final a = px.x(gapFrom), b = px.x(gapTo);
      if (inL < a) px.fillExact(inL, y, a, y + h, color);
      if (b < inR) px.fillExact(b, y, inR, y + h, color);
    }

    across(r.top, c.bevelDark, r.left, r.right);
    across(r.top + h, c.bevelLight, r.left + w, r.right - w);
    px.fillExact(r.left, r.top + h, r.left + w, r.bottom, c.bevelDark);
    px.fillExact(r.right - w, r.top + h, r.right, r.bottom, c.bevelDark);
    px.fillExact(r.left, r.bottom - h, r.right, r.bottom, c.bevelDark);
    px.fillExact(
      r.left + w,
      r.top + 2 * h,
      r.left + 2 * w,
      r.bottom - h,
      c.bevelLight,
    );
    px.fillExact(r.right, r.top + h, r.right + w, r.bottom + h, c.bevelLight);
    px.fillExact(r.left + w, r.bottom, r.right + w, r.bottom + h, c.bevelLight);
  }

  @override
  bool shouldRepaint(_GroupPainter o) =>
      o.c != c ||
      o.gapFrom != gapFrom ||
      o.gapTo != gapTo ||
      o.shape != shape ||
      o.fill != fill ||
      o.top != top;
}

class _GroupLayout extends MultiChildRenderObjectWidget {
  const _GroupLayout({
    required this.c,
    required this.padding,
    required super.children,
  });
  final RetroDesktopColors c;
  final EdgeInsets padding;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroup(c, Directionality.of(context), padding);
  @override
  void updateRenderObject(BuildContext context, _RenderGroup o) {
    o
      ..c = c
      ..direction = Directionality.of(context)
      ..padding = padding
      ..markNeedsLayout();
  }
}

class _GroupData extends ContainerBoxParentData<RenderBox> {}

/// A group box's frame stops where its name stands, so it needs no ground colour behind the name.
class _RenderGroup extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _GroupData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _GroupData> {
  _RenderGroup(this.c, this.direction, this.padding);
  RetroDesktopColors c;
  TextDirection direction;
  double _gapFrom = 0, _gapTo = 0, rimTop = 10;
  EdgeInsets padding;
  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _GroupData) child.parentData = _GroupData();
  }

  @override
  void performLayout() {
    final label = firstChild!;
    final body = childAfter(label)!;
    final w = constraints.maxWidth;
    label.layout(
      BoxConstraints(maxWidth: math.max(0, w - padding.horizontal - 4)),
      parentUsesSize: true,
    );
    final top = math.max(padding.top, label.size.height + padding.top - 18);
    rimTop = label.size.height / 2 + 1;
    final room = constraints.hasBoundedHeight
        ? math.max(0.0, constraints.maxHeight - top - padding.bottom)
        : double.infinity;
    body.layout(
      BoxConstraints(
        minWidth: math.max(0, w - padding.horizontal),
        maxWidth: math.max(0, w - padding.horizontal),
        minHeight: constraints.hasTightHeight ? room : 0,
        maxHeight: room,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(w, top + body.size.height + padding.bottom),
    );
    final rtl = direction == TextDirection.rtl;
    // The name stands on its rows' keyline.
    final labelX = rtl ? w - padding.right - label.size.width : padding.left;
    (label.parentData as _GroupData).offset = Offset(labelX, 1);
    (body.parentData as _GroupData).offset = Offset(padding.left, top);
    _gapFrom = labelX - 6;
    _gapTo = labelX + label.size.width + 6;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final d = child.parentData! as _GroupData;
    transform.translateByDouble(d.offset.dx, d.offset.dy, 0, 1);
  }

  double get gapFrom => _gapFrom;
  double get gapTo => _gapTo;
}

/// A named group inside a window: an etched frame, its name standing in the line. It takes no ground colour, so it stands on
/// the machine and on paper alike.
///
/// ```dart
/// RetroDesktopGroupBox(title: 'Checklist', icon: RetroDesktopGlyphs.listChecks, count: '6 of 10', child: list)
/// ```
class RetroDesktopGroupBox extends StatelessWidget {
  /// Creates a [RetroDesktopGroupBox].
  const RetroDesktopGroupBox({
    super.key,
    this.style,
    required this.title,
    required this.child,
    this.icon,
    this.count,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The heading displayed above the content.
  final String title;

  /// The glyph shown with the content.
  final IconData? icon;

  /// After the name, in the highlight.
  final String? count;

  /// The widget displayed inside this part.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.cardTheme], get, const {});
    final text = t.type
        .pixel(16, 18)
        .merge(slot((s) => s.textStyle))
        .copyWith(color: slot((s) => s.foreground));
    final side =
        slot((s) => s.side) ??
        BorderSide(
          color: slot((s) => s.edge) ?? c.bevelDark,
          width: t.strokes.regular,
        );
    final outline = (slot((s) => s.shape) ?? t.shapes.medium).copyWith(
      side: side,
    );
    final padding = t.density.apply(
      slot((s) => s.padding) ?? const EdgeInsets.fromLTRB(15, 33, 15, 15),
      Directionality.of(context),
    );
    final minimum = slot((s) => s.minimumSize) ?? Size.zero;
    // To the window the group is its frame; inside, its name and its rows share keylines (ui_core's alignment.dart).
    return DesignKeylineRegion(
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minimum.width,
          minHeight: minimum.height,
        ),
        child: _GroupFrame(
          c: c,
          shape: outline,
          fill: slot((s) => s.fill),
          child: _GroupLayout(
            c: c,
            padding: padding,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: slot((s) => s.iconSize) ?? 16,
                      color: slot((s) => s.foreground) ?? c.text,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      title,
                      style: text,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      count!,
                      // A count is a fact about the group, not a selection:
                      // quiet ink, the accent kept for what is chosen or now.
                      style: text.copyWith(
                        color: slot((s) => s.foreground) ?? c.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints the frame from the layout's own numbers, behind it.
class _GroupFrame extends SingleChildRenderObjectWidget {
  const _GroupFrame({
    required this.c,
    required this.shape,
    this.fill,
    required Widget super.child,
  });
  final RetroDesktopColors c;
  final OutlinedBorder shape;
  final Color? fill;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderGroupFrame(c, shape, fill);
  @override
  void updateRenderObject(BuildContext context, _RenderGroupFrame o) {
    o
      ..c = c
      ..shape = shape
      ..fill = fill
      ..markNeedsPaint();
  }
}

class _RenderGroupFrame extends RenderRetroDesktopPixelPaint {
  _RenderGroupFrame(this.c, this.shape, this.fill)
    : super(_GroupPainter(c, 0, 0, shape, fill, 10), false);
  RetroDesktopColors c;
  OutlinedBorder shape;
  Color? fill;
  @override
  void paint(PaintingContext context, Offset offset) {
    final group = child;
    if (group is _RenderGroup) {
      paintWith(
        _GroupPainter(c, group.gapFrom, group.gapTo, shape, fill, group.rimTop),
      );
    }
    super.paint(context, offset);
  }
}

/// One folder tab: its name and its count.
class RetroDesktopFolderTab {
  /// Creates a [RetroDesktopFolderTab].
  const RetroDesktopFolderTab(this.label, {this.count, this.key});

  /// The visible or accessible name of this part.
  final String label;

  /// The count displayed by this part.
  final String? count;

  /// The stable identity of this item.
  final Key? key;
}

/// Folder tabs over a panel. The open tab stands taller and joins the panel. They keep their widths: if a phone is too
/// narrow for them all they scroll sideways, rather than crush.
///
/// ```dart
/// RetroDesktopTabBar(tabs: const ['Today', 'Later'], onChanged: (i) {}, child: list, selectedIndex: 0, counts: ['6', '5'])
/// ```
class RetroDesktopTabBar extends StatefulWidget implements RetroDesktopFlush {
  /// Creates a [RetroDesktopTabBar].
  const RetroDesktopTabBar({
    super.key,
    required this.tabs,
    this.child,
    this.selectedIndex = 0,
    this.onChanged,
    this.label,
    this.counts = const [],
    this.style,
  });

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The tabs in reading order.
  final List<String> tabs;

  /// The index of the currently selected item.
  final int selectedIndex;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<int>? onChanged;

  /// The widget displayed inside this part.
  final Widget? child;

  /// The visible or accessible name of this part.
  final String? label;

  /// Each tab's count, shown after its words; null (or a shorter list) shows none.
  final List<String?> counts;
  @override
  State<RetroDesktopTabBar> createState() => _TabBarState();
}

// Clips an overflowing tab strip to its whole tabs.
class _WholeTabs extends CustomClipper<Rect> {
  _WholeTabs(this.clip, Listenable reclip) : super(reclip: reclip);
  final Rect? Function(Size size) clip;

  @override
  Rect getClip(Size size) => clip(size) ?? Offset.zero & size;

  @override
  bool shouldReclip(_WholeTabs oldClipper) => true;
}

class _TabBarState extends State<RetroDesktopTabBar> {
  final List<FocusNode> _nodes = [];
  final _strip = ScrollController();
  final _metrics = ValueNotifier(0);
  // The scroller keeps its place when the arrows come and go around it.
  final _scroller = GlobalKey();
  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _strip.dispose();
    _metrics.dispose();
    super.dispose();
  }

  final List<GlobalKey> _tabKeys = [];

  // Each tab's run along the strip, start edge to end edge, in scroll offsets.
  List<(double, double)> _spans() {
    final view = _scroller.currentContext?.findRenderObject();
    if (view is! RenderBox || !view.hasSize || !_strip.hasClients) {
      return const [];
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final w = view.size.width;
    final at = _strip.position.pixels;
    final spans = <(double, double)>[];
    for (final key in _tabKeys.take(widget.tabs.length)) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) continue;
      final left = box.localToGlobal(Offset.zero, ancestor: view).dx;
      final right = left + box.size.width;
      spans.add(
        rtl ? (w - right + at, w - left + at) : (left + at, right + at),
      );
    }
    return spans;
  }

  // An arrow brings the next tab cut at the edge whole into view at the strip's start (or, back, the run of tabs
  // before the first whole one to its end).
  void _step(int by) {
    final p = _strip.position;
    final spans = _spans();
    final room = p.viewportDimension;
    double to;
    if (spans.isEmpty) {
      to = p.pixels + by * room * .75;
    } else if (by > 0) {
      final cut = spans.where((s) => s.$2 > p.pixels + room + .5);
      to = cut.isEmpty ? p.maxScrollExtent : cut.first.$1;
    } else {
      final first = spans.firstWhere(
        (s) => s.$1 >= p.pixels - .5,
        orElse: () => spans.first,
      );
      to = spans.firstWhere((s) => s.$1 >= first.$1 - room - .5).$1;
    }
    _strip.jumpTo(to.clamp(0, p.maxScrollExtent));
  }

  // The strip shows whole tabs only: a tab cut at the edge would leave a sliver of one stroke of its words before the
  // arrows, read as broken.
  Rect? _wholeTabs(Size size) {
    if (!_strip.hasClients) return null;
    final p = _strip.position;
    final whole = [
      for (final s in _spans())
        if (s.$1 >= p.pixels - .5 &&
            s.$2 <= p.pixels + p.viewportDimension + .5)
          s,
    ];
    if (whole.isEmpty) return null;
    final from = whole.first.$1 - p.pixels;
    final to = whole.last.$2 - p.pixels;
    return Directionality.of(context) == TextDirection.rtl
        ? Rect.fromLTRB(size.width - to, 0, size.width - from, size.height)
        : Rect.fromLTRB(from, 0, to, size.height);
  }

  KeyEventResult _keys(int index, KeyEvent event) {
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final int target;
    if (key == LogicalKeyboardKey.home) {
      target = 0;
    } else if (key == LogicalKeyboardKey.end) {
      target = widget.tabs.length - 1;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      target = (index + (rtl ? -1 : 1)) % widget.tabs.length;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      target = (index + (rtl ? 1 : -1)) % widget.tabs.length;
    } else {
      return KeyEventResult.ignored;
    }
    _nodes[target].requestFocus();
    final targetContext = _nodes[target].context;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: RetroDesktopMotion.of(targetContext).move,
      );
    }
    widget.onChanged!(target);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.tabs.isEmpty ||
          (widget.selectedIndex >= 0 &&
              widget.selectedIndex < widget.tabs.length),
    );
    while (_nodes.length < widget.tabs.length) {
      _nodes.add(FocusNode());
    }
    while (_tabKeys.length < widget.tabs.length) {
      _tabKeys.add(GlobalKey());
    }
    final t = RetroDesktopTheme.of(context);
    final selectedFill =
        RetroDesktopStyle.first<Color>(
          [widget.style, t.tabBarTheme, t.cardTheme],
          (s) => s.fill,
          {WidgetState.selected},
        ) ??
        (t.chisel ? t.colors.platinum : t.colors.platinumLight);
    // Platinum rounds a tab's top corners as it rounds its buttons; Chisel's
    // folder tabs are square.
    final buttonShape = t.shapes.button;
    final OutlinedBorder? tabShape = t.chisel
        ? null
        : buttonShape is RoundedRectangleBorder
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: buttonShape.borderRadius
                  .resolve(Directionality.of(context))
                  .topLeft,
            ),
          )
        : null;
    final tabSide =
        RetroDesktopStyle.first<BorderSide>(
          [widget.style, t.tabBarTheme],
          (s) => s.side,
          {WidgetState.selected},
        ) ??
        BorderSide(width: t.strokes.regular);
    final panelSide =
        RetroDesktopStyle.first<BorderSide>(
          [t.cardTheme],
          (s) => s.side,
          const {},
        ) ??
        BorderSide(width: t.strokes.regular);
    final join =
        (math.max(tabSide.strokeInset, panelSide.strokeInset) +
                t.strokes.hairline +
                1)
            .ceilToDouble();
    // The panel's rule: a closed tab's foot stands on it (its own bottom
    // outline over the rule, one line, not two), and the open tab's sides stop
    // there.
    final rule = math
        .min(tabSide.strokeInset, panelSide.strokeInset)
        .ceilToDouble();
    final scroller = SingleChildScrollView(
      controller: _strip,
      scrollDirection: Axis.horizontal,
      // A tab bar to assistive technology and each tab a tab: the role on
      // the tab's merged node, its selected state and its tap the press's.
      child: Semantics(
        role: SemanticsRole.tabBar,
        container: true,
        explicitChildNodes: true,
        label: widget.label ?? RetroDesktopLocalizations.of(context).tabs,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              Builder(
                key: _tabKeys[i],
                builder: (context) {
                  final selected = i == widget.selectedIndex;
                  _nodes[i].skipTraversal = !selected;
                  final count = i < widget.counts.length
                      ? widget.counts[i]
                      : null;
                  return MergeSemantics(
                    child: Semantics(
                      role: SemanticsRole.tab,
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        includeSemantics: false,
                        onKeyEvent: (_, event) => _keys(i, event),
                        child: RetroDesktopPressable(
                          focusNode: _nodes[i],
                          alignment: Alignment.bottomCenter,
                          selected: selected,
                          label: widget.tabs[i],
                          value: count,
                          onPressed: widget.onChanged == null
                              ? null
                              : () => widget.onChanged!(i),
                          builder: (context, states) => Padding(
                            padding: EdgeInsets.only(
                              bottom: !selected && widget.child != null
                                  ? join - rule
                                  : 0,
                            ),
                            // The tab's own face, not the panel's rule that shows
                            // under a closed tab, is what its label is centred on.
                            child: DesignKeylineFace(
                              child: retroDesktopFace(
                                openBottom: selected && widget.child != null,
                                openDepth: join - rule,
                                states: states,
                                component: t.tabBarTheme.merge(
                                  RetroDesktopStyle(
                                    fill: WidgetStatePropertyAll(
                                      selected
                                          ? selectedFill
                                          : t.colors.platinumDark,
                                    ),
                                    shape: tabShape == null
                                        ? null
                                        : WidgetStatePropertyAll(tabShape),
                                    // A closed tab's words in full ink, as the
                                    // period's were: grey type means
                                    // unavailable (the state law).
                                    foreground: WidgetStatePropertyAll(
                                      t.colors.text,
                                    ),
                                    textStyle: WidgetStatePropertyAll(
                                      t.type.chrome,
                                    ),
                                  ),
                                ),
                                style: widget.style,
                                // The chosen tab stands 4 taller, all of it above
                                // its words: every label keeps one centre line.
                                padding: EdgeInsets.fromLTRB(
                                  12,
                                  selected ? 10 : 6,
                                  12,
                                  selected && widget.child != null
                                      ? 6 + join
                                      : 6,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RetroDesktopCaps(Text(widget.tabs[i])),
                                    if (count != null) ...[
                                      const SizedBox(width: 6),
                                      RetroDesktopCaps(Text(count)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
    // Tabs too wide for their room scroll sideways, and then show it: a pair of
    // arrows at the row's end, as a tab control did when its tabs overflowed
    // (a tab cut at the edge, alone, read as broken).
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final words = RetroDesktopLocalizations.of(context);
    final tabs = ListenableBuilder(
      listenable: Listenable.merge([_strip, _metrics]),
      builder: (context, child) {
        final p = _strip.hasClients ? _strip.position : null;
        if (p == null || !p.hasContentDimensions || p.maxScrollExtent <= 0) {
          return child!;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: ClipRect(
                clipper: _WholeTabs(
                  _wholeTabs,
                  Listenable.merge([_strip, _metrics]),
                ),
                child: child!,
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                start: 2,
                bottom: widget.child != null ? join : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  RetroDesktopIconButton(
                    rtl
                        ? RetroDesktopGlyphs.chevronRight
                        : RetroDesktopGlyphs.chevronLeft,
                    label: words.earlierTabs,
                    size: RetroDesktopButtonSize.small,
                    onPressed: p.pixels > 0 ? () => _step(-1) : null,
                  ),
                  RetroDesktopIconButton(
                    rtl
                        ? RetroDesktopGlyphs.chevronLeft
                        : RetroDesktopGlyphs.chevronRight,
                    label: words.laterTabs,
                    size: RetroDesktopButtonSize.small,
                    onPressed: p.pixels < p.maxScrollExtent
                        ? () => _step(1)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      child: NotificationListener<ScrollMetricsNotification>(
        key: _scroller,
        onNotification: (_) {
          _metrics.value++;
          return false;
        },
        child: scroller,
      ),
    );
    // For ui_core's keyline check: the row of tabs is one item to what holds it, and the panel is a section of its own.
    final strip = DesignKeylineRegion(
      label: widget.label ?? RetroDesktopLocalizations.of(context).tabs,
      mixedHeights:
          'the open tab stands taller than the others and joins its panel, '
          'as a folder tab does',
      child: tabs,
    );
    if (widget.child == null) return strip;
    return _JoinedTabPanel(
      overlap: widget.tabs.isEmpty ? 0 : join,
      header: strip,
      // The panel, its frame included, is the section: its frame stands on
      // the holder's keyline, its contents on the frame's own.
      panel: DesignKeylineRegion(
        label: widget.tabs.isEmpty
            ? null
            : widget.tabs[widget.selectedIndex.clamp(
                0,
                widget.tabs.length - 1,
              )],
        child: retroDesktopFace(
          states: const {},
          component: t.cardTheme,
          style: RetroDesktopStyle(fill: WidgetStatePropertyAll(selectedFill)),
          scale: RetroDesktopFaceScale.surface,
          padding: const EdgeInsets.all(9),
          child: widget.child!,
        ),
      ),
    );
  }
}

// Paint the panel first so the raised selected tab opens its top rule. The
// shared column supplies measured layout/intrinsics; hit tests follow paint.
class _JoinedTabPanel extends RetroDesktopColumn {
  _JoinedTabPanel({
    required double overlap,
    required Widget header,
    required Widget panel,
  }) : super(gap: -overlap, children: [header, panel]);
  @override
  RenderRetroDesktopColumn createRenderObject(BuildContext context) =>
      _RenderJoinedTabPanel(gap, Directionality.of(context));
}

class _RenderJoinedTabPanel extends RenderRetroDesktopColumn {
  _RenderJoinedTabPanel(double gap, TextDirection direction)
    : super(gap, null, null, direction);
  @override
  void paint(PaintingContext context, Offset offset) {
    for (var child = lastChild; child != null; child = childBefore(child)) {
      context.paintChild(
        child,
        offset + (child.parentData! as BoxParentData).offset,
      );
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final current = child;
      if (result.addWithPaintOffset(
        offset: (current.parentData! as BoxParentData).offset,
        position: position,
        hitTest: (result, local) => current.hitTest(result, position: local),
      )) {
        return true;
      }
    }
    return false;
  }
}

double _wholeWidth(String text, TextStyle style, TextScaler scaler) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();
  final width = tp.width;
  tp.dispose();
  return width;
}
