import 'package:material_ui/material_ui.dart';

/// A stack of locations an app without a router keeps: the page each one
/// stands for goes on one `Navigator`'s pages ([PageStackApp]), the root
/// first.
class PageStack extends ChangeNotifier {
  /// A stack standing on [root].
  PageStack([this.root = '/']) : _locations = <String>[root];

  /// The location the stack stands on.
  final String root;

  List<String> _locations;

  /// The locations, the root first.
  List<String> get locations => List<String>.unmodifiable(_locations);

  /// The location on top.
  String get path => _locations.last;

  /// Shows [location] one level off the root, as a router's `go` shows a
  /// child route of the root: the root alone when [location] is the root.
  void go(String location) {
    _locations = <String>[root, if (location != root) location];
    notifyListeners();
  }

  /// Pushes [location] over the top.
  void push(String location) {
    _locations = <String>[..._locations, location];
    notifyListeners();
  }

  void _removeAt(int index) {
    _locations = <String>[..._locations]..removeAt(index);
    notifyListeners();
  }
}

/// A `MaterialApp` whose one navigator stands [stack]'s pages, each from
/// [page] keyed by its location (or by its own key), and wrapped by
/// [builder] (the host). A page's pop removes its location; the system
/// back reaches the navigator through [WidgetsBindingObserver.didPopRoute],
/// as a router's back button dispatcher brings it.
class PageStackApp extends StatefulWidget {
  /// An app showing [stack].
  const PageStackApp({
    required this.stack,
    required this.page,
    required this.builder,
    super.key,
  });

  /// The locations shown.
  final PageStack stack;

  /// The page a location stands for.
  final Page<void> Function(String location, LocalKey key) page;

  /// Wraps the navigator: the host, the media.
  final Widget Function(BuildContext context, Widget navigator) builder;

  @override
  State<PageStackApp> createState() => _PageStackAppState();
}

class _PageStackAppState extends State<PageStackApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  List<Page<void>> _pages = const <Page<void>>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<bool> didPopRoute() async =>
      await _navigator.currentState?.maybePop() ?? false;

  void _removed(Page<Object?> page) {
    final index = _pages.indexWhere(
      (p) => identical(p, page) || p.key == page.key,
    );
    if (index >= 0) widget.stack._removeAt(index);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.stack,
    builder: (context, _) {
      _pages = <Page<void>>[
        for (final location in widget.stack._locations)
          widget.page(location, ValueKey<String>(location)),
      ];
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, _) => widget.builder(
          context,
          Navigator(key: _navigator, pages: _pages, onDidRemovePage: _removed),
        ),
      );
    },
  );
}
