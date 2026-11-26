import 'package:flutter/widgets.dart';
import 'package:ledger_ui/ledger_ui.dart';

class SortFiles extends StatefulWidget {
  const SortFiles({super.key});
  @override
  State<SortFiles> createState() => _SortFilesState();
}

class _SortFilesState extends State<SortFiles> {
  String order = 'Name';

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      LedgerButton(
        'Sort files',
        onPressed: () async {
          final sort = await LedgerSheet.show<String>(
            context,
            title: 'Sort files',
            builder: (sheet) => [
              LedgerMenu(
                semanticLabel: 'Sort order',
                items: [
                  for (final sort in ['Name', 'Date'])
                    LedgerMenuItem(
                      sort,
                      selected: order == sort,
                      onTap: () => Navigator.pop(sheet, sort),
                    ),
                ],
              ),
            ],
          );
          if (mounted && sort != null) setState(() => order = sort);
        },
      ),
      const SizedBox(height: 12),
      Text('Sort order: $order'),
    ],
  );
}
