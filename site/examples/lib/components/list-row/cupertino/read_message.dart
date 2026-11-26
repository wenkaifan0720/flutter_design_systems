import 'package:cupertino_ui/cupertino_ui.dart';

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
    // A list tile takes the height it's given: in a column it keeps its own.
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoListTile(
          leading: Icon(
            read ? CupertinoIcons.envelope_open : CupertinoIcons.envelope,
          ),
          title: const Text('Route change'),
          subtitle: Text(read ? 'Read' : 'Unread'),
          onTap: () => setState(() => read = !read),
        ),
      ],
    ),
  );
}
