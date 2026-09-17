import 'package:emotely/app/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('urlFrom', () {
    test('accepts an absolute URL', () {
      expect(
        urlFrom('https://api.example.test/api/config', define: 'X'),
        Uri.parse('https://api.example.test/api/config'),
      );
    });

    test('refuses a value without a scheme, naming the define', () {
      expect(
        () => urlFrom('api.example.test/api/config', define: 'EMOTELY_X'),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'EMOTELY_X'),
        ),
      );
    });

    test('refuses a value without a host', () {
      expect(
        () => urlFrom('https:///api/config', define: 'EMOTELY_X'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses an empty value', () {
      expect(
        () => urlFrom('', define: 'EMOTELY_X'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
