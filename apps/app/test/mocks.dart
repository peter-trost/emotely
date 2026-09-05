import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Every mock in the suite is generated from here. The http client is the
/// only seam through which session behavior is faked; the PostHog SDK is a
/// platform channel, faked so tests can inspect what would leave the device.
@GenerateNiceMocks([MockSpec<http.Client>(), MockSpec<Posthog>()])
void main() {}
