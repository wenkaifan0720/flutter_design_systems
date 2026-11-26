import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
                Fluent2Button(
                  'Remove book',
                  onPressed: () => setState(() => added = false),
                ),
              ],
            )
          : Fluent2EmptyState(
              title: 'No books yet',
              body: 'Books you save will appear here.',
              actionLabel: 'Add book',
              onAction: () => setState(() => added = true),
            ),
    ),
  );
}
