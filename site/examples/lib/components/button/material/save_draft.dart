import 'package:material_ui/material_ui.dart';

class SaveDraft extends StatefulWidget {
  const SaveDraft({super.key});
  @override
  State<SaveDraft> createState() => _SaveDraftState();
}

class _SaveDraftState extends State<SaveDraft> {
  bool saved = false;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 12,
    runSpacing: 12,
    children: [
      FilledButton(
        onPressed: saved ? null : () => setState(() => saved = true),
        child: Text(saved ? 'Draft saved' : 'Save draft'),
      ),
      OutlinedButton(
        onPressed: saved ? () => setState(() => saved = false) : null,
        child: const Text('Reset'),
      ),
    ],
  );
}
