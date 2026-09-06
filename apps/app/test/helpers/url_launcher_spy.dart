import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Stands in for the url_launcher platform channel and records every URL
/// the app asked to open, so a test can prove where a button leads without
/// leaving the process. Install with [install].
class UrlLauncherSpy()
    extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  /// URLs in the order the app launched them.
  final launched = <String>[];

  /// Makes this spy the platform implementation for the rest of the test.
  void install() => UrlLauncherPlatform.instance = this;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}
