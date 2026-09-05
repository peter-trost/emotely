import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

/// `#RRGGBB` on the wire, [Color] in Dart.
///
/// Contract colors are opaque; decoding forces full alpha and encoding drops
/// it, so a widget never has to reason about transparency.
class const HexColorConverter() implements JsonConverter<Color, String> {
  static final RegExp _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  @override
  Color fromJson(String json) {
    if (!_hex.hasMatch(json)) {
      throw FormatException('expected a #RRGGBB color', json);
    }
    return Color(0xFF000000 | int.parse(json.substring(1), radix: 16));
  }

  @override
  String toJson(Color object) {
    final rgb = object.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
