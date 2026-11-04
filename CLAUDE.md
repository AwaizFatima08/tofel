# Prep Simulator for TOEFL (HomiLabs) — project notes

Flutter Android app simulating the TOEFL iBT in its January 2026 format: 20 full mock tests with adaptive Reading
and Listening (router module, then a lower or upper module), Writing and Speaking; 1-6 band scores per section and
overall with CEFR and a comparable 0-120 total; every answer explained; lessons and practice for all 13 task types;
guide articles (format, scoring, tips, study plans); vocabulary flashcards. Package `toefl_prep`, app id
`com.homilabs.toefl_prep` (locked after the first Play upload). Launcher name "TOEFL Simulator".
Built on the GRE app's engine (`/mnt/storage/projects/gre`), reworked for TOEFL tasks and audio.
The folder, repo and subdomain are spelled "tofel" (Homi's choice); the exam is TOEFL everywhere users see it.

## Locations
- Code: `/mnt/storage/projects/tofel` · GitHub `AwaizFatima08/tofel` (PUBLIC repo: no secrets)
- Local backup: `/mnt/storage/project_backups/tofel_backup` · Google Drive: https://drive.google.com/drive/folders/1n1MVDIk3WL1oWxWc3Hdygk4zZ_dbIpou
- Backups: `bash scripts/backup.sh` (all three layers)
- Site: https://tofel.homilabs.org (Hostinger `public_html/tofel`, a checkout of the `deploy` branch), source in `website/`, `bash scripts/publish-site.sh`

## Exam format (ets.org + "TOEFL iBT 2026 Update Test Blueprint and Specifications", checked 4 Nov 2026)
Summary in `docs/toefl-format.md`. `tool/make_blueprint.py` holds the module recipes and the routing threshold
(upper module at 60 % of router points). Bands are estimates (`lib/core/scoring.dart`).

## Audio
- Listening recordings and speaking prompts are read by the phone's text-to-speech (`flutter_tts`), woman/man voices
  per script line (`lib/audio/audio.dart`). No audio files ship. A recording plays once in a mock (`Attempt.played`).
- Speaking answers are recorded with `record` to app storage (`recordings/<attempt>-<question>.m4a`) and played back
  with `just_audio`. Writing and Speaking are self-rated 0-5 against rubric lines and model answers; no AI scoring.
- If homidev Kokoro voices are wanted later, clips would follow the homidev workflow (Homi approves every clip).

## Content
- `content/bank/<section>/<topic>.jsonl` (format in `docs/content-schema.md`, quality bar `docs/writer-brief.md`),
  lessons/guide/vocab in `content/lessons|guide|vocab` (`docs/lesson-format.md`).
- `python3 tool/validate.py`, `python3 tool/build_content.py` (fixed seeds: papers stay stable).
  `flutter test test/content` checks the built papers. Strings: edit `tool/make_arb.py`, run it, then `flutter gen-l10n`.
- Every item is original HomiLabs work. Never copy ETS (TestReady, official practice tests, sample questions) or prep material.
- Items writers flagged for a human look: `docs/review-flags.md`.

## Ads
Ids in `config/admob.json`. Banner on Home tabs only; interstitial when leaving results or a practice set, 5 minutes
apart. Never during a mock, practice question or review. Debug builds use Google test units;
`bash scripts/check-release-ad-ids.sh` before a release build.

## Gate before commit
```
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```
Heavy jobs follow `~/.claude/heavy-jobs.md`: use `jobq`, then `./gradlew --stop`. Emulator AVD: `tofel_api35`.
