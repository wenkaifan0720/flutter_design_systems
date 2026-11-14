/// The screen group's demo: a small live app on a plain `Navigator` whose
/// pages author no bars of their own — `ExpressiveScaffold` derives each from its
/// route: the root's large flexible bar collapsing as the list scrolls, a
/// pushed page's small bar and back arrow, a sheet's close-and-title
/// header, and a full-screen dialog's close, title and confirm action.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit_stack.dart';

/// The screen group's demo, in [brightness].
Widget kitScreenDemo(Brightness brightness) => KitStack(
  brightness: brightness,
  page: _page,
  initial: const <String>['/journal'],
);

const List<(String, String)> _entries = <(String, String)>[
  ('Morning pages', 'Slept badly; the harbour fog helped.'),
  ('Market day', 'Figs, a loaf of rye and far too many tomatoes.'),
  ('Letter from Inês', 'She is moving north in the spring.'),
  ('Run by the river', '6.2 km, a heron at the second bridge.'),
  ('Bread, attempt four', 'Better crumb. Still too dense at the base.'),
  ('A quiet Sunday', 'Read on the balcony until the light went.'),
  ('Garden notes', 'The basil finally took; the mint took over.'),
  ('Night ferry', 'Cold deck, warm coffee, the city lit up behind.'),
];

/// The page `/journal`, `/journal/entry/<index>`, `/filter` (a sheet) or
/// `/new` (a full-screen dialog) stands for.
Page<void> _page(String location, LocalKey key) =>
    switch (location.split('/').where((part) => part.isNotEmpty).toList()) {
      ['journal', 'entry', final index] => ExpressivePage<void>(
        key: key,
        child: _Entry(_entries[int.parse(index)]),
      ),
      ['filter'] => ExpressiveSheetPage<void>(key: key, child: const _Filter()),
      ['new'] => ExpressiveSheetPage<void>(
        key: key,
        drawer: true,
        child: const _NewEntry(),
      ),
      _ => ExpressivePage<void>(key: key, child: const _Journal()),
    };

/// The root: the large flexible bar the root register derives, collapsing
/// as the list scrolls, with its actions.
class _Journal extends StatelessWidget {
  const _Journal();

  @override
  Widget build(BuildContext context) => ExpressiveScaffold(
    topBar: ExpressiveAppBar(
      title: 'Journal',
      subtitle: 'May · 8 entries',
      large: true,
      collapsing: true,
      actions: <Widget>[
        ExpressiveAppBarAction(
          ExpressiveSymbols.filterList,
          label: 'Filter',
          onPressed: () => KitStack.push(context, '/filter'),
        ),
        ExpressiveAppBarAction(
          ExpressiveSymbols.edit,
          label: 'New entry',
          onPressed: () => KitStack.push(context, '/new'),
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Note(
          'The root derives a large flexible bar that collapses as the '
          'list scrolls. Open an entry for the pushed register, the filter '
          'for a sheet, the pencil for a full-screen dialog.',
        ),
        for (var i = 0; i < _entries.length; i++)
          _EntryRow(
            _entries[i],
            onTap: () => KitStack.push(context, '/journal/entry/$i'),
          ),
      ],
    ),
  );
}

/// A pushed page: only a title — the small bar and the back arrow are
/// derived.
class _Entry extends StatelessWidget {
  const _Entry(this.entry);

  final (String, String) entry;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressiveScaffold(
      title: entry.$1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ExpressiveSpacing.s16,
        children: <Widget>[
          Text(
            entry.$2,
            style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
          ),
          const _Note(
            'Pushed: the screen derived the small bar and the back arrow '
            '(Material’s on both platforms). Back, the edge swipe on iOS or '
            'predictive back on Android returns to the journal.',
          ),
        ],
      ),
    );
  }
}

/// A sheet: close and the title, on the sheet's own container.
class _Filter extends StatefulWidget {
  const _Filter();

  @override
  State<_Filter> createState() => _FilterState();
}

class _FilterState extends State<_Filter> {
  final Set<String> _tags = <String>{'Walks'};

  @override
  Widget build(BuildContext context) => ExpressiveScaffold(
    title: 'Filter entries',
    body: ExpressiveChipRow(
      children: <Widget>[
        for (final tag in const <String>['Walks', 'Food', 'Letters', 'Sleep'])
          ExpressiveChip.filter(
            tag,
            selected: _tags.contains(tag),
            onPressed: () => setState(
              () => _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag),
            ),
          ),
      ],
    ),
  );
}

/// A full-screen dialog: close, the title and the confirm action.
class _NewEntry extends StatelessWidget {
  const _NewEntry();

  @override
  Widget build(BuildContext context) => ExpressiveScaffold(
    topBar: ExpressiveAppBar(
      title: 'New entry',
      actions: <Widget>[
        ExpressiveAppBarAction(
          ExpressiveSymbols.check,
          label: 'Save',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    ),
    body: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ExpressiveSpacing.s16,
      children: <Widget>[
        ExpressiveTextField(label: 'Title'),
        ExpressiveTextArea(label: 'What happened today?'),
        _Note(
          'A full-screen dialog: close, the title and the confirm action '
          'in the bar, over the surface.',
        ),
      ],
    ),
  );
}

/// A quiet explanatory line.
class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ExpressiveSpacing.s8),
      child: Text(
        text,
        style: t.type.bodyMedium.copyWith(color: t.colors.onSurfaceVariant),
      ),
    );
  }
}

/// One journal entry in the list.
class _EntryRow extends StatelessWidget {
  const _EntryRow(this.entry, {required this.onTap});

  final (String, String) entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return ExpressivePressable(
      shapes: ExpressivePressShapes.all(t.shapes.medium),
      motion: ExpressiveMotionKey.fastSpatial,
      color: t.colors.surface,
      contentColor: t.colors.onSurface,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ExpressiveSpacing.s8,
          vertical: ExpressiveSpacing.s12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              entry.$1,
              style: t.type.titleMedium.copyWith(color: t.colors.onSurface),
            ),
            Text(
              entry.$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.type.bodyMedium.copyWith(
                color: t.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A root page: the large bar over a scrolling list of entries.
Widget kitSpecimenScreenJournal() => ExpressiveScaffold(
  topBar: const ExpressiveAppBar(title: 'Journal', large: true),
  body: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      for (final (title, line) in _entries)
        ExpressiveListTile(
          title: Text(title),
          subtitle: Text(line),
          onTap: () {},
        ),
    ],
  ),
);
