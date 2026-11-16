/// One run of slipway's: its head, its steps and the failing step's log,
/// searchable.
library;

import 'package:flutter/widgets.dart';

import '../slipway.dart';

Widget kitRunDetailDemo(Brightness brightness) =>
    slipwayApp(brightness, place: SlipwayPlace.run);
