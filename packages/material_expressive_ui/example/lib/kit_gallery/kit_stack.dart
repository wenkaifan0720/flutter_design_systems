/// The gallery's live-app frame on a plain `Navigator`: a demo that runs a
/// stack of pages — a page pushed off a root, a sheet raised over it — the
/// way an app without a router runs, so it travels with the package's
/// example. Each page stands for a location (`/entry/tide-pools`) and is
/// keyed by it.
library;

import 'package:flutter/material.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import 'kit.dart';

/// The page [location] stands for, keyed by [key].
typedef KitPageBuilder = Page<void> Function(String location, LocalKey key);

/// A live app of the [initial] pages and those pushed over them, on one
/// `Navigator`'s pages: [KitStack.push] adds a location, a page's back (its
/// arrow, the system back, a swipe) removes it. The system back reaches the
/// navigator through [WidgetsBindingObserver.didPopRoute], as a router's
/// back button dispatcher would bring it.
class KitStack extends StatefulWidget {
  /// A stack starting at [initial], each location's page from [page].
  const KitStack({
    required this.brightness,
    required this.page,
    this.initial = const <String>['/'],
    super.key,
  });

  /// The brightness the app runs in.
  final Brightness brightness;

  /// Makes the page a location stands for.
  final KitPageBuilder page;

  /// The locations the app opens on, the root (the stack's floor) first.
  final List<String> initial;

  /// Pushes the page [location] stands for over the nearest stack.
  static void push(BuildContext context, String location) =>
      context.findAncestorStateOfType<_KitStackState>()!._push(location);

  @override
  State<KitStack> createState() => _KitStackState();
}

class _KitStackState extends State<KitStack> with WidgetsBindingObserver {
  // A live page opens on its root alone: in the example app a tab that
  // opened under a raised sheet hid the page it named behind a scrim. The
  // static sheets (goldens, screenshots) keep every initial page raised.
  late List<String> _locations =
      context.getInheritedWidgetOfExactType<KitLiveViewport>() != null
      ? <String>[widget.initial.first]
      : <String>[...widget.initial];
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();

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

  void _push(String location) =>
      setState(() => _locations = <String>[..._locations, location]);

  void _removed(Page<Object?> page) {
    final key = page.key;
    if (key is! ValueKey<String>) return;
    setState(
      () => _locations = <String>[
        for (final location in _locations)
          if (location != key.value) location,
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PreviewFrame(
    platform: kitPlatform,
    brightness: widget.brightness,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      // The stack's own app reads in the page's direction (its English
      // locale would turn a right-to-left page's demo left to right).
      builder: (inner, _) => Directionality(
        textDirection:
            Directionality.maybeOf(context) ?? Directionality.of(inner),
        child: kitHost(
          brightness: widget.brightness,
          child: Navigator(
            key: _navigator,
            pages: <Page<void>>[
              for (final location in _locations)
                widget.page(location, ValueKey<String>(location)),
            ],
            onDidRemovePage: _removed,
          ),
        ),
      ),
    ),
  );
}
