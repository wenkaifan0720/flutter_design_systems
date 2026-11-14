/// Fluent 2's image in its three shapes, bordered and raised by its
/// shadow, at a fixed size and as a block filling its column, the five fits
/// of one landscape photograph in a square, and the placeholder an image
/// stands as while it loads or when it fails.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

Widget kitImageDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Image',
  sections: [
    kitSection('Shapes', children: [kitSpecimenImageShapes()]),
    kitSection('Bordered and raised', children: [kitSpecimenImageFramed()]),
    kitSection('Block, 16 by 9', children: [kitSpecimenImageBlock()]),
    kitSection('Fits, a wide photo in a square', children: [kitImageFits()]),
    kitSection(
      'Placeholder, loading or failed',
      children: [
        kitRow([
          const Fluent2Image(
            width: 96,
            height: 96,
            shape: Fluent2ImageShape.rounded,
            bordered: true,
            semanticLabel: 'Photo still loading',
          ),
        ]),
      ],
    ),
  ],
);

// --- Specimens --------------------------------------------------------------

Widget kitSpecimenImageShapes() => kitRow([
  for (final shape in Fluent2ImageShape.values)
    Fluent2Image(
      image: kitPhoto,
      width: 96,
      height: 96,
      shape: shape,
      semanticLabel: 'Dashboard on a tablet, ${kitSay(shape)}',
    ),
]);

Widget kitSpecimenImageFramed() => kitRow([
  Fluent2Image(
    image: kitPhoto,
    width: 128,
    aspectRatio: 4 / 3,
    shape: Fluent2ImageShape.rounded,
    bordered: true,
    semanticLabel: 'Dashboard on a tablet, bordered',
  ),
  Fluent2Image(
    image: kitPhoto,
    width: 128,
    aspectRatio: 4 / 3,
    shape: Fluent2ImageShape.rounded,
    shadow: true,
    semanticLabel: 'Dashboard on a tablet, raised',
  ),
]);

Widget kitSpecimenImageBlock() => Fluent2Image(
  image: kitPhoto,
  block: true,
  aspectRatio: 16 / 9,
  shape: Fluent2ImageShape.rounded,
  semanticLabel: 'Dashboard on a tablet beside a coffee cup',
);

/// Each fit named under its square.
Widget kitImageFits() => Builder(
  builder: (context) {
    final t = context.fluent2Theme;
    return Wrap(
      spacing: Fluent2Spacing.l,
      runSpacing: Fluent2Spacing.l,
      children: [
        for (final fit in Fluent2ImageFit.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Fluent2Spacing.xs,
            children: [
              Fluent2Image(
                image: kitPhoto,
                width: 80,
                height: 80,
                fit: fit,
                bordered: true,
                semanticLabel: 'Dashboard on a tablet, ${kitSay(fit)}',
              ),
              ExcludeSemantics(
                child: Text(kitSay(fit), style: t.caption1.c(t.textSecondary)),
              ),
            ],
          ),
      ],
    );
  },
);
