# The rebuild ships under the original store listings

The original emotely (2023–2025) left two live store records behind: an App
Store app (Apple ID 6466288395, nine ratings at 5.0, a subscription group) and a
Play listing, both under the bundle ID / package name `de.emotely.emotely`.
Apple fixes an app record's bundle ID once a build has been uploaded and Google
never lets a package name change, so the only way to keep those records is to
ship the rebuild as `de.emotely.emotely` — not `com.trostsystems.emotely`, which
the rebuild started with.

We reuse them. The alternative — a fresh record and a fresh identifier — would
throw away the ratings, fight for the "emotely" name that the old record holds,
and still require unpublishing the old Play listing to avoid two emotely apps
under one developer. Reuse costs a two-line identifier change and one caveat:
the rebuild lands on the ~12 Android devices that still have the old app as an
*update*, with none of their data (Firebase then, Supabase now). The old app was
sunset in early 2025, so that is acceptable, but the first launch must tolerate
whatever the old app left behind on the device.

The Apple record was transferred on 2026-09-13 from the developer account it
was created under (an accidental Yahoo-mail Apple Account, membership lapsing
2026-09-28, not renewed) to the account that holds every app going forward:
peter@petertrost.com, Team ID `VCZSHMZY25`. The Play developer account stays as
it is; peter@petertrost.com holds admin rights there.

## What follows from it

- `PRODUCT_BUNDLE_IDENTIFIER`, `namespace` and `applicationId` are
  `de.emotely.emotely` and never change. The Xcode team is `VCZSHMZY25`.
- Versions must climb past the legacy app's: `1.21.15` (build 594) on Apple,
  and past the last Android `versionCode`. The rebuild ships as `2.0.0`.
- The App Store record is still titled "Reflect Therapy AI: emotely"; the name
  changes to "emotely" with the first new version, because a name change is
  only possible together with a new version.
- The Android upload keystore is the legacy one (SHA-1 `6B:17:6E:AE:…:7F:87`,
  matches Play Console's upload key); Play App Signing holds the app signing key.
