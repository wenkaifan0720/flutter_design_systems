import 'package:flutter/widgets.dart';
import 'package:keycap_ui/keycap_ui.dart';

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
      child: KeycapCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Route note'),
            const SizedBox(height: 12),
            const Text('Meet at the west entrance.'),
            const SizedBox(height: 12),
            KeycapButton(
              onPressed: () => setState(() => pinned = !pinned),
              child: Text(pinned ? 'Unpin' : 'Pin'),
            ),
          ],
        ),
      ),
    ),
  );
}
