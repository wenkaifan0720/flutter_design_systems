import 'package:flutter/widgets.dart';
import 'package:civic_ui/civic_ui.dart';

class PinNote extends StatefulWidget {
  const PinNote({super.key});
  @override
  State<PinNote> createState() => _PinNoteState();
}

class _PinNoteState extends State<PinNote> {
  bool pinned = false;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: SingleChildScrollView(
      child: CivicSummaryCard(
        title: 'Route note',
        actions: [
          CivicButton(
            onPressed: () => setState(() => pinned = !pinned),
            child: Text(pinned ? 'Unpin' : 'Pin'),
          ),
        ],
        child: const Text('Meet at the west entrance.'),
      ),
    ),
  );
}
