/// The `media` oracle group (Compose twin: `MediaScenes.kt`): the avatar at
/// its five sizes (Material's list avatar is `m`), and the image masked by
/// the corner scale and by library shapes. Compose has no image or avatar
/// component: its twin is `Modifier.clip(shape)` over a filled box, with
/// the initials centred in `onPrimaryContainer`; the image's picture is a
/// flat `tertiaryContainer` placeholder on both sides, so only the mask is
/// compared.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/src/material_expressive/internal/tokens/list_tokens.g.dart';

import '../harness/oracle.dart';

/// The avatar sizes, by key segment.
const List<(String, ExpressiveAvatarSize)> mediaAvatarSizes = [
  ('xs', ExpressiveAvatarSize.extraSmall),
  ('s', ExpressiveAvatarSize.small),
  ('m', ExpressiveAvatarSize.medium),
  ('l', ExpressiveAvatarSize.large),
  ('xl', ExpressiveAvatarSize.extraLarge),
];

/// The image corners, by key segment.
const List<(String, ExpressiveCorner)> mediaImageCorners = [
  ('none', ExpressiveCorner.none),
  ('medium', ExpressiveCorner.medium),
  ('large', ExpressiveCorner.large),
  ('extra-large', ExpressiveCorner.extraLarge),
];

/// The library shapes an image is masked by, by key segment.
const List<(String, ExpressiveMaterialShape)> mediaImageShapes = [
  ('cookie-9-sided', ExpressiveMaterialShape.cookie9Sided),
  ('clover-4-leaf', ExpressiveMaterialShape.clover4Leaf),
  ('arch', ExpressiveMaterialShape.arch),
];

/// The flat picture both sides fill an image with.
Widget _flat(BuildContext context) =>
    ColoredBox(color: context.expressiveTheme.colors.tertiaryContainer);

/// Centres [child] in a [size] box the way Compose's `Alignment.Center`
/// does: the offset is rounded to a whole device pixel (Compose lays out in
/// integer pixels), where Flutter's [Center] would leave it at a half pixel
/// and shift every edge and glyph of the scene against the oracle.
class _PixelCenter extends StatelessWidget {
  const _PixelCenter({required this.size, required this.child});

  final Size size;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: CustomSingleChildLayout(
      delegate: _PixelCenterDelegate(),
      child: child,
    ),
  );
}

class _PixelCenterDelegate extends SingleChildLayoutDelegate {
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double snap(double free) =>
        (free * oracleDensity / 2).roundToDouble() / oracleDensity;
    return Offset(
      snap(size.width - childSize.width),
      snap(size.height - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_PixelCenterDelegate oldDelegate) => false;
}

final OracleGroup mediaScenes = OracleGroup(
  id: 'media',
  scenes: [
    OracleScene(
      key: 'media/avatar/sizes',
      size: const Size(336, 128),
      build: (context) => _PixelCenter(
        size: const Size(336, 128),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            for (final (name, size) in mediaAvatarSizes)
              _PixelCenter(
                size: Size(
                  size.dimension,
                  ExpressiveAvatarSize.extraLarge.dimension,
                ),
                child: OracleTag(
                  'avatar-$name',
                  shape: context.expressiveTheme.shapes.of(
                    ListTokens.itemLeadingAvatarShape,
                  ),
                  child: ExpressiveAvatar(
                    name: 'Mara Quist',
                    size: size,
                    tone: ExpressiveMediaTone.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    OracleScene(
      key: 'media/image/corners',
      size: const Size(240, 240),
      build: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          for (var i = 0; i < mediaImageCorners.length; i += 2)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16,
              children: [
                for (final (name, corner) in mediaImageCorners.skip(i).take(2))
                  OracleTag(
                    'image-$name',
                    shape: context.expressiveTheme.shapes.corner(corner),
                    child: SizedBox.square(
                      dimension: 96,
                      child: ExpressiveMedia(
                        slotId: 'oracle-$name',
                        aspectRatio: 1,
                        corner: corner,
                        placeholder: _flat(context),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    ),
    OracleScene(
      key: 'media/image/shaped',
      size: const Size(352, 128),
      build: (context) => ExpressiveHeroMoment(
        label: 'oracle',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            for (final (name, shape) in mediaImageShapes)
              OracleTag(
                'image-$name',
                child: SizedBox.square(
                  dimension: 96,
                  child: ExpressiveMedia.shaped(
                    slotId: 'oracle-$name',
                    shape: shape,
                    placeholder: _flat(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  ],
);

void main() => runOracleGroup(mediaScenes);
