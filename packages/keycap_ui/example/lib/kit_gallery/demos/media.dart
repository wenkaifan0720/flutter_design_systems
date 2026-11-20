import 'package:material_ui/material_ui.dart';

import '../kit.dart';

/// People, counts, tags, pictures and a list of terms: printed on the case, sunk where they are read.
Widget kitMediaDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Avatars and media',
  sections: kitSpecimens(const [
    'Avatar',
    'AvatarGroup',
    'Badge',
    'Tag',
    'Media',
    'DescriptionList',
  ]),
);
