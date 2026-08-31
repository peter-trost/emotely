import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The accessibility bar every widget test runs (ported from the legacy app,
/// applied universally there rather than selectively): platform tap-target
/// sizes, labeled tappables, and WCAG AA text contrast, evaluated with
/// accessibility features enabled.
extension AccessibilityTesting on WidgetTester {
  /// Pumps [widget] and asserts the four Flutter accessibility guidelines.
  Future<void> expectMeetsAccessibilityGuidelines(
    Widget widget, {
    Future<void> Function(WidgetTester tester)? prepare,
  }) async {
    platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures.allOn;
    addTearDown(platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpWidget(widget);
    await prepare?.call(this);

    await expectLater(this, meetsGuideline(androidTapTargetGuideline));
    await expectLater(this, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(this, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(this, meetsGuideline(textContrastGuideline));
  }
}
