import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class BrowseResults extends StatefulWidget {
  const BrowseResults({super.key});
  @override
  State<BrowseResults> createState() => _BrowseResultsState();
}

class _BrowseResultsState extends State<BrowseResults> {
  int page = 0;
  static const titles = ['Field notes', 'Reading list', 'Trip plan'];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinimalPagination(
          pageCount: titles.length,
          page: page,
          onPageChanged: (next) => setState(() => page = next),
        ),
        const SizedBox(height: 12),
        Text('Page ${page + 1} · ${titles[page]}'),
      ],
    ),
  );
}
