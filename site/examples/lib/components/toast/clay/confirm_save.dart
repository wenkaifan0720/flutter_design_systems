import 'package:flutter/widgets.dart';
import 'package:clay_ui/clay_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => ClayToaster(
    child: Center(
      child: Builder(
        builder: (context) => ClayButton(
          'Save draft',
          onPressed: () =>
              showClayToast(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
