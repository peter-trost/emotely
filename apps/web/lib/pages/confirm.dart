import 'package:emotely_web/components/confirm_waitlist.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Where the confirmation mail's link lands (`/confirm?t=<token>`). The
/// island does the work; this is its frame.
class const Confirm({super.key}) extends StatelessComponent {
  @override
  Component build(BuildContext context) =>
      const main_(classes: 'page prose', [ConfirmWaitlist()]);
}
