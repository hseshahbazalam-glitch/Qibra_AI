# G2 pass report — honesty pass, and the workflows-free rebuild

Path: `docs/G2_PASS_REPORT.md` · Written on 2026-11-16 against
`arena/01a05b41-qibra-ai`, parent of this pass `a3f9ebf`.

Status: the code of this pass is `47d0755`→`5e6abac`; run **`43808377270`** verified
that tree (`🎉 728 tests passed.`, `hard findings: 0 | G2 advisories: 318 | L2 alpha
advisories: 80`, success). This file landed in `0efc263` and run **`43808868341`**
went green on that tree with the same two lines read from its log — `🎉 728 tests
passed.` and `static battery: 185 dart files under lib` / `ALL GATES PASS`. The
sentence naming that run is a docs-only commit on top, and one docs line moves no
count; the run for it is named in the pass hand-off, not here.
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

## 3. Findings opened, and left open

1. **`alembic check` is not clean** (found by QB-018, not by the brief). Against a
   database built by `upgrade head` it exits 255 with: missing index
   `ix_progress_user_id` on `progress.user_id`, and `users.updated_at` nullable in the
   migrations vs `nullable=False` in the model. This was invisible while every boot
   ran `create_all`, because dev databases came from the models and production ones
   from the migrations. It needs a `0005` revision — out of scope for a pass that
   pins head = `0004` — so it is named here and in `docs/DATABASE.md`, and `alembic
   check` is not wired into the CI job so the owner's paste is green on arrival.
2. **The backend tip was not green when this pass found it** (`1 failed, 320 passed`)
   for the HR-2.1 reason in § 2.2. Re-pinned, with its name and justification.
3. **`docs/DEPLOY.md` carried two stale environment claims**, corrected in § 2.3.
4. **CI cannot see any of the backend work** — 327 tests and an audit that only this
   sandbox ran. QB-019 is the paste that closes it; until then every backend claim
   here is "green in `/home/user/.venv-qb2`, a venv nobody else has".

## 4. Gates

| Gate | Required | Measured |
| --- | --- | --- |
| `flutter analyze --no-fatal-infos` | 0 errors, 0 warnings | green in run `43808377270` (the gate run). History: run `43806206960` (red tree) passed analyze and failed tests, which is the only reason a red round is useful; run `43807569632` **failed here with 3 × `error • Undefined name 'AppRoutes'`**, my mistake, fixed in `8f0be57`; run `43808267080` was cancelled by the next push (`5e6abac`) before it finished |
| `flutter test` | green | run `43808377270`: **`🎉 728 tests passed.`** — 719 + QB-006's 9. Red evidence, run `43806206960`: `720 tests passed, 8 failed.`, and the 9th (the controls test) passed on the old tree exactly as designed |
| `python3 scripts/static_battery.py` | hard 0 · G2 ≤ 319 · L2 ≤ 83 | **`hard findings: 0 \| G2 advisories: 318 \| L2 alpha advisories: 80`**, `static battery: 185 dart files under lib`, `ALL GATES PASS (static; device compile remains the authority)` — printed identically by CI (`43808377270`, from the log) and by the local A/B measurement (baseline `319 \| 83` obtained on this machine by checking out the pre-change files, so the −1/−3 delta is a measurement and not an inference) |
| backend suite | green | `327 passed, 1 warning in 31.92s` (321 + QB-018's 6) |
| `pip-audit` | 0 known vulns | `No known vulnerabilities found`, exit 0 |
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
backend suite collected            321        ->  327  (+6, QB-018's file)
backend pytest warnings            3          ->  1    (on_event x2 gone; TestClient's stays)
backend pip-audit findings         26          ->  0
requirements.txt lines             12         ->  10   (+ new requirements-dev.txt: 12 lines)
hadith asset bytes / files         unchanged (15 files, 65,741,265 B, 62.69 MiB)
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
  `docs/ci-backend-job.yaml` (QB-019), after which `327 passed` and `0 known
  vulnerabilities` become machine-checked rather than reported here.
* It does not claim the merge: `main` is on hold until the owner orders the PR, the
  merge commit, and the `v1.0.0-rc` tag.
* It does not open `0005` for the alembic drift in § 3; that number is now reserved by
  a finding, not by a file.
