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

/// Which wording the user agreed to, as stored in
/// `public.consent_events.version`.
///
/// Dated, so the text as it stood can be found in the repository at that
/// date; the server refuses a version dated after today. **Changing the
/// wording below means changing this**: a user whose latest event names an
/// older version is asked again before their next session, which is the
/// whole point of storing it.
///
/// This is not left to discipline. [consentWording] is hashed in a test
/// against a checked-in value, so editing any of the strings below without
/// bumping this date fails CI — otherwise two different texts could ship
/// under one version and nobody would ever be re-asked.
///
/// The tripwire cuts both ways, and it is the expensive direction that
/// matters: bumping this re-gates **every existing user** on their next
/// session. That is correct when the wording materially changes, and
/// needless churn when it does not — so a typo fix is worth a moment's
/// thought about whether the meaning moved (see ADR 0014).
const consentVersion = '2026-09-15';

/// Where the full notice lives. The consent screen links it, and so does the
/// account screen.
const privacyNoticeUrl = 'https://getemotely.com/app-privacy';

/// The imprint § 5 DDG asks for; linked next to the notice.
const imprintUrl = 'https://getemotely.com/imprint';

/// The heading of the consent screen. Names the moment rather than asking a
/// question, and stays true when the screen is shown again after a wording
/// change or after a withdrawal — neither of which is a "first" session.
const consentTitle = 'Before emotely sends your writing';

/// What is sent, to whom, and what it can contain. Plain, in the app's own
/// voice, and specific enough that agreeing to it is informed: the three
/// bullets name the data, the recipients and the sensitivity, which is what
/// Art. 9 (2) (a) asks an explicit consent to cover.
const consentWhatIsSent =
    'A session is a conversation: emotely asks a question, you answer, and '
    'at the end it writes your entry.';

/// The recipients, in the order the transcript travels, and where they sit.
/// Matches the notice's "The conversation with the assistant" section.
///
/// The third country and its safeguard are named because EDPB 05/2020 para
/// 64 (vi) lists them among the minimum elements of an informed consent, and
/// this processing genuinely may leave the EU.
const consentRecipients =
    'To answer, the conversation so far — the questions and the answers you '
    'write in them — is sent to our server, which passes it to a language '
    'model provider through the Vercel AI Gateway. That provider may be '
    'outside the EU; where it is, the transfer rests on the European '
    'Commission’s standard contractual clauses (Art. 46 GDPR). Your entries '
    'themselves are stored in our database in Frankfurt and nowhere else.';

/// What the provider may not do with it. True as of #96, which sends
/// `disallowPromptTraining` and `zeroDataRetention` on every round — the
/// gateway then routes only to providers contractually bound to both.
/// Material to an informed consent, and the most reassuring true thing
/// there is to say here.
const consentNoTraining =
    'Every request tells the gateway to route only to providers that are '
    'contractually barred from training on what you write and from keeping '
    'it after they answer.';

/// The one thing consent cannot undo, said plainly rather than left to be
/// discovered. Matches the notice.
const consentIrreversible =
    'Withdrawing stops anything further being sent, but a conversation that '
    'has already been answered cannot be recalled from the provider.';

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
    'screen, reached from the icon at the top right of your journal — it is '
    'one tap, and it does not require deleting anything.';

/// The label on the checkbox: the affirmative act itself. Unticked, always.
const consentCheckboxLabel =
    'I consent to my journal entries being sent to a model provider as '
    'described above.';

/// The button that records it; enabled only once the box is ticked.
const consentAgreeLabel = 'Start journaling';

/// Declining. Named plainly rather than as a soft "not now", because the
/// choice has to be real.
const consentDeclineLabel = 'Not now';

/// Read out instead of a silently dimmed button. Not part of
/// [consentWording]: it is an instruction for operating the screen, not a
/// term being agreed to, so improving it does not re-gate anyone.
const consentAgreeBlockedHint = 'Tick the box above to continue';

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

/// Shown when the app could not find out whether consent already stands.
/// Not the same as "you have not consented": asking the question again here
/// would re-prompt someone who already answered it.
const consentUnknownMessage =
    'Could not check whether you have already agreed to this. Nothing has '
    'been sent. Check your connection and try again.';

/// Every string the user reads before deciding, in the order the screen
/// shows them. This is what [consentVersion] names, and what the version
/// test hashes: if any of it changes, the version must change too, because
/// a record naming `2026-09-15` has to mean one particular text and not
/// whatever the file happens to say today.
///
/// Deliberately only the *decision* strings — the title, the four
/// paragraphs, the checkbox and the two buttons. Failure messages and link
/// labels are not part of what was agreed to, so editing them does not
/// re-gate the user base.
const consentWording = [
  consentTitle,
  consentWhatIsSent,
  consentRecipients,
  consentNoTraining,
  consentSensitivity,
  consentIrreversible,
  consentLegalBasis,
  consentCheckboxLabel,
  consentAgreeLabel,
  consentDeclineLabel,
];
