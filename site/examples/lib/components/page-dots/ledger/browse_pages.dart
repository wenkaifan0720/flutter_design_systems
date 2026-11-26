import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class BrowsePages extends StatefulWidget {
  const BrowsePages({super.key});
  @override
  State<BrowsePages> createState() => _BrowsePagesState();
}

class _BrowsePagesState extends State<BrowsePages> {
  int page = 0;
  static const titles = ['Cover', 'Notes', 'Credits'];

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(titles[page]),
      const SizedBox(height: 12),
      LedgerPageDots(
        pageCount: titles.length,
        page: page,
        onChanged: (next) => setState(() => page = next),
      ),
    ],
  );
}
