import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class CheckSecret extends StatefulWidget {
  const CheckSecret({super.key});

  @override
  State<CheckSecret> createState() => _CheckSecretState();
}

class _CheckSecretState extends State<CheckSecret> {
  bool entered = false;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RetroDesktopPasswordField(
          labelText: 'Sample password',
          onChanged: (value) => setState(() => entered = value.isNotEmpty),
        ),
        const SizedBox(height: 12),
        Text(entered ? 'Sample entered' : 'Enter a sample word'),
      ],
    ),
  );
}
