/// The options list a combobox and a tag input show under their field, the
/// keys that move its highlight, and the reveal that keeps the highlighted
/// row in view. Inside ui_core; not exported.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../combobox.dart';
import '../localizations.dart';
import '../pressable.dart';
import 'announce.dart';
import 'back.dart';
import 'quiet_focus.dart';

/// An option taken from the list, as a [RawAutocomplete]'s `onSelected` gets
/// it: a new object each time, so the autocomplete never skips an option it
/// took before (it compares with the last), and always closes the list.
class DesignPick {
  /// Takes [option].
  DesignPick(this.option);

  /// The option taken.
  final Object option;
}

/// ui_core's keys over a [RawAutocomplete]'s options list, in place of the
/// autocomplete's own, which clamp at the ends, move on the key that opens a
/// closed list, and start on the first option.
///
/// Up and Down move round past the ends; Page Up and Down move four and stop
/// at the ends; Ctrl or Cmd with an arrow goes to the first or the last. All
/// of them pass over a disabled option. On a closed list each opens it
/// without moving, and its highlight starts where the list's `start` says (a
/// combobox's value). Home, End and letters stay with the text.
class DesignListKeys {
  _KeyedRows? _list;
  bool _shown = false;
  BuildContext? _field;
  ModalRoute<Object?>? _route;

  /// Whether a list of options is on screen.
  bool get isOpen => _list != null && _shown;

  /// Wraps the text field so arrows move its highlight and a hardware Enter
  /// accepts it. An active input-method composition keeps its Enter key.
  Widget field(TextEditingController controller, Widget child) => Builder(
    builder: (context) {
      _field = context;
      final route = ModalRoute.of(context);
      if (!identical(route, _route)) {
        _route = route;
        _syncBack();
      }
      return Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: _focusChanged,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent ||
              (event.logicalKey != LogicalKeyboardKey.enter &&
                  event.logicalKey != LogicalKeyboardKey.numpadEnter) ||
              !controller.value.composing.isCollapsed ||
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed ||
              HardwareKeyboard.instance.isAltPressed ||
              HardwareKeyboard.instance.isShiftPressed) {
            return KeyEventResult.ignored;
          }
          return submit() ? KeyEventResult.handled : KeyEventResult.ignored;
        },
        child: Actions(actions: _actions, child: child),
      );
    },
  );

  // The autocomplete opens its list as the field gains focus. Focus given
  // back by ui_core (a closed popover's) is not the user's: the list closes
  // again before it is built, and Down, a press or typing opens it.
  void _focusChanged(bool focused) {
    if (!focused || !DesignQuietFocus.isRestoring) return;
    // After the autocomplete has heard the focus too.
    scheduleMicrotask(() {
      final field = _field;
      if (field == null || !field.mounted) return;
      // Its list shows while one of its arrows can move a highlight.
      const shows = AutocompleteNextOptionIntent();
      if (!(_autocomplete(shows)?.isEnabled(shows) ?? false)) return;
      _shown = false;
      _syncBack();
      Actions.maybeInvoke<Intent>(field, const DismissIntent());
    });
  }

  // While the list is open, the field's route holds this: a system back
  // (Android's button or gesture) closes the list as Escape does, focus
  // staying in the field, and the page stays; the next back pops the page.
  late final DesignBackHold _back = DesignBackHold(() {
    const intent = DismissIntent();
    final field = _field;
    if (!isOpen || field == null || !field.mounted) return;
    if (!(_autocomplete(intent)?.isEnabled(intent) ?? false)) return;
    _shown = false;
    _syncBack();
    Actions.maybeInvoke<Intent>(field, intent);
  });

  void _syncBack() => isOpen ? _back.hold(_route) : _back.release();

  /// Takes the highlighted option, and says whether a list was open to take
  /// it from (none is taken when every option is disabled).
  bool submit() {
    final list = _list;
    if (list == null || !_shown) return false;
    list._takeHighlighted();
    return true;
  }

  /// Notes that the list closes: an option was taken.
  void closed() {
    _shown = false;
    _syncBack();
  }

  /// Closes the list the autocomplete shows, from inside it: a search found
  /// nothing to show. Call it only while the list is built (else the
  /// autocomplete passes the dismissal on to the page).
  void hide() {
    final field = _field;
    if (field == null || !field.mounted) return;
    _shown = false;
    _syncBack();
    Actions.maybeInvoke<Intent>(field, const DismissIntent());
  }

  late final Map<Type, Action<Intent>> _actions = {
    AutocompleteNextOptionIntent: _ListKeyAction<AutocompleteNextOptionIntent>(
      this,
      (l) => l._step(1),
    ),
    AutocompletePreviousOptionIntent:
        _ListKeyAction<AutocompletePreviousOptionIntent>(
          this,
          (l) => l._step(-1),
        ),
    AutocompleteFirstOptionIntent:
        _ListKeyAction<AutocompleteFirstOptionIntent>(
          this,
          (l) => l._edge(last: false),
        ),
    AutocompleteLastOptionIntent: _ListKeyAction<AutocompleteLastOptionIntent>(
      this,
      (l) => l._edge(last: true),
    ),
    AutocompleteNextPageOptionIntent:
        _ListKeyAction<AutocompleteNextPageOptionIntent>(
          this,
          (l) => l._page(_pageSize),
        ),
    AutocompletePreviousPageOptionIntent:
        _ListKeyAction<AutocompletePreviousPageOptionIntent>(
          this,
          (l) => l._page(-_pageSize),
        ),
    DismissIntent: _DismissAction(this),
  };

  // RawAutocomplete's page.
  static const int _pageSize = 4;

  // The autocomplete's own action for [intent], under which these keys sit.
  Action<Intent>? _autocomplete(Intent intent) {
    final field = _field;
    if (field == null || !field.mounted) return null;
    return Actions.maybeFind<Intent>(field, intent: intent);
  }

  void _attach(_KeyedRows list) {
    _list = list;
    _shown = true;
    _syncBack();
  }

  void _detach(_KeyedRows list) {
    if (identical(_list, list)) _list = null;
    _syncBack();
  }
}

class _ListKeyAction<I extends Intent> extends ContextAction<I> {
  _ListKeyAction(this.keys, this.move);

  final DesignListKeys keys;
  final void Function(_KeyedRows list) move;

  // Open: these keys move it. Closed: as the autocomplete's, which opens it
  // when it has options.
  @override
  bool isEnabled(I intent, [BuildContext? context]) =>
      keys.isOpen || (keys._autocomplete(intent)?.isEnabled(intent) ?? false);

  @override
  bool consumesKey(I intent) => isEnabled(intent);

  @override
  Object? invoke(I intent, [BuildContext? context]) {
    final list = keys._list;
    if (list != null && keys._shown) {
      move(list);
      return null;
    }
    // The autocomplete's action opens the list (and moves a highlight of its
    // own, which no list reads); its highlight starts where it should.
    final field = keys._field;
    if (field == null || !field.mounted) return null;
    Actions.maybeInvoke<Intent>(field, intent);
    if (list != null) {
      // Hidden and shown again within a frame: it stayed built.
      keys._shown = true;
      keys._syncBack();
      list._restart();
    }
    return null;
  }
}

// Escape: the autocomplete's, which hides the list (or passes it on when none
// shows); the keys note that the list closes.
class _DismissAction extends ContextAction<DismissIntent> {
  _DismissAction(this.keys);

  final DesignListKeys keys;

  @override
  bool isEnabled(DismissIntent intent, [BuildContext? context]) =>
      keys._autocomplete(intent)?.isEnabled(intent) ?? false;

  @override
  Object? invoke(DismissIntent intent, [BuildContext? context]) {
    keys._shown = false;
    keys._syncBack();
    final field = keys._field;
    return field == null || !field.mounted
        ? null
        : Actions.maybeInvoke<Intent>(field, intent);
  }
}

/// A scrolling list of options with a keyboard highlight: what a combobox
/// and a tag input show under their field, as a [RawAutocomplete]'s options
/// view. [keys] move the highlight; the item under it scrolls into view and
/// is announced.
class DesignOptionList<T extends Object> extends StatefulWidget {
  /// A list of [options]; a tap or Enter on an enabled one calls
  /// [onSelected].
  const DesignOptionList({
    super.key,
    required this.keys,
    required this.options,
    required this.start,
    required this.onSelected,
    required this.value,
    required this.isOptionEnabled,
    required this.highlightFollowsPointer,
    required this.displayStringForOption,
    required this.optionBuilder,
    required this.surfaceBuilder,
    required this.maxHeight,
    required this.semanticLabel,
  });

  /// The keys that move the highlight and take the highlighted option.
  final DesignListKeys keys;

  /// The options shown.
  final List<T> options;

  /// Where the highlight starts, when the list opens and when its options
  /// change: an index into [options], or -1 for none.
  final int start;

  /// Takes an option.
  final ValueChanged<T> onSelected;

  /// The option already taken, shown as [WidgetState.selected].
  final T? value;

  /// Whether an option can be taken; null: all can.
  final bool Function(T option)? isOptionEnabled;

  /// Whether a pointer moving over an option that can be taken highlights
  /// it: one place for the pointer and the keys, no option
  /// [WidgetState.hovered].
  final bool highlightFollowsPointer;

  /// An option's text, for the announcement.
  final String Function(T option) displayStringForOption;

  /// Paints one option.
  final DesignOptionBuilder<T> optionBuilder;

  /// Paints the surface around the list.
  final DesignListSurfaceBuilder? surfaceBuilder;

  /// The list's greatest height.
  final double maxHeight;

  /// What a screen reader calls the list.
  final String? semanticLabel;

  @override
  State<DesignOptionList<T>> createState() => _OptionListState<T>();
}

// What the keys move through: a list's options, or a failed search's one
// row ("Try again").
abstract class _KeyedRows {
  void _step(int by);
  void _edge({required bool last});
  void _page(int by);
  void _takeHighlighted();
  void _restart();
}

class _OptionListState<T extends Object> extends State<DesignOptionList<T>>
    implements _KeyedRows {
  late int _highlighted = widget.start;
  int? _announced;

  final DesignRowReveal _reveal = DesignRowReveal();
  // The row last brought into view for the highlight.
  late int _shownRow = _highlighted;

  @override
  void initState() {
    super.initState();
    widget.keys._attach(this);
    // Opened: the chosen option in view, else the highlighted one.
    final value = widget.value;
    final chosen = value == null ? -1 : widget.options.indexOf(value);
    _reveal.reveal(chosen >= 0 ? chosen : _highlighted);
  }

  @override
  void didUpdateWidget(DesignOptionList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.keys, widget.keys)) {
      oldWidget.keys._detach(this);
      widget.keys._attach(this);
    }
    if (!listEquals(oldWidget.options, widget.options)) {
      _highlighted = widget.start;
      _reveal.forget();
    }
  }

  @override
  void dispose() {
    widget.keys._detach(this);
    _reveal.dispose();
    super.dispose();
  }

  int get _count => widget.options.length;

  bool _enabled(int i) =>
      widget.isOptionEnabled?.call(widget.options[i]) ?? true;

  void _moveTo(int index) {
    if (index != _highlighted) setState(() => _highlighted = index);
  }

  @override
  void _restart() => _moveTo(widget.start);

  // Up and Down: the next enabled option that way, round past the ends.
  @override
  void _step(int by) {
    var i = _highlighted;
    for (var k = 0; k < _count; k++) {
      i = i < 0 || i >= _count ? (by > 0 ? 0 : _count - 1) : (i + by) % _count;
      if (_enabled(i)) return _moveTo(i);
    }
  }

  // Ctrl or Cmd with an arrow: the first or the last enabled option.
  @override
  void _edge({required bool last}) {
    for (var k = 0; k < _count; k++) {
      final i = last ? _count - 1 - k : k;
      if (_enabled(i)) return _moveTo(i);
    }
  }

  // Page Up and Down: [by] options on, stopping at the ends, onto the
  // nearest enabled option (on past it, else back).
  @override
  void _page(int by) {
    if (_count == 0) return;
    final to = (_highlighted < 0 ? 0 : _highlighted + by).clamp(0, _count - 1);
    final on = by > 0 ? 1 : -1;
    for (var i = to; i >= 0 && i < _count; i += on) {
      if (_enabled(i)) return _moveTo(i);
    }
    for (var i = to - on; i >= 0 && i < _count; i -= on) {
      if (_enabled(i)) return _moveTo(i);
    }
  }

  @override
  void _takeHighlighted() {
    final i = _highlighted;
    if (i >= 0 && i < _count && _enabled(i)) {
      widget.onSelected(widget.options[i]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = _highlighted < _count ? _highlighted : -1;
    if (_announced != highlighted && highlighted >= 0 && _announced != null) {
      final message = widget.displayStringForOption(
        widget.options[highlighted],
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) designAnnounce(context, message);
      });
    }
    _announced = highlighted;
    // Every move of the highlight keeps its row in view.
    if (highlighted != _shownRow) {
      _shownRow = highlighted;
      _reveal.reveal(highlighted);
    }
    final list = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: ListView.builder(
        controller: _reveal.controller,
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: _count,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final lit = index == highlighted;
          final enabled = _enabled(index);
          final follows = widget.highlightFollowsPointer;
          Widget item = DesignPressable(
            onPressed: enabled ? () => widget.onSelected(option) : null,
            selected: option == widget.value,
            semanticSelected: option == widget.value,
            builder: (context, states, _) =>
                widget.optionBuilder(context, option, {
                  ...follows
                      ? states.difference(const {WidgetState.hovered})
                      : states,
                  if (lit) WidgetState.focused,
                }),
          );
          // The pointer's moves, not a row scrolled under a resting
          // pointer (the keys scroll the list), move the highlight; leaving
          // the list leaves it where it is.
          if (follows && enabled) {
            item = MouseRegion(onHover: (_) => _moveTo(index), child: item);
          }
          return _reveal.row(index, item);
        },
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: widget.surfaceBuilder?.call(context, list) ?? list,
    );
  }
}

/// Keeps a lazy list's highlighted row fully in view: the list scrolls by
/// [controller], each row is laid out through [row], and [reveal] brings a
/// row into view whether it is built or not. A lazy list builds no row past
/// its viewport and cache, so a row cannot reveal itself: an unbuilt row is
/// first scrolled to where the rows measured so far put it, then shown
/// exactly once it is built. Only the list moves, not the scrollables
/// around it (a command palette on a page).
class DesignRowReveal {
  /// The list's scrolling.
  final ScrollController controller = ScrollController();

  final Map<int, _RevealRowState> _rows = {};
  final Map<int, double> _extents = {};
  int _ticket = 0;

  /// Releases [controller].
  void dispose() => controller.dispose();

  /// The list's row at [index], laid out as [child].
  Widget row(int index, Widget child) =>
      _RevealRow(reveal: this, index: index, child: child);

  /// Forgets the rows' heights: the list's rows changed.
  void forget() => _extents.clear();

  /// Brings row [index] fully into view after this frame; a later call
  /// takes over.
  void reveal(int index) {
    if (index < 0) return;
    final ticket = ++_ticket;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _bring(index, ticket, 8))
      ..ensureVisualUpdate();
  }

  void _bring(int index, int ticket, int tries) {
    if (ticket != _ticket || !controller.hasClients) return;
    final position = controller.position;
    for (final MapEntry(:key, :value) in _rows.entries) {
      final box = value.context.findRenderObject();
      if (box is RenderBox && box.hasSize) _extents[key] = box.size.height;
    }
    final row = _rows[index]?.context.findRenderObject();
    if (row is RenderBox && row.attached && row.hasSize) {
      position
          .ensureVisible(
            row,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          )
          .ignore();
      position
          .ensureVisible(
            row,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          )
          .ignore();
      return;
    }
    if (tries == 0) return;
    final to = _offsetOf(index)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if (to != position.pixels) position.jumpTo(to);
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => _bring(index, ticket, tries - 1))
      ..ensureVisualUpdate();
  }

  // Where row [index] starts: the rows before it, at their measured heights,
  // the rows not yet built at the mean of those measured.
  double _offsetOf(int index) {
    final mean = _extents.isEmpty
        ? 0.0
        : _extents.values.reduce((a, b) => a + b) / _extents.length;
    var offset = 0.0;
    for (var i = 0; i < index; i++) {
      offset += _extents[i] ?? mean;
    }
    return offset;
  }
}

class _RevealRow extends StatefulWidget {
  const _RevealRow({
    required this.reveal,
    required this.index,
    required this.child,
  });

  final DesignRowReveal reveal;
  final int index;
  final Widget child;

  @override
  State<_RevealRow> createState() => _RevealRowState();
}

class _RevealRowState extends State<_RevealRow> {
  @override
  void initState() {
    super.initState();
    widget.reveal._rows[widget.index] = this;
  }

  @override
  void didUpdateWidget(_RevealRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index ||
        !identical(oldWidget.reveal, widget.reveal)) {
      _leave(oldWidget);
      widget.reveal._rows[widget.index] = this;
    }
  }

  @override
  void dispose() {
    _leave(widget);
    super.dispose();
  }

  void _leave(_RevealRow row) {
    if (identical(row.reveal._rows[row.index], this)) {
      row.reveal._rows.remove(row.index);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// 0.3.0 overlays: a search's states (debounced, loading, failed).

/// A search as a combobox or a tag input runs it: after its debounce, the
/// latest query's result only (an earlier one that arrives late is
/// dropped), and a failure kept for the list to show.
class DesignSearchRun<T extends Object> extends ChangeNotifier {
  String _query = '';
  bool _loading = false;
  List<T> _found = const [];
  Object? _error;
  StackTrace? _stackTrace;
  int _ticket = 0;
  int _retries = 0;
  Timer? _wait;
  Completer<void>? _waiting;
  DesignOptionSearch<T>? _search;
  bool _dropped = false;
  bool _disposed = false;

  /// The words of the latest search.
  String get query => _query;

  /// Whether the latest search is pending (waiting out its debounce, or
  /// searching).
  bool get loading => _loading;

  /// What the last search that finished found; kept while the next loads.
  List<T> get found => _found;

  /// What the latest search threw, if it failed.
  Object? get error => _error;

  /// Where it threw.
  StackTrace? get stackTrace => _stackTrace;

  /// How many times [retry] ran a search again.
  int get retries => _retries;

  /// Whether a search the list's closing dropped ([drop]) waits to run again
  /// as it opens ([resume]).
  bool get dropped => _dropped;

  /// Searches [query] with [search], after [debounce] when it is given; a
  /// later run, or [drop], drops this one. What it found, or null when it
  /// was dropped or failed (then [error]; with [report] also
  /// [FlutterError.reportError]).
  Future<List<T>?> run(
    String query,
    DesignOptionSearch<T> search, {
    Duration? debounce,
    bool report = false,
  }) async {
    final ticket = ++_ticket;
    _search = search;
    _dropped = false;
    _cancelWait();
    _query = query;
    _loading = true;
    _error = null;
    _stackTrace = null;
    _notify();
    if (debounce != null && debounce > Duration.zero) {
      final waiting = _waiting = Completer<void>();
      _wait = Timer(debounce, () {
        if (!waiting.isCompleted) waiting.complete();
      });
      await waiting.future;
      if (ticket != _ticket) return null;
    }
    try {
      final found = (await search(query)).toList();
      if (ticket != _ticket) return null;
      _found = found;
      _loading = false;
      _notify();
      return found;
    } catch (error, stackTrace) {
      if (ticket != _ticket) return null;
      _error = error;
      _stackTrace = stackTrace;
      _loading = false;
      _notify();
      if (report) _report(error, stackTrace);
      return null;
    }
  }

  /// Runs the latest search again for the same words, at once.
  void retry() {
    final search = _search;
    if (search == null || _disposed) return;
    _retries++;
    unawaited(run(_query, search));
  }

  /// Drops a pending search: the list closed. Nothing is said.
  void drop() {
    _ticket++;
    _cancelWait();
    if (_loading) _dropped = true;
    _loading = false;
  }

  /// Runs a search [drop] dropped again: the list opened again on the same
  /// words.
  void resume() {
    final search = _search;
    if (!_dropped || search == null || _disposed) return;
    unawaited(run(_query, search));
  }

  void _cancelWait() {
    _wait?.cancel();
    _wait = null;
    final waiting = _waiting;
    _waiting = null;
    // A dropped wait ends, so its run returns.
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    drop();
    super.dispose();
  }
}

/// Reports a search's failure where Flutter reports errors: a list with no
/// way to show it closes.
void _report(Object error, StackTrace stackTrace) => FlutterError.reportError(
  FlutterErrorDetails(
    exception: error,
    stack: stackTrace,
    library: 'ui_core',
    context: ErrorDescription('while searching for options'),
  ),
);

/// The list's surface while a search is pending: [builder]'s painting, read
/// as [DesignLocalizations.loadingLabel], as it appears.
Widget designSearchLoading(
  BuildContext context,
  WidgetBuilder builder,
  DesignListSurfaceBuilder? surfaceBuilder,
) {
  final painted = builder(context);
  return Semantics(
    container: true,
    liveRegion: true,
    label: DesignLocalizations.of(context).loadingLabel,
    child: ExcludeSemantics(
      child: surfaceBuilder?.call(context, painted) ?? painted,
    ),
  );
}

/// The list's surface after a search failed: the look's [builder] with a
/// way to try again, which the keys reach as the list's one row (Down moves
/// there, Enter runs [retry]); a screen reader hears
/// [DesignLocalizations.searchFailedMessage] as it appears, and the focus
/// stays in the field.
class DesignSearchFailure extends StatefulWidget {
  /// A failure of [error], with [retry].
  const DesignSearchFailure({
    super.key,
    required this.keys,
    required this.error,
    required this.stackTrace,
    required this.retry,
    required this.builder,
    required this.surfaceBuilder,
  });

  /// The keys that reach "Try again".
  final DesignListKeys keys;

  /// What the search threw.
  final Object error;

  /// Where it threw.
  final StackTrace? stackTrace;

  /// Runs the search again.
  final VoidCallback retry;

  /// Paints the failure.
  final DesignSearchErrorBuilder builder;

  /// Paints the list's surface around it.
  final DesignListSurfaceBuilder? surfaceBuilder;

  @override
  State<DesignSearchFailure> createState() => _SearchFailureState();
}

class _SearchFailureState extends State<DesignSearchFailure>
    implements _KeyedRows {
  bool _lit = false;

  @override
  void initState() {
    super.initState();
    widget.keys._attach(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        designAnnounce(
          context,
          DesignLocalizations.of(context).searchFailedMessage,
        );
      }
    });
  }

  @override
  void didUpdateWidget(DesignSearchFailure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.keys, widget.keys)) {
      oldWidget.keys._detach(this);
      widget.keys._attach(this);
    }
    if (!identical(oldWidget.error, widget.error)) _lit = false;
  }

  @override
  void dispose() {
    widget.keys._detach(this);
    super.dispose();
  }

  // One row: every move lights it.
  void _light() {
    if (_lit) return;
    setState(() => _lit = true);
    designAnnounce(context, DesignLocalizations.of(context).retryButtonLabel);
  }

  @override
  void _step(int by) => _light();

  @override
  void _edge({required bool last}) => _light();

  @override
  void _page(int by) => _light();

  @override
  void _restart() {
    if (_lit) setState(() => _lit = false);
  }

  @override
  void _takeHighlighted() {
    if (_lit) widget.retry();
  }

  @override
  Widget build(BuildContext context) {
    final painted = widget.builder(
      context,
      DesignSearchError(
        error: widget.error,
        stackTrace: widget.stackTrace,
        retry: widget.retry,
        focused: _lit,
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      liveRegion: true,
      label: DesignLocalizations.of(context).searchFailedMessage,
      child: widget.surfaceBuilder?.call(context, painted) ?? painted,
    );
  }
}

/// Keeps a live list's search while it shows, and drops a pending one when
/// it closes.
class DesignSearchScope extends StatefulWidget {
  /// [child], over [run].
  const DesignSearchScope({super.key, required this.run, required this.child});

  /// The search.
  final DesignSearchRun<Object> run;

  /// The list.
  final Widget child;

  @override
  State<DesignSearchScope> createState() => _SearchScopeState();
}

class _SearchScopeState extends State<DesignSearchScope> {
  @override
  void initState() {
    super.initState();
    // After the frame that builds the list: a search notifies as it starts.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.run.resume();
    });
  }

  @override
  void dispose() {
    widget.run.drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
