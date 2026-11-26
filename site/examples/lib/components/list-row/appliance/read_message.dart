import 'package:flutter/widgets.dart';
import 'package:appliance_ui/appliance_ui.dart';

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
    child: ApplianceListTile(
      title: 'Route change',
      subtitle: read ? 'Read' : 'Unread',
      onTap: () => setState(() => read = !read),
    ),
  );
}
