/// The command palette, as a fuzzy finder draws one: `>` and what is typed,
/// a count of what matches, then the commands that match, the letters that
/// matched lit and the highlighted one under the cursor.
library;

import 'package:flutter/foundation.dart';
// One line, so an app's copy of this file (look:check's copy-out, which
// reads its imports a line at a time) keeps it whole.
// dart format off
import 'package:material_ui/material_ui.dart' show InputDecoration, Material, MaterialType, TextField;
// dart format on
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../primitives/box.dart';
import '../primitives/control.dart';
import '../style.dart';
import '../theme.dart';
import 'key_hint.dart';
import 'pane.dart';

/// Where [query] matched [text], as [designMatchScore] ranks it: the
/// prefix, the word or the run of letters it found, or each letter in
/// order. Ranges are start inclusive, end exclusive; empty when nothing
/// matched.
///
/// ```dart
/// termMatchRanges('deploy to staging', 'dts'); // [(0, 1), (7, 8), (10, 11)]
/// ```
List<(int, int)> termMatchRanges(String text, String query) {
  final t = text.toLowerCase();
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final at = t.indexOf(q);
  if (at >= 0) return [(at, at + q.length)];
  final ranges = <(int, int)>[];
  var i = 0;
  for (var j = 0; j < t.length && i < q.length; j++) {
    if (t.codeUnitAt(j) != q.codeUnitAt(i)) continue;
    i++;
    if (ranges.isNotEmpty && ranges.last.$2 == j) {
      ranges.last = (ranges.last.$1, j + 1);
    } else {
      ranges.add((j, j + 1));
    }
  }
  return i == q.length ? ranges : const [];
}

/// A command palette standing on a page: `>` and a field, then [commands]
/// ranked as the query is typed, grouped under their [DesignCommand.group],
/// each with its matched letters lit and its [DesignCommand.shortcut] at
/// the end. Up and Down move the highlight (the pointer moves it too),
/// Return runs it. Open one over the screen with [showTermCommandPalette].
///
/// ```dart
/// TermCommandPalette(
///   commands: [
///     DesignCommand(label: 'deploy to staging', group: 'deploy', onPressed: deploy),
///     DesignCommand(label: 'open the runs', group: 'go', shortcut: 'M-2', onPressed: openRuns),
///   ],
/// )
/// ```
///
/// The behaviour (ranking, keys, focus, what a screen reader hears) is
/// ui_core's `DesignCommandPalette`.
class TermCommandPalette extends StatefulWidget {
  /// A palette of [commands].
  const TermCommandPalette({
    super.key,
    required this.commands,
    this.onSelected,
    this.hintText = 'type a command',
    this.emptyText = 'no command matches',
    this.title = 'commands',
    this.maxLines = 10,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.raised = false,
    this.style,
  }) : assert(maxLines > 0);

  /// Overrides for the rows, over the theme's [TermThemeData.menuStyle]:
  /// `fill` (the cursor on the lit row) and `foreground` (the words). The
  /// frame is a [TermPane]'s, styled by [TermThemeData.paneStyle].
  final TermStyle? style;

  /// The commands, in the order they list with no query.
  final List<DesignCommand> commands;

  /// Takes a chosen command; null runs its own [DesignCommand.onPressed].
  final ValueChanged<DesignCommand>? onSelected;

  /// The dim words while nothing is typed.
  final String hintText;

  /// What it says when nothing matches.
  final String emptyText;

  /// Cut into the frame's top line.
  final String title;

  /// The most lines of results before they scroll.
  final int maxLines;

  /// The query's text: the caller's to dispose; null: the palette's own.
  final TextEditingController? controller;

  /// The field's focus: the caller's to dispose; null: the palette's own.
  final FocusNode? focusNode;

  /// Whether the field takes focus once built: true over a screen, false
  /// standing on a page.
  final bool autofocus;

  /// Whether it stands over the screen: filled and shaded, as
  /// [showTermCommandPalette] shows it.
  final bool raised;

  @override
  State<TermCommandPalette> createState() => _TermCommandPaletteState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('commands', commands.length))
      ..add(StringProperty('title', title))
      ..add(IntProperty('maxLines', maxLines, defaultValue: 10))
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'))
      ..add(FlagProperty('raised', value: raised, ifTrue: 'raised'));
  }
}

class _TermCommandPaletteState extends State<TermCommandPalette> {
  TextEditingController? _own;
  TextEditingController get _text =>
      widget.controller ?? (_own ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _text.addListener(_typed);
  }

  @override
  void didUpdateWidget(TermCommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_typed);
      _text.addListener(_typed);
    }
  }

  @override
  void dispose() {
    _text.removeListener(_typed);
    _own?.dispose();
    super.dispose();
  }

  void _typed() => setState(() {});

  int get _matching {
    final q = _text.text;
    if (q.trim().isEmpty) return widget.commands.length;
    var n = 0;
    for (final c in widget.commands) {
      if ([c.label, ...c.keywords].any((w) => designMatchScore(w, q) != null)) {
        n++;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final floor = DesignTapTargets.of(context).floorOn();
    final row = grid.ceil(Size(0, floor.height)).height;

    return TermPane(
      title: widget.title,
      trailing: '$_matching/${widget.commands.length}',
      footer: termKeysShown(context) ? '↑↓ move · ⏎ run · esc close' : null,
      focused: true,
      raised: widget.raised,
      padding: TermInset.zero,
      child: DesignCommandPalette(
        commands: widget.commands,
        onSelected: widget.onSelected,
        controller: _text,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        maxHeight: lh * widget.maxLines,
        fieldBuilder: (context, field) =>
            _Field(field: field, hintText: widget.hintText),
        groupBuilder: (context, group) => SizedBox(
          height: lh,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: cw * 2, end: cw),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                group,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.dimStyle,
              ),
            ),
          ),
        ),
        emptyBuilder: (context) => SizedBox(
          height: lh * 2,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: cw * 2, end: cw),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                '${widget.emptyText}: "${_text.text.trim()}"',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.dimStyle,
              ),
            ),
          ),
        ),
        layoutBuilder: (context, field, results) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: lh * 0.5),
            field,
            SizedBox(
              height: lh,
              child: CustomPaint(
                painter: TermRulePainter(
                  color: theme.rule,
                  stroke: termStroke(theme, grid),
                ),
              ),
            ),
            Flexible(child: results),
            SizedBox(height: lh * 0.5),
          ],
        ),
        itemBuilder: (context, command, states) => _Item(
          command: command,
          query: _text.text,
          height: row,
          lit: states.contains(WidgetState.focused),
          enabled: command.enabled,
          own: TermStyleOf([widget.style, theme.menuStyle], states),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.field, required this.hintText});

  final DesignComboboxField field;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final lh = grid.lineHeight;
    final floor = DesignTapTargets.of(context).floorOn();
    final tall = grid.ceil(Size(0, floor.height)).height;
    final pad = (tall - lh) / 2;
    // The field is the whole line, margins and prompt included, so a tap
    // anywhere a screen reader outlines reaches it; the `> ` is drawn over
    // its start and lets taps through.
    return SizedBox(
      height: tall,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: field.controller,
                focusNode: field.focusNode,
                // Return runs the lit command, the palette keeping the
                // focus while none matches: no onSubmitted, whose restarted
                // input would take no more typing in a browser.
                onEditingComplete: field.submit,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.go,
                style: theme.textStyle,
                cursorColor: theme.accent,
                cursorWidth: cw,
                cursorHeight: grid.fontSize * 1.25,
                cursorRadius: Radius.zero,
                decoration:
                    InputDecoration.collapsed(
                      hintText: hintText,
                      hintStyle: theme.dimStyle,
                    ).copyWith(
                      contentPadding: EdgeInsetsDirectional.fromSTEB(
                        cw * 3,
                        pad,
                        cw,
                        pad,
                      ),
                    ),
              ),
            ),
          ),
          PositionedDirectional(
            start: cw,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Align(
                  widthFactor: 1,
                  child: Text(
                    '> ',
                    style: theme.boldStyle.copyWith(color: theme.accent),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.command,
    required this.query,
    required this.height,
    required this.lit,
    required this.enabled,
    required this.own,
  });

  final TermStyleOf own;
  final DesignCommand command;
  final String query;
  final double height;
  final bool lit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final ink = !enabled
        ? theme.rule
        : lit
        ? theme.onAccent
        : own.foreground ?? theme.foreground;
    final words = theme.textStyle.copyWith(color: ink);
    // A matched letter: the accent, bold; on the inverse row, bold and
    // underlined in the row's own ink, so it reads on either ground.
    final hit = lit
        ? words.copyWith(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
            decorationColor: ink,
          )
        : words.copyWith(fontWeight: FontWeight.w700, color: theme.accent);
    final label = command.label;
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end)
        in enabled ? termMatchRanges(label, query) : const <(int, int)>[]) {
      if (start > at) spans.add(TextSpan(text: label.substring(at, start)));
      spans.add(TextSpan(text: label.substring(start, end), style: hit));
      at = end;
    }
    if (at < label.length) spans.add(TextSpan(text: label.substring(at)));

    final shortcut = command.shortcut;
    // A command too long for its row wraps onto whole lines under itself,
    // so two commands that start alike (`deploy atlas-api to staging`, `…
    // to production`) never read the same; the mark and the key keep to
    // its first line.
    final pad = (height - grid.lineHeight) / 2;
    // The highlighted command is the cursor: the row in the accent, a pair
    // of brackets cut out of its end cells.
    return CustomPaint(
      painter: TermCursorPainter(
        grid: grid,
        amount: lit ? 1 : 0,
        color: own.fill ?? theme.accent,
        knockout: theme.onAccent,
        stroke: termStroke(theme, grid),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(cw, pad, cw, pad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: cw,
                child: ExcludeSemantics(
                  child: Text(lit ? '›' : ' ', style: words),
                ),
              ),
              SizedBox(width: cw),
              Expanded(
                child: Text.rich(
                  TextSpan(style: words, children: spans),
                  semanticsLabel: label,
                ),
              ),
              if (shortcut != null && termKeysShown(context)) ...[
                SizedBox(width: cw),
                TermKey(
                  shortcut,
                  style: TermStyle(
                    foreground: WidgetStatePropertyAll(
                      lit ? theme.onAccent : theme.dim,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a [TermCommandPalette] of [commands] over the screen, the screen
/// behind dimmed, at most [cols] cells wide, a quarter of the way down. It
/// comes up in place in a very short fade; a chosen command runs once the
/// palette has closed and focus is back where it was. Escape or a tap
/// outside closes it. Pair it with `DesignCommandShortcut` for `^K`.
///
/// ```dart
/// DesignCommandShortcut(
///   onOpen: () => showTermCommandPalette(context: context, commands: commands),
///   child: app,
/// )
/// ```
Future<void> showTermCommandPalette({
  required BuildContext context,
  required List<DesignCommand> commands,
  String title = 'commands',
  String hintText = 'type a command',
  String emptyText = 'no command matches',
  String? initialQuery,
  int cols = 64,
}) async {
  final theme = TermTheme.of(context);
  final grid = context.termGrid;
  final navigator = Navigator.of(context, rootNavigator: true);
  final themes = InheritedTheme.capture(from: context, to: navigator.context);
  final still = designReduceMotionOf(context);
  final chosen = await navigator.push<DesignCommand>(
    RawDialogRoute<DesignCommand>(
      barrierDismissible: true,
      barrierLabel: DesignLocalizations.of(context).commandPaletteBarrierLabel,
      barrierColor: theme.background.withValues(alpha: 0.72),
      transitionDuration: still ? Duration.zero : TermMotion.screen,
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      ),
      pageBuilder: (routeContext, _, _) => themes.wrap(
        SafeArea(
          child: Align(
            alignment: const Alignment(0, -0.5),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: grid.cellWidth),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: grid.cols(cols)),
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  label: title,
                  child: _RoutePalette(
                    commands: commands,
                    onSelected: (command) =>
                        Navigator.of(routeContext).pop(command),
                    title: title,
                    hintText: hintText,
                    emptyText: emptyText,
                    initialQuery: initialQuery,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  chosen?.onPressed?.call();
}

// The palette over the screen, owning its query's controller.
class _RoutePalette extends StatefulWidget {
  const _RoutePalette({
    required this.commands,
    required this.onSelected,
    required this.title,
    required this.hintText,
    required this.emptyText,
    required this.initialQuery,
  });

  final List<DesignCommand> commands;
  final ValueChanged<DesignCommand> onSelected;
  final String title;
  final String hintText;
  final String emptyText;
  final String? initialQuery;

  @override
  State<_RoutePalette> createState() => _RoutePaletteState();
}

class _RoutePaletteState extends State<_RoutePalette> {
  // The caret after the words it opens with, as a prompt has it: typing
  // goes on from them rather than replacing them.
  late final _query = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.initialQuery ?? '',
      selection: TextSelection.collapsed(
        offset: widget.initialQuery?.length ?? 0,
      ),
    ),
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TermCommandPalette(
    commands: widget.commands,
    onSelected: widget.onSelected,
    title: widget.title,
    hintText: widget.hintText,
    emptyText: widget.emptyText,
    controller: _query,
    autofocus: true,
    raised: true,
  );
}
