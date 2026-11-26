import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class ChooseChannel extends StatefulWidget {
  const ChooseChannel({super.key});
  @override
  State<ChooseChannel> createState() => _ChooseChannelState();
}

class _ChooseChannelState extends State<ChooseChannel> {
  String channel = 'Email';
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TermPane.list(
            title: 'Delivery',
            children: [
              for (final name in ['Email', 'Post'])
                TermListTile(
                  title: Text(name),
                  onTap: () => setState(() => channel = name),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Deliver by $channel'),
        ],
      ),
    ),
  );
}
