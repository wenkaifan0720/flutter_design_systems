import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';

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
                GlossButton(
                  'Remove book',
                  onPressed: () => setState(() => added = false),
                ),
              ],
            )
          : GlossStateView(
              state: GlossState.empty,
              title: 'No books yet',
              message: 'Books you save will appear here.',
              actions: [
                GlossButton(
                  'Add book',
                  onPressed: () => setState(() => added = true),
                ),
              ],
            ),
    ),
  );
}
