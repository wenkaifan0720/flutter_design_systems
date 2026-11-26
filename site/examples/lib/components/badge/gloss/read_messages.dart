import 'package:flutter/widgets.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show Icons;

class ReadMessages extends StatefulWidget {
  const ReadMessages({super.key});
  @override
  State<ReadMessages> createState() => _ReadMessagesState();
}

class _ReadMessagesState extends State<ReadMessages> {
  int unread = 3;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Inbox'),
        const SizedBox(height: 12),
        GlossBadge(
          count: unread,
          semanticLabel: '$unread unread messages',
          child: const Icon(Icons.mail_outline),
        ),
        const SizedBox(height: 12),
        GlossButton(
          unread == 0 ? 'Reset inbox' : 'Mark one read',
          onPressed: () =>
              setState(() => unread = unread == 0 ? 3 : unread - 1),
        ),
      ],
    ),
  );
}
