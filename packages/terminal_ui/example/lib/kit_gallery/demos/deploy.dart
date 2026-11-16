/// slipway's new-deploy form: what, where and how, and the y/N before
/// production.
library;

import 'package:flutter/widgets.dart';

import '../slipway.dart';

Widget kitDeployDemo(Brightness brightness) =>
    slipwayApp(brightness, place: SlipwayPlace.deploy);
