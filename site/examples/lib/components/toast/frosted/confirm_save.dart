import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => FrostedButton(
    'Save draft',
    onPressed: () =>
        showFrostedSnackBar(context, 'Revision ${++revision} saved'),
  );
}
