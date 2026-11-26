import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class CheckSecret extends StatefulWidget {
  const CheckSecret({super.key});

  @override
  State<CheckSecret> createState() => _CheckSecretState();
}

class _CheckSecretState extends State<CheckSecret> {
  final password = TextEditingController();

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TermPasswordField(labelText: 'Sample password', controller: password),
        const SizedBox(height: 12),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: password,
          builder: (context, value, child) => Text(
            value.text.isEmpty ? 'Enter a sample word' : 'Sample entered',
          ),
        ),
      ],
    ),
  );
}
