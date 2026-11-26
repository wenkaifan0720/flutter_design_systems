import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ReadMessage extends StatefulWidget {
  const ReadMessage({super.key});
  @override
  State<ReadMessage> createState() => _ReadMessageState();
}

class _ReadMessageState extends State<ReadMessage> {
  bool read = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: NeumorphicListTile(
      title: read ? 'Route change, read' : 'Route change, unread',
      subtitle: 'Service notice',
      onPressed: () => setState(() => read = !read),
    ),
  );
}
