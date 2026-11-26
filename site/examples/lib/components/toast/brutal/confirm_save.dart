import 'package:flutter/widgets.dart';
import 'package:brutal_ui/brutal_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => BrutalToaster(
    child: Center(
      child: Builder(
        builder: (context) => BrutalButton(
          'Save draft',
          onPressed: () =>
              showBrutalToast(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
