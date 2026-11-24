/// A command palette, headless: a search field over grouped commands,
/// ranked as the query is typed. Focus stays in the field: Up and Down move
/// the highlight (and wrap), Enter runs it, Escape closes the palette and
/// focus goes back where it was. [showRawCommandPalette] opens it modal;
/// [RawCommandShortcut] opens it on Ctrl+K or Cmd+K.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'combobox.dart';
import 'form_field.dart';
import 'internal/announce.dart';
import 'internal/option_list.dart';
import 'internal/painted_barrier.dart';
import 'localizations.dart';
import 'motion.dart';
import 'pressable.dart';

/// A command in a palette.
@immutable
class RawCommand {
  /// A command [label]led, in [group], that [onPressed] runs.
  const RawCommand({
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
int? rawMatchScore(String text, String query) {
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

/// A palette's list, as [RawCommandPalette.layoutBuilder] lays it out.
typedef RawPaletteLayoutBuilder = Widget Function(
  BuildContext context,
  Widget field,
  Widget results,
);

/// The palette's body: the field over the results. Put it in a route with
/// [showRawCommandPalette], or anywhere (a sidebar's search).
///
/// ```dart
/// RawCommandPalette(commands: const [RawCommand(label: 'New file')], fieldBuilder: (context, field) => EditableText(controller: field.controller, focusNode: field.focusNode, style: const TextStyle(), cursorColor: const Color(0xFF000000), backgroundCursorColor: const Color(0xFF808080), onEditingComplete: field.submit), itemBuilder: (context, command, states) => Text(command.label))
/// ```
class RawCommandPalette extends StatefulWidget {
  /// A palette of [commands].
  const RawCommandPalette({
    super.key,
    required this.commands,
    required this.fieldBuilder,
    required this.itemBuilder,
    this.onSelected,
    this.groupBuilder,
    this.emptyBuilder,
    this.layoutBuilder,
    this.score = rawMatchScore,
    this.maxHeight = 360,
    this.semanticLabel,
    this.resultsMessage,
    this.controller,
    this.focusNode,
    this.autofocus = true,
  }) : assert(maxHeight > 0);

  /// The commands, in the order they list with no query.
  final List<RawCommand> commands;

  /// Paints the search field ([RawComboboxField.submit], its input's
  /// `onEditingComplete`, runs the highlighted command).
  final RawComboboxFieldBuilder fieldBuilder;

  /// Paints a command; [WidgetState.focused] marks the highlighted one.
  final Widget Function(
    BuildContext context,
    RawCommand command,
    Set<WidgetState> states,
  )
  itemBuilder;

  /// Takes a chosen command; null runs its own [RawCommand.onPressed].
  /// [showRawCommandPalette] closes the route here.
  final ValueChanged<RawCommand>? onSelected;

  /// Paints a group's heading.
  final Widget Function(BuildContext context, String group)? groupBuilder;

  /// Paints "No results"; null: nothing.
  final WidgetBuilder? emptyBuilder;

  /// Lays out the field over the results; null: a column.
  final RawPaletteLayoutBuilder? layoutBuilder;

  /// Ranks a command's words against the query.
  final int? Function(String text, String query) score;

  /// The results' greatest height before they scroll.
  final double maxHeight;

  /// What a screen reader calls the results; null:
  /// [RawWidgetsLocalizations.commandPaletteLabel].
  final String? semanticLabel;

  /// What a screen reader hears when the results change; null:
  /// [RawWidgetsLocalizations.commandPaletteResultsMessage].
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
  State<RawCommandPalette> createState() => _DesignCommandPaletteState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<RawCommand>('commands', commands))
      ..add(
        ObjectFlagProperty<RawComboboxFieldBuilder>.has(
          'fieldBuilder',
          fieldBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<
          Widget Function(
            BuildContext context,
            RawCommand command,
            Set<WidgetState> states,
          )
        >.has('itemBuilder', itemBuilder),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawCommand>>.has(
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
        ObjectFlagProperty<RawPaletteLayoutBuilder>.has(
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

class _DesignCommandPaletteState extends State<RawCommandPalette> {
  TextEditingController? _ownText;
  FocusNode? _ownFocus;
  int _highlight = 0;
  final RawRowReveal _reveal = RawRowReveal();
  // The list row last brought into view for the highlight.
  int _shownRow = -1;
  String _query = '';
  late List<RawCommand> _shown = _filter('');
  int? _announcedCount;

  TextEditingController get _text =>
      widget.controller ?? (_ownText ??= TextEditingController());

  FocusNode get _focus =>
      widget.focusNode ??
      (_ownFocus ??= FocusNode(debugLabel: 'RawCommandPalette'));

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
  void didUpdateWidget(RawCommandPalette oldWidget) {
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
  List<RawCommand> _filter(String query) {
    if (query.trim().isEmpty) {
      final order = <String?>[];
      for (final c in widget.commands) {
        if (!order.contains(c.group)) order.add(c.group);
      }
      return [
        for (final g in order) ...widget.commands.where((c) => c.group == g),
      ];
    }
    final scored = <(RawCommand, int)>[];
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
        final words = RawWidgetsLocalizations.of(context);
        rawAnnounce(
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
    rawAnnounce(context, _shown[i].label);
  }

  void _run([RawCommand? command]) {
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
      // The keys alone: no semantics node of its own.
      includeSemantics: false,
      child: Actions(
        actions: {
          _MoveIntent: CallbackAction<_MoveIntent>(
            onInvoke: (intent) => _move(intent.by),
          ),
          _RunIntent: CallbackAction<_RunIntent>(onInvoke: (_) => _run()),
        },
        // A field's node, as a RawInputDecorator's: the words the look draws
        // beside its text field (a "Search" before it) name the text field
        // on its one node, read once.
        child: RawInputDecorator(
          builder: (context, parts) => parts.control,
          child: widget.fieldBuilder(
            context,
            RawComboboxField(
              controller: _text,
              focusNode: _focus,
              submit: _run,
              // The palette's list always shows.
              isOpen: true,
            ),
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
            child: RawButton(
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
          RawWidgetsLocalizations.of(context).commandPaletteLabel,
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
Future<void> showRawCommandPalette({
  required BuildContext context,
  required RawCommandPalette Function(ValueChanged<RawCommand> run) palette,
  Widget Function(BuildContext context, Widget palette)? surfaceBuilder,
  Color barrierColor = const Color(0x66000000),
  RawBarrierBuilder? barrierBuilder,
  String? barrierLabel,
  AlignmentGeometry alignment = const Alignment(0, -0.6),
}) async {
  final chosen = await Navigator.of(context, rootNavigator: true).push(
    _PaletteRoute<RawCommand>(
      barrierPaint: barrierBuilder,
      barrierDismissible: true,
      barrierLabel:
          barrierLabel ??
          RawWidgetsLocalizations.of(context).commandPaletteBarrierLabel,
      barrierColor: barrierBuilder == null ? barrierColor : null,
      transitionDuration: rawReduceMotionOf(context)
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
                  RawWidgetsLocalizations.of(context).commandPaletteLabel,
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

  final RawBarrierBuilder? barrierPaint;

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
/// RawCommandShortcut(onOpen: () {}, child: const SizedBox())
/// ```
class RawCommandShortcut extends StatelessWidget {
  /// [child], with [onOpen] on its keys.
  const RawCommandShortcut({
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

  // CallbackShortcuts' keys, on a Focus that adds no semantics node of its
  // own: CallbackShortcuts' would merge the nodes of the app under it (a
  // heading and the text under it) into one.
  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    includeSemantics: false,
    onKeyEvent: (node, event) {
      var handled = false;
      for (final activator in activators) {
        if (activator.accepts(event, HardwareKeyboard.instance)) {
          onOpen();
          handled = true;
        }
      }
      return handled ? KeyEventResult.handled : KeyEventResult.ignored;
    },
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
