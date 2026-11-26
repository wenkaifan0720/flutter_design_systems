import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ComicSectionHeader('Delivery'),
              const SizedBox(height: 12),
              ComicListSection(
                label: 'Delivery',
                children: [
                  ComicListTile(
                    title: 'Email',
                    onPressed: () => setState(() => channel = 'Email'),
                  ),
                  ComicListTile(
                    title: 'Post',
                    onPressed: () => setState(() => channel = 'Post'),
                  ),
                ],
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
