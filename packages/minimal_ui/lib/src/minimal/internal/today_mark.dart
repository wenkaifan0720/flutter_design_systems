import 'package:flutter/widgets.dart';

import 'cap_label.dart';
import 'field.dart';

/// A day's figure, with today's mark under it when [today]: a short bar in
/// the figure's [ink], 5 px above the bottom of the day's mark (the box this
/// fills), and lowered as larger text lowers the figure's foot, so the bar
/// keeps its 4 px under the digits. Today is a fact, not a choice, so it
/// never takes the chosen day's fill or an outline that reads as one.
Widget minimalTodayMark({
  required Widget figure,
  required Color ink,
  required bool today,
}) {
  if (!today) return figure;
  return SizedBox.expand(
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        figure,
        Builder(
          builder: (context) {
            // The figure stands centred by its capitals: larger text drops
            // its foot by half the capitals it adds.
            const size = MinimalFieldMetrics.valueType;
            final grown = MediaQuery.textScalerOf(context).scale(size) - size;
            return PositionedDirectional(
              bottom: 5 - grown * minimalCapHeight / 2,
              child: Container(
                width: 10,
                height: 2,
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: const BorderRadius.all(Radius.circular(1)),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}
