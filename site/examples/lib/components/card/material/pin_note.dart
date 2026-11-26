import 'package:material_ui/material_ui.dart';

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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Route note',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('Meet at the west entrance.'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => setState(() => pinned = !pinned),
                child: Text(pinned ? 'Unpin' : 'Pin'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
