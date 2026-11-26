import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => ExpressiveFilledButton(
    'Save draft',
    onPressed: () =>
        showExpressiveSnackBar(context, 'Revision ${++revision} saved'),
  );
}
