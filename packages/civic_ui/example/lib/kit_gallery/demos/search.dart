// Finding things: the search box with its joined button, and the pages of
// a long list (the page shown in ink, far pages folded).
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitSearchDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Search & pagination',
  sections: [
    KitSection(
      title: 'Search field',
      children: [
        CivicSearchField(
          labelText: 'Search for a street',
          helperText: 'For example, Ropewalk Row',
          onSubmitted: (_) {},
        ),
        const CivicSearchField(
          labelText: 'Search (unavailable)',
          enabled: false,
        ),
      ],
    ),
    KitSection(
      title: 'Pagination',
      children: [
        for (final (count, start) in const [(3, 0), (12, 5), (12, 11)])
          _Pages(count: count, start: start),
      ],
    ),
  ],
);

class _Pages extends StatefulWidget {
  const _Pages({required this.count, required this.start});

  final int count;
  final int start;

  @override
  State<_Pages> createState() => _PagesState();
}

class _PagesState extends State<_Pages> {
  late int _page = widget.start;

  @override
  Widget build(BuildContext context) => CivicPagination(
    pageCount: widget.count,
    selectedIndex: _page,
    onPageChanged: (page) => setState(() => _page = page),
  );
}
