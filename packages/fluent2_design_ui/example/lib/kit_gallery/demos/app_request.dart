/// The Screens group's Northwind New request, the form: two form sections (title, type, priority, details; when and who), then Submit and Clear at the form's start.
/// The whole app stands around it: the tab bar on a phone, the nav pane
/// from 1024 wide, the other roots a tap away.
library;

import 'package:flutter/material.dart';

import '../kit.dart';

Widget kitAppRequestDemo(Brightness brightness) =>
    KitNorthwind(brightness: brightness, root: KitNorthwindRoot.requests);
