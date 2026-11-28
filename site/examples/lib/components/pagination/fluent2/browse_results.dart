import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class BrowseResults extends StatefulWidget {
  const BrowseResults({super.key});
  @override
  State<BrowseResults> createState() => _BrowseResultsState();
}

class _BrowseResultsState extends State<BrowseResults> {
  int page = 1;
  static const titles = ['Field notes', 'Reading list', 'Trip plan'];

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 600),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Fluent2Pagination(
          pages: titles.length,
          page: page,
          onChanged: (next) => setState(() => page = next),
          semanticLabel: 'Result pages',
        ),
        const SizedBox(height: 12),
        Text('Page $page · ${titles[page - 1]}'),
      ],
    ),
  );
}
