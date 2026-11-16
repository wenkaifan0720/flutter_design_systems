/// slipway's settings, written as the config file they are.
library;

import 'package:flutter/widgets.dart';

import '../slipway.dart';

Widget kitSettingsDemo(Brightness brightness) =>
    slipwayApp(brightness, place: SlipwayPlace.settings);
