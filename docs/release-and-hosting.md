# Release and hosting kit: Prep Simulator for TOEFL

## Build
- Package `com.homilabs.toefl_prep` (locked after the first Play upload). Version 1.0.0 (versionCode 1).
- Build: `jobq run --name toefl-release-aab -- flutter build appbundle --release`, then `./gradlew --stop` in `android/`.
- Before every release: `bash scripts/check-release-ad-ids.sh`, `python3 tool/validate.py`, `flutter test`.
- Signing: upload key created 4 Nov 2026: `.secrets/toefl-upload.keystore` (alias `toefl-upload`, RSA 2048, valid 10,000 days), passwords in `.secrets/toefl-upload-keystore-credentials.txt`, read by `android/key.properties`. Certificate SHA-256 `05:CA:6A:E3:64:18:B0:B3:19:1A:61:A5:25:E3:1A:20:8A:93:4C:FC:3B:22:BE:89:AB:56:27:2A:37:DA:BA:C4`. `.secrets/` goes to the local and Drive backups, never GitHub. Losing it means asking Play support for an upload-key reset.
- Release 1.0.0+1 built 4 Nov 2026: `releases/1.0.0+1/toefl-prep-1.0.0+1.aab` (upload this to Play, SHA-256 `8f438723…48fb9`) and `.apk` (sideload test, SHA-256 `1512b168…a271a`), both signed with the upload key. Gate before the build: format, analyze, 20 tests (including a full mock sat through every part to the results), validator 0 errors.
- Device testing on emulator `tofel_api35`: launch, Reading (Complete the Words input, Daily Life), adaptive routing, Listening text-to-speech with man and woman voices, practice conversation with replay, transcript and explanation. Not verified on a device: microphone recording and playback (the emulator kept freezing); covered by the widget test with an in-memory recorder. Check it on a real phone before production.

## Website: https://tofel.homilabs.org
- Hostinger: subdomain `tofel.homilabs.org` created 4 Nov 2026 (folder `public_html/tofel` of the homilabs.org website).
- `public_html/tofel` is a git checkout of this repo's `deploy` branch (cloned over SSH, as for gre and nts; hPanel's one Git slot for homilabs.org belongs to the games site).
- Change `website/`, commit, then `bash scripts/publish-site.sh` (pushes `deploy`, then pulls it on the server over SSH). Flush the CDN cache in hPanel if pages look stale.
- Pages: landing, `/privacy.html`, `/terms.html`, `/app-ads.txt`.
- After Play launch: replace "Coming soon on Google Play" with the Play link, and add the app to homilabs.org.

## AdMob (account homilabs.smc@gmail.com)
- Created 4 Nov 2026: app "Prep Simulator for TOEFL", App ID `ca-app-pub-2087846699268567~6422141298`; units banner `toefl_home_banner` and interstitial `toefl_results_interstitial` (ids in `config/admob.json`). Debug builds use Google test units.
- "Limited ad serving" until the Play listing is live. After launch: AdMob → Apps → this app → Add store (com.homilabs.toefl_prep).
- Privacy & messaging: European regulations message "Prep Simulator for TOEFL consent" published 4 Nov 2026 for this app (Consent / Do not consent / Manage options, privacy URL https://tofel.homilabs.org/privacy.html). The app runs Google UMP before the SDK.

## Play Console
| Item | Value |
|---|---|
| App icon 512×512 | `store-assets/icon-512.png` |
| Feature graphic | `store-assets/feature-graphic.png` |
| Phone screenshots | `store-assets/screenshots/` |
| Privacy policy URL | https://tofel.homilabs.org/privacy.html |
| Website | https://tofel.homilabs.org |
| Contact email | homilabs.smc@gmail.com |
| Ads | Yes (AdMob banner on home tabs; one interstitial after results or practice) |
| App access | All functionality available without login |
| Permissions | Microphone (RECORD_AUDIO): records Speaking answers only while a timed answer runs; files stay on the device |
| Data safety | Collected and shared: Device or other IDs (advertising ID) and app activity via the ads SDK, purpose Advertising, shared with Google AdMob; encrypted in transit. Audio (voice recordings) is processed only on the device and never leaves it, so it is not "collected" under Play's definition. Attempts and written answers stay on the device |
| Content rating | Reference/educational; No to violence, sexuality, language, drugs, gambling, purchases, user interaction |
| Target audience | 18+ (or 13+ if Homi prefers; the app is not directed at children) |
| Category | Education |

**App name** (24 characters): `Prep Simulator for TOEFL`

**Short description** (80 max): `20 adaptive TOEFL iBT mock tests with band scores, model answers and practice.`

**Full description**:
```
Practise for the new TOEFL iBT (the format used since January 2026) the way it feels on the day.

20 FULL-LENGTH MOCK TESTS
• Reading, Listening, Writing and Speaking in the current pattern, each part timed and introduced as on test day.
• Adaptive like the real test: your first Reading and Listening module decides whether the second is easier or harder.
• Listening recordings play once, as on the test; take notes and answer.
• Speak your answers into the microphone with the real time limits, then play them back.
• Estimated 1-6 band scores for each section and overall, the CEFR level and a comparable 0-120 total.
• Every Reading and Listening answer explained, with the transcript of every recording.
• Compare your emails, discussion posts and spoken answers with model answers and rate them against clear criteria.

EVERY TASK TYPE
Complete the Words, Read in Daily Life, Read an Academic Passage, Listen and Choose a Response, conversations, announcements, academic talks, Build a Sentence, Write an Email, Write for an Academic Discussion, Listen and Repeat and Take an Interview.

LESSONS AND PRACTICE FOR EVERY TASK
• What is on screen, a step-by-step method, worked examples, traps, and templates for emails and discussion posts.
• Separate practice items with instant answers, replayable listening and transcripts, so practice never spoils a mock.
• Timed writing and speaking practice with model answers.
• Vocabulary flashcards of academic words, phrasal verbs and idioms.

GUIDANCE, TIPS AND STUDY PLANS
The 2026 format and scoring, bands and CEFR, test day and Home Edition, time management, note-taking, common mistakes, test anxiety, and 4 and 8-week study plans.

PRIVATE AND OFFLINE
No account. Works offline once your phone has an English text-to-speech voice. Your answers and voice recordings stay on your phone. Free, with light ads, never during a test or a practice question.

Prep Simulator for TOEFL is independent practice material by HomiLabs. TOEFL® and TOEFL iBT® are registered trademarks of ETS. This app is not endorsed or approved by ETS and is not affiliated with it. All questions are original practice material, recordings are read by your phone's voice, and scores are practice estimates.
```

## Before production (open items)
- Test Speaking (recording, playback, rating) and a full mock on a real phone.
- Phone screenshots (2-8) for the listing.
- Homi reviews the content flags in `docs/review-flags.md` and spot-checks mocks, listening voices and speaking flow on a real phone.
- Listening uses the phone's text-to-speech voice; recorded human or homidev Kokoro voices would be an upgrade (homidev workflow, Homi approves each clip).
