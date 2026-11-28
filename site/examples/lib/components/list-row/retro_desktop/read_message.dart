import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

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
    child: RetroDesktopListTile(
      title: 'Route change',
      semanticLabel: read ? 'Route change, read' : 'Route change, unread',
      subtitle: read ? 'Read' : 'Unread',
      onPressed: () => setState(() => read = !read),
    ),
  );
}
