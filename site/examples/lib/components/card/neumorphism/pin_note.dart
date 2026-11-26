import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

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
      child: NeumorphicCard(
        title: 'Route note',
        children: [
          const Text('Meet at the west entrance.'),
          NeumorphicButton(
            pinned ? 'Unpin' : 'Pin',
            onPressed: () => setState(() => pinned = !pinned),
          ),
        ],
      ),
    ),
  );
}
