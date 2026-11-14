/// The frame the package example's apps (Habits, Issues, Orders) stand in:
/// the whole window, the app's own navigation for the width (the bar on a
/// phone, the rail from [KitApp.railFrom], a sidebar with the app's name from
/// [KitApp.sidebarFrom]), each tab its own route stack, and one quiet
/// Gallery control that leads back to the gallery and carries the
/// appearance and Customize, so a preset can be tried on the app.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One destination of an app: its tab, and the root page the tab opens.
typedef KitAppDestination = ({MinimalNavItem item, WidgetBuilder root});

/// The way out of an app, which the example sets.
@immutable
class KitGalleryLink {
  /// Back to the gallery with [onBack]; [onAppearance] flips light and dark
  /// ([dark] says which shows); [onCustomize] opens the Customize panel.
  const KitGalleryLink({
    required this.onBack,
    required this.dark,
    required this.onAppearance,
    required this.onCustomize,
  });

  final VoidCallback onBack;
  final bool dark;
  final VoidCallback onAppearance;
  final ValueChanged<BuildContext> onCustomize;
}

/// An app of the example, filling the window.
class KitApp extends StatefulWidget {
  /// The app [name], its [destinations], [gallery] the way out.
  const KitApp({
    super.key,
    required this.name,
    required this.destinations,
    required this.gallery,
    this.initial = 0,
  });

  final String name;
  final List<KitAppDestination> destinations;

  /// The way out; null (the app shown inside a gallery page) shows none.
  final KitGalleryLink? gallery;

  /// The tab the app opens on.
  final int initial;

  /// From this wide the tabs stand in a rail at the start edge (a tablet).
  static const double railFrom = MinimalLayout.compact;

  /// From this wide they stand in a sidebar under the app's name (a laptop).
  static const double sidebarFrom = MinimalLayout.expanded;

  /// The Gallery control for a root page's bar on a phone, where neither a
  /// rail nor a sidebar carries it; null elsewhere, and off a root.
  static Widget? leading(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_KitAppScope>();
    final link = scope?.link;
    if (scope == null || link == null || !scope.barred) return null;
    if (!(ModalRoute.of(context)?.isFirst ?? true)) return null;
    return KitGalleryButton(link: link);
  }

  @override
  State<KitApp> createState() => _KitAppState();
}

class _KitAppState extends State<KitApp> {
  late int _index = widget.initial;
  late final List<GlobalKey<NavigatorState>> _keys = [
    for (final _ in widget.destinations) GlobalKey<NavigatorState>(),
  ];
  late final List<_Depth> _depths = [
    for (final _ in widget.destinations) _Depth(),
  ];

  @override
  void initState() {
    super.initState();
    for (final depth in _depths) {
      depth.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final depth in _depths) {
      depth
        ..removeListener(_changed)
        ..dispose();
    }
    super.dispose();
  }

  /// Opens tab [i]; the current tab's again returns it to its root.
  void _select(int i) {
    if (i == _index) {
      _keys[i].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _index = i);
  }

  Widget _pages() => IndexedStack(
    index: _index,
    children: [
      for (final (i, d) in widget.destinations.indexed)
        HeroControllerScope.none(
          child: Navigator(
            key: _keys[i],
            observers: [_depths[i]],
            onGenerateRoute: (settings) =>
                MaterialPageRoute<void>(settings: settings, builder: d.root),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final items = [for (final d in widget.destinations) d.item];
      if (box.maxWidth < KitApp.railFrom) return _barred(context, items);
      final sidebar = box.maxWidth >= KitApp.sidebarFrom;
      final t = context.minimalTheme;
      return _KitAppScope(
        link: widget.gallery,
        barred: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: t.card,
              child: SafeArea(
                right: false,
                child: sidebar
                    ? MinimalNavigationDrawer(
                        sections: [
                          MinimalNavigationSection(destinations: items),
                        ],
                        selectedIndex: _index,
                        onDestinationSelected: _select,
                        header: _header(context),
                      )
                    : MinimalNavigationRail(
                        destinations: items,
                        selectedIndex: _index,
                        onDestinationSelected: _select,
                        leading: widget.gallery == null
                            ? null
                            : KitGalleryButton(link: widget.gallery!),
                      ),
              ),
            ),
            // Its own semantics node: each tab's route barrier blocks the
            // semantics painted before it, and the rail paints first.
            Expanded(child: Semantics(container: true, child: _pages())),
          ],
        ),
      );
    },
  );

  /// The sidebar's head: the app's name, and the Gallery control at its end.
  Widget _header(BuildContext context) {
    final t = context.minimalTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        MinimalSpacing.s8,
        MinimalSpacing.s8,
        0,
        MinimalSpacing.s8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(widget.name, style: t.h3),
            ),
          ),
          if (widget.gallery case final link?) KitGalleryButton(link: link),
        ],
      ),
    );
  }

  /// The phone's form: the bar along the bottom edge, gone while a page is
  /// pushed on the current tab, as the look's shell does it.
  Widget _barred(BuildContext context, List<MinimalNavItem> items) {
    final bar = MinimalNavigationBar.heightIn(
      MediaQuery.paddingOf(context).bottom,
    );
    final shown = _depths[_index].depth <= 1;
    return _KitAppScope(
      link: widget.gallery,
      barred: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MinimalShellInsets(allowance: shown ? bar : 0, child: _pages()),
          if (shown)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MinimalNavigationBar(
                items: items,
                selectedIndex: _index,
                onDestinationSelected: _select,
              ),
            ),
        ],
      ),
    );
  }
}

/// A list and the page of the row it opens: side by side where both have
/// room (the open row marked), the page pushed on the tab where they don't.
class KitListAndDetail extends StatefulWidget {
  const KitListAndDetail({
    super.key,
    required this.initial,
    required this.list,
    required this.detail,
    required this.parent,
    this.listWidth = 400,
  });

  /// The row open beside the list when the app opens wide.
  final String initial;

  /// The list, its [open] row marked (null on a phone), [onOpen] opening one.
  final Widget Function(String? open, ValueChanged<String> onOpen) list;

  /// The page of row [id]; [parent] names the list for a pushed page's way
  /// back, null beside it.
  final Widget Function(String id, String? parent) detail;
  final String parent;

  /// The list's width beside the page.
  final double listWidth;

  /// The least a page beside its list keeps: a phone's width and more.
  static const double detailMin = 440;

  /// Whether [width] holds a list [listWidth] wide and its page beside it.
  static bool sideBySide(double width, double listWidth) =>
      width >= listWidth + detailMin;

  @override
  State<KitListAndDetail> createState() => _KitListAndDetailState();
}

class _KitListAndDetailState extends State<KitListAndDetail> {
  late String _open = widget.initial;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _build(
      context,
      wide: KitListAndDetail.sideBySide(box.maxWidth, widget.listWidth),
    ),
  );

  Widget _build(BuildContext context, {required bool wide}) {
    final list = widget.list(
      wide ? _open : null,
      (id) => wide
          ? setState(() => _open = id)
          : Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => widget.detail(id, widget.parent),
              ),
            ),
    );
    if (!wide) return list;
    final t = context.minimalTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: widget.listWidth, child: list),
        MinimalDivider.vertical(space: t.hairline),
        Expanded(
          child: KeyedSubtree(
            key: ValueKey(_open),
            child: widget.detail(_open, null),
          ),
        ),
      ],
    );
  }
}

/// How many pages stand on a tab's stack.
class _Depth extends NavigatorObserver with ChangeNotifier {
  int depth = 0;
  bool _gone = false;

  void _moved(int by) {
    depth += by;
    // The navigator reports during its own build: tell the frame after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gone) notifyListeners();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _moved(1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _moved(-1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _moved(-1);

  @override
  void dispose() {
    _gone = true;
    super.dispose();
  }
}

class _KitAppScope extends InheritedWidget {
  const _KitAppScope({
    required this.link,
    required this.barred,
    required super.child,
  });

  final KitGalleryLink? link;
  final bool barred;

  @override
  bool updateShouldNotify(_KitAppScope old) =>
      link != old.link || barred != old.barred;
}

/// The one way out of an app: a quiet icon button whose menu leads back to
/// the gallery, flips the appearance and opens Customize.
class KitGalleryButton extends StatelessWidget {
  const KitGalleryButton({super.key, required this.link});

  final KitGalleryLink link;

  @override
  Widget build(BuildContext context) => MinimalMenu.button(
    LucideIcons.layoutGrid,
    label: 'Gallery',
    items: [
      MinimalMenuItem(
        'Back to the gallery',
        icon: LucideIcons.arrowLeft,
        onPressed: link.onBack,
      ),
      MinimalMenuItem(
        link.dark ? 'Light appearance' : 'Dark appearance',
        icon: link.dark ? LucideIcons.sun : LucideIcons.moon,
        startsGroup: true,
        onPressed: link.onAppearance,
      ),
      MinimalMenuItem(
        'Customize',
        icon: LucideIcons.slidersHorizontal,
        onPressed: () => link.onCustomize(context),
      ),
    ],
  );
}
