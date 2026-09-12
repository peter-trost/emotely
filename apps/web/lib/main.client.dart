/// The client entrypoint: runs in the browser and mounts every `@client`
/// component the pre-rendered page contains (only the waitlist form).
library;

import 'package:emotely_web/main.client.options.dart';
import 'package:jaspr/client.dart';

void main() {
  Jaspr.initializeApp(options: defaultClientOptions);
  runApp(const ClientApp());
}
