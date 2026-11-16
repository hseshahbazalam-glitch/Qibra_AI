# G2 pass report — honesty pass, and the workflows-free rebuild

Path: `docs/G2_PASS_REPORT.md` · Written on 2026-09-01 against
`arena/01a05b41-qibra-ai`, parent of this pass `a3f9ebf`. Every `05:xx:xx` time in
this file is a GitHub runner timestamp, and those runners' clocks read 2026-11-16;
the two dates are not a typo and the logs are quoted as printed.

Status — every run this pass produced, with the line read from that run's own log. A
docs-only commit gets its own run, and this file does not predict the outcome of the
run that follows it; the head's run is recorded in the hand-off.

| Tree | What it is | Run | Read from that run |
| --- | --- | --- | --- |
| `5e6abac` | the code of this pass (`47d0755`→`5e6abac`) | `43808377270` | `🎉 728 tests passed.` · `hard findings: 0 \| G2 advisories: 318 \| L2 alpha advisories: 80` · `ALL GATES PASS (static; device compile remains the authority)` |
| `0efc263` | this file, first landing | `43808868341` | `🎉 728 tests passed.` (`05:15:58.974`) · `static battery: 185 dart files under lib` · `0 \| 318 \| 80` |
| `41bf1d5` | prose only | `43809214669` | **`727 tests passed, 1 failed.`** — `Analyze` success, `Full test suite` failure, `Static battery` skipped |
| `604f635` | EMPTY commit, tree byte-identical to `41bf1d5` | `43809711358` | conclusion success with `Full test suite` and `Static battery` both success — a step list, not a quote: no log line was read for this one |
| `1e15761` | § 3 item 5 added | `43810762467` | `🎉 728 tests passed.` (`05:33:19.336`) · annotation `hard findings: 0 \| G2 advisories: 318 \| L2 alpha advisories: 80` |
| `06162ee` | run ids and claims tightened | `43811204972` | `🎉 728 tests passed.` (`05:37:05.414`) · annotation `hard findings: 0 \| G2 advisories: 318 \| L2 alpha advisories: 80` |
| `251da05` | alembic `0005` (§ 7); **zero Dart files** | `43814662942` | **`727 tests passed, 1 failed.`** — the § 3 item 5 flake again, same shape, on a tree that cannot have caused it |
| `61219fe` | EMPTY commit, tree byte-identical to `251da05` — the policy re-run | `43814962927` | all ten listed steps success · annotation `hard findings: 0 \| G2 advisories: 318 \| L2 alpha advisories: 80` |

Two rows in that table are the same story: `41bf1d5` (prose) and `251da05` (alembic
and backend tests, **no Dart file at all**) both printed
`727 tests passed, 1 failed.`, and both went green on a byte-identical tree one
commit later (`43809711358`, `43814962927`). That is the answer to the claim this file
itself made in its `0efc263` version — "one docs line moves no count" — and it is also
the evidence for § 3 item 5: the same one-test shape reproduces on trees that share
nothing but the Dart code, so the cause is the runner, not the diff. Nothing was
edited, skipped, retried or re-pinned to get any green in that table; the mechanism is
the owner's policy, recorded verbatim in § 7.

Operational note, because it changes what "the workspace" is: after `06162ee` the
sandbox was re-provisioned. `/home/user/Qibra_AI` came back as a fresh shallow clone
at `15a3a81` with 181 stale-modified paths and 54 untracked leftovers restored from a
snapshot, and the `.hrfix` worktree this pass was built in came back empty. Nothing
was authored away and nothing was deleted: the branch was fetched from `origin`, the
checkout fast-forwarded to `06162ee` (`git status --porcelain` → 0 lines,
`git diff --name-only 06162ee` → 0 paths), and the untracked leftovers were moved
aside to `/tmp/arena-stale-06162ee/`. All static and backend gates were then re-run
on the restored tree and reproduced exactly: `hard findings: 0 | G2 advisories: 318 |
L2 alpha advisories: 80` with `ALL GATES PASS`; backend `327 passed, 1 warning in
31.16s`; `pip-audit` → `No known vulnerabilities found`; `validate_content.py` →
`hadith_matrix_issues []`, 14 files / 14, `rows_with_neither_edition` 203,
`urdu_rows_off_spine` 1, `OK 114/6236; licenses not VERIFIED`; the hadith bundle on
disk 15 files, 65,741,265 bytes, no `arabic.json`. The Flutter gates could not be
re-run here (no Dart SDK in this sandbox either), which is why their evidence stays
the six CI rows above.

What it was is written up as a finding in § 3 item 5, and the honest headline is that
**the identity of that single failing test is not recoverable from here**: GitHub's
check-run annotations for that job carry only `727 tests passed, 1 failed.` and
`Process completed with exit code 1.` (3 annotations total, `output.summary` empty),
and the raw job log lives behind a blob-store redirect that this sandbox's egress
policy refuses (`curl` exits 35). The windows of that log that were readable
(05:17:59–05:18:35 and 05:18:55–05:19:27) contain no `❌` or `[E]` line at all — the
HR-1 benchmark and the HR-1.3 measurement both passing there — so the `[E]` line sits
in the stretch that was not readable, and no test is being named on suspicion.
Every number below was printed by a command and copied; where a number came from a
CI run, the run id is named next to it. Where a premise in the brief turned out to
be wrong, the correction is in the text, not in a footnote.

---

## 1. G2-A, G2-B, G2-C — LANDED

| Pass | Commit | Gate run | What it fixed |
| --- | --- | --- | --- |
| **G2-A** | `c60384f` | `43561236803` | boot refuses a silent config, hashes carry their cost, emails are canonical — QB-001, QB-004, QB-015, QB-017 |
| **G2-B** | `947d8cd` | `43561751059` | the account lifecycle does what it claims — QB-002, QB-003, QB-016 |
| **G2-C** | `1097d27` | `43562958923` | the paid endpoint is a paid endpoint, and a 429 wears its seatbelt — QB-011, QB-012, QB-013 |

Three run ids, three successes, nothing pending in those three passes. This file
does not re-litigate them; their evidence is in their commit bodies and the runs
named above.

## 2. G2-D — the rebuild, in the order the brief gave

A previous round of G2-D was lost before it landed; its scope was restated by the
owner as five items, and it is executed here in that order. `.github/` and
`analysis_options.yaml` were **not touched** (measured: `git diff --name-only
a3f9ebf..HEAD -- .github/ analysis_options.yaml` → 0 files), so nothing in this
pass edits a workflow — item 4 is a document for the owner to paste.

Discipline held: each Dart item ships its **red test first** as its own commit, with
the run id of that red recorded here, then the change. The backend items were
red/greened locally because CI has no backend job (that absence is item 4).

### 2.1 QB-006 — the forgot-password screen stops pretending (the only `lib/` change)

* red: `47d0755` (test only, `lib/` untouched) → **run `43806206960`, FAILED:
  `720 tests passed, 8 failed.`**
* green: `2e23957` (the screen + l10n)
* follow-ups: `8f0be57` (my analyzer error + a wrong grep path in my own comment),
  `5e6abac` (test 6 pinned prose instead of code)

**Deleted.** An email field with its `Form`/`TextFormField`/controller/focus
node/validator; `await Future.delayed(const Duration(seconds: 2))` sitting under a
comment that claimed to simulate the API call; `_isLoading`, `_emailSent`,
`_errorMessage` and the `AnimatedSwitcher` that flipped form→success; the
`AnimationController` pair and their curved tweens; 7 `HapticFeedback` calls
(including the heavy one that celebrated a link that was never sent);
`_buildErrorBanner` (a catch around a timer); `_buildInfoCard`/`_buildStepItem`
("NEXT STEPS"); `_buildSuccessActions` ("Open Email App"); `_buildBackToLoginLink`
("Back to Login"); the raw literals 'PASSWORD RECOVERY', 'Forgot Password?',
'No worries! …'; and `AppStrings.openingEmailApp`, whose only reader in `lib/` was
the button that used it (grep proved it, and no test named it).

**Written.** 925 lines → 270. The headline is "Not available in this build"; one
sentence says why ("Qibra AI has no email service connected, so this app cannot send
a password reset link"); a card states "Nothing was sent — no reset request was made
and no message is on its way. Your password is unchanged."; a second card, "What you
can do", lists the two things that actually work. Three `context.go` call sites, two
destinations (`AppRoutes.login` from the shared `AuthHeader` and the primary button,
`AppRoutes.register` from the secondary), both `AuthButton`s at the shared 56dp. No
field, no spinner, no `AnimationController`, no haptics, no `services.dart` import —
the screen has no mechanism left for implying work.

**i18n.** Ten getters in `app_strings.dart`, real in en/ar/ur (Arabic script in both
translation columns, ar≠en, ur≠en, ur≠ar), `String get` total 456 with zero
duplicate names, and `openingEmailApp` deleted (its name survives only in a
retirement comment). The line-based census in `test/core/i18n_phase_a_test.dart`
still finds exactly its 5 pinned allowlist entries and **zero** from this screen:
the screen has no raw `Text('X',` at all.

**a11y/i18n counters.** Old screen and new screen each contribute `IconButton(` 0,
`Semantics(` 0, `semanticLabel:` 0, `ExcludeSemantics(` 0, `liveRegion: true` 0,
`Tooltip(` 0, `AppStrings.of(context)` 1 — so every counter pinned in
`test/core/a11y_pass_test.dart` (63 / 1 / 2 / 3 / 25 / 52 / ≥70) is unmoved by
construction rather than by hope.

**Icons.** Four are used — `lock_reset_rounded`, `info_outline_rounded`,
`arrow_back_rounded`, `person_add_alt_1_rounded` — and each was validated against
`scripts/data/flutter_icons_stable.txt`, the same metadata battery G8 reads. The
lost round shipped `Icons.mail_off_rounded`, which does not exist, and paid 2 hard
findings for it; test 9 of the new file now pins this rule inside `test/`, so the
next screen cannot repeat it silently. No mail icon survives an honest screen.

**Two mistakes of mine, both CI's find, both disclosed:**
1. `8f0be57` — I removed `import '…/core/constants/app_constants.dart'` as "unused".
   It was the library declaring `AppRoutes` (via `parts/app_routes.dart`), so
   `flutter analyze` returned 3 × `error • Undefined name 'AppRoutes'` and run
   `43807569632` died in 15 s. Same class as HR-2.2's two SDK-invisible losses:
   a name used in a file need not be declared in that file.
2. `5e6abac` — test 6 checked the raw `app_strings.dart` for `openingEmailApp`, and
   my own retirement comment names it: the pin would have failed on prose. Moved to
   `_code()` (comment-stripped) plus a sharper `String get openingEmailApp` check.
   The guard family extracted `stripCommentsForGuard` precisely for this hazard, and
   I wrote a pin that violated its own helper's reason for existing.

**Corrected premise.** The screen's comment and the test's header originally cited
`grep -rn "forgot|reset" backend/app/api/`. `backend/app/api/` does not exist. What
was actually run, and what both files now say:
`grep -rniE "forgot|reset_password|password_reset|/reset" backend/app/` → exit 1, no
match; `routers/auth.py` mounts POST `/register`, `/login`, `/refresh`, `/logout`,
`/logout-all` and GET `/me`, `/sessions` (the `/verify` route belongs to billing,
not to auth). No recovery route exists to be faked.

### 2.2 QB-014 — the backend pins, and the weight that came off them

| Package | Before | After | Why |
| --- | --- | --- | --- |
| fastapi | 0.115.0 | **0.162.7** | brief |
| starlette | 0.38.6 | **1.10.0** | closes PYSEC-2026-1943 / -1941 / -161 / -2280 / -2281 / -248 / -249 |
| python-dotenv | 1.0.1 | **1.2.2** | closes PYSEC-2026-2270; kept (not deleted) because pydantic-settings 2.5.2 requires `python-dotenv>=0.21.0` |
| pytest | 8.3.3 | **9.0.3**, moved to the new `backend/requirements-dev.txt` | closes PYSEC-2026-1845; production must not install a test runner |
| python-jose[cryptography] | 3.3.0 | **deleted** | `grep -rn "jose" app/ tests/` → exit 1. Tokens are HMAC-SHA256 in `app/security.py:104,129`; passwords are `hashlib.pbkdf2_hmac` (`:42,:74`) |
| uvicorn / sqlalchemy / alembic / pydantic / pydantic-settings / email-validator / httpx | — | unchanged | 0.30.6 / 2.0.35 / 1.13.2 / 2.9.2 / 2.5.2 / 2.2.0 / 0.27.2 |

`requirements.txt`: 12 lines → 10. Compatibility read off PyPI metadata before
editing (fastapi 0.162.7 wants starlette>=0.46.0, pydantic>=2.9.0, anyio>=4.1.0;
starlette 1.10.0 wants anyio<5,>=4), and a clean `pip install` of both files resolved
without conflict (anyio 4.16.0). In that clean env `cryptography` and `ecdsa` are not
installed at all and the suite is still green — proof the deleted extra carried only
advisories.

**Audits, same command CI will run:**
```
pip-audit -r requirements.txt            (the old file)  -> exit 1
   Found 26 known vulnerabilities in 5 packages
   rows: starlette 14, python-jose 6, pytest 2, python-dotenv 2, ecdsa 2
   14 distinct ids: PYSEC-2024-232/-233, PYSEC-2025-185, PYSEC-2026-161/-1325/
   -1845/-1941/-1943/-2270/-2280/-2281/-248/-249/-4298
pip-audit -r requirements.txt -r requirements-dev.txt     -> exit 0
   No known vulnerabilities found
```

**Suite, three states** (`python -m pytest tests -q`, `/home/user/.venv-qb2`, a venv
created for this pass from nothing but the two requirement files, Python 3.11.2):
```
before, original pins          1 failed, 320 passed, 3 warnings in 27.64s
at the new pins, tests as-is   2 failed, 319 passed
after the two named edits      321 passed, 3 warnings in 31.06s
```
The first failure was **already on the tip** and is a real finding, not dependency
noise: `test_phase6_integrity.py::test_hadith_no_duplicate_ids_all_files_present`
asserts `len(rows) == 21` while `scan_hadith()` returns 14, because **HR-2.1** set
`HADITH_LANGS = ("english","urdu")` and deleted the seven `arabic.json` files
without re-pinning this line. So "full backend suite green" required a re-pin
**21 → 14**, disclosed here as an existing-test change caused by HR-2.1, not by the
bumps.

The second failure was caused by the bump and is FastAPI being *more* correct than
before: 0.116+ parses a body as JSON only when Content-Type says so, and
`test_qb012_streamed_body_cap.py::test_a_legitimately_large_sync_payload_still_gets_through`
posted raw bytes with no media type → 422 `model_attributes_type`. The fix is in the
test (one header, matching what `lib/core/network/api_client.dart:49-50` has always
sent and what the sibling 413-test at :176 already set); the app was **not**
loosened to keep a lenient fixture.

**Existing tests changed: two, by name** — `test_phase6_integrity.py` (re-pin, with
a comment naming HR-2.1) and `test_qb012_streamed_body_cap.py` (the content-type
header, with a comment naming the FastAPI rule). No bulk "updated tests" commit; no
other backend test file touched; no new test file in this item.

**Deliberate non-fixes.** Starlette 1.10's TestClient prints `Using httpx with
starlette.testclient is deprecated; install httpx2 instead`. We did not add `httpx2`
(a new dependency is out of scope) and did **not** edit `filterwarnings` to hide it.

### 2.3 QB-018 — alembic owns the schema; dev keeps a convenience

* red: `b3bb7bd` → `5 failed, 1 passed in 0.70s` locally (CI cannot see backend tests;
  that is item 4)
* green: `0580c64` → `6 passed in 0.81s`, and the full suite `327 passed, 1 warning
  in 31.92s` — **the suite's warning count went 3 → 1**, because two of the three
  were `on_event is deprecated`

1. `backend/alembic.ini` gains `prepend_sys_path = .`
2. `reset_engine()`'s `Base.metadata.create_all(bind=engine)` is now behind
   `if dev_mode():` — the gate has exactly one home, so no second call site can
   bypass it.
3. `@app.on_event("startup")` is replaced by an `asynccontextmanager` lifespan passed
   to `FastAPI(lifespan=…)`, which calls `reset_engine()` and must not touch
   `create_all` itself.
4. A new test drives the **console script**, not `python -m alembic`.

**The bug, measured.** `alembic/env.py:7` imports `app.db.*`; nothing put
`backend/` on `sys.path` for the bare script. So:
```
alembic heads                        -> 0004 (head)      # this subcommand never runs env.py
alembic upgrade head --sql           -> ModuleNotFoundError: No module named 'app'
python -m alembic upgrade head --sql -> runs fine        # runpy prepends the cwd
```
Every developer's migrations worked; the command `docs/DATABASE.md` tells an operator
to type did not. `alembic heads` looked healthy the whole time, which is why the test
refuses to trust it and runs `alembic upgrade head` against a fresh file database,
then asserts exit 0, `Running upgrade 0003 -> 0004`, `alembic_version = ('0004',)`,
and that the nine model tables are exactly what got built (+ `alembic_version`).

**The red behaviour, asserted not described.** With `QIBRA_ENV=staging` and a file
database, the old `reset_engine()` created `['audit_events', 'bookmarks', 'progress',
'refresh_tokens', 'sync_operations', 'sync_records', 'user_sessions',
'user_settings', 'users']`. Now the same call creates `[]`, and the dev call still
creates all nine (the suite depends on that half). The chain guard
(`0001→0002→0003→0004`, one head, read off the AST of `alembic/versions/*.py`) was
already green and stays: it guards the future, not the present.

**Correction to the brief's premise:** `alembic upgrade head --sql` cannot pass even
after the fix — revision 0004 uses `batch_alter_table` on sqlite, which needs a live
connection to reflect `progress` ("This operation cannot proceed in --sql mode"). The
test therefore does not use offline mode.

**Docs corrected rather than extended** (`docs/DATABASE.md`): why both alembic
commands must run from `backend/`, and a two-row table of what a boot does per
`QIBRA_ENV`. `docs/DEPLOY.md`: the `DATABASE_URL` row claimed "optional / default
in-memory SQLite" — stale since QB-004 (`database_url_or_raise`, `app/config.py:77`,
has no default and refuses SQLite outside dev); the `QIBRA_ENV` row claimed
"production turns on strict secret validation" — strict is the default, `dev` is the
opt-in. Both rows now say what is true, and the install row states that
`requirements-dev.txt` is *not* installed on the service.

### 2.4 QB-019 — the backend CI job, paste-ready and deliberately unapplied

`docs/ci-backend-job.yaml` carries the exact `backend:` job (ubuntu-latest,
`setup-python@v5` with `"3.12"`, pip cache keyed on both requirement files, `pip
install -r requirements.txt -r requirements-dev.txt`, `python -m pytest tests -q`,
`alembic upgrade head` + `heads | grep -q "0004 (head)"`, then a **fatal**
`pip-audit`), plus the one line telling the owner to append it under `jobs:` in
`.github/workflows/ci.yml` via the web editor and to fix that file's stale
"`Full test suite (the ~318-test gate)`" comment on line 35 (the suite is 719 in run
`43634767116`, 728 with QB-006's nine — read it off the run, not off this sentence).

Verified before writing: the merged YAML parses (`jobs: ['quality','backend']`, 6
steps); the migration step was executed verbatim in the same venv and matched; and
the trap that *would* have made the paste red is documented inline — exporting
`DATABASE_URL` at job level makes `test_qb004_database_guard.py` fail (measured:
`1 failed, 326 passed`, on `assert body["database"]["in_memory"] is True`), which is
why the exports live inside the one step that needs them. `alembic check` is
deliberately **not** a step, for the reason in § 3.

**Status: implemented, CI gate pending owner paste.** No test in this repo pins the
workflow — held back on purpose, because a test asserting the contents of a file this
pass may not touch would be a lie with an exit code.

## 3. Findings opened — one since closed by § 7, four still open

1. **`alembic check` is not clean** (found by QB-018, not by the brief) —
   **CLOSED by `0005`, § 7.** It read: against a database built by `upgrade head`, exit
   255 with missing index `ix_progress_user_id` on `progress.user_id`, and
   `users.updated_at` nullable in the migrations vs `nullable=False` in the model.
   Invisible while every boot ran `create_all`, because dev databases came from the
   models and production ones from the migrations. G2-D could not fix it (that pass
   pins head = `0004`), so it was named here and in `docs/DATABASE.md`, and `alembic
   check` was deliberately kept out of the CI paste so the paste would be green on
   arrival. The owner ordered the closure pre-merge; `alembic check` now exits 0 and
   the paste runs it fatally.
2. **The backend tip was not green when this pass found it** (`1 failed, 320 passed`)
   for the HR-2.1 reason in § 2.2. Re-pinned, with its name and justification.
3. **`docs/DEPLOY.md` carried two stale environment claims**, corrected in § 2.3.
4. **CI cannot see any of the backend work** — 327 tests and an audit that only this
   sandbox ran. QB-019 is the paste that closes it; until then every backend claim
   here is "green in `/home/user/.venv-qb2`, a venv nobody else has".
5. **The Flutter suite contains at least one test that is not stable under runner
   load** (found by `43809214669`, proven by `43809711358`). On a tree whose only
   difference from the green `43808868341` was prose in `docs/`, one test of 728
   failed; on a byte-identical tree one commit later, zero failed. Nothing was
   changed to buy that green — no test edited, no bound moved, no `retry`, no
   `skip`, no `filterwarnings` — because a flake papered over is a flake that comes
   back on the owner's machine at a worse moment.
   The suite's threshold-based tests, all of them pre-existing and none of them
   touched by this pass, are the only candidates by class:
   `test/features/hadith/hadith_pass_hr1_test.dart:612` (settle < 15,000 ms),
   `:681` (p95 main block < 16 ms over 14 keystrokes on 20,020 rows), `:684`
   (p95 end-to-end < 500 ms);
   `test/features/hadith/hadith_hotfix_hr13_fold_cache_test.dart:318`
   (p95 cached scan < `_scanBoundMs = 500.0`), `:398` (whole-corpus fold <
   `_wholeCorpusFoldBoundMs = 4000.0`), `:512` (fold growth ratio <
   `_foldGrowthBound = 12.0`), `:747` (RSS delta bounded by the mirror's own size);
   `test/features/hadith/hadith_hotfix_hr11_worker_liveness_test.dart:248,551,554`
   (miss/timeout counters, which move if the box stalls a reply);
   `test/features/ai/ai_revival_test.dart:128-131` (a 150 ms bounded poll asserted
   `>= 100` and `< 2000`) and `:160` (`< 1000`).
   A 16 ms p95 on a shared 2-core runner is the sort of gate that reads 11.3 ms on
   one run and 10.6 ms on the next, so a single excursion is plausible.
   **Status: the owner decided (2026-09-01) — "green on the shipping tree + one
   re-run, no re-pin, no skip", with the `@Tags(['perf'])` exclusion to be added by
   the owner's own `ci.yml` edit and `.github/` staying untouched by this agent.**
   That policy has now been applied twice on this branch, once on each side of the
   micro-pass (`43809214669` → `43809711358`, `43814662942` → `43814962927`), and the
   second pair is the sharper evidence because `251da05` changes no Dart file at all.
   Two consequences worth stating: the candidate list above is the exclusion list the
   owner will need, and the identity of the failing test is still unrecovered — if the
   `@Tags(['perf'])` edit is to be exact rather than broad, someone must read one of
   these logs from a machine that can reach the blob host.

## 4. Gates

| Gate | Required | Measured |
| --- | --- | --- |
| `flutter analyze --no-fatal-infos` | 0 errors, 0 warnings | green in run `43808377270` (the gate run). History: run `43806206960` (red tree) passed analyze and failed tests, which is the only reason a red round is useful; run `43807569632` **failed here with 3 × `error • Undefined name 'AppRoutes'`**, my mistake, fixed in `8f0be57`; run `43808267080` was cancelled by the next push (`5e6abac`) before it finished |
| `flutter test` | green | run `43808377270`: **`🎉 728 tests passed.`** — 719 + QB-006's 9. Red evidence, run `43806206960`: `720 tests passed, 8 failed.`, and the 9th (the controls test) passed on the old tree exactly as designed. Post-report runs on this same suite, none of which touched a Dart file: `43809214669` `727 tests passed, 1 failed.` → `43809711358` green on a byte-identical tree (§ 3 item 5); `43810762467` and `43811204972`, both `🎉 728 tests passed.` read from their logs; `43814662942` `727 tests passed, 1 failed.` on the `0005` commit → `43814962927` green, the policy re-run, all ten steps |
| `python3 scripts/static_battery.py` | hard 0 · G2 ≤ 319 · L2 ≤ 83 | **`hard findings: 0 \| G2 advisories: 318 \| L2 alpha advisories: 80`**, `static battery: 185 dart files under lib`, `ALL GATES PASS (static; device compile remains the authority)` — printed identically by CI (`43808377270`, from the log) and by the local A/B measurement (baseline `319 \| 83` obtained on this machine by checking out the pre-change files, so the −1/−3 delta is a measurement and not an inference) |
| backend suite | green | `335 passed, 1 warning in 34.34s` — 321 + QB-018's 6 + `0005`'s 8 (§ 7). At the G2-D gate run itself it was `327 passed, 1 warning in 31.92s` |
| `pip-audit` | 0 known vulns | `No known vulnerabilities found`, exit 0 |
| `alembic upgrade head` / `heads` / `check` | lands clean | exit 0 with `Running upgrade 0004 -> 0005`; `0005 (head)`; **`No new upgrade operations detected.`, exit 0** — was exit 255 with two drift ops before `0005` (§ 7) |
| `alembic downgrade 0004` + re-`upgrade head` | reversible | both exit 0 on the same file database, and `ix_progress_user_id` comes back |
| `assets/` | zero diff | `git diff --name-only a3f9ebf..HEAD -- assets/` → 0 files |
| hadith feature | untouched | `git diff --name-only a3f9ebf..HEAD -- lib/features/hadith test/features/hadith scripts/` → 0 files |
| `validate_content.py` | unchanged | `hadith_matrix_issues []`, `manifest {"ok": true, …, "issues": []}`, 14/14 files, english 35,975 (98.9 %), urdu 33,476 (92.0 %), `rows_with_neither_edition` 203 |
| `lib/` scope | QB-006 only | 2 files: `lib/core/l10n/app_strings.dart`, `lib/features/auth/presentation/forgot_password_screen.dart` |

One honest footnote on the 318: the G2 list is the "referenced but not provided by
imports" family, and the battery's heuristic accepts only the *defining* file as the
provider. So every file that uses `AppRoutes` is listed — `core/router/app_router.dart`
included — and `features/auth/presentation/forgot_password_screen.dart` appears once
for the same reason. It is the advisory that, had it been fatal, would have prevented
my `8f0be57` mistake; the repo keeps it advisory at a capped count because 185 files
generate 318 of them.

### Ledger, old → new

```
forgot_password_screen.dart        925 lines  ->  270
AppStrings `String get`            447        ->  456   (+10 forgot*, -1 openingEmailApp)
static battery hard findings       0          ->  0
static battery G2 advisories       319        ->  318   (the deleted 0.20/0.24 washes)
static battery L2 alpha advisories 83         ->  80    (same cause)
i18n raw-Text census               5          ->  5    (allowlist entries; this screen: 0)
Dart tests collected               719        ->  728  (+9, QB-006's file)
backend suite collected            321        ->  327  ->  335   (QB-018's 6, then 0005's 8)
alembic revisions / head           4 / 0004   ->  5 / 0005        (pre-merge micro-pass)
backend pytest warnings            3          ->  1    (on_event x2 gone; TestClient's stays)
backend pip-audit findings         26          ->  0
requirements.txt lines             12         ->  10   (+ new requirements-dev.txt: 12 lines)
hadith asset bytes / files         unchanged (15 files, 65,741,265 B, 62.70 MiB)
```

## 5. Standing walls — unchanged, and now matched by the UI

* **No email system.** Nothing in the product can send email. Until QB-006 the
  forgot-password screen claimed otherwise; now the screen says the feature is
  unavailable and offers only real exits. Fixed by honesty, not by a mailer.
* **Rate limits are per-process.** In-memory store; a multi-instance deploy divides
  the guarantee by the instance count. Unchanged, and still the reason the login
  guard and AI quota live where they do.
* **PBKDF2, not argon2id** (`hashlib.pbkdf2_hmac`, `app/security.py:42,74`). QB-014
  deleted `python-jose` and with it the transitive `cryptography`/`ecdsa` weight; the
  hash function is the standard library's, and the wall is untouched.
* **≤15-minute post-logout access window.** Access tokens stay valid until they
  expire; logout revokes the refresh side. Unchanged. The deleted fake "Link expires
  in 15 minutes" line on this screen was at least accidentally honest about a
  different number.
* **Urdu/English only hadith corpus, 203 rows with neither edition shown as-is**, and
  `has_verified: false` on the content manifest (114/6236 spot-check) — the HR-2.1 /
  HR-2.2 state, untouched by this pass.

## 6. What this pass does not claim

* It does not claim a device build. CI is the compiler and the static battery is a
  static approximation; the authority on a real compile remains a real compile.
* It does not claim Postgres behaviour: `pool_pre_ping`/`pool_size` are unread here,
  and no Postgres test runs anywhere.
* It does not claim CI enforces the backend. That needs the owner's paste of
  `docs/ci-backend-job.yaml` (QB-019), after which `335 passed`, `0 known
  vulnerabilities` and `alembic check` become machine-checked rather than reported here.
* It does not claim a deterministic first-attempt green from this suite. One test in
  the 728 has moved between runs on identical content twice (`43809214669` →
  `43809711358`, `43814662942` → `43814962927`); the gate is "green on the shipping
  tree + one re-run" (owner policy, § 7), and a red that does not reproduce is
  reported, not re-pinned.
* It does not verify 0005 against Postgres. `batch_alter_table`'s non-SQLite branch is
  read out of alembic's source, not executed — the first managed-database
  `alembic upgrade head` is that check, and the revision says so in its own docstring.
* It does not carry the release-chain ids: the PR number, the merge SHA and the
  `v1.0.0-rc` tag SHA live in the PR body and in the tag, because a file cannot contain
  the id of the merge that brings it in.

---

## 7. The pre-merge micro-pass — alembic `0005`, and the flake policy as ordered

Ordered by the owner on 2026-09-01, executed after G2-D and before the release
candidate: *"ALEMBIC 0005 FIRST (pre-merge, micro-pass): one migration that brings
the schema to what the models already say — create ix_progress_user_id, and align
users.updated_at nullability with the model. Red test first (a spec that fails on
0004, passes on 0005). Gates: backend suite green, alembic upgrade head lands clean,
flutter side untouched."*

**Red first — `5f4cc60`, one file only:** `backend/tests/test_alembic_0005_schema_drift.py`,
8 tests. CI has no backend job (§ 3 item 4), so the local run is the evidence, exactly
as in QB-018:

```
$ python -m pytest tests/test_alembic_0005_schema_drift.py -q
  8 failed in 4.54s
$ python -m pytest tests -q
  8 failed, 327 passed, 1 warning in 33.39s
```

The printed reasons are the drift, not scaffolding: `` `alembic check` still wants to
change the schema (exit 255) ``, `` `progress` has only ['sqlite_autoindex_progress_1'] ``,
`users.updated_at carries notnull=0`, `head must be exactly 0005, got ['0004']`,
`no revision file starting with '0005' exists`. All eight failed; none passed
vacuously, which is why the spec has no "expected to fail today" carve-out.

**Then the migration — `251da05`:**
`backend/alembic/versions/0005_schema_drift_closure.py`, three statements up, two
down, no new table:

| # | `upgrade()` | `downgrade()` |
| --- | --- | --- |
| 1 | `UPDATE users SET updated_at = created_at WHERE updated_at IS NULL` | `batch_alter_table("users")` → `alter_column("updated_at", nullable=True)` |
| 2 | `create_index("ix_progress_user_id", "progress", ["user_id"])` | `drop_index("ix_progress_user_id")` |
| 3 | `batch_alter_table("users")` → `alter_column("updated_at", nullable=False)` | — |

Two decisions in that order are the substance, not cosmetics. The `UPDATE` comes
first because a live database holding one NULL row would otherwise refuse the
migration outright. The `WHERE` is scoped because `now()` (or a `COALESCE(..., now())`
"just in case") would stamp every migrated account as freshly active — a lie about
data the app wrote correctly. A row that never changed was last changed when it was
created, so `created_at` is the only defensible fill, and `created_at` has been
NOT NULL since `0001`, so no fallback branch is needed at all.

**Green — the same two commands:**

```
$ python -m pytest tests/test_alembic_0005_schema_drift.py -q
  8 passed in 4.73s
$ python -m pytest tests -q
  335 passed, 1 warning in 34.34s
```

**The operator path, run the way `docs/DATABASE.md` tells an operator to run it**
(console script, from `backend/`, fresh file database — not `python -m alembic`, per
QB-018's `prepend_sys_path` hole):

```
alembic upgrade head                    exit 0, last step "Running upgrade 0004 -> 0005"
alembic heads                           0005 (head)
alembic check                           "No new upgrade operations detected."   exit 0
   (before 0005, the same command: exit 255,
    "New upgrade operations detected: [('add_index', Index('ix_progress_user_id', …)),
     [('modify_nullable', None, 'users', 'updated_at', …, True, False)]]")
alembic downgrade 0004; alembic upgrade head     both exit 0, and the index returns
PRAGMA index_list('progress')           ['ix_progress_user_id', 'sqlite_autoindex_progress_1']
PRAGMA table_info('users') → updated_at notnull = 1
```

**Existing tests moved, by name and justification** — QB-018 pinned the head the owner
ordered moved, so its pins moved with it and nothing else in that file did:

| Test | Change |
| --- | --- |
| `test_head_is_0004_and_the_chain_is_linear` | renamed to `test_head_is_0005_and_the_chain_is_linear`; `len(revisions) == 4 → 5`, `heads == ["0004"] → ["0005"]`, chain `["0004","0003","0002","0001"] → ["0005","0004","0003","0002","0001"]` |
| `test_the_console_script_builds_the_schema_on_a_clean_database` | `version_num == [("0004",)] → [("0005",)]`, and it now asserts `Running upgrade 0004 -> 0005` alongside the `0003 -> 0004` line. The nine-table census, the `declared - built == set()` assertion and the "the developer's own `./qibra.db` stays untouched" guard are unchanged |

One fix went to the new file itself, and it is disclosed because it was found by
running the test rather than by reading it: the model-side half of
`test_the_models_and_the_migrations_now_agree_by_construction` imported `Base` without
`from app.db import models`, so `Base.metadata` was empty and the comparison would
have passed vacuously (in practice it surfaced as `NoSuchTableError`). It now imports
the mappers and asserts `{"progress", "users"} <= set(Base.metadata.tables)` first.

**Docs, because the finding they record is closed.** `docs/DATABASE.md` keeps the
before/after measurements and its revision chain now ends at `0005`. The QB-019 paste
`docs/ci-backend-job.yaml` pins `0005 (head)`, counts 335 tests, and **adds `alembic
check` as a fatal step** — the only reason it was excluded was "not clean", and that
reason is gone; the block still parses to 6 steps with PyYAML. `docs/DEPLOY.md` needed
no change: it never names a revision.

**Disclosed, not claimed.** The Postgres branch of `batch_alter_table` is source
inspection — `requires_recreate_in_batch` returns False in
`alembic/ddl/impl.py:139-149` and the SQLite override at `alembic/ddl/sqlite.py:46-70`
returns True for any batch op that is not create/drop index — so `recreate="auto"`
means "recreate and copy here, plain `SET NOT NULL` there". There is no Postgres in
this sandbox; the first managed-database `alembic upgrade head` is the check, and the
revision says so about itself.

**Flutter side untouched, and CI answered twice.** `5f4cc60` and `251da05` change no
Dart file: 1 migration, 2 backend test files, 2 docs. The branch run for `251da05` was
**`43814662942` = `727 tests passed, 1 failed.`** — `Analyze` success, `Full test
suite` failure, `Static battery` skipped — the § 3 item 5 flake, same shape, on a tree
that cannot have caused it. Under the policy below it was re-run rather than repaired:
**`43814962927`** on `61219fe`, an empty commit whose tree is byte-identical, all ten
listed steps success with `hard findings: 0 | G2 advisories: 318 | L2 alpha
advisories: 80`. That re-run is the gate the release stands on.

### The flake policy, as ordered (decision 4, recorded here)

> the load-sensitive suite test is governed by "green on the shipping tree + one
> re-run" — no re-pin, no skip. The `@Tags(['perf'])` exclusion will be added by the
> OWNER's ci.yml edit, not by you. `.github/` stays untouched by you in all of this.

Applied, not just written down: each red above produced exactly one re-run on an
identical tree and a green, and no bound, tag, skip, `retry` or `filterwarnings` was
touched anywhere in this pass — `git diff --name-only a3f9ebf..HEAD -- .github/
analysis_options.yaml` → 0 files, re-measured after `0005`. Two notes for whoever
makes the owner's `ci.yml` edit: the list in § 3 item 5 is the exclusion list, and the
excluded tests should keep running in a job of their own — a gate moved somewhere that
never runs is a gate deleted.
