import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main(BuildContext context) {
  final share = Fluent2IconButton(
    Fluent2Icons.share,
    label: 'Share',
    onPressed: () {},
  );
  share.label;
  Fluent2Slider(label: 'Volume', value: 0.5, onChanged: (_) {});
  Fluent2SegmentedButton<String>(
    label: 'View',
    segments: const [
      Fluent2ButtonSegment('day', 'Day'),
      Fluent2ButtonSegment('week', 'Week'),
    ],
    value: 'day',
    onChanged: (_) {},
  );
  Fluent2TextField(label: 'Name', onChanged: (_) {});
  Fluent2Badge(3, label: '3 unread messages');
  Fluent2Badge.dot(label: 'New');
  showFluent2Menu<String>(
    context,
    items: const [Fluent2MenuItem('rename', 'Rename')],
    label: 'File',
  );
}
