import 'package:flutter/widgets.dart';
import 'package:minimal_ui/minimal_ui.dart';

class EnterCode extends StatefulWidget {
  const EnterCode({super.key});

  @override
  State<EnterCode> createState() => _EnterCodeState();
}

class _EnterCodeState extends State<EnterCode> {
  int digits = 0;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MinimalInputOtp(
          labelText: 'Verification code',
          length: 4,
          onChanged: (value) => setState(() => digits = value.length),
        ),
        const SizedBox(height: 12),
        Text(digits == 4 ? 'Code complete' : 'Digits entered: $digits of 4'),
      ],
    ),
  );
}
