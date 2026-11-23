import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// Text fields and selects: glass windows set into the metal.
Widget kitFieldsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Text fields and selects',
  sections: [
    const KitSection(
      title: 'Text fields',
      note: 'Focused, the window\'s rim lights and the caret glows.',
      children: [
        StudioTextField(
          labelText: 'Episode title',
          hintText: 'Season 2, episode 4',
        ),
        StudioTextField(
          labelText: 'Description',
          hintText: 'What is this episode about?',
          maxLines: 4,
          minLines: 3,
        ),
        StudioTextField(
          labelText: 'Search',
          hintText: 'Shows and episodes',
          prefixIcon: Icon(LucideIcons.search),
        ),
        StudioTextField(
          labelText: 'Title',
          errorText: 'Give the episode a title.',
        ),
        StudioTextField(
          labelText: 'Feed address',
          hintText: 'Set by your host',
          enabled: false,
        ),
      ],
    ),
    KitSection(
      title: 'Selects',
      note: 'The list opens on the chosen setting, its lamp lit.',
      children: [
        kitState<String>(
          'high',
          (context, v, set) => StudioSelect<String>(
            labelText: 'Audio quality',
            value: v,
            items: const [
              StudioSelectItem(value: 'standard', label: 'Standard, 64 kbps'),
              StudioSelectItem(value: 'high', label: 'High, 128 kbps'),
              StudioSelectItem(value: 'lossless', label: 'Lossless'),
            ],
            onChanged: set,
          ),
        ),
        const StudioSelect<String>(
          labelText: 'Host',
          value: null,
          hintText: 'Choose a host',
          items: [],
          onChanged: null,
        ),
      ],
    ),
    const KitSection(
      title: 'Search, password and groups',
      note: 'The same display window, with a lens, a show key or plates at its ends.',
      children: [
        StudioSearchField(hintText: 'Search shows'),
        StudioPasswordField(labelText: 'Password'),
        StudioInputGroup(
          labelText: 'Feed address',
          leading: Text('https://'),
          hintText: 'roomtone.example/feed',
        ),
        StudioInputGroup(
          labelText: 'Bit rate',
          trailing: Text('kbps'),
          hintText: '128',
          errorText: 'Between 64 and 320.',
        ),
      ],
    ),
    KitSection(
      title: 'Codes and steppers',
      note: 'One window per character; a readout between two keys.',
      children: [
        const StudioCodeField(labelText: 'Sign-in code'),
        kitState<int>(
          2,
          (context, v, set) => StudioStepper(
            value: v,
            min: 1,
            max: 9,
            semanticLabel: 'Takes',
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Combobox and tags',
      note: 'Type to narrow a list under glass; Enter takes the lit row and the field keeps typing.',
      children: [
        Builder(
          builder: (context) => StudioCombobox<String>(
            labelText: 'Show',
            options: const [
              'Night Desk',
              'Night Shift',
              'Field Notes',
              'Long Table',
            ],
            labelOf: (s) => s,
            onSelected: (s) => kitFeedback(context, s),
          ),
        ),
        kitState<List<String>>(
          const ['Interviews'],
          (context, v, set) => StudioTagInput<String>(
            labelText: 'Topics',
            values: v,
            options: const ['Interviews', 'Science', 'Music', 'History'],
            labelOf: (s) => s,
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Form field',
      note: 'A label, a helper and an error round any control.',
      children: [
        kitState<int>(
          0,
          (context, v, set) => StudioFormField(
            labelText: 'Episode type',
            helperText: 'Trailers play before the first episode.',
            isRequired: true,
            child: StudioSegmentedButton<int>(
              semanticLabel: 'Episode type',
              segments: const [
                StudioSegment(value: 0, label: 'Full'),
                StudioSegment(value: 1, label: 'Trailer'),
                StudioSegment(value: 2, label: 'Bonus'),
              ],
              value: v,
              onChanged: set,
            ),
          ),
        ),
      ],
    ),
  ],
);
