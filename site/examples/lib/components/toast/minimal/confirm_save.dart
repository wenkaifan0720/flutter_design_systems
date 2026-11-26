import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => MinimalToaster(
    child: Center(
      child: Builder(
        builder: (context) => MinimalButton(
          'Save draft',
          onPressed: () =>
              showMinimalSnackBar(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
