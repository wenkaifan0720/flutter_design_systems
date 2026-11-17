// Find your permit zone: a search over Brindlemere's streets, the count
// of what it found (a live region), filters by zone (beside the results
// from 1024 wide, above them below), the results five to a page with
// pagination, and the page's empty and unavailable states. Street names
// are proper names: they stay as they are in Arabic.
import 'package:flutter/material.dart';
import 'package:civic_ui/civic_ui.dart';

import 'account.dart';
import 'flow.dart';
import 'permits.dart';

const _zones = [
  ('a', 'Zone\u00A0A: Old Town', 'Permits every day, 8am to 8pm'),
  ('b', 'Zone\u00A0B: Harbourside', 'Permits Monday to Saturday, 8am to 6pm'),
  ('c', 'Zone\u00A0C: Millbrook', 'Permits Monday to Friday, 9am to 5pm'),
  ('d', 'Zone D: Fernlea', 'Permits Monday to Friday, 9am to 5pm'),
];

const _streets = [
  ('Abbey Close', 'a'),
  ('Bellfounders Lane', 'a'),
  ('Brook Terrace', 'c'),
  ('Chandlers Yard', 'b'),
  ("Cooper's Hill", 'a'),
  ('Fernlea Road', 'd'),
  ('Gorse Close', 'd'),
  ('Harbour Street', 'b'),
  ('Hollybank Avenue', 'd'),
  ('Kiln Lane', 'c'),
  ('Lantern Hill', 'c'),
  ('Millrace Road', 'c'),
  ('Northgate', 'a'),
  ('Old Market Square', 'a'),
  ('Orchard Rise', 'c'),
  ('Quay Lane', 'b'),
  ('Ropewalk Row', 'b'),
  ('Saltmarsh Road', 'b'),
  ('Sandpiper Way', 'd'),
  ('Station Approach', 'd'),
  ('Tanners Walk', 'a'),
  ('Weavers Row', 'a'),
  ('Wharf Road', 'b'),
];

/// Results to a page.
const _perPage = 5;

/// Finds the reader's permit zone by their street.
class PermitsZonesPage extends StatefulWidget {
  /// The search page.
  const PermitsZonesPage({super.key});

  @override
  State<PermitsZonesPage> createState() => _PermitsZonesPageState();
}

class _PermitsZonesPageState extends State<PermitsZonesPage> {
  // Made on the first build that needs it, from the words searched last;
  // never in dispose, where the page's state is no longer in reach.
  TextEditingController? _words;

  @override
  void dispose() {
    _words?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.permits;
    final back = context.backLinkTo(PermitsPage.start);
    if (state.condition == PermitsCondition.unavailable) {
      return PermitsUnavailable(
        title: 'Sorry, street search is not working right now',
        backLink: back,
        safe: 'You can still apply: we will find your zone from your address.',
        elseLabel: 'Apply for a permit',
        onElse: () => state.go(PermitsPage.start),
      );
    }
    final text = context.civicText;
    final query = state.query.trim().toLowerCase();
    final found = [
      for (final s in _streets)
        if ((query.isEmpty || s.$1.toLowerCase().contains(query)) &&
            (state.zones.isEmpty || state.zones.contains(s.$2)))
          s,
    ];
    final pages = (found.length / _perPage).ceil();
    final page = state.resultsPage.clamp(0, pages == 0 ? 0 : pages - 1);
    final shown = found.skip(page * _perPage).take(_perPage);
    final search = CivicSearchField(
      controller: _words ??= TextEditingController(text: state.query),
      labelText: context.say('Search for a street'),
      helperText: context.say('For example, Ropewalk\u00A0Row'),
      onSubmitted: (words) {
        state.query = words;
        state.resultsPage = 0;
        state.changed();
      },
    );
    final filters = CivicFieldset(
      labelText: context.say('Zone'),
      // What a tick does, before it is ticked.
      helperText: context.say('Tick zones to narrow the list.'),
      children: [
        for (final (id, label, _) in _zones)
          CivicCheckbox(
            value: state.zones.contains(id),
            labelText: context.say(label),
            onChanged: (v) {
              v == true ? state.zones.add(id) : state.zones.remove(id);
              state.resultsPage = 0;
              state.changed();
            },
          ),
      ],
    );
    final count = Semantics(
      liveRegion: true,
      child: Text(
        context.sayCount(found.length, one: '1 street', other: '# streets'),
        // A count reads as the applications' does: a quiet line over the list.
        style: text.caption,
      ),
    );
    return permitsFilteredBody(
      context,
      title: context.say('Find your permit zone'),
      backLink: back,
      filterTitle: context.say('Filter by zone'),
      filters: filters,
      lead: [search],
      main: [
        if (found.isEmpty)
          CivicEmptyState(
            title: context
                .say('No streets match “Quillon”')
                .replaceAll('Quillon', state.query.trim()),
            announce: true,
            children: [
              Text(context.say('To find more streets:')),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final tip in [
                    'check the spelling of the street',
                    'search for its name without the house number',
                    // Only while a zone is ticked.
                    if (state.zones.isNotEmpty) 'clear the zone filters',
                  ])
                    PermitsBullet(text: context.say(tip)),
                ],
              ),
            ],
          )
        else ...[
          count,
          const SizedBox(height: CivicSpacing.s8),
          CivicListGroup(
            children: [
              for (final (name, id) in shown)
                if (_zones.firstWhere((z) => z.$1 == id) case (
                  _,
                  final zone,
                  final hours,
                ))
                  CivicListRow(
                    title: Text(name),
                    subtitle: Text(
                      '${context.say(zone)}\n${context.say(hours)}',
                    ),
                    onTap: () => state.go(PermitsPage.start),
                  ),
            ],
          ),
          if (pages > 1) ...[
            const SizedBox(height: CivicSpacing.s32),
            CivicPagination(
              pageCount: pages,
              selectedIndex: page,
              onPageChanged: (i) {
                state.resultsPage = i;
                state.changed();
              },
            ),
          ],
        ],
      ],
    );
  }
}
