/// The accounts the app stores' reviewers sign in with. Store review and
/// Google's pre-launch crawler cannot read a mailbox, so these two sign in
/// with a password instead of an emailed code (and never cost an email).
/// They exist only on the server, created by the release skill's
/// `reviewer-accounts.sh`; nothing in the app can create one.
const reviewAccounts = {
  'google-play-review@getemotely.com',
  'app-store-review@getemotely.com',
};

/// Whether [email] names a review account, however it was typed: surrounding
/// whitespace and letter case do not count, so the check cannot be sidestepped
/// into the code flow (which would cost an email) by a stray capital.
bool isReviewAccount(String email) =>
    reviewAccounts.contains(email.trim().toLowerCase());
