/// slipway's runs: the status tabs, the branch, the list; at a desk the
/// list, the run and its log tiled side by side.
library;

import 'package:flutter/widgets.dart';

import '../kit_slipway.dart';

Widget kitRunsDemo(Brightness brightness) =>
    slipwayApp(brightness, place: SlipwayPlace.runs);
