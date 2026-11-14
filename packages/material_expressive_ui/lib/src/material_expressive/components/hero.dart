/// The hero: [ExpressiveHeroMoment], the scope every opt-in hero widget requires
/// and the expression budget counts (CONTRACT §3). No vocabulary role of its
/// own. Owner: w1-host.
///
/// CONTRACT §3's opt-in hero moments — L/XL buttons, library-shape masks on
/// images, avatars and metrics, emphasized display and headline type,
/// vibrant menus, wavy progress, the large flexible app bar with imagery,
/// the FAB menu, the container transform — each assert an [ExpressiveHeroMoment]
/// above them in debug builds ([ExpressiveHeroMoment.debugCheck]). A page spends
/// at most one hero moment and an app no more than its theme's
/// `expression` allows (calm none, balanced one, bold two); the source law
/// that counts hero pages against the budget reads
/// [ExpressiveHeroMoment.countOn] and the `ExpressiveHeroMoment(` call sites.
library;

import 'package:flutter/widgets.dart';

/// One hero moment: the scope a hero widget requires. Wrap the one place on
/// a page that spends the app's expression — the primary action's L/XL
/// button, a shaped hero image, the FAB menu — and nothing else.
///
/// Heroes do not nest (one moment is one moment); a page's heroes are
/// counted on its route ([countOn]).
class ExpressiveHeroMoment extends StatefulWidget {
  /// A hero scope around [child].
  const ExpressiveHeroMoment({required this.child, this.label, super.key});

  /// The hero moment.
  final Widget child;

  /// What the moment is, for the budget's report (`primary action`,
  /// `cover art`); optional.
  final String? label;

  /// The hero scope above [context], or null outside any.
  static ExpressiveHeroMomentScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ExpressiveHeroMomentScope>();

  /// Whether [context] is inside a hero moment.
  static bool isInside(BuildContext context) => maybeOf(context) != null;

  /// Asserts, in debug builds, that [widget] (a hero widget's name, such as
  /// `ExpressiveButton (XL)`) renders inside an [ExpressiveHeroMoment]. Call it
  /// from the hero widget's `build`: `assert(ExpressiveHeroMoment.debugCheck(
  /// context, 'ExpressiveButton (XL)'));`. Always true in release.
  static bool debugCheck(BuildContext context, String widget) {
    assert(() {
      if (maybeOf(context) == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            '$widget is a hero widget outside an ExpressiveHeroMoment.',
          ),
          ErrorDescription(
            'Hero widgets spend the app\'s expression budget (CONTRACT §3): '
            'at most one hero moment per page, and no more per app than the '
            'theme\'s expression allows.',
          ),
          ErrorHint(
            'Wrap the one hero moment on this page in ExpressiveHeroMoment, or use '
            'the non-hero variant.',
          ),
          context.describeElement('The hero widget was'),
        ]);
      }
      return true;
    }());
    return true;
  }

  static final Expando<List<_HeroEntry>> _heroesByRoute =
      Expando<List<_HeroEntry>>('ExpressiveHeroMoment');

  static final List<_HeroEntry> _unrouted = <_HeroEntry>[];

  /// How many hero moments are mounted on [route] now (every
  /// [ExpressiveHeroMoment] below it, on screen or not): the per-page count the
  /// budget's gallery lint and tests read. A null [route] counts the heroes
  /// mounted outside any route.
  static int countOn(Route<Object?>? route) =>
      route == null ? _unrouted.length : (_heroesByRoute[route]?.length ?? 0);

  /// The labels of the hero moments mounted on [route] (null for unlabelled
  /// ones), in mount order.
  static List<String?> labelsOn(Route<Object?>? route) =>
      <_HeroEntry>[...?(route == null ? _unrouted : _heroesByRoute[route])]
          .map((entry) => entry.label)
          .toList(growable: false);

  /// How many hero moments are mounted on the page (route) that holds
  /// [context].
  static int countOnPageOf(BuildContext context) =>
      countOn(ModalRoute.of(context));

  @override
  State<ExpressiveHeroMoment> createState() => _ExpressiveHeroMomentState();
}

class _ExpressiveHeroMomentState extends State<ExpressiveHeroMoment> {
  Route<Object?>? _route;
  bool _counted = false;
  late final _HeroEntry _entry = _HeroEntry(widget.label);

  List<_HeroEntry> _listFor(Route<Object?>? route) => route == null
      ? ExpressiveHeroMoment._unrouted
      : (ExpressiveHeroMoment._heroesByRoute[route] ??= <_HeroEntry>[]);

  @override
  void didUpdateWidget(ExpressiveHeroMoment oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.label = widget.label;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    assert(() {
      if (ExpressiveHeroMoment.maybeOf(context) != null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
            'ExpressiveHeroMoment inside another ExpressiveHeroMoment.',
          ),
          ErrorDescription('One hero moment is one ExpressiveHeroMoment.'),
          context.describeElement('The inner ExpressiveHeroMoment was'),
        ]);
      }
      return true;
    }());
    final route = ModalRoute.of(context);
    if (_counted && route == _route) return;
    _uncount();
    _route = route;
    _listFor(route).add(_entry);
    _counted = true;
  }

  void _uncount() {
    if (!_counted) return;
    _listFor(_route).remove(_entry);
    _counted = false;
  }

  @override
  void dispose() {
    _uncount();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ExpressiveHeroMomentScope._(label: widget.label, child: widget.child);
}

/// The mounted scope of one [ExpressiveHeroMoment]: what a hero widget finds
/// above it.
class ExpressiveHeroMomentScope extends InheritedWidget {
  const ExpressiveHeroMomentScope._({
    required this.label,
    required super.child,
  });

  /// The moment's label, if its [ExpressiveHeroMoment] gave one.
  final String? label;

  @override
  bool updateShouldNotify(ExpressiveHeroMomentScope oldWidget) =>
      label != oldWidget.label;
}

/// One mounted hero moment, as its route's count holds it.
class _HeroEntry {
  _HeroEntry(this.label);

  String? label;
}
