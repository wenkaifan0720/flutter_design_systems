import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:material_ui/material_ui.dart' show Icons;

class StartList extends StatefulWidget {
  const StartList({super.key});
  @override
  State<StartList> createState() => _StartListState();
}

class _StartListState extends State<StartList> {
  bool added = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: added
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A Field Guide'),
                const SizedBox(height: 12),
                MinimalButton(
                  'Remove book',
                  onPressed: () => setState(() => added = false),
                ),
              ],
            )
          : MinimalEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No books yet',
              body: 'Books you save will appear here.',
              actionLabel: 'Add book',
              onAction: () => setState(() => added = true),
            ),
    ),
  );
}
