// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

class Constants {
  Constants._();

  static final Random _random = Random();
  static final int _maxColor = 256;

  static const int hoursADay = 24;

  static final List<String> weekTitles = ["M", "T", "W", "T", "F", "S", "S"];

  static const Color defaultLiveTimeIndicatorColor = Color(0xff444444);
  static const Color defaultBorderColor = Color(0xffdddddd);
  static const Color black = Color(0xff000000);
  static const Color white = Color(0xffffffff);
  static const Color offWhite = Color(0xfff8f8f8);
  static const Color grey = Color(0xffeeeeee);
  static const Color headerBackground = Colors.black26;
  static Color get randomColor {
    return Color.fromRGBO(_random.nextInt(_maxColor),
        _random.nextInt(_maxColor), _random.nextInt(_maxColor), 1);
  }
}
