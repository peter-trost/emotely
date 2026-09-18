import 'package:emotely/journal/journal_models.dart';
import 'package:emotely/session/view/entry_view.dart';
import 'package:material_ui/material_ui.dart';

/// One filed entry, read back the way the session showed it.
class const EntryPage({required final EntryRecord record, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        MaterialLocalizations.of(context).formatShortDate(record.createdAt),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: EntryView(entry: record.entry, questions: record.questionsById),
      ),
    ),
  );
}
