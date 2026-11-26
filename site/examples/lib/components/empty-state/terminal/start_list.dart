import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

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
                TermButton(
                  label: 'Remove book',
                  onPressed: () => setState(() => added = false),
                ),
              ],
            )
          : TermEmptyState(
              title: 'No books yet',
              message: 'Books you save will appear here.',
              action: TermButton(
                label: 'Add book',
                onPressed: () => setState(() => added = true),
              ),
            ),
    ),
  );
}
