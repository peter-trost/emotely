/// The two store links the beta page hands out, and the path it lives at.
///
/// They sit apart from the page because replacing the TestFlight placeholder
/// is a separate act from writing the copy, and because the tests assert on
/// the values rather than on the rendered markup.
library;

/// Where the unlisted beta page lives. Nothing on the site links here: it
/// reaches a tester through one invitation mail and nowhere else.
const betaPath = '/beta';

/// The public TestFlight link for the external "Beta" group.
///
/// PLACEHOLDER — must be replaced before this page is announced. The real
/// link comes from App Store Connect › TestFlight › group "Beta" › public
/// link, which only exists once the group has a build that passed Beta App
/// Review. Until then this URL 404s for anyone who opens it.
const testFlightJoinUrl =
    'https://testflight.apple.com/join/REPLACE-BEFORE-MERGE';

/// The Play opt-in link for the closed testing track. Derived from the
/// package name, so it is final: it resolves as soon as the track has a
/// build and the tester's account is on the list.
const playTestingUrl =
    'https://play.google.com/apps/testing/de.emotely.emotely';
