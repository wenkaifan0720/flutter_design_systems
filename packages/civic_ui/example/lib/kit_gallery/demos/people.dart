// People and figures: avatars and a group of them, counts on their words,
// pictures with their descriptions and the missing one, the key figures a
// page leads with and amounts read whole.
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitPeopleDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Avatars, badges, pictures & figures',
  sections: [
    const KitSection(
      title: 'Avatars',
      caption: 'Initials when there is no picture; the name is in words too.',
      children: [
        Row(
          spacing: CivicSpacing.s16,
          children: [
            CivicAvatar(name: 'Amara Okafor', size: 48),
            Expanded(child: Text('Amara Okafor, the applicant')),
          ],
        ),
        CivicAvatarGroup(
          names: ['Amara Okafor', 'Ben Hale', 'Chi Lee', 'Dev Rao', 'Eli Moss'],
        ),
      ],
    ),
    const KitSection(
      title: 'Badges',
      caption: 'A count after its words, read with its noun.',
      children: [
        CivicBadge(count: 2, noun: 'update', child: Text('Your applications')),
        CivicBadge(
          count: 1,
          noun: 'thing to do',
          nouns: 'things to do',
          needsAction: true,
          child: Text('Your permits'),
        ),
        CivicBadge(count: 140, noun: 'message', child: Text('Messages')),
      ],
    ),
    KitSection(
      title: 'Pictures',
      caption: 'Described for a screen reader; the missing one says so.',
      children: [
        CivicImage(
          image: kitZoneMap,
          description: 'Map of Zone B: from the river to Mill Lane',
          caption: 'Zone B runs from the river to Mill Lane.',
        ),
        const CivicImage(
          image: null,
          description: 'Photo of the permit bay sign',
          caption: 'The sign at each permit bay.',
          aspectRatio: 16 / 9,
        ),
      ],
    ),
    const KitSection(
      title: 'Key figures and amounts',
      children: [
        CivicGrid(
          children: [
            CivicKeyFigure(
              label: 'Permits issued this year',
              value: '1,240',
              detail: 'To 31 October 2026',
            ),
            CivicKeyFigure(
              label: 'Average time to decide',
              value: '3 days',
              detail: 'Target: 5 working days',
            ),
          ],
        ),
        Wrap(
          spacing: CivicSpacing.s8,
          children: [
            Text('A resident permit costs'),
            CivicAmount(
              6250,
              textStyle: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    ),
  ],
);

/// A drawn map of Zone B: the zone's edge, its roads and the river.
final ImageProvider kitZoneMap = MemoryImage(base64Decode(_zone));

const _zone =
    'iVBORw0KGgoAAAANSUhEUgAAAPAAAACgCAIAAAC9uXYyAAADYUlEQVR42u3dvY0VMRhA'
    '0a2EOimEAqiBiIiIMhBCRNRAspuhCVZPzI/n3fEc68Yjy3v0BZbe+uX3n5960OtiOY13'
    '+/RtRaM38+LvAfRpmoEGmmaggQZaQE+gGWiggQZaVc1AAw000DRXNQMNNNBA01zVDDTQ'
    'U2kGGmiggaa5qhlooIEGmuaqZqCBBhpomquagQYaaKBprmoGGuiDQT99t0DPAPr7j6+D'
    'Wjue//OzQAP9BNCDNAMNNNBAA13VDDTQQAMNdFUz0EADDTTQVc1AAw10HvSXjx8u0RJ0'
    'dpPX0gw00CeBPkcz0EADfR3Qf399LrcEXdvbsaBP0ww00EADDXRVM9BAAw000FXNQAMN'
    'NNBAVzUDDXQF9FEX3kADPQT0U8Yz0EAPAf0szUADDTTQQFc1Aw000EADXdUMNNBAAw10'
    'VTPQQAMNNNBVzUADfQzoiGaggQYaaKCrmoEGGmigga5qBhpooIEGuqoZaKCBBhroqmag'
    'gT4J9DmagQZ6I+jmeAYa6C2gs5qBBhpooO8NuqwZaKCBBvrGoOOagQYaaKDvCrqvGWig'
    'gQb6TqD/nepazfM9lAr0PKBpBhpooIFOgqYZaKCBBjoJmmaggQYa6CRomoEGGmigk6Bp'
    'Bvq+oKfXDPS1QRvPQM8Dmmaggb4B6Ffrgmut5vucDNBAA23RDLQFNNAWzStBu+W41i2H'
    'yw3XdvOAphnoeUDTDDTQQAOdBE0z0EADDXQSNM1AAw000EnQNAMNNNBAJ0HTDPR9QdMM'
    'dBq08Qz0PKBpBhpoAZ0ETTPQQAvoJOi1mpdvrAhooIEGuqQZaKCBBhro8aC3aQYa6CLo'
    'tZrffXhTQAMNNNABzUADDTTQQI8HvU0z0EADDTTQg0Fv1gw00EADDfRI0Hs0Aw30tUE/'
    'eOubY6CfD3rneAYa6BDo/ZqBBhpooIEeAPoQzUADDTTQQB8N+ijNQAMNNNDjQcdbgt7/'
    'tc2/SXkcx0ADDTTQSc1AJ0BfpSXoPd/xz5CABlpAJ0HTDDTQAjoJmmaggRbQSdA0Aw20'
    'gE6Cphno+4J21ECnQRvPQM8DmmaggRbQSdA0Aw20gE6CphlooAV0EjTNQAMtoJOgaQZ6'
    'HtA0Aw20gE6CphlooAV0EjTNQAMtoJOgaQYaaAGdBE1zsDeqn8xy+Ps2CwAAAABJRU5E'
    'rkJggg==';
