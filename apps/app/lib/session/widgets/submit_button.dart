import 'package:material_ui/material_ui.dart';

/// The one way an answer leaves its widget: disabled until the widget holds
/// a valid answer, so the agent never receives an empty one.
class const SubmitButton({required final VoidCallback? onPressed, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton(onPressed: onPressed, child: const Text('Submit')),
  );
}
