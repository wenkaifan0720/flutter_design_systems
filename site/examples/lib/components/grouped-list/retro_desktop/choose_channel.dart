import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

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
          RetroDesktopListSection(
            title: 'Delivery',
            children: [
              for (final name in ['Email', 'Post'])
                RetroDesktopListTile(
                  title: name,
                  isFirst: name == 'Email',
                  onPressed: () => setState(() => channel = name),
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
