/// Admit's Search: a field over the week's events, its results as the
/// events table, and what it says when nothing matches.
library;

import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'admit.dart';
import 'data.dart';
import 'events.dart';

/// The events whose title, byline, venue, address or kind holds [query].
List<AdmitEvent> admitSearch(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final e in admitEvents)
      if ([
        e.title,
        e.byline,
        e.venue,
        e.address,
        e.kind.label,
      ].any((s) => s.toLowerCase().contains(q)))
        e,
  ];
}

/// Search, opened on [initialQuery].
class AdmitSearchPage extends StatefulWidget {
  /// Search.
  const AdmitSearchPage({super.key, this.initialQuery = ''});

  /// What the field holds at first.
  final String initialQuery;

  @override
  State<AdmitSearchPage> createState() => _AdmitSearchPageState();
}

class _AdmitSearchPageState extends State<AdmitSearchPage> {
  late final _query = TextEditingController(text: widget.initialQuery);
  final _field = FocusNode();

  static const _recent = ['harbour', 'film'];

  @override
  void dispose() {
    _query.dispose();
    _field.dispose();
    super.dispose();
  }

  void _set(String q) {
    _query.value = TextEditingValue(
      text: q,
      selection: TextSelection.collapsed(offset: q.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = context.brutalTheme.textTheme;
    final frame = AdmitFrame.of(context);
    final q = _query.text.trim();
    final found = admitSearch(q);
    return AdmitPage(
      title: 'Search',
      children: [
        BrutalSearchField(
          controller: _query,
          focusNode: _field,
          label: 'Search the week',
          hint: 'Events, venues, who is on',
          autofocus: widget.initialQuery.isEmpty,
          onChanged: (_) => setState(() {}),
        ),
        admitGroupGap,
        if (q.isEmpty) ...[
          BrutalListGroup(
            header: 'Recent searches',
            children: [
              for (final r in _recent)
                BrutalListTile(
                  leading: const Icon(LucideIcons.history),
                  title: r,
                  onTap: () => _set(r),
                ),
            ],
          ),
        ] else if (found.isEmpty)
          BrutalStateView(
            state: BrutalState.empty,
            icon: const Icon(LucideIcons.searchX),
            title: 'Nothing matches “$q” this week',
            message:
                'Search looks at titles, venues and who is on, from Tue 17 '
                'to Sun 22 Nov. Try a venue, or see the whole week.',
            actions: [
              BrutalButton(
                'Clear search',
                onPressed: () {
                  _set('');
                  _field.requestFocus();
                },
              ),
              BrutalButton.text(
                'All events',
                onPressed: () => frame.go(AdmitPlace.events),
              ),
            ],
          )
        else ...[
          Semantics(
            container: true,
            liveRegion: true,
            child: Text(
              '${found.length} ${found.length == 1 ? 'event' : 'events'} '
              'for “$q”',
              style: t.secondary,
            ),
          ),
          const SizedBox(height: BrutalSpacing.small),
          AdmitEventTable(
            events: found,
            onOpen: (e) => frame.push(AdmitEventPage(event: e)),
          ),
        ],
      ],
    );
  }
}
