import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

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
          ExpressiveListSection(
            header: 'Delivery',
            children: [
              ExpressiveListTile(
                title: Text('Email'),
                onTap: () => setState(() => channel = 'Email'),
              ),
              ExpressiveListTile(
                title: Text('Post'),
                onTap: () => setState(() => channel = 'Post'),
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
