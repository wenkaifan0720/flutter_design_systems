/// Shared host for the Ledger gallery's demo screens and catalog specimens,
/// and the Keel pilot's sample owner, tabs and figures they show.
///
/// Every demo renders inside the environment a Ledger page gets live: a
/// MaterialApp under [LedgerHost], themed by the preset the lab applied
/// (theme.dart's [kitPreset]), with the appearance pinned explicitly because
/// the preview host ignores the shell's simulated platform brightness, and
/// the owner's account ([kitMaren]) above the navigator as an app mounts it.
///
/// The words and figures are the sample data's: the owner, the moment
/// (Wednesday, October 28, 7:40 PM), the accounts and their balances.
///
/// Demos import ONLY the Ledger barrel, this file, Flutter and the
/// packages Ledger depends on.
library;

import 'package:flutter/material.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'keel.dart';
import 'theme.dart';

export 'keel.dart';

/// The pilot's moment: `now` in the sample data.
final DateTime kitNow = DateTime(2026, 10, 28, 19, 40);

/// A demo screen: a scrolling nav root titled [title], with labelled
/// sections, one per variant or state. [footer] pins a widget under the
/// scroll (an action bar); [body] replaces the sections for demos that own
/// their layout. No date eyebrow: a part page is pushed in Quill, where its
/// crumb stands in the eyebrow's place.
Widget kitScreen({
  required Brightness brightness,
  required String title,
  List<Widget> sections = const [],
  Widget? body,
  Widget? footer,
}) {
  assert(body == null || sections.isEmpty, 'sections or body, not both');
  return _kitApp(
    brightness: brightness,
    home: LedgerScreen(
      topBar: LedgerTopBar(title: title),
      footer: footer,
      body:
          body ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final section in sections) ...[
                section,
                const LedgerGap(LedgerSpacing.s32),
              ],
            ],
          ),
    ),
  );
}

/// A demo that is its own whole surface (a route stack): the themed app
/// around exactly the widget the demo builds.
Widget kitSurface({required Brightness brightness, required Widget child}) =>
    _kitApp(brightness: brightness, home: child);

/// The density every gallery page is set at; null keeps the preset's (the
/// platform's). A test sets it to read each page under each density.
LedgerDensity? kitDensity;

LedgerThemeData _atKitDensity(LedgerThemeData t) {
  final density = kitDensity;
  return density == null || t.density == density
      ? t
      : t.copyWith(density: density);
}

/// The preset's light and dark themes, for demos that mount their own host
/// (a [LedgerPreview]).
LedgerThemeData kitTheme(Brightness brightness) =>
    _atKitDensity(LedgerThemeData.preset(kitPreset, brightness));

Widget _kitApp({required Brightness brightness, required Widget home}) =>
    Builder(
      builder: (context) => LedgerTheme.maybeOf(context) != null
          // A page opened inside an app that already hosts the look (Quill's
          // index of parts) is one of its pages: that app's host, navigator
          // and density, so a sheet or a dialog it raises covers the whole
          // window, the side bar too, not only the frame's body.
          ? LedgerAccountScope(account: kitMaren, child: home)
          : MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Keel',
              builder: (context, child) => LedgerHost(
                light: kitTheme(Brightness.light),
                dark: kitTheme(Brightness.dark),
                brightness: brightness,
                child: LedgerAccountScope(
                  account: kitMaren,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
              home: home,
            ),
    );

/// One labelled variant band inside a demo screen: its name in the label's
/// capitals over the ink rule, as the source heads a section.
Widget kitSection(String label, {required List<Widget> children}) => Builder(
  builder: (context) {
    final t = context.ledgerTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.headRule)),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: LedgerSpacing.s10),
            child: Text(label.toUpperCase(), style: t.label),
          ),
        ),
        const LedgerGap(LedgerSpacing.s16),
        // Keyed by its label, so a review can find the section's parts.
        KeyedSubtree(
          key: ValueKey<String>('kit-section:$label'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: LedgerSpacing.s16,
            children: children,
          ),
        ),
        const LedgerGap(LedgerSpacing.s16),
      ],
    );
  },
);

/// A row of demo children that wraps instead of overflowing the phone.
Widget kitRow(List<Widget> children) => Wrap(
  spacing: LedgerSpacing.s12,
  runSpacing: LedgerSpacing.s12,
  crossAxisAlignment: WrapCrossAlignment.center,
  children: children,
);

/// A demo that is its own routed app (a shell over a go_router): the themed
/// app around [router], the owner's account above it.
Widget kitRouterApp({
  required Brightness brightness,
  required RouterConfig<Object> router,
}) => MaterialApp.router(
  debugShowCheckedModeBanner: false,
  title: 'Keel',
  routerConfig: router,
  builder: (context, child) => LedgerHost(
    light: kitTheme(Brightness.light),
    dark: kitTheme(Brightness.dark),
    brightness: brightness,
    child: LedgerAccountScope(
      account: kitMaren,
      child: child ?? const SizedBox.shrink(),
    ),
  ),
);

/// [child] as a route of [register] draws it (a pushed page's bar, a sheet
/// page's head), for a still that stands on no route of its own.
Widget kitInRegister(RoutePresentation register, Widget child) =>
    RoutePresentationScope(presentation: register, child: child);

/// Keel's five root tabs (the source's NAV), Move in the middle drawn as
/// the green disc; the sidebar's green act says its act, Move money, as the
/// source's does.
const List<LedgerNavItem> keelTabs = [
  LedgerNavItem(LucideIcons.house, 'Home'),
  LedgerNavItem(LucideIcons.chartPie, 'Spending'),
  LedgerNavItem.act(LucideIcons.arrowRightLeft, 'Move', actLabel: 'Move money'),
  LedgerNavItem(LucideIcons.target, 'Goals'),
  LedgerNavItem(LucideIcons.creditCard, 'Cards'),
];

/// The owner, as the pilot's chrome draws her (the sample data's person; one
/// notification unread). Her profile, notifications and search are pages
/// the gallery doesn't have, so they open nothing; they're still given, as
/// an app gives them, so the avatar, the bell and the search pill draw live.
const kitMaren = LedgerAccount(
  name: 'Maren Holt',
  initials: 'MH',
  meta: 'Since Mar 2023',
  unread: 1,
  onProfilePressed: _openNothing,
  onNotificationsPressed: _openNothing,
  searchHint: 'Search activity',
  onSearchPressed: _openNothing,
);

void _openNothing(BuildContext context) {}

/// How wide a part stands on the source's 1440 desktop: its board is 12
/// columns, 24 apart, across the 1080 the sidebar leaves (`.board`): the
/// main block on 8 (712), a half of it on 4 (344), the ruled margin's 4
/// less its 32 inset (312), or the whole board (1080).
enum KitSpan {
  main(712),
  half(344),
  margin(312),
  full(1080);

  const KitSpan(this.desk);

  /// The width from 1024 wide, in logical px.
  final double desk;
}

/// [child] at the width the source's desktop board gives it ([span]), set
/// at the start, from 1024 wide; across the column on a phone. The gallery
/// draws each part at the source's own width so its desktop shots compare
/// one to one.
Widget kitSpan(KitSpan span, Widget child) => Builder(
  builder: (context) => LedgerLayout.isWide(context)
      ? Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: span.desk, child: child),
        )
      : child,
);

/// A fact of the pilot's as the ledger states it: a sum in its dollars and
/// cents, or its words.
LedgerFact kitFact(KitFact f) {
  final tone = f.green
      ? LedgerTone.moneyIn
      : f.over
      ? LedgerTone.over
      : LedgerTone.plain;
  return switch (f.amount) {
    final amount? => LedgerFact.money(
      f.label,
      amount,
      note: f.note,
      showSign: f.sign,
      showCents: f.cents != null,
      tone: tone,
    ),
    null => LedgerFact(f.label, f.value, note: f.note, tone: tone),
  };
}

/// A count in words as the source writes one: "no" to
/// "ten", the digits beyond; [cap] capitalizes it ("Three goals").
String kitWord(int n, {bool cap = false}) {
  const words = [
    'no', 'one', 'two', 'three', 'four', 'five', //
    'six', 'seven', 'eight', 'nine', 'ten',
  ];
  final w = n >= 0 && n < words.length ? words[n] : '$n';
  return cap ? '${w[0].toUpperCase()}${w.substring(1)}' : w;
}

/// A specimen whose field holds words ([text]): it owns the controller it
/// hands [builder], as a page's state would.
class KitTyped extends StatefulWidget {
  const KitTyped(this.text, this.builder, {super.key});

  final String text;
  final Widget Function(TextEditingController controller) builder;

  @override
  State<KitTyped> createState() => _KitTypedState();
}

class _KitTypedState extends State<KitTyped> {
  late final _controller = TextEditingController(text: widget.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// Where a catalog specimen sits on its stage (the specimen's `frame` in
/// metadata.yaml names the same band): the bottom or top edge, a band across
/// the middle, or the whole phone.
class KitFrame {
  const KitFrame.bottom(double this.height) : _place = _KitPlace.bottom;
  const KitFrame.top(double this.height) : _place = _KitPlace.top;
  const KitFrame.band(double this.height) : _place = _KitPlace.band;
  const KitFrame.screen() : height = null, _place = _KitPlace.screen;

  /// The band's height in logical px; null for the whole phone.
  final double? height;
  final _KitPlace _place;
}

enum _KitPlace { bottom, top, band, screen }

/// The stage a catalog specimen renders on: the host themed by [style] (a
/// preset resolved at runtime, so one compile draws every preset) in
/// [brightness], on the page ground, the owner's account above it, with
/// [child] placed by [frame]. A specimen builder never names a style: the
/// stage decides it.
Widget kitSpecimenStage({
  required String style,
  required Brightness brightness,
  required KitFrame frame,
  required Widget child,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Keel',
  builder: (context, home) => LedgerHost(
    light: _atKitDensity(LedgerThemeData.preset(style, Brightness.light)),
    dark: _atKitDensity(LedgerThemeData.preset(style, Brightness.dark)),
    brightness: brightness,
    child: LedgerAccountScope(
      account: kitMaren,
      child: home ?? const SizedBox.shrink(),
    ),
  ),
  home: _KitStage(frame: frame, child: child),
);

class _KitStage extends StatelessWidget {
  const _KitStage({required this.frame, required this.child});

  final KitFrame frame;
  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.ledgerTheme.background,
    child: switch (frame._place) {
      _KitPlace.bottom => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, bottom: 0, child: child)],
      ),
      _KitPlace.top => Stack(
        fit: StackFit.expand,
        children: [Positioned(left: 0, right: 0, top: 0, child: child)],
      ),
      // A band sits on the page's own gutter, as it would in a body.
      _KitPlace.band => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LedgerChromeMetrics.gutter,
          ),
          child: child,
        ),
      ),
      _KitPlace.screen => child,
    },
  );
}
