/// The lists group's demo: the list item in one, two and three lines with
/// every slot, its states (selected, checked, disabled, dragged), segmented
/// sections with single and multiple selection, plain lists with each
/// divider inset and section headers, a live reorderable list, swipe to
/// dismiss and swipe actions, an accordion group, the lazy grid, and
/// dividers — every one live, so press, focus and hover show on the real
/// thing.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The lists group's demo, in [brightness].
Widget kitListsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Lists',
  sections: const <Widget>[
    _Anatomy(),
    _Segmented(),
    _MultiSelect(),
    _States(),
    _Plain(),
    _Reorder(),
    _Swipe(),
    _Accordions(),
    _Grid(),
    _Dividers(),
  ],
);

/// A 56dp leading thumbnail (the list's leading image: small corners).
class _Thumb extends StatelessWidget {
  const _Thumb(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return SizedBox.square(
      dimension: 56,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: t.shapes.small,
          color: t.colors.tertiaryContainer,
        ),
        child: Icon(icon, color: t.colors.onTertiaryContainer),
      ),
    );
  }
}

/// A section's container colour on the demo's `surface` page.
Color _group(BuildContext context) =>
    context.expressiveTheme.colors.surfaceContainer;

class _Anatomy extends StatefulWidget {
  const _Anatomy();

  @override
  State<_Anatomy> createState() => _AnatomyState();
}

class _AnatomyState extends State<_Anatomy> {
  bool _wifi = true;
  bool _starred = false;

  @override
  Widget build(BuildContext context) => kitSection(
    'List item · one, two and three lines',
    children: <Widget>[
      ExpressiveListSection(
        containerColor: _group(context),
        children: <Widget>[
          // The whole row is the toggle (Compose's `ListItem(checked,
          // onCheckedChange)` over a `Switch` with no handler of its own):
          // one target, announced as Wi-Fi and on or off.
          ExpressiveListTile.toggleable(
            title: const Text('Wi-Fi'),
            leading: const Icon(ExpressiveSymbols.wifi),
            trailing: ExpressiveSwitch.mark(value: _wifi),
            value: _wifi,
            onChanged: (v) => setState(() => _wifi = v),
          ),
          ExpressiveListTile(
            title: const Text('Maya Okafor'),
            subtitle: const Text('Sent the Lisbon itinerary'),
            leading: const ExpressiveAvatar(name: 'Maya Okafor'),
            trailing: const Text('9:41'),
            onTap: () {},
          ),
          ExpressiveListTile(
            overline: const Text('Recipe · 25 min'),
            title: const Text('Charred corn salad'),
            subtitle: const Text(
              'Lime, feta and a handful of mint. Serves four as a side.',
            ),
            leading: const _Thumb(ExpressiveSymbols.restaurant),
            trailing: ExpressiveIcon(
              ExpressiveSymbols.star,
              selected: _starred,
            ),
            onTap: () => setState(() => _starred = !_starred),
          ),
          ExpressiveListTile(
            title: const Text('Storage'),
            subtitle: const Text(
              '41 GB of 128 GB used. Photos and videos take the most room; '
              'offloading unused apps frees space without losing their data.',
            ),
            leading: const Icon(ExpressiveSymbols.cloud),
            trailing: const Icon(ExpressiveSymbols.chevronRight),
            onTap: () {},
          ),
        ],
      ),
    ],
  );
}

class _Segmented extends StatefulWidget {
  const _Segmented();

  @override
  State<_Segmented> createState() => _SegmentedState();
}

class _SegmentedState extends State<_Segmented> {
  int _plan = 1;

  static const List<(String, String, IconData)> _plans =
      <(String, String, IconData)>[
        ('Standard', 'Arrives in 4–6 days', ExpressiveSymbols.localShipping),
        ('Express', 'Arrives tomorrow', ExpressiveSymbols.bolt),
        ('Pick up', 'Ready at the Alfama store', ExpressiveSymbols.storefront),
      ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Segmented · single selection',
    children: <Widget>[
      ExpressiveListSection(
        header: 'Delivery',
        footer: 'You can change this until the order ships.',
        containerColor: _group(context),
        children: <Widget>[
          for (var i = 0; i < _plans.length; i++)
            ExpressiveListTile.selectable(
              title: Text(_plans[i].$1),
              subtitle: Text(_plans[i].$2),
              leading: Icon(_plans[i].$3),
              trailing: _plan == i ? const Icon(ExpressiveSymbols.check) : null,
              selected: _plan == i,
              onTap: () => setState(() => _plan = i),
            ),
        ],
      ),
    ],
  );
}

class _MultiSelect extends StatefulWidget {
  const _MultiSelect();

  @override
  State<_MultiSelect> createState() => _MultiSelectState();
}

class _MultiSelectState extends State<_MultiSelect> {
  final Set<String> _packed = <String>{'Passport'};

  static const List<String> _items = <String>[
    'Passport',
    'Charger',
    'Rain jacket',
    'Headphones',
  ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Segmented · multiple selection',
    children: <Widget>[
      ExpressiveListSection(
        containerColor: _group(context),
        children: <Widget>[
          for (final item in _items)
            ExpressiveListTile.toggleable(
              title: Text(item),
              leading: ExpressiveCheckbox.mark(value: _packed.contains(item)),
              value: _packed.contains(item),
              onChanged: (v) =>
                  setState(() => v ? _packed.add(item) : _packed.remove(item)),
            ),
        ],
      ),
    ],
  );
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => kitSection(
    'States',
    children: <Widget>[
      ExpressiveListSection(
        containerColor: _group(context),
        children: <Widget>[
          ExpressiveListTile(
            title: const Text('Enabled'),
            leading: const Icon(ExpressiveSymbols.notifications),
            onTap: () {},
          ),
          ExpressiveListTile.selectable(
            title: const Text('Selected'),
            leading: const Icon(ExpressiveSymbols.notifications),
            selected: true,
            onTap: () {},
          ),
          ExpressiveListTile(
            title: const Text('Disabled'),
            subtitle: const Text('Turn on notifications first'),
            leading: const Icon(ExpressiveSymbols.notificationsOff),
            enabled: false,
            onTap: () {},
          ),
          const ExpressiveListTile(
            title: Text('Dragged'),
            leading: Icon(ExpressiveSymbols.notifications),
            trailing: Icon(ExpressiveSymbols.dragIndicator),
            dragged: true,
          ),
          const ExpressiveListTile(
            title: Text('Static'),
            subtitle: Text('No click: no ripple, no touch target'),
            leading: Icon(ExpressiveSymbols.info),
          ),
        ],
      ),
    ],
  );
}

class _Plain extends StatelessWidget {
  const _Plain();

  @override
  Widget build(BuildContext context) => kitSection(
    'Plain lists · section headers and dividers',
    children: <Widget>[
      ExpressiveListSection(
        segmented: false,
        header: 'Today',
        divider: ExpressiveDividerInset.start,
        children: <Widget>[
          ExpressiveListTile(
            title: const Text('Standup'),
            subtitle: const Text('9:30 · Room 4'),
            leading: const Icon(ExpressiveSymbols.event),
            onTap: () {},
          ),
          ExpressiveListTile(
            title: const Text('Design review'),
            subtitle: const Text('14:00 · Video call'),
            leading: const Icon(ExpressiveSymbols.videocam),
            onTap: () {},
          ),
        ],
      ),
      ExpressiveListSection(
        segmented: false,
        header: 'Tomorrow',
        divider: ExpressiveDividerInset.none,
        children: <Widget>[
          ExpressiveListTile(
            title: const Text('Dentist'),
            trailing: const Text('8:15'),
            onTap: () {},
          ),
          ExpressiveListTile(
            title: const Text('Pick up the bike'),
            trailing: const Text('17:30'),
            onTap: () {},
          ),
        ],
      ),
      ExpressiveListSection(
        segmented: false,
        divider: ExpressiveDividerInset.both,
        children: <Widget>[
          ExpressiveListTile(title: const Text('Middle inset'), onTap: () {}),
          ExpressiveListTile(
            title: const Text('Between both edges'),
            onTap: () {},
          ),
        ],
      ),
    ],
  );
}

class _Reorder extends StatefulWidget {
  const _Reorder();

  @override
  State<_Reorder> createState() => _ReorderState();
}

class _ReorderState extends State<_Reorder> {
  final List<String> _stops = <String>[
    'Belém Tower',
    'LX Factory',
    'Time Out Market',
    'Miradouro da Graça',
  ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Reorderable · drag a handle',
    children: <Widget>[
      ExpressiveReorderableListView(
        containerColor: _group(context),
        itemCount: _stops.length,
        onReorder: (from, to) =>
            setState(() => _stops.insert(to, _stops.removeAt(from))),
        itemBuilder: (context, i) => ExpressiveListTile(
          key: ValueKey<String>(_stops[i]),
          title: Text(_stops[i]),
          subtitle: Text('Stop ${i + 1}'),
          leading: const Icon(ExpressiveSymbols.place),
          trailing: ExpressiveReorderHandle(index: i),
        ),
      ),
    ],
  );
}

class _Swipe extends StatefulWidget {
  const _Swipe();

  @override
  State<_Swipe> createState() => _SwipeState();
}

class _SwipeState extends State<_Swipe> {
  static const List<(String, String)> _all = <(String, String)>[
    ('Studio rent', 'Due Friday'),
    ('Book club', 'Chapter 7 notes'),
    ('Pharmacy', 'Prescription ready'),
  ];

  List<(String, String)> _inbox = List<(String, String)>.of(_all);
  String _last = 'Swipe a row';

  @override
  Widget build(BuildContext context) => kitSection(
    'Swipe to dismiss · swipe actions',
    children: <Widget>[
      ExpressiveListSection(
        containerColor: _group(context),
        children: <Widget>[
          for (final (title, detail) in _inbox)
            ExpressiveSwipeToDismiss(
              key: ValueKey<String>(title),
              onDismissed: (_) => setState(() {
                _inbox = _inbox.where((m) => m.$1 != title).toList();
                _last = 'Deleted $title';
              }),
              child: ExpressiveListTile(
                title: Text(title),
                subtitle: Text(detail),
                leading: const Icon(ExpressiveSymbols.email),
                onTap: () {},
              ),
            ),
          if (_inbox.length < _all.length)
            ExpressiveListTile(
              title: const Text('Restore'),
              leading: const Icon(ExpressiveSymbols.undo),
              onTap: () => setState(() => _inbox = List.of(_all)),
            ),
        ],
      ),
      ExpressiveListSection(
        containerColor: _group(context),
        footer: _last,
        children: <Widget>[
          ExpressiveSwipeActions(
            trailing: <ExpressiveSwipeAction>[
              ExpressiveSwipeAction(
                label: 'Delete',
                icon: ExpressiveSymbols.delete,
                destructive: true,
                onPressed: () => setState(() => _last = 'Deleted the trip'),
              ),
              ExpressiveSwipeAction(
                label: 'Archive',
                icon: ExpressiveSymbols.archive,
                onPressed: () => setState(() => _last = 'Archived the trip'),
              ),
            ],
            leading: <ExpressiveSwipeAction>[
              ExpressiveSwipeAction(
                label: 'Pin',
                icon: ExpressiveSymbols.pushPin,
                emphasized: true,
                onPressed: () => setState(() => _last = 'Pinned the trip'),
              ),
            ],
            allowsFullSwipe: true,
            child: ExpressiveListTile(
              title: const Text('Porto weekend'),
              subtitle: const Text('Swipe either way'),
              leading: const Icon(ExpressiveSymbols.flight),
              onTap: () {},
            ),
          ),
        ],
      ),
    ],
  );
}

class _Accordions extends StatelessWidget {
  const _Accordions();

  @override
  Widget build(BuildContext context) => kitSection(
    'Accordion',
    children: <Widget>[
      ExpressiveListSection(
        containerColor: _group(context),
        children: const <Widget>[
          ExpressiveDisclosure(
            title: Text('How long does shipping take?'),
            leading: Icon(ExpressiveSymbols.localShipping),
            initiallyExpanded: true,
            child: Text(
              'Standard orders arrive in four to six days; express orders '
              'placed before noon arrive the next day.',
            ),
          ),
          ExpressiveDisclosure(
            title: Text('Can I return an item?'),
            leading: Icon(ExpressiveSymbols.autorenew),
            child: Text(
              'Anything unworn goes back free within 30 days. Start a '
              'return from your orders.',
            ),
          ),
          ExpressiveDisclosure(
            title: Text('Do you ship abroad?'),
            leading: Icon(ExpressiveSymbols.public),
            child: Text('We ship to 28 countries across Europe.'),
          ),
        ],
      ),
    ],
  );
}

class _Grid extends StatelessWidget {
  const _Grid();

  static const List<(String, IconData)> _tiles = <(String, IconData)>[
    ('Photos', ExpressiveSymbols.photoLibrary),
    ('Music', ExpressiveSymbols.musicNote),
    ('Maps', ExpressiveSymbols.map),
    ('Wallet', ExpressiveSymbols.wallet),
    ('Fitness', ExpressiveSymbols.fitnessCenter),
    ('Books', ExpressiveSymbols.book),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Grid · adaptive columns',
      children: <Widget>[
        ExpressiveSectionHeader(
          'Your apps',
          trailing: Text(
            '${_tiles.length}',
            style: t.type.labelLarge.copyWith(color: t.colors.onSurfaceVariant),
          ),
        ),
        ExpressiveGrid(
          shrinkWrap: true,
          minItemWidth: 96,
          itemCount: _tiles.length,
          itemBuilder: (context, i) => DecoratedBox(
            decoration: ShapeDecoration(
              shape: t.shapes.large,
              color: t.colors.secondaryContainer,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(_tiles[i].$2, color: t.colors.onSecondaryContainer),
                Text(
                  _tiles[i].$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.type.labelLarge.copyWith(
                    color: t.colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Dividers extends StatelessWidget {
  const _Dividers();

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    Widget caption(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: kitGap),
      child: Text(
        text,
        style: t.type.labelMedium.copyWith(color: t.colors.onSurfaceVariant),
      ),
    );
    return kitSection(
      'Dividers',
      children: <Widget>[
        caption('Full width'),
        const ExpressiveDivider(),
        caption('Inset'),
        const ExpressiveDivider(inset: ExpressiveDividerInset.start),
        caption('Middle inset'),
        const ExpressiveDivider(inset: ExpressiveDividerInset.both),
        caption('Vertical'),
        SizedBox(
          height: 32,
          child: Row(
            children: <Widget>[
              Expanded(child: Center(child: caption('Day'))),
              const ExpressiveDivider(vertical: true),
              Expanded(child: Center(child: caption('Week'))),
              const ExpressiveDivider(vertical: true),
              Expanded(child: Center(child: caption('Month'))),
            ],
          ),
        ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A two-line item: a glyph, the headline over its supporting line, and a
/// chevron.
Widget kitSpecimenListItemTwoLine() => ExpressiveListTile(
  title: const Text('Lisbon in May'),
  subtitle: const Text('12 photos · 3 shared'),
  leading: const Icon(ExpressiveSymbols.photoLibrary),
  trailing: const Icon(ExpressiveSymbols.chevronRight),
  onTap: () {},
);

/// A segmented section of three settings under its header.
Widget kitSpecimenListSectionSettings() => ExpressiveListSection(
  header: 'Notifications',
  children: <Widget>[
    ExpressiveListTile.toggleable(
      title: const Text('Trip reminders'),
      leading: const Icon(ExpressiveSymbols.notifications),
      value: true,
      onChanged: (_) {},
    ),
    ExpressiveListTile(
      title: const Text('Quiet hours'),
      subtitle: const Text('10 PM to 7 AM'),
      leading: const Icon(ExpressiveSymbols.bedtime),
      onTap: () {},
    ),
    ExpressiveListTile(
      title: const Text('Sounds'),
      leading: const Icon(ExpressiveSymbols.volumeUp),
      onTap: () {},
    ),
  ],
);

/// A section's title over its first item.
Widget kitSpecimenSectionHeaderTitle() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    const ExpressiveSectionHeader('Upcoming'),
    ExpressiveListTile(
      title: const Text('Porto weekend'),
      subtitle: const Text('Fri 2 Oct'),
      onTap: () {},
    ),
  ],
);

/// A divider between two items, inset to their text.
Widget kitSpecimenDividerInset() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    ExpressiveListTile(
      title: const Text('Porto weekend'),
      leading: const Icon(ExpressiveSymbols.place),
      onTap: () {},
    ),
    const ExpressiveDivider(inset: ExpressiveDividerInset.start),
    ExpressiveListTile(
      title: const Text('Madeira hike'),
      leading: const Icon(ExpressiveSymbols.place),
      onTap: () {},
    ),
  ],
);

/// Three stops that reorder by their handles.
Widget kitSpecimenReorderableStops() => SizedBox(
  height: ExpressiveSpacing.s72 * 3 + ExpressiveSpacing.s8,
  child: ExpressiveReorderableListView(
    itemCount: 3,
    onReorder: (_, _) {},
    itemBuilder: (context, i) => ExpressiveListTile(
      key: ValueKey<int>(i),
      title: Text(const <String>['Belém', 'Alfama', 'LX Factory'][i]),
      subtitle: Text('Stop ${i + 1}'),
      leading: const Icon(ExpressiveSymbols.place),
      trailing: ExpressiveReorderHandle(index: i),
    ),
  ),
);

/// An expanded question over its answer, a closed one under it.
Widget kitSpecimenAccordionFaq() => const Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    ExpressiveDisclosure(
      title: Text('How long does shipping take?'),
      leading: Icon(ExpressiveSymbols.localShipping),
      initiallyExpanded: true,
      child: Text(
        'Standard orders arrive in four to six days; express orders placed '
        'before noon arrive the next day.',
      ),
    ),
    ExpressiveDisclosure(
      title: Text('Can I return an item?'),
      leading: Icon(ExpressiveSymbols.autorenew),
      child: Text('Anything unworn goes back free within 30 days.'),
    ),
  ],
);
