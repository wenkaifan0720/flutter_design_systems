import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

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
              const MinimalSectionHeader('Delivery'),
              const SizedBox(height: 12),
              MinimalListSection(
                inset: true,
                children: [
                  MinimalListTile(
                    title: 'Email',
                    onTap: () => setState(() => channel = 'Email'),
                  ),
                  MinimalListTile(
                    title: 'Post',
                    onTap: () => setState(() => channel = 'Post'),
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
