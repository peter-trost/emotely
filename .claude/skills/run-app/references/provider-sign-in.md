# Driving Sign in with Google and Apple

Sign in with Google (iOS, Android) and Sign in with Apple (iOS only) sit
under the email step. They need a real account in the platform's own sheet,
so an agent cannot finish them unattended; drive them only with the human
at the device. Google on Android works only for a build signed with a key
that has an Android OAuth client in the `emotely-sign-in` Google Cloud
project (Play App Signing, and the maintainer's local debug key); any other
key fails with `canceled` before the sheet does anything. Apple on the
simulator needs an Apple Account signed in under Settings.
