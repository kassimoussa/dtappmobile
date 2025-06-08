// lib/extensions/color_extensions.dart
import 'package:flutter/material.dart';

extension ColorExtension on Color {
  Color withOpacityValue(double opacity) {
    return withAlpha((opacity * 255).round());
  }
}