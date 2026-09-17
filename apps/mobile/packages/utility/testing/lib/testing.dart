/// Test support shared by every package: the accessibility bar, the submit
/// helpers, Supabase scripted at the http seam, the url_launcher spy and the
/// generated mocks. Nothing here knows the app or a feature.
library;

export 'src/a11y.dart';
export 'src/mocks.dart';
export 'src/submit.dart';
export 'src/supabase_stub.dart';
export 'src/url_launcher_spy.dart';
