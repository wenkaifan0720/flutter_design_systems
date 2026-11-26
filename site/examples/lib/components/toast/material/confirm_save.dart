import 'package:material_ui/material_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Revision ${++revision} saved'))),
        child: const Text('Save draft'),
      ),
    ),
  );
}
