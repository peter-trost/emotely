import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';

/// Every mock in the suite is generated from here; the http client is the
/// only seam through which session behavior is faked.
@GenerateNiceMocks([MockSpec<http.Client>()])
void main() {}
