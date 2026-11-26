import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class NameDraft extends StatefulWidget {
  const NameDraft({super.key});

  @override
  State<NameDraft> createState() => _NameDraftState();
}

class _NameDraftState extends State<NameDraft> {
  String title = '';

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Fluent2FormField(
          labelText: 'Draft title',
          child: Fluent2TextField(
            onChanged: (value) => setState(() => title = value.trim()),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title.isEmpty ? 'Untitled' : title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
