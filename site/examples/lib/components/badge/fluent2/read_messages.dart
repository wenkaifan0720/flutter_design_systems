import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
        Fluent2Badge(unread, semanticLabel: '$unread unread messages'),
        const SizedBox(height: 12),
        Fluent2Button(
          unread == 0 ? 'Reset inbox' : 'Mark one read',
          onPressed: () =>
              setState(() => unread = unread == 0 ? 3 : unread - 1),
        ),
      ],
    ),
  );
}
