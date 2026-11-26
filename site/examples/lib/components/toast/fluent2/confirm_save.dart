import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => Fluent2Toaster(
    child: Center(
      child: Builder(
        builder: (context) => Fluent2Button(
          'Save draft',
          onPressed: () =>
              showFluent2Toast(context, 'Revision ${++revision} saved'),
        ),
      ),
    ),
  );
}
