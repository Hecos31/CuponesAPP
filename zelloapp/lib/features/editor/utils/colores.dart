import 'package:flutter/material.dart';
String colorAHex(Color color) => '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';