import 'dart:ui';

import 'package:emotely/contract/contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group(HexColorConverter, () {
    const converter = HexColorConverter();

    test('decodes #RRGGBB as an opaque color', () {
      expect(converter.fromJson('#FF8800'), const Color(0xFFFF8800));
    });

    test('accepts lowercase hex digits', () {
      expect(converter.fromJson('#ff8800'), const Color(0xFFFF8800));
    });

    test('encodes uppercase #RRGGBB and drops alpha', () {
      expect(converter.toJson(const Color(0x80FF8800)), '#FF8800');
    });

    test('pads small channel values to two digits', () {
      expect(converter.toJson(const Color(0xFF00010A)), '#00010A');
    });

    test('rejects anything that is not #RRGGBB', () {
      for (final bad in ['FF8800', '#FF880', '#GG8800', '#FF88001', '']) {
        expect(
          () => converter.fromJson(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });
  });
}
