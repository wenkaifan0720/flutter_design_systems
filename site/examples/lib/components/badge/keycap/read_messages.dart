import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
        KeycapBadge(count: unread),
        const SizedBox(height: 12),
        KeycapButton(
          onPressed: () =>
              setState(() => unread = unread == 0 ? 3 : unread - 1),
          child: Text(unread == 0 ? 'Reset inbox' : 'Mark one read'),
        ),
      ],
    ),
  );
}
