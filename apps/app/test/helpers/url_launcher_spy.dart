import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Stands in for the url_launcher platform channel and records every URL
/// the app asked to open, so a test can prove where a button leads without
/// leaving the process.
///
/// A hand-written [Fake] rather than a generated mock: mockito 5.8 deprecates
/// mixing [MockPlatformInterfaceMixin] (the token bypass a platform interface
/// needs) into generated mocks, and a manual `Mock` subclass would have to
/// spell out a `noSuchMethod` override per method for null safety anyway.
///
/// Constructing it installs the spy as the platform implementation for the
/// current test and restores the previous implementation when the test ends.
class UrlLauncherSpy.setup()
    extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  this {
    final original = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = this;
    addTearDown(() => UrlLauncherPlatform.instance = original);
  }

  /// URLs in the order the app launched them.
  final launched = <String>[];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}
