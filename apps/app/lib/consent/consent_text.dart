/// The wording of the explicit consent the app asks for before the first
/// session, and the identifier that names it.
///
/// The app asks for consent under Art. 9 (2) (a) GDPR because a journal entry
/// can carry health and other special-category data, and the transcript
/// leaves the device for a model provider. What this text says about where
/// the transcript goes has to agree with the notice at
/// `getemotely.com/app-privacy` (apps/web `lib/pages/app_privacy.dart`): the
/// same recipients, in the same order, named the same way. If one changes,
/// both change, and [consentVersion] changes with them.
library;

/// Which wording the user agreed to, as stored in `public.consents.version`.
///
/// Dated, so the text as it stood can be found in the repository at that
/// date. **Changing the wording below means changing this**: a user whose
/// record names an older version is asked again before their next session,
/// which is the whole point of storing it.
const consentVersion = '2026-09-15';

/// Where the full notice lives. The consent screen links it, and so does the
/// account screen.
const privacyNoticeUrl = 'https://getemotely.com/app-privacy';

/// The imprint § 5 DDG asks for; linked next to the notice.
const imprintUrl = 'https://getemotely.com/imprint';

/// The heading of the consent screen: a question, because it is one.
const consentTitle = 'Before your first session';

/// What is sent, to whom, and what it can contain. Plain, in the app's own
/// voice, and specific enough that agreeing to it is informed: the three
/// bullets name the data, the recipients and the sensitivity, which is what
/// Art. 9 (2) (a) asks an explicit consent to cover.
const consentWhatIsSent =
    'A session is a conversation: emotely asks a question, you answer, and '
    'at the end it writes your entry.';

/// The recipients, in the order the transcript travels. Matches the notice's
/// "The conversation with the assistant" section.
const consentRecipients =
    'To answer, the conversation so far — the questions and the answers you '
    'write in them — is sent to our server, which passes it to a language '
    'model provider through the Vercel AI Gateway. Your entries themselves '
    'are stored in our database in Frankfurt and nowhere else.';

/// Why this needs consent rather than a checkbox nobody reads: because of
/// what a journal entry is.
const consentSensitivity =
    'What you write can say how you feel, how you sleep, how things are with '
    'the people close to you, or how your health is. That is sensitive '
    'information, so we do not send it anywhere without asking you first.';

/// The legal statement, said once and without hedging, so the record means
/// what it says.
const consentLegalBasis =
    'Ticking the box below is your explicit consent to that, under '
    'Art. 9 (2) (a) GDPR. You can take it back at any time on the account '
    'screen — it is one tap, and it does not require deleting anything.';

/// The label on the checkbox: the affirmative act itself. Unticked, always.
const consentCheckboxLabel =
    'I consent to my journal entries being sent to a model provider as '
    'described above.';

/// The button that records it; enabled only once the box is ticked.
const consentAgreeLabel = 'Start journaling';

/// Declining. Named plainly rather than as a soft "not now", because the
/// choice has to be real.
const consentDeclineLabel = 'Not now';

/// What declining means. There is no session without the model, so this says
/// so rather than pretending otherwise — and everything else stays usable.
const consentDeclinedMessage =
    'No problem. Nothing has been sent. You can still read the entries you '
    'already have, and you can start a session whenever you decide to.';

/// The link to the whole notice, from the consent screen.
const consentReadNoticeLabel = 'Read the full privacy notice';

/// What the account screen says above the withdraw button while consent
/// stands. Art. 7 (3): withdrawal must be as easy as giving, and the user
/// should know what it does before they tap.
const withdrawConsentExplanation =
    'You consented to your entries being sent to a model provider so emotely '
    'can write them with you. Withdraw it and no new session can start. The '
    'entries you already wrote stay where they are until you delete them, '
    'and withdrawing does not delete your account.';

/// The account screen's withdraw button.
const withdrawConsentLabel = 'Withdraw consent';

/// What the account screen says once consent has been withdrawn, with the
/// way back. Giving it again must be no harder than taking it back.
const consentWithdrawnExplanation =
    'You have withdrawn your consent, so no new session can start. Your '
    'entries are untouched. You can consent again whenever you like.';

/// The account screen's button to consent again after a withdrawal.
const restoreConsentLabel = 'Consent again';

/// The account screen's link to the notice.
const privacyNoticeLabel = 'Privacy notice';

/// The account screen's link to the imprint.
const imprintLabel = 'Imprint';

/// Shown when the consent could not be recorded. The session does not start
/// on a consent that was never written down, so this says what happened
/// rather than quietly continuing.
const consentFailureMessage =
    'Could not record your consent. Check your connection and try again.';

/// Shown when withdrawing could not be recorded, for the same reason.
const withdrawFailureMessage =
    'Could not withdraw your consent. Check your connection and try again.';
