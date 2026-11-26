import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

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
      child: Fluent2Card(
        children: [
          const Fluent2CardHeader(
            header: 'Route note',
            description: 'Meet at the west entrance.',
          ),
          Fluent2Button(
            pinned ? 'Unpin' : 'Pin',
            onPressed: () => setState(() => pinned = !pinned),
          ),
        ],
      ),
    ),
  );
}
