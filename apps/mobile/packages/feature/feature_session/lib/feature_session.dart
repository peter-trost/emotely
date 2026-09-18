/// The session feature: one journaling session, from the first question to
/// the finished entry. The app registers it with `registerSession` and
/// opens it with `SessionPage`; the answer widgets are exported so the
/// app's own end-to-end tests can find and drive them.
library;

export 'src/register.dart';
export 'src/view/session_page.dart';
export 'src/widgets/answer_input.dart';
export 'src/widgets/color_input.dart';
export 'src/widgets/emoji_input.dart';
export 'src/widgets/longtext_input.dart';
export 'src/widgets/rating_input.dart';
export 'src/widgets/text_list_input.dart';
