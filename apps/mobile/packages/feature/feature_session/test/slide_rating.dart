import 'package:feature_session/src/widgets/rating_input.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

/// Rests the rating slider on [value]; 0 is the "no answer" stop.
Future<void> slideRatingTo(WidgetTester tester, int value) =>
    tapSliderAt(tester, find.byKey(RatingInput.sliderKey), value);
