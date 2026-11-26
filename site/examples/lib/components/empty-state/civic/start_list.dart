import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

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
                CivicButton(
                  onPressed: () => setState(() => added = false),
                  child: Text('Remove book'),
                ),
              ],
            )
          : CivicEmptyState(
              title: 'No books yet',
              actions: [
                CivicButton(
                  onPressed: () => setState(() => added = true),
                  child: Text('Add book'),
                ),
              ],
              children: [const Text('Books you save will appear here.')],
            ),
    ),
  );
}
