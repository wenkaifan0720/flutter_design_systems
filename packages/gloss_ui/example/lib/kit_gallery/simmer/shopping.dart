/// Simmer's shopping list: what is left lit along a groove, a field to add
/// a thing, then the list by aisle, each aisle a well of checkbox rows.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'data.dart';
import 'planner.dart';
import 'simmer.dart';

/// Where the shopping list stands.
enum SimmerListState {
  /// Synced: the list.
  ready,

  /// Fetching it again.
  loading,

  /// The last sync failed.
  failed,

  /// Nothing planned, so nothing to buy.
  empty,
}

/// The shopping list.
class SimmerShopping extends StatefulWidget {
  /// The shopping list.
  const SimmerShopping({super.key, this.initialState = SimmerListState.ready});

  /// Where the list stands when it opens.
  final SimmerListState initialState;

  @override
  State<SimmerShopping> createState() => _SimmerShoppingState();
}

class _SimmerShoppingState extends State<SimmerShopping> {
  List<SimmerItem> get _items => SimmerFrame.of(context).shoppingItems;
  final TextEditingController _adding = TextEditingController();
  late SimmerListState _state = widget.initialState;
  Timer? _retry;

  @override
  void dispose() {
    _retry?.cancel();
    _adding.dispose();
    super.dispose();
  }

  void _tryAgain() {
    setState(() => _state = SimmerListState.loading);
    _retry = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _state = SimmerListState.ready);
    });
  }

  Widget _stateView(BuildContext context, SimmerListState state) {
    final frame = SimmerFrame.of(context);
    // The state's one gel key is the page's: at the foot in a thumb's reach
    // (in the title strip on a desk), the words in the middle of the page.
    final key = switch (state) {
      SimmerListState.failed => GlossButton.filled(
        'Try again',
        icon: const Icon(LucideIcons.refreshCw),
        onPressed: _tryAgain,
      ),
      SimmerListState.loading => null,
      _ => GlossButton.filled(
        'Plan more dinners',
        icon: const Icon(LucideIcons.calendarDays),
        onPressed: () => frame.push(const SimmerPlanner()),
      ),
    };
    // A state stands in the middle of the whole page, not of the list's
    // reading column.
    return SimmerPage(
      title: 'Shopping list',
      large: true,
      maxWidth: double.infinity,
      bottom: key == null ? null : SimmerKeys(primary: key),
      children: [
        const SizedBox(height: GlossSpacing.huge),
        switch (state) {
          SimmerListState.failed => const GlossStateView(
            state: GlossState.error,
            icon: Icon(LucideIcons.cloudOff),
            title: 'Your list did not load',
            message: 'Simmer could not reach its server to fetch your list. It is kept there; try again once you are\u00A0online.',
          ),
          SimmerListState.loading => const GlossStateView(
            state: GlossState.loading,
            title: 'Syncing your list',
          ),
          _ => const GlossStateView(
            state: GlossState.empty,
            icon: Icon(LucideIcons.shoppingBasket),
            title: 'The list is clear',
            message: 'Everything for this week’s dinners is in the basket. Plan more and Simmer adds them, aisle by aisle.',
          ),
        },
      ],
    );
  }

  void _add() {
    final name = _adding.text.trim();
    if (name.isEmpty) return;
    setState(
      () => _items.add(SimmerItem(name, '1', 'Other', addedByHand: true)),
    );
    _adding.clear();
    showGlossToast(context, 'Added $name');
  }

  @override
  Widget build(BuildContext context) {
    final state = switch (_state) {
      SimmerListState.ready || SimmerListState.empty =>
        _items.isEmpty ? SimmerListState.empty : SimmerListState.ready,
      _ => _state,
    };
    if (state != SimmerListState.ready) return _stateView(context, state);
    final theme = context.glossTheme;
    final t = theme.textTheme;
    final c = theme.colors;
    final bought = _items.where((i) => i.bought).length;
    final aisles = <String>[
      for (final i in _items)
        if (!_items.takeWhile((j) => j != i).any((j) => j.aisle == i.aisle))
          i.aisle,
    ];
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final progress = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$bought', style: t.display.copyWith(color: c.jadeInk)),
            const SizedBox(width: GlossSpacing.small),
            Expanded(
              child: Text(
                'of ${_items.length} in the basket',
                style: t.body.copyWith(color: c.inkSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: GlossSpacing.medium),
        Semantics(
          label: 'Shopping progress',
          value: '$bought of ${_items.length}',
          child: SizedBox(
            height: 12,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: bought / math.max(1, _items.length)),
              duration: MediaQuery.maybeDisableAnimationsOf(context) ?? false
                  ? Duration.zero
                  : const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              // Lit from the start side, whichever that is.
              builder: (context, done, _) => Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: CustomPaint(painter: _GroovePainter(c, done)),
              ),
            ),
          ),
        ),
        const SizedBox(height: GlossSpacing.large),
        GlossTextField(
          controller: _adding,
          hint: 'Add a thing to buy',
          semanticLabel: 'Add a thing to buy',
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _add(),
          prefixIcon: const Icon(LucideIcons.plus),
        ),
      ],
    );
    final wells = [
      for (final (n, aisle) in aisles.indexed) ...[
        if (n > 0) const SizedBox(height: GlossSpacing.large),
        GlossWell(
          header: aisle,
          dividerIndent: GlossListTile.leadingExtent,
          children: [
            for (final item in _items.where((i) => i.aisle == aisle))
              _ItemRow(
                item: item,
                onChanged: (v) => setState(() => item.bought = v),
              ),
          ],
        ),
      ],
    ];
    return SimmerPage(
      title: 'Shopping list',
      large: true,
      maxWidth: wide ? 1000 : GlossMetrics.readingWidth,
      actions: [
        GlossIconButton(
          onPressed: () => showGlossToast(context, 'List shared with Sam'),
          tooltip: 'Share list',
          icon: const Icon(LucideIcons.share2),
        ),
      ],
      children: wide
          ? [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 320, child: progress),
                  const SizedBox(width: GlossSpacing.extraLarge),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: wells,
                    ),
                  ),
                ],
              ),
            ]
          : [progress, simmerGroupGap, ...wells],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onChanged});

  final SimmerItem item;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.glossTheme.colors;
    return SimmerCheckRow(
      value: item.bought,
      onChanged: onChanged,
      title: item.name,
      trailingText: item.amount,
      style: GlossStyle(
        foreground: WidgetStatePropertyAll(item.bought ? c.inkSecondary : null),
        textStyle: WidgetStatePropertyAll(
          item.bought
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: c.inkSecondary,
                )
              : null,
        ),
      ),
    );
  }
}

class _GroovePainter extends CustomPainter {
  _GroovePainter(this.colors, this.done);

  final GlossColors colors;
  final double done;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    paintGlossFace(canvas, rect, GlossFace.well(colors));
    final lit = (done.clamp(0.0, 1.05)) * size.width;
    if (lit > 1) {
      paintGlossFace(
        canvas,
        Rect.fromLTWH(0, 0, math.max(size.height, lit), size.height),
        GlossFace.well(colors).copyWith(
          top: colors.jadeBottom,
          middle: colors.jade,
          bottom: colors.jadeTop,
          shade: const Color(0x80002814),
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_GroovePainter old) =>
      old.colors != colors || old.done != done;
}
