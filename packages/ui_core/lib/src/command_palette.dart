/// A command palette, headless: a search field over grouped commands,
/// ranked as the query is typed. Focus stays in the field: Up and Down move
/// the highlight (and wrap), Enter runs it, Escape closes the palette and
/// focus goes back where it was. [showDesignCommandPalette] opens it modal;
/// [DesignCommandShortcut] opens it on Ctrl+K or Cmd+K.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'combobox.dart';
import 'internal/announce.dart';
import 'internal/option_list.dart';
import 'internal/painted_barrier.dart';
import 'localizations.dart';
import 'motion.dart';
import 'pressable.dart';

/// A command in a palette.
@immutable
class DesignCommand {
  /// A command [label]led, in [group], that [onPressed] runs.
  const DesignCommand({
    required this.label,
    this.onPressed,
    this.group,
    this.keywords = const [],
    this.shortcut,
    this.enabled = true,
    this.data,
  });

  /// Its name.
  final String label;

  /// Runs it, after the palette closed.
  final VoidCallback? onPressed;

  /// The heading it is listed under; null: the first, unheaded group.
  final String? group;

  /// Other words that find it.
  final List<String> keywords;

  /// Its key, for the look to show ("⌘S").
  final String? shortcut;

  /// Whether it can run.
  final bool enabled;

  /// Anything the look needs to paint it (an icon).
  final Object? data;
}

/// How well [query] finds [text]: null not at all, higher better. A prefix
/// beats a word's start, which beats a substring, which beats the letters
/// in order.
int? designMatchScore(String text, String query) {
  final t = text.toLowerCase();
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return 0;
  if (t.startsWith(q)) return 400 - t.length;
  final at = t.indexOf(q);
  if (at > 0) {
    final before = t.codeUnitAt(at - 1);
    final wordStart = !_isWordChar(before);
    return (wordStart ? 300 : 200) - at;
  }
  var i = 0;
  var gaps = 0;
  for (var j = 0; j < t.length && i < q.length; j++) {
    if (t.codeUnitAt(j) == q.codeUnitAt(i)) {
      i++;
    } else if (i > 0) {
      gaps++;
    }
  }
  return i == q.length ? 100 - gaps : null;
}

bool _isWordChar(int c) =>
    (c >= 0x30 && c <= 0x39) || (c >= 0x61 && c <= 0x7a) || c > 0x7f;

/// A palette's list, as [DesignCommandPalette.layoutBuilder] lays it out.
typedef DesignPaletteLayoutBuilder = Widget Function(
  BuildContext context,
  Widget field,
  Widget results,
);

/// The palette's body: the field over the results. Put it in a route with
/// [showDesignCommandPalette], or anywhere (a sidebar's search).
///
/// ```dart
/// DesignCommandPalette(commands: const [DesignCommand(label: 'New file')], fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080), onEditingComplete: field.submit), itemBuilder: (context, command, states) => Text(command.label))
/// ```
class DesignCommandPalette extends StatefulWidget {
  /// A palette of [commands].
  const DesignCommandPalette({
    super.key,
    required this.commands,
    required this.fieldBuilder,
    required this.itemBuilder,
    this.onSelected,
    this.groupBuilder,
    this.emptyBuilder,
    this.layoutBuilder,
    this.score = designMatchScore,
    this.maxHeight = 360,
    this.semanticLabel,
    this.resultsMessage,
    this.controller,
    this.focusNode,
    this.autofocus = true,
  }) : assert(maxHeight > 0);

  /// The commands, in the order they list with no query.
  final List<DesignCommand> commands;

  /// Paints the search field ([DesignComboboxField.submit], its input's
  /// `onEditingComplete`, runs the highlighted command).
  final DesignComboboxFieldBuilder fieldBuilder;

  /// Paints a command; [WidgetState.focused] marks the highlighted one.
  final Widget Function(
    BuildContext context,
    DesignCommand command,
    Set<WidgetState> states,
  )
  itemBuilder;

  /// Takes a chosen command; null runs its own [DesignCommand.onPressed].
  /// [showDesignCommandPalette] closes the route here.
  final ValueChanged<DesignCommand>? onSelected;

  /// Paints a group's heading.
  final Widget Function(BuildContext context, String group)? groupBuilder;

  /// Paints "No results"; null: nothing.
  final WidgetBuilder? emptyBuilder;

  /// Lays out the field over the results; null: a column.
  final DesignPaletteLayoutBuilder? layoutBuilder;

  /// Ranks a command's words against the query.
  final int? Function(String text, String query) score;

  /// The results' greatest height before they scroll.
  final double maxHeight;

  /// What a screen reader calls the results; null:
  /// [DesignLocalizations.commandPaletteLabel].
  final String? semanticLabel;

  /// What a screen reader hears when the results change; null:
  /// [DesignLocalizations.commandPaletteResultsMessage].
  final String Function(int count)? resultsMessage;

  /// The field's text. The caller's, who disposes it; null: the palette
  /// makes its own and disposes it.
  final TextEditingController? controller;

  /// The field's focus.
  ///
  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Whether the field takes focus once it is built: true for a palette opened over the page, false for one that
  /// stands inline on a page and waits to be reached.
  final bool autofocus;

  @override
  State<DesignCommandPalette> createState() => _DesignCommandPaletteState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<DesignCommand>('commands', commands))
      ..add(
        ObjectFlagProperty<DesignComboboxFieldBuilder>.has(
          'fieldBuilder',
          fieldBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            DesignCommand command,
            Set<WidgetState> states,
          )
        >.has('itemBuilder', itemBuilder),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<DesignCommand>>.has(
          'onSelected',
          onSelected,
        ),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(BuildContext context, String group)
        >.has('groupBuilder', groupBuilder),
      )
      ..add(ObjectFlagProperty<WidgetBuilder>.has('emptyBuilder', emptyBuilder))
      ..add(
        ObjectFlagProperty<DesignPaletteLayoutBuilder>.has(
          'layoutBuilder',
          layoutBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<int? Function(String text, String query)>.has(
          'score',
          score,
        ),
      )
      ..add(DoubleProperty('maxHeight', maxHeight, defaultValue: 360))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(int count)>.has(
          'resultsMessage',
          resultsMessage,
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
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifFalse: 'autofocus: false',
          defaultValue: true,
        ),
      );
  }
}

class _MoveIntent extends Intent {
  const _MoveIntent(this.by);

  final int by;
}

class _RunIntent extends Intent {
  const _RunIntent();
}

class _DesignCommandPaletteState extends State<DesignCommandPalette> {
  TextEditingController? _ownText;
  FocusNode? _ownFocus;
  int _highlight = 0;
  final DesignRowReveal _reveal = DesignRowReveal();
  // The list row last brought into view for the highlight.
  int _shownRow = -1;
  String _query = '';
  late List<DesignCommand> _shown = _filter('');
  int? _announcedCount;

  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'DesignCommandPalette'));

  @override
  void initState() {
    super.initState();
    _text.addListener(_changed);
    _highlight = _firstEnabled(0, 1) ?? 0;
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(DesignCommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownText)?.removeListener(_changed);
      _text.addListener(_changed);
    }
    _shown = _filter(_query);
  }

  @override
  void dispose() {
    _text.removeListener(_changed);
    _ownText?.dispose();
    _ownFocus?.dispose();
    _reveal.dispose();
    super.dispose();
  }

  // Groups keep their first appearance's order; with a query, each group's
  // commands rank by score and groups by their best.
  List<DesignCommand> _filter(String query) {
    if (query.trim().isEmpty) {
      final order = <String?>[];
      for (final c in widget.commands) {
        if (!order.contains(c.group)) order.add(c.group);
      }
      return [
        for (final g in order) ...widget.commands.where((c) => c.group == g),
      ];
    }
    final scored = <(DesignCommand, int)>[];
    for (final c in widget.commands) {
      int? best;
      for (final words in [c.label, ...c.keywords]) {
        final s = widget.score(words, query);
        if (s != null && (best == null || s > best)) best = s;
      }
      if (best != null) scored.add((c, best));
    }
    final groupBest = <String?, int>{};
    for (final (c, s) in scored) {
      final b = groupBest[c.group];
      if (b == null || s > b) groupBest[c.group] = s;
    }
    final groups = groupBest.keys.toList()
      ..sort((a, b) => groupBest[b]!.compareTo(groupBest[a]!));
    return [
      for (final g in groups)
        ...(scored.where((e) => e.$1.group == g).toList()
              ..sort((a, b) => b.$2.compareTo(a.$2)))
            .map((e) => e.$1),
    ];
  }

  void _changed() {
    if (_text.text == _query) return;
    setState(() {
      _query = _text.text;
      _shown = _filter(_query);
      _highlight = _firstEnabled(0, 1) ?? 0;
      _reveal.forget();
    });
    final n = _shown.length;
    if (n != _announcedCount) {
      _announcedCount = n;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final words = DesignLocalizations.of(context);
        designAnnounce(
          context,
          (widget.resultsMessage ?? words.commandPaletteResultsMessage)(n),
        );
      });
    }
  }

  int? _firstEnabled(int from, int by) {
    final n = _shown.length;
    for (var k = 0; k < n; k++) {
      final i = (from + by * k) % n;
      if (_shown[i].enabled) return i;
    }
    return null;
  }

  void _move(int by) {
    if (_shown.isEmpty) return;
    final i = _firstEnabled((_highlight + by) % _shown.length, by);
    if (i == null) return;
    setState(() => _highlight = i);
    designAnnounce(context, _shown[i].label);
  }

  void _run([DesignCommand? command]) {
    final c =
        command ?? (_highlight < _shown.length ? _shown[_highlight] : null);
    if (c == null || !c.enabled) return;
    final selected = widget.onSelected;
    if (selected != null) {
      selected(c);
    } else {
      c.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.enter): _RunIntent(),
        SingleActivator(LogicalKeyboardKey.numpadEnter): _RunIntent(),
      },
      child: Actions(
        actions: {
          _MoveIntent: CallbackAction<_MoveIntent>(
            onInvoke: (intent) => _move(intent.by),
          ),
          _RunIntent: CallbackAction<_RunIntent>(onInvoke: (_) => _run()),
        },
        child: widget.fieldBuilder(
          context,
          DesignComboboxField(
            controller: _text,
            focusNode: _focus,
            submit: _run,
          ),
        ),
      ),
    );
    final items = <Widget>[];
    var litRow = -1;
    String? group;
    for (var i = 0; i < _shown.length; i++) {
      final c = _shown[i];
      final heading = c.group;
      if (heading != null && (i == 0 || heading != group)) {
        items.add(
          Semantics(
            header: true,
            child: widget.groupBuilder?.call(context, heading) ?? Text(heading),
          ),
        );
      }
      group = heading;
      final lit = i == _highlight;
      if (lit) litRow = items.length;
      items.add(
        _reveal.row(
          items.length,
          MouseRegion(
            onHover: (_) {
              if (_highlight != i && c.enabled) setState(() => _highlight = i);
            },
            child: DesignPressable(
              onPressed: c.enabled ? () => _run(c) : null,
              semanticSelected: lit,
              builder: (context, states, _) => widget.itemBuilder(context, c, {
                ...states,
                if (lit) WidgetState.focused,
              }),
            ),
          ),
        ),
      );
    }
    // Every move of the highlight keeps its row in view.
    if (litRow != _shownRow) {
      _shownRow = litRow;
      _reveal.reveal(litRow);
    }
    final Widget results = items.isEmpty
        ? (widget.emptyBuilder?.call(context) ?? const SizedBox.shrink())
        : ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: ExcludeFocus(
              child: ListView(
                controller: _reveal.controller,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: items,
              ),
            ),
          );
    final list = Semantics(
      container: true,
      explicitChildNodes: true,
      label:
          widget.semanticLabel ??
          DesignLocalizations.of(context).commandPaletteLabel,
      child: results,
    );
    return widget.layoutBuilder?.call(context, field, list) ??
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            field,
            Flexible(child: list),
          ],
        );
  }
}

/// Opens [palette] in a modal route over a barrier; [surfaceBuilder]
/// paints the panel around it. A command runs after the route has closed
/// and focus is back where it was.
///
/// The barrier is [barrierColor], or [barrierBuilder]'s painting (a look's
/// own screen, as its other modals wear) when given.
Future<void> showDesignCommandPalette({
  required BuildContext context,
  required DesignCommandPalette Function(ValueChanged<DesignCommand> run)
  palette,
  Widget Function(BuildContext context, Widget palette)? surfaceBuilder,
  Color barrierColor = const Color(0x66000000),
  DesignBarrierBuilder? barrierBuilder,
  String? barrierLabel,
  AlignmentGeometry alignment = const Alignment(0, -0.6),
}) async {
  final chosen = await Navigator.of(context, rootNavigator: true).push(
    _PaletteRoute<DesignCommand>(
      barrierPaint: barrierBuilder,
      barrierDismissible: true,
      barrierLabel:
          barrierLabel ??
          DesignLocalizations.of(context).commandPaletteBarrierLabel,
      barrierColor: barrierBuilder == null ? barrierColor : null,
      transitionDuration: designReduceMotionOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 150),
      transitionBuilder: (context, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (context, _, _) {
        final body = palette((c) => Navigator.of(context).pop(c));
        return SafeArea(
          child: Align(
            alignment: alignment,
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label:
                  body.semanticLabel ??
                  DesignLocalizations.of(context).commandPaletteLabel,
              child: surfaceBuilder?.call(context, body) ?? body,
            ),
          ),
        );
      },
    ),
  );
  chosen?.onPressed?.call();
}

// showGeneralDialog's route, its barrier painted by a look when it gives a
// builder. The field is not named barrierBuilder: Flutter 3.50 gave
// RawDialogRoute a barrierBuilder of its own type, and a field of that name
// here stops ui_core compiling there.
class _PaletteRoute<T> extends RawDialogRoute<T> {
  _PaletteRoute({
    required this.barrierPaint,
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.transitionDuration,
    super.transitionBuilder,
  });

  final DesignBarrierBuilder? barrierPaint;

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    final paint = barrierPaint;
    return paint == null ? barrier : paintedBarrier(paint, animation!, barrier);
  }
}

/// Opens a palette from anywhere under it on [activators] (Ctrl+K and
/// Cmd+K).
///
/// ```dart
/// DesignCommandShortcut(onOpen: () {}, child: const SizedBox())
/// ```
class DesignCommandShortcut extends StatelessWidget {
  /// [child], with [onOpen] on its keys.
  const DesignCommandShortcut({
    super.key,
    required this.onOpen,
    required this.child,
    this.activators = const [
      SingleActivator(LogicalKeyboardKey.keyK, control: true),
      SingleActivator(LogicalKeyboardKey.keyK, meta: true),
    ],
  });

  /// Opens the palette.
  final VoidCallback onOpen;

  /// The app, or the part of it the keys work in.
  final Widget child;

  /// The keys.
  final List<ShortcutActivator> activators;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {for (final a in activators) a: onOpen},
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ObjectFlagProperty<VoidCallback>.has('onOpen', onOpen))
      ..add(
        IterableProperty<ShortcutActivator>(
          'activators',
          activators,
          defaultValue: const <ShortcutActivator>[
            SingleActivator(LogicalKeyboardKey.keyK, control: true),
            SingleActivator(LogicalKeyboardKey.keyK, meta: true),
          ],
        ),
      );
  }
}
