import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class ConfirmSave extends StatefulWidget {
  const ConfirmSave({super.key});
  @override
  State<ConfirmSave> createState() => _ConfirmSaveState();
}

class _ConfirmSaveState extends State<ConfirmSave> {
  int revision = 0;

  @override
  Widget build(BuildContext context) => NeumorphicToaster(
    child: Center(
      child: Builder(
        builder: (context) => NeumorphicButton(
          'Save draft',
          onPressed: () => showNeumorphicToast(
            context,
            message: 'Revision ${++revision} saved',
          ),
        ),
      ),
    ),
  );
}
