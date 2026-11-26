import 'package:material_ui/material_ui.dart';

class LabelDraft extends StatefulWidget {
  const LabelDraft({super.key});
  @override
  State<LabelDraft> createState() => _LabelDraftState();
}

class _LabelDraftState extends State<LabelDraft> {
  bool published = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 440),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Chip(
          avatar: Icon(published ? Icons.check_circle : Icons.edit_outlined),
          label: Text(published ? 'Published' : 'Draft'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => setState(() => published = !published),
          child: Text(published ? 'Return to draft' : 'Publish'),
        ),
      ],
    ),
  );
}
