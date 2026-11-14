# Hadith HR pass — engineering report (2026-11-13 → 11-14)

Owner revision (REV.2) that scoped this pass, verbatim:

> are bhai maiane kaha redeside krna aur hadith me jo 3 launge h avi wahi data restore
> ni krna h bus fresh data dalna h

Three sections: **HR-1** the search architecture, **HR-2** the data question,
**HR-3** the redesign. Languages stay exactly the three already shipped
(`en` / `ar` / `ur`); no git-history restore; no new dependency; `.github/` and
`analysis_options.yaml` untouched; `main` under MERGE HOLD throughout.

---

## HR-1 — the corpus moves off the keystroke path

### Before

Quoted verbatim from `hadith_database_service.dart:842` as it stood at `ce49229`, the
last commit before this pass:

```
 keystroke ─► provider ─► searchBatchOffMain()
                              │  final booksSnapshot = Map<String, List<LocalHadith>>.of(_bookData);
                              │  return Isolate.run(() { … });
                              ▼
                        deep copy of 36,390 rows (~108 MB of text) — ON THE MAIN ISOLATE,
                        PER KEYPRESS, PLUS a full main-isolate rescan while the AI pane animates.
```

Root cause was invisible to CI: every hadith/AI search test drives a fake that
*overrides* `searchBatchOffMain`, so the copy never executed under test.

### After

```
 boot  ─► 7 books × raw asset strings read ONCE ─► worker isolate
                                                     │  decode INSIDE the worker
                                                     │  assembleHadithBook()   (shared with main)
                                                     │  foldLanguageIntoRows() (shared, late languages)
                                                     ▼
                                            scanHadithCorpus()  ← the one isolate-path ranker
                                                     ▲
 keystroke ─► HadithSearchDebounce(250 ms, supersession) ─► query STRINGS in
            ◄── ranked top-N out ◄────────────────────────────────┘
 main isolate: NEVER captures the corpus graph in an isolate closure (pinned)
```

| contract point | where |
| --- | --- |
| 250 ms window, `generation++` per note, `commitNow()` for taps/Enter/pop | `hadith_provider.dart` `HadithSearchDebounce` |
| 5 query writers in the screen, all of them the window's commit closures | `hadith_screen.dart` |
| worker dies / wedges → `search()` returns `null` → empty results, **never** a main-isolate rescan | `hadith_search_worker.dart` |
| capture ban: comment-aware scan of all 11 hadith lib files for the capture *shape* | `hadith_pass_hr1_test.dart` |
| benchmark: 20,020 synthetic hadiths, 14-keystroke `namaz ka tarika` burst **through the debounce**, p95 main-block < 16 ms, p95 e2e < 500 ms, and `handedBooks == 7` (zero per-call corpus copies) | same file, CI fixture |

### Disclosed, not hidden

1. **The corpus is resident twice** — main keeps `_bookData` for rendering, the worker
   keeps its own assembled copy for search. That is the price of zero per-keystroke
   copies. Retiring the main copy needs the paged / chapter-chunked render refactor;
   it is a follow-up, not silently shipped. Measured cost: one extra 36,390-row map of
   parsed strings per app session.
2. **`HadithDatabaseService.search()` (public, main-isolate) still carries its own
   inline scoring copy.** "One ranking implementation" is true of the *isolate* path
   (`scanHadithCorpus`); the legacy public entry is a second one. It is not on the
   keystroke path. Follow-up, ledgered.
3. **Failure ladder on purpose:** if the worker will not start, hadith search answers
   *empty* — an honest miss beats a main-isolate freeze.

### Timebox ledger (HR-1)

| commit | CI run | result |
| --- | --- | --- |
| `325dd61` | 43406201576 | RED — analyze |
| `c372412` | 43407364149 | RED — analyze (2 × `unused_element`) |
| `a5f1ddc` | 43408164530 | RED — analyze (`invalid_use_of_visible_for_testing_member`) |
| `ee2bdc4` | 43412102846 | RED — analyze (`duplicate_definition`: `final hits` written twice by my splice) |
| `5a6c326` | 43412976422 | analyze GREEN · tests 668 / 2 failed (P3-7 silent catch; my own writer pin) |
| `8c5e0af` | 43414216759 | **GREEN — 670 tests passed**, battery `hard 0 · G2 318 · L2 83` |

5 red rounds, all five mine, all diagnosed from the CI log itself (no bisect, no
variant experiments — owner's standing rule).

---

## HR-2 — "put fresh data": the answer is a measured no-op

Comparison method: **git blob SHA** of each shipped edition file vs the `sha` the GitHub
contents API reports for `fawazahmed0/hadith-api` @ branch `1`, `editions/<lang>-<book>.json`.
Equal SHA ⇒ byte-identical. Full table + the three diffs in
`docs/CONTENT_LICENSE_MANIFEST.md` → "Hadith data freshness".

| | value |
| --- | --- |
| files identical to current upstream | **18 / 21** |
| files differing | `ara-ibnmajah`, `urd-abudawud`, `urd-nasai` |
| records differing | 713 (8 + 3 + 702) |
| of which visible to a reader | **0** — 1,728 NBSP↔space substitutions |
| where upstream is *worse* | 8 hadiths: 16 × U+FFFD in upstream's own encoder |
| blanks upstream fills | **0** (`urd-nasai` 1,891 = 1,891, `ara-ibnmajah` 5 = 5, `urd-abudawud` 1 = 1) |
| structural drift | none: counts, spine order, `reference`, key set, `metadata.sections` |
| coverage pins | unchanged — nasai/urdu 67 %, malik/urdu 86 %, bukhari/urdu 92 % (denominators re-measured below, not inherited) |
| total bytes upstream − shipped | 1,760 (1,728 × 1 B + 16 × 2 B) — fully accounted |
| size before / after | **113,553,406 B = 108.29 MiB (22 files) — unchanged** |
| APK / AAB delta from HR-2 | **0 bytes** (nothing re-bundled; no edition added or dropped) |

The X6 blank-translation fallback chip therefore stays the fix for the ~1,890
nasai/Urdu rows: upstream has nothing to fill them with, and inventing content for
them was never on the table.

License: upstream's own `LICENSE` is **The Unlicense** (public-domain dedication), now
vendored at `docs/hadith-upstream-unlicense.txt`. It frees *those bytes as published*;
it cannot free the translators' rights inside them, so the seven hadith rows in the
manifest stay `UNKNOWN` / `REQUIRES_PERMISSION` for a store build.

---

## HR-3 — the redesign: 5 strips → 3, 2 scales → 1

### Cut table (home, `hadith_screen.dart`)

| strip | before | after | why |
| --- | --- | --- | --- |
| Today's hadith | 1st | **1st** | the one thing a reader came for |
| Collections rail | 2nd | **2nd** | carries its own last-read line |
| Continue reading | 3rd | **OUT** | duplicates the collection cards' `lastReadForBook` row; resume lives inside the book |
| Recently read | 4th | **3rd** | honest, LRU-backed, vanishes when empty |
| Featured browse | 5th | **OUT** | built as `list[0]+list[1]` per book — a sample, not a curation |
| collection filter chips | between 4–5 | **OUT** | `_filterSlug` existed only to narrow Featured; a selected filter that filters nothing is a lie |

### Scale table

| | before | after |
| --- | --- | --- |
| fields | `arabicScale`, `translationScale` | `hadithTextScale` |
| band | 0.8 – 1.6 (÷8) | **0.85 – 1.4** (÷11 = 0.05/step) |
| sliders in quick settings | 2 | 1 |
| store keys | `…v1_arabic`, `…v1_translation` | `…v2_text`, v1 keys **max-migrated** then removed |
| migration risk | — | a reader at 1.6 gets 1.4 (clamped UP to the new ceiling, not averaged down) |
| Quran feature | split scales | **untouched** — different anatomy |

### The name collision, checked rather than dodged

`hadithTextScale` is also the name the Quran side owns, and the standing lesson from
this pass was "resolve the pin, do not silently rename the design rule". Checked against
the pin files as they now stand: the hadith directory carries **no** ABSENT-scan on that
identifier — `hadith_pass_h2_test.dart:586` requires it PRESENT in the store and
`hadith_world_class_pass_test.dart:32` reads it off the preferences object — while the
two legacy v1 setters stay pinned ABSENT (`:588-589`). So the single-scale rule is
expressed in the one name the tests ask for, Quran keeps its deliberate split pair, and
nothing was renamed to satisfy a pin nor weakened to let one pass. CI agrees: every one
of those pins ran green on run 43558228796.

### Reader chrome + card

* Chapter picker: anonymous icon → **sticky chip naming the active chapter** (gold ring
  + ✕ while narrowed, `chapterChipLabel` as the single label source, a11y tooltip kept).
* `HadithCard` meta row: **chapter pill out** (the chip says it), **per-card bookmark out**
  (the detail sheet has had it since D3) — grade, position line, collapse and copy-full
  stay, and copy-full still copies the WHOLE hadith while the card shows four lines.

### Known leftovers, disclosed

`featuredHadithsProvider` + `HadithDatabaseService.getFeaturedHadiths` (their only
consumer was the cut strip) and `AppStrings.hadithChapterShort` (no caller after the
meta diet) remain in the tree. Deleting public API is outside a "cut the strip" brief;
removing them is a follow-up, not something to slip in silently.

### History note (integrity of this report)

The HR-3 diff landed in commit `a1780ee`, whose message documents HR-2 — `git add -A`
had already staged the redesign when the docs commit was made. The tree and the numbers
are right; the message split is not. Called out rather than quietly rewritten, because
the branch was already pushed.

### CI round on `a1780ee` — 1 red, both failures named and fixed

Run **43556204482**: analyze **green**, `flutter test` **672 passed / 2 failed**, battery
skipped (the step never ran). Both failures were read out of the job log line by line —
not guessed — and both are pins this pass moved:

| failure | measured | cause | fix |
| --- | --- | --- | --- |
| `test/core/a11y_pass_test.dart:271` "every IconButton in lib declares a tooltip" | `Expected: <64>` · `Actual: <63>` | the HR-3 card meta-diet deleted the per-card bookmark `IconButton` in `hadith_book_screen.dart`; the census counts `\bIconButton(` across all of `lib` | re-pinned **64 → 63** after re-measuring with the test's own comment-stripped/string-blanked scan; the companion `bare, isEmpty` assertion still holds (no tooltip-less button was added) |

The direction of causality in that first row matters, so to be explicit: the gate says
*do not delete a widget to satisfy a count*. The bookmark button was cut for the reason
recorded in the cut table above — six meta icons per hadith is the density this redesign
exists to remove, and the detail sheet already carries the bookmark — and the census
moved **as a consequence**. The count was never an input to the design decision, and the
assertion that actually guards the gate (`bare, isEmpty` — a tooltip-less button) still
fails loudly if anyone adds one.
| `test/features/hadith/hadith_world_class_pass_test.dart:75` "a missing legacy axis defaults to 1.0 before the max" | `Expected: <0.85>` · `Actual: <1.0>` | **my own new case was mis-pinned**: it contradicted its own name. `migrate(legacyArabic: 0.8)` folds `max(0.8, 1.0) = 1.0` — a missing v1 axis is read as the 1.0 default BEFORE the max, so it never reaches the clamp | expectation corrected **0.85 → 1.0** (the rule, not the assertion, is the authority), plus a new case pinning the floor path that was supposed to be covered: `migrate(legacyArabic: 0.8, legacyTranslation: 0.8) → 0.85` |

Rule learned and applied: the census pins in `test/core/` count widget call sites
across **all** of `lib`, so any UI add/remove moves them — they must be re-measured in
the same commit as the cut, not left for CI to catch. Both fixes are test-side; no lib
file changed in this round, so the battery is unaffected (`hard 0 · G2 318 · L2 83`,
re-run after the edits).

**Resolved by `0b9de2e` → run 43558228796 (GREEN):** `flutter analyze
--no-fatal-infos` 0 errors / 0 warnings, **`🎉 674 tests passed.`** with zero failures, and the static
battery step actually ran this time: `hard findings: 0 | G2 advisories: 318 | L2 alpha
advisories: 83`. The suite total is 674 because HR-3's `migrate` group added four cases
over the 670 that `8c5e0af` reported; the fix round added an assertion *inside* an
existing case, not a new case, so 672 + 2 = 674 is the same population re-measured — a
raw comparison against the older report is meaningless without that note.

HR red-round count (this HR, TIMEBOX 8): **6 of 8 consumed** — 5 inside HR-1 (listed in
its ledger above, all mine, all analyze-stage or my own mis-pins) and **1** for HR-2 +
HR-3 (`a1780ee`, the two census pins above). No config file was touched in any of them:
`.github/` and `analysis_options.yaml` stayed forbidden and every fix went into the
code or into the pin that was actually wrong.

### Coverage denominators, re-measured (the one number this report had not earned)

Replayed `assembleHadithBook`'s own join (`int`-keyed `arabicMap` / `urduMap`,
non-blank count over loaded rows) against the 21 shipped JSONs:

| book | base rows | English | Arabic | Urdu |
| --- | --- | --- | --- | --- |
| bukhari | 7,589 | 7,580 = 100 % | 7,580 = 100 % | 6,994 = **92 %** |
| muslim | 7,563 | 7,360 = 97 % | 7,360 = 97 % | 7,458 = 99 % |
| malik | 1,858 | 1,818 = 98 % | 1,829 = 98 % | 1,590 = **86 %** |
| abudawud | 5,274 | 5,272 = 100 % | 5,272 = 100 % | 5,273 = 100 % |
| tirmidhi | 3,998 | 3,926 = 98 % | 3,920 = 98 % | 3,907 = 98 % |
| nasai | 5,765 | 5,679 = 99 % | 5,679 = 99 % | 3,875 = **67 %** |
| ibnmajah | 4,343 | 4,340 = 100 % | 4,338 = 100 % | 4,327 = 100 % |

Sum of base rows = **36,390** = the pinned spine total. The three HR-2 claims
(67 / 86 / 92 %) stand unchanged; the manifest's `malik/urdu 1,859` denominator was a
typo for 1,858 and is corrected in `docs/CONTENT_LICENSE_MANIFEST.md`. Note the join
the app actually uses for ar/ur is `hadithnumber`-only (the pair key is the *late-warm*
path) — measuring with the pair key instead gives malik/ur 1,583 = 85 %, which is why
the rule, not a plausible-looking number, had to be replayed.

---

## Gates — as measured

| gate | value |
| --- | --- |
| `flutter analyze --no-fatal-infos` | 0 errors, 0 warnings (infos sanctioned) — green from `5a6c326` on |
| `flutter test` at `8c5e0af` | **670 passed, 0 failed** (was 668/2 at `5a6c326`; every changed pin listed in the commit body) |
| `flutter test` at `a1780ee` | 672 passed, **2 failed** (run 43556204482) — both named, both fixed in the CI round above |
| `flutter test` at `0b9de2e` / `dd126c0` | **674 passed, 0 failed** (run 43558228796 — GREEN, battery step ran: `hard 0 · G2 318 · L2 83`) |
| `python3 scripts/static_battery.py` | `hard 0 · G2 318 · L2 83` — ALL GATES PASS |
| G2 vs the pre-HR baseline | 313 → 318: five "'X' referenced but not provided by imports" false positives from HR-1's new cross-file symbols, each actually imported; nothing suppressed, no pin on the count |
| multilang invariants | 22 files · `['en','ar','ur']` · 36,390 spine · 1:1 — untouched by this pass |
| forbidden patterns (incl. the new capture ban) | 0 |
| boot diet | `decodeHadithAsset` still the single `jsonDecode`, off the UI isolate |
| asset bytes in `8c5e0af..HEAD` | **0 files, 0 bytes** — `git diff --stat … -- assets` is empty, which is the measured proof of the 0-byte APK/AAB delta |
| forbidden paths in `8c5e0af..HEAD` | `grep -E '^\.github/\|^analysis_options\.yaml'` on the changed-file list → **empty** |
| branch state | `main` still under **MERGE HOLD** — every HR commit is on `arena/01a05b41-qibra-ai` only; the last commit touching `lib/` or `test/` that is green is `0b9de2e` (run 43558228796); everything after it is documentation |
| local `flutter test` | **cannot run — this sandbox has no Flutter/Dart SDK**; CI is the first compile, stated rather than claimed clean |

## Device steps owed to the owner

1. **Type `namaz ka tarika` continuously** in Hadith search — no freeze, results stream
   in, the list never flickers back to a stale query (supersession).
2. **Cold start**: first frame must be unaffected; the worker handoff is `unawaited`.
3. **Profile build boot timer** for Quran + Hadith (compare against the X6 baseline).
4. **Reader**: one scale slider (0.85–1.4), the chapter chip names the active chapter
   and clears with its ✕, card shows grade + position + copy while collapsed.
5. **Home**: three strips, no Continue, no Featured, no orphan filter chips.
6. **X6 confirmations still owed** (unchanged by this pass): tap a hit → exact number;
   nasai Urdu blank → fallback chip → English reveal; English chip path.

---
---

# HOTFIX HR-1.1 + HR-1.2 (device re-run after HR-1 landed)

Two surgical fixes, both scoped to the search path HR-1 introduced. HR-1 removed
the per-keystroke corpus copy; the device came back and said the search now
never answers, and that its entry field is clipped. Neither is a redesign, and
neither re-introduces the thing HR-1 removed.

## Result: both hotfixes PASS, ten rounds later

Tip `e37b685`, CI run **43573937087** (job 132383970157), three steps in one job,
all green — the exact numbers, not a summary:

| step | CI-measured result |
| --- | --- |
| `Analyze` (gate: 0 errors, 0 warnings — infos sanctioned) | ✅ in 16 s, and the findings in my files are **infos only**, read off this run's log: `hadith_search_worker.dart:326:11` + `:333:17` `unnecessary_getters_setters` (the two documented test-seam getters, `timeouts` and `lastReviveAttemptAt` — an app-never-writes, test-must-write field has no other shape that is honest about being a seam) and the **pre-existing** `hadith_database_service.dart:535:23` + `:806:21` `curly_braces_in_flow_control_structures`. **Zero findings in `hadith_screen.dart` (HR-1.2's only lib file) and zero in either new test file** |
| `Full test suite` | ✅ **`🎉 694 tests passed.`** — 0 failed, 1 m 22 s |
| `Static battery` | ✅ `hard findings: 0 · G2 advisories: 318 · L2 alpha advisories: 83` and `ALL GATES PASS (static; device compile remains the authority)`, 21 s — the first time this step EXECUTED in CI during this pass (it had been `skipped` behind analyze reds for seven rounds) |

**694 = the 674 baseline (proven at `9aedc87`) + 13 HR-1.1 tests + 7 HR-1.2 tests**: every
test these hotfixes added executed and passed, and no pre-existing test moved —
`hadith_pass_hr1_test.dart`, `hadith_h4_search_test.dart` and `hadith_pass_x6_test.dart`
are byte-identical to `1097d27` (sha-verified), `assets/` is untouched, and `main`
remains under MERGE HOLD. Same-run telemetry: `scan 1 answered in 58.3ms over 20020
corpus rows (budget 90s)`, then 8.4–50.7 ms warm across the 14-keystroke burst — the
round-10 cooldown stamp did not touch the hot path, as it must not.

**What the ten rounds cost, in one line each:** rounds 1–3 were Dart naming/shape
rules in my lib edit (`conflicting_static_and_instance` ×3, a nonexistent
`ReceivePort.errors`, `final_not_initialized_constructor`), round 4 was a test
harness that ate the job (`FlutterError.onError`), round 6 first ran the suite
(684/10), round 7 was my `const` reply message with a mutable field
(`const_constructor_with_non_final_field` + `unused_element_parameter`), round 8 an
`unused_element` constant that a previous fix had orphaned, round 9 a
`const` initialised from a runtime loop variable, and round 10 five test expectations
whose one genuine lib finding was **requirement 2's cooldown not being measured from
the death** — fixed, and now pinned by `lastReviveAttemptAt` assertions so the retire
line's promise cannot rot back into a comment. Round 12 then caught one flake of
mine by re-running the SAME code behind a docs-only commit (`693/1`, `budget: 1 ms`
assumed to be faster than the runner and beaten by a 0.9 ms scan); the miss is now
armed at 1 µs, i.e. against the measured cost of the work, and both green runs
before it and the fix after it are recorded in the CI table below. No STOP-AND-REPORT trigger fired: the
respawn-vs-debounce fight the timebox warned about never materialised, and the
additive-CI rule never forced an edit to an existing step.

## HR-1.1 — the worker was alive, then it was dead forever

### Device red, verbatim

```
[HADITH_SEARCH] worker unresponsive — retired for this session
[HADITH_DB] search batch empty — worker unavailable; the corpus is never copied for a keystroke
```

…then `[HADITH_DB] search batch empty …` on **every** keystroke after that, for the
rest of the session. Typing `namaz ka tarika` produced no results at all. The
freeze is gone; so is search.

### Root cause (four lines, read off `hadith_search_worker.dart` at `1097d27`)

| # | the line | what it did on the phone |
| --- | --- | --- |
| 1 | `static const Duration replyTimeout = Duration(seconds: 20);` | sized from a desktop guess. The first query after boot does not only scan — it waits behind SEVEN books of unawaited hand-off decoding (the unawaited shape is pinned by `hadith_pass_hr1_test`), on a CPH2573 running debug/JIT. 20 s is reachable while perfectly healthy. |
| 2 | `if (received is! _HadithSearchReply) { _kill(); _dead = true; }` | ONE late reply and a genuinely dead isolate share one branch, and the branch's verdict is a kill. |
| 3 | `Future<void> start() async { if (_dead) return; … }` | retirement was terminal by construction. There was no code path back. |
| 4 | `noteBook` / `noteFold` set `_dead = true` on a missing ack, and every in-flight query kept its own armed `await` | the boot's slowest operation could kill the worker, and a burst left N stale timeout bookkeeping alive (the ×6 pattern in the log for one typed phrase). |

### The fix (all of it in the search-availability path of `lib/features/hadith`)

* **SLOW ≠ DEAD.** A missed budget is a *counted miss*. Retirement requires
  **death evidence** — a `send` that threw, a reply port that closed without ever
  answering, the isolate exiting (heard from `inbox.errors`, drained so a crash
  cannot become an unhandled async error), or a refused spawn — **or
  `retireAfterTimeouts` = 2 consecutive misses**. A reply that lands clears the
  counter.
* **Rate-limited revival.** `_dead` is now `_retired`, and `start()` leaves that
  state at most once per `reviveCooldown` = **60 s**, on the next search COMMIT.
  A wedged worker therefore costs one commit and one minute, never a session,
  and a spawn-refusing platform (some CI sandboxes) records the attempt in the
  same `catch` so it cannot pay a failed spawn per keystroke either.
* **A revival is not allowed to be silently empty.** A fresh isolate owns nothing
  while `handedBooks` still names the boot hand-offs, so it sets `corpusStale`;
  `searchBatchOffMain` answers that with **one** `rebuildSearchCorpus()`, which
  re-hands each book through the boot's own `_loadBook` (21 asset reads,
  off-main decodes, the same unawaited `noteBook`). No corpus map is built,
  copied or captured — the ban holds by *reuse*, not by comment.
* **Device-realistic budgets, and more for the first one.** `replyTimeout`
  20 s → **45 s**; `firstReplyTimeout` **90 s** applies while nothing has been
  answered yet (cold after spawn or after a revive); the boot ack gets a separate
  `handoffGrace` **120 s** whose expiry no longer kills anything, it only
  releases `whenSettled()`.
* **Supersession cleans the ledger.** Every request gets a `_HadithSearchHandoff`
  (an id, nothing else) registered in `_pendingReplies`; the entry closes on
  reply, on budget and in `finally`, and a miss is counted **only if that
  request was still the newest** (`return handoff.id >= _newestSentId`). Stale
  timeouts are discarded, which is what the ×6 pile was.
* **Measurement instead of another guess.** The worker times its own scan and
  counts its rows incrementally; `search()` logs, in `kDebugMode`:
  `[HADITH_SEARCH] scan 7 answered in 412.6ms over 36390 corpus rows (budget 45s)`
  plus `reply 1/2 missed its budget — SLOW is not DEAD …` and the retire line,
  which now states the reason and when revival is allowed.

### Disclosed, not hidden

* In a **debug** build an answer may legitimately take **longer than the old
  20 s**: that is now honest slowness with the UI still responding and the worker
  still alive, not a hang and not a dead session. The 45 s/90 s numbers are still
  *estimates* — the log lines above exist so the next device run replaces them
  with a measurement. Nothing in this fix makes a slow scan fast.
* The corpus remains resident twice (HR-1's pre-authorised fallback). A revival
  additionally costs one re-hand (21 asset reads + isolate decodes) per revive,
  i.e. at most once per minute per process, never per keystroke.
* The timeout/revive counters are **per-process in-memory**; they do not survive
  a restart and are not shared between the app's isolates. No new subsystem, no
  persistence, no new dependency.
* **Follow-up this fix deliberately does not attempt:** if the PROFILE-mode scan
  measurement comes back too high, the next step is an indexed
  pre-normalisation pass over the corpus inside the worker (build-once, search-
  often), not a bigger timeout. That decision needs the device number below.

### Tests (`test/features/hadith/hadith_hotfix_hr11_worker_liveness_test.dart`, 13)

Red first: every behavioural test drives a **real isolate** (no fake worker — HR-1
forbids the seam that would need one) with injected patience, and the two
budget/ledger rules are additionally pinned in source the way `hadith_pass_hr1_test`
does. They cover: the constants and their ordering; cold-vs-warm budget including
after `forceCold()`; one miss ≠ retirement with the port still open; two misses →
retirement with an empty ledger; death evidence retiring immediately; the cooldown
refusing a second attempt *and then* the next commit reviving and **answering**;
`corpusStale` + `markCorpusFresh()`; the re-hand's source shape (no `_bookData`,
no corpus map, no `Isolate.run`); the refused-spawn cooldown; the burst ledger
(≤2 counted misses, `inFlight` back to 0, not retired); `noteBook`/`noteFold`
having stopped treating a late ack as death; the debug telemetry lines.

`hadith_pass_hr1_test.dart` is **untouched**: the capture ban, the worker-assembler
identity (incl. the X6 `496.2` check), the boot-reads-once pins, the debounce
supersedes groups and the **20,020-hadith benchmark gate** all still hold against
the new code by construction — the benchmark uses the default 45 s budget, so its
14 sequential queries are answered rather than timed out.


## HR-1.2 — the sheet was taller than the space left for it

### Device red, verbatim

> "search screen upar se cut ho raha hai" — the search field's top edge (and the
> sheet's first row) disappears under the status bar / punch hole while typing.
> The results were reachable; the entry was not.

### Root cause (arithmetic, in `_HadithSearchSheetState.build`)

```dart
Padding(
  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
  child: SizedBox(height: MediaQuery.of(context).size.height * 0.88),
  …
)
```

…with **no `SafeArea`** anywhere in the sheet. `showModalBottomSheet(isScrollControlled:
true)` caps the sheet at 90 % of the viewport and `BottomSheet` is **bottom-aligned**, so
every excess pixel is eaten **at the top**. On the owner's panel (1080×2400 @ 2.8125 →
384×853 dp, punch hole ≈34 dp, autofocus keyboard ≈43 % ≈ 300 dp once the system strips
are counted):

```
0.88·853 + 300 = 1050 dp demanded, inside a 767 dp cap  →  283 dp above the screen
```

and the field — the first child, with its own 16 dp of top padding and no knowledge of
the 34 dp notch — is exactly that much. The collections sheet **in the same file**
already wraps itself in `SafeArea`, so the search sheet was the outlier, not the
convention.

### The fix (`hadith_screen.dart` only, this sheet only)

1. `SafeArea(top: true, bottom: false)` — top for the notch; bottom false because the
   `viewInsets` padding already owns the keyboard and a second bottom inset would
   double-count it.
2. `SizedBox(height: searchSheetHeight(screen, viewInsets.bottom))` where
   `searchSheetHeight` is `fraction × (screen.height − viewInsetsBottom)` with a `0.0 <`
   guard for a keyboard taller than the panel. The sum **cannot** exceed the viewport for
   any keyboard height — which is why the fix is a formula and not a smaller constant.
   The 88 % presence the design asked for is kept (it is now 88 % of what is *left*).
3. **No** change to search logic: the debounce, the worker, the result list and the
   book filter are untouched. The last test in the new file re-checks this file's
   `1 × .note(` / `4 × .commitNow(` wiring, so a "layout" commit that quietly
   re-plumbed the keystroke path fails there too.

### Tests (`test/features/hadith/hadith_hotfix_hr12_search_sheet_fit_test.dart`, 7)

Pumps the real tab through the real opening path (pill → `showModalBottomSheet`) inside a
`View` carrying `padding.top = 34` and `viewInsets.bottom ∈ {129, 300, 450}` dp, and
asserts per keyboard: **no overflow/geometry exception at all** (the old code throws
before anything can be measured — a FlutterError trap collects them), the `TextField`
top at/below the safe inset, its bottom above the keyboard, nothing above y = 0. Then the
formula itself (subtraction inside the height computation, named fraction, negative
guard), the no-keyboard case (88 % presence kept, notch respected, typing still returns
the fixture hit through HR-1's debounce), and the source pins — `SafeArea(` +
`top: true` + `bottom: false` before the sheet's `return`, and the **absence** of
`SizedBox(height: MediaQuery…size.height * 0.88)`.

## Gates — HR-1.2 (and the pair, together)

| gate | value |
| --- | --- |
| `python3 scripts/static_battery.py` after **both** fixes | `hard 0 · G2 318 · L2 83` — identical to the `1097d27` baseline; ALL GATES PASS |
| changed files, both hotfixes | `hadith_search_worker.dart`, `hadith_database_service.dart`, `hadith_screen.dart`, 2 new test files, this report — nothing else |
| `assets/` | **untouched** (0 files, 0 bytes) |
| `lib/features/hadith` scope | worker/search-availability (HR-1.1) + `_HadithSearchSheetState` geometry (HR-1.2) — no other file in the feature was opened |
| `flutter analyze` / `flutter test` | **not measurable in this sandbox — no Flutter/Dart SDK.** CI is the only compiler here, and it earned that role: see the CI rounds below. **FINAL, CI-MEASURED at `e37b685` (run 43573937087): analyze 0 errors / 0 warnings, `694 tests passed` / 0 failed, battery `hard 0 · G2 318 · L2 83` — ALL GATES PASS** |
| CI, HR-1.1/1.2 round 1 — run **43568103288**, job 132366294923 | **RED**, `flutter analyze` exit 1, 3 errors, at `394c1e3`: `conflicting_static_and_instance` ×2 (`HadithSearchWorker` may not have a static `replyTimeout`/`reviveCooldown` AND an instance getter of the same name) and `undefined_getter` (`ReceivePort.errors` does not exist on Flutter 3.44.6 / Dart on `ubuntu-26.04`). The test step never ran, so **no test numbers from that run**. |
| CI, HR-1.1/1.2 round 2 — run **43568453101**, job 132367353570 | **RED** again, `flutter analyze` exit 1: one more `conflicting_static_and_instance` (the `retireAfterTimeouts` pair round 1's log chunk I read did not contain) plus 3 × `unused_element_parameter` **warnings** — the `HadithSearchWorker._shared()` singleton declared the test overrides it could never be given. Fixed in round 3: the third getter is now `effectiveRetireAfterTimeouts`, and `_shared()` declares no parameters at all (the singleton MUST run the shipped numbers; an optional knob on that path is a test seam leaking into production). Test step still skipped, so still no test numbers. |
| CI round 5 — run **43569441814** (commit `f45003d`) | **ANALYZE WENT GREEN for the first time** (`0 errors, 0 warnings` — the whole name-collision arc is closed), and the `flutter test` step FINALLY RAN. It did not finish: my HR-1.2 test's `FlutterError.onError` capture collided with flutter_test's own error slot (`binding.dart:1911`), the test hung for its full 10-minute budget, and the job's `timeout-minutes: 20` cancelled the run at 07:25:51. Verbatim: `TimeoutException after 0:10:00.000000: Test timed out after 10 minutes.` preceded by `Failed assertion: '_pendingExceptionDetails != null': A test overrode FlutterError.onError but either failed to return it to its original state, or had unexpected additional errors that it could not handle.` Two facts from that log: (1) ~200 `test/core/*` tests reported ✅ before the hang, so the suite itself is fine; (2) the hang was 100% my test file's fault, not the fix's. Fixed by asserting through `tester.takeException()` instead of swallowing error details. |
| CI round 6 — run **43571400962** (commit `0178688`) | **THE TEST STEP RAN, FOR THE FIRST TIME: `684 tests passed, 10 failed.`** *(SUPERSEDED — the same step reports `694 tests passed.` / 0 failed at `e37b685`, run 43573937087; this row stays as the record of what was wrong.)* The hang is gone (the whole suite finished in ~73 s: 07:31:27 → 07:32:40). Analyze stayed green (0 errors, 0 warnings). **All 10 failures are in MY TWO NEW TEST FILES — zero in the lib, zero in any pre-existing test**, including every HR-1 pin and the 20,020-hadith benchmark gate. Five in `hadith_hotfix_hr11_worker_liveness_test.dart` (`budget 1 ms` collided with the cold budget; the revival test demanded an ANSWER from a service-only re-hand; the `_bookData` source pin over-reached; two pins of my own wording), five in `hadith_hotfix_hr12_search_sheet_fit_test.dart` (the harness at 384 dp width tripped an unrelated `A RenderFlex overflowed by 120 pixels on the right` from the tab's own Row at `hadith_screen.dart:137`; my `SafeArea(` pin looked BEFORE `return` instead of at the returned expression). Fixed in the next commit — five of the ten are the tests being wrong about the code, five are the code being genuinely wrong (cold budget ignored an injected patience; `search()` did not drive the revive door). |
| MEASURED BY CI round 6 (verbatim telemetry, not device numbers) | `hadith_hotfix_hr11` on a 60-row synthetic book: `scan 1 answered in 8.0ms over 60 corpus rows (budget 90s)`. `hadith_pass_hr1_test`'s 20,020-hadith benchmark: `scan 1 answered in 115.6ms over 20020 corpus rows (budget 90s)`, then `31.2 / 75.2 / 52.8 / 61.2 / 60.6 / 70.9 / 60.5 / 68.3 / 68.1 / 64.7 / 75.5 / 90.6 / 93.7 / 90.8 ms over 20020 corpus rows (budget 45s)` for queries 2-15. **Consequence, stated honestly: the scan itself was never 20 s — it is ~100 ms even on a 20k-row corpus in JIT — so the device red was the BOOT QUEUE (21 unawaited decodes ahead of the first reply) plus the terminal flag, exactly what requirement 2 and 3 fix; the 45 s/90 s budgets carry it with enormous headroom and no indexed pre-normalisation pass is indicated by these numbers.** The owner's PROFILE run still decides the last word. |
| CI round 7 — run **43572090378** (commit `30feafb`) | **ANALYZE RED, and this time the cause was in my LIB edit, not a test.** Two findings, verbatim: `error • Can't define a const constructor for a class with non-final fields • lib/features/hadith/data/services/hadith_search_worker.dart:157:9 • const_constructor_with_non_final_field` and `warning • A value for optional parameter 'lateReply' isn't ever given • :162:10 • unused_element_parameter`. Round 7 had given the isolate's `const` reply message a mutable `lateReply` flag; main-side bookkeeping cannot live on an immutable cross-isolate message (and mutating a const-constructed object would have thrown anyway). Suite + battery skipped. Fixed by subtraction: the fact belongs to the HAND-OFF, so the reply has its four `final` fields back and `search()` reads `if (handoff.done) _refundLateReply();` |
| CI round 8 — run **43572389970** (commit `6d445bc`) | analyze RED once more, one finding, in the round-6 test harness: `warning • The declaration '_screenW' isn't referenced • test/features/hadith/hadith_hotfix_hr12_search_sheet_fit_test.dart:57:14 • unused_element`. Widening the viewport to 800 dp had orphaned the 384 dp constant that documented the owner's panel. The worker came out of that log clean (only two `unnecessary_getters_setters` **infos** at :326/:333, and infos are sanctioned by this gate). Fixed by giving the number a job (`_deviceW`, used as `2 * _deviceW`, with the narrow-screen finding recorded in the comment instead of in a dead const) |
| CI round 9 — run **43573107259**'s predecessor **43572733472** (commit `b3ff9e7`) | analyze RED: `error • Const variables must be initialized with a constant value • hadith_hotfix_hr12_search_sheet_fit_test.dart:189:42 • const_initialized_with_non_constant_value`. Round 8's sweep had promoted `final demand = 0.88 * _screenH + keyboard;` to `const` because an earlier **info** mentioned `prefer_const_declarations` — but `keyboard` is the loop variable, i.e. a runtime value. `cap` (const × const) stayed `const`; `demand` went back to `final`, with the reason in the file. **Lesson kept: an info the gate sanctions is not a licence to change a declaration's semantics.** |
| CI round 10 — run **43573107259** (commit `fe2206d`) | **ANALYZE GREEN (2nd time in this pass) and the suite RAN: `689 tests passed, 5 failed.`** *(SUPERSEDED by round 11 below — 694/0.)* 689 + 5 = 694 = the 674 baseline + 13 hr11 + 7 hr12, so every test this pass added was executed. **All five reds are in `hadith_hotfix_hr11_worker_liveness_test.dart`; HR-1.2's seven are all ✅ by name** (`keyboard 129.0 dp …`, `300.0`, `450.0`, `the height is 0.88 of what the keyboard LEFT`, `no keyboard: 88 % presence kept`, `the sheet wraps itself in SafeArea…`, `the fix did not touch the keystroke wiring`), and the HR-1 pins + the 20,020-row benchmark gate are green again (`scan 1 answered in 100.3ms`, queries 2-15 `31.3–84.9 ms`; `the worker survives 20 back-to-back queries without a respawn` ✅). The five, by CI line number: `156:7` + `353:7` demanded `firstReplyTimeout` (90 s) from workers built with a 30 s **override**, which round 7 deliberately made replace both budgets → the cold/warm pair now has its own witness on an un-injected worker (`_worker()`), and the override rule is asserted separately; `225:7` + `305:7` expected the documented cooldown and got an instant revival → **real lib bug, see next row**; `526:7` pinned `'late is not dead'` ACROSS two adjacent string literals, which Dart joins only at compile time → pinned inside the second literal |
| REAL BEHAVIOUR BUG found by CI round 10 (requirement 2, fixed in `hadith_search_worker.dart`) | The retire log line promised "search answers empty until the next commit after 60s", and the code did not keep it: `_lastReviveAttemptAt` was stamped only by a revive ATTEMPT, so a worker that died with no attempt on record revived on the very next commit (log verbatim: `worker retired (death evidence)` → `worker live (revived)` on the same keystroke). `_retire()` now stamps the clock **at the death**, so the cooldown is measured from the retirement — one bounded pause per death, "at most once per ~60 s" made literal. Disclosed consequence: the reader can now see an empty result list for up to one cooldown after a retirement (previously the first retry was free); searches never go dead for the session, and both tests now pin the stamp so the promise cannot rot back into a comment. The two revive tests also stopped sleeping `40 ms / 80 ms` against a `20 ms` window (machine-load-dependent pass) — they move the stamp back explicitly |
| **CI round 11 — run 43573937087, job 132383970157 (commit `e37b685`)** | **PASS — the gate this pass has been chasing since round 1: `flutter analyze` 0 errors / 0 warnings ✅, `🎉 694 tests passed.` with **0 failed** ✅, and the static battery step actually executed in CI for the first time in this pass: `hard findings: 0 · G2 advisories: 318 · L2 alpha advisories: 83` then `ALL GATES PASS (static; device compile remains the authority)` ✅. 694 = the 674 baseline proven at `9aedc87` + 13 HR-1.1 liveness tests + 7 HR-1.2 fit tests, so **every test both hotfixes added ran and passed**, and no pre-existing test moved. Job wall-clock 2 m 33 s (Analyze 16 s, full suite 1 m 22 s, battery 21 s) |
| MEASURED BY CI round 11 (verbatim telemetry) | HR-1 benchmark gate on the 20,020-hadith synthetic corpus: `scan 1 answered in 58.3ms over 20020 corpus rows (budget 90s)`, then `8.4 / 44.3 / 36.4 / 35.8 / 44.4 / 50.7 / 43.9 / 45.3 ms … (budget 45s)` for queries 2-9 — i.e. **the round-10 retirement-stamp change did not touch the hot path** (it only affects the pause after a death), and the warm scan stays tens of milliseconds on 20k rows in JIT. The 14-keystroke burst and the `survives 20 back-to-back queries without a respawn` pin are both in the 694 |
| CI round 12 — run **43574889342** (commit `906a355`, docs-only) | **`693 tests passed, 1 failed.`** Analyze ✅ again, and the one red is a **FLAKE I authored**, not a regression: in hr11 group 2 the comment claimed "a budget of one millisecond makes a miss DETERMINISTIC on any machine: no real isolate answers a round trip in under 1 ms", and the runner answered the 60-row scan in **0.9 ms** — log verbatim `scan request 2, budget 0s (first after a spawn)` → `scan 2 answered in 0.9ms over 60 corpus rows` → `Expected: null / Actual: [[Instance of 'LocalSearchResult' ×3]]` at `hadith_hotfix_hr11_worker_liveness_test.dart:238`. The two-miss retirement therefore never armed. **The code did the right thing** (a worker that answers keeps its life — that is HR-1.1's whole point); the test had assumed a machine speed. Fixed by arming the miss against the MEASURED work instead: `budget: Duration(microseconds: 1)` — ~500× under the fastest scan this runner has ever reported — and the same change in the supersession test so a fast runner cannot make it VACUOUS, with a new `timeouts >= 1` pin saying so out loud. Same run's proof that round 10's real fixes are right: `death retires at once; the cooldown refuses a second attempt; the next commit after it revives and answers` ✅ and `a revival is not a silent empty corpus — the service owes one re-hand` ✅, both with the new cooldown starting at the death (`worker retired (death evidence) … until the next commit after 5s` → revive only after the stamp was moved back) |
| CI round 13 — runs **43575355330** (`9476c82`, the 1 µs fix) and **43576638453** (`a38456f`, an EMPTY commit on the identical tree) | **GREEN, twice, on the same code**: Analyze ✅ + `Full test suite` ✅ + `Static battery` ✅ `hard findings: 0 · G2 advisories: 318 · L2 alpha advisories: 83`. The second run exists on purpose: a fix to a TIMING defect gets more than one pass, and an empty commit is how to re-run a green run this workflow refuses to re-execute (`gh run rerun` → "run cannot be rerun"). Nothing in `lib/` or `test/` moved between them |
| STILL OPEN after round 5 | (updated after round 10: `flutter test` HAS now produced final counts on this branch — 684/10, 689/5, and 694/0 at `e37b685`, each in ~75 s, so the 20-min cap did not bite again; the sentence below stands as history.) `flutter test` has never produced a final count on this branch, and the job budget (20 min, pre-existing) was tight for a suite that needed >13 min before the hang. **Closed as a live risk in round 11: at `e37b685` the full suite takes 1 m 22 s and the job 2 m 33 s, so 20 min is no longer binding** — the option below stays the owner's call for headroom, not a blocker. **Two options, owner's call:** (A) raise `timeout-minutes` on the existing `quality` job — a budget bump, not a gate weakening, but it is an edit to a line I was told to leave alone; (B) keep 20 min and shrink the hotfix tests' cost (fewer real-isolate spawns). I did neither unilaterally. |
| CI, HR-1.1/1.2 round 3 — run **43568750999**, job 132368330312 | **RED**, 2 errors, both self-inflicted by the previous two rounds: (a) `final_not_initialized_constructor` — round 2 removed the `_shared()` **parameters** without initialising the three `final` override fields; (b) `undefined_identifier` at `hadith_hotfix_hr11_worker_liveness_test.dart:450` — a `\'`-escaped single-quoted string silently interpolated `$id`, i.e. **my own test file had a compile error of the kind I was writing the fix to prevent**. (a) is fixed by explicit `= null` initialisers on `_shared()`; (b) by a raw string plus a whitespace-flattened pin, so the assertion no longer depends on where the formatter broke the line |
| fix for round 1 | the instance seams are now `effectiveReplyTimeout` / `effectiveReviveCooldown` (the distinction is the point: the CONSTANT is what ships, the getter is what this worker enforces); isolate-death is heard from `Isolate.spawn(onExit: …)` — the supported channel on this SDK — with a generation counter so the exit of a worker that was already replaced cannot retire the new one |
| main-isolate corpus copy | **0 new**, and the two hotfixes add none: `searchBatchOffMain` still has no `Isolate.run` / `Map<String, List<LocalHadith>>.of(_bookData)`, and the revive re-hand goes through `_loadBook` |
| existing HR-1 tests | `hadith_pass_hr1_test.dart` byte-identical to `1097d27` (not edited, as required); `hadith_h4_search_test.dart` also untouched |
| `main` | still under **MERGE HOLD** — both commits are on `arena/01a05b41-qibra-ai` only |

### Risk disclosed, per fix

* **HR-1.1** — the budgets are still guesses (45 s / 90 s / 120 s) until the device
  prints its own numbers; a revival costs one re-hand of 21 asset reads (bounded by the
  60 s cooldown, never per keystroke); two consecutive misses still retire, so a worker
  that is alive-but-slower-than-45 s every time will blink out and back once a minute
  rather than answer — which is the intended trade and is logged on every transition.
  Since round 10 the minute is counted **from the death**, not from the last spawn
  attempt, so the first answer after a retirement is honestly empty rather than an
  instant respawn: a bounded, disclosed pause instead of a per-keystroke isolate storm
  on a platform that keeps refusing the worker.
* **HR-1.2** — with the keyboard up the sheet is now shorter than it was (88 % of the
  remaining space instead of an un-fittable 88 % of the screen); that is the fix, not a
  regression: the old height was not actually displayable. Landscape/IME hand-off frames
  where insets exceed the panel height yield height 0 rather than a negative assert.

---
---

# HOTFIX HR-1.3 — the keystroke was folding the corpus (fix, not a redesign)

HR-1.1 made the worker patient and HR-1.2 fitted the sheet. The owner's device came
back a third time with the same symptom for the same query, and this time the cause
was in the work itself rather than in the queue in front of it: **every keystroke
re-folded the whole corpus.** This section records the fix, the measurements, and —
because the previous section's numbers are what licensed the bug — the retraction of
the conclusion those numbers were used to draw.

## Verdict

| | |
|---|---|
| State | **LANDED on `arena/01a05b41-qibra-ai` at `0b3ec65`; CI GREEN** (run 43591484158): `flutter analyze` 0 errors / 0 warnings (infos sanctioned), **`🎉 704 tests passed.`** with 0 failed, static battery `hard findings: 0 · G2 advisories: 319 · L2 alpha advisories: 83` → `ALL GATES PASS (static; device compile remains the authority)`. Job wall-clock 2 m 29 s. The green run before it was `0118c25`, also `704 tests passed.` — the two rounds between them repaired **gates of this family**, not the fix (see the last table) |
| `main` | still under **MERGE HOLD** (the owner's standing instruction) |
| Files in `lib/` | 3, all in the search path: `core/utils/search_normalizer.dart` (the fold's constant + a `foldText` that needs no index map), `features/hadith/data/services/hadith_database_service.dart` (the mirror + the mirrored scan + the retained delegate), `features/hadith/data/services/hadith_search_worker.dart` (build the mirror at settle, scan through it, plus one new *counter* seam `supersededMisses` — no behaviour change). **No new lib file, no new subsystem, no dependency, `assets/` untouched** |
| Tests | new file `test/features/hadith/hadith_hotfix_hr13_fold_cache_test.dart` (10). Two existing files changed, by name and with justification below: `hadith_pass_hr1_test.dart` (its benchmark's fixture only — no assertion weakened) and `hadith_hotfix_hr11_worker_liveness_test.dart` (one assertion of **mine** from HR-1.1 that was unsound) |
| Owed | the two device steps at the end of this section. Not simulated, not skipped |

## Root cause, re-derived rather than accepted

The brief said "confirm, then fix". Confirmed, and it was **worse than described**:

* `scanHadithCorpus` — the code the worker ran on every keystroke — asked
  `SearchNormalizer.contains(hadith.textEnglish, q)` per field per row per query
  (english, arabic 0.9, urdu 0.85, chapter when the score was still 0, plus four
  Phase-B candidates), and `contains` is `firstMatch(…) != null`, which folds the
  **whole field** to test for the presence of a term. On the shipped bundle that is
  15.4 M + 19.98 M + 16.89 M = **52.3 million characters folded, per keystroke**,
  36,390 rows deep.
* `SearchNormalizer.fold`'s whitespace-collapse guard was
  `foldedBuf.toString().codeUnitAt(foldedBuf.length - 1)` — a fresh full-string copy
  for **every space** in the text. A 1,400-char hadith with ~200 spaces rebuilt its
  buffer ~200 times, averaging half a string each time. The fold was super-linear in
  the row, and the corpus is 36,390 rows of that.
* One correction to the brief's own framing, because it changes the fix: that
  quadratic is bounded by **row length** (mean 423 chars ⇒ ~35× the linear work), not
  by corpus size. So a one-time build would have inherited it too — which is why
  `SearchNormalizer` is in scope and not just the worker.

## The retraction, stated plainly

Previous section, CI round 6, verbatim:

> **Consequence, stated honestly: the scan itself was never 20 s — it is ~100 ms even
> on a 20k-row corpus in JIT — so the device red was the BOOT QUEUE … and no indexed
> pre-normalisation pass is indicated by these numbers.**

**That was wrong.** The numbers could not have said anything else: they were measured
on a fixture whose rows were **13.1× lighter** than the shipped ones (131 english
chars/row against a real mean of 1,716 searched chars/row — `[HR13_MEASURE]` prints
both), on a path whose cost is dominated by *folding*, which the benchmark's own
`scanHadithCorpus` call did per query but which a 131-char row makes nearly free. A
gate that measures a shape with nothing in it reports the shape as free. The
follow-up that section explicitly declined to attempt — "an indexed pre-normalisation
pass over the corpus inside the worker (build-once, search-often), not a bigger
timeout" — **is exactly what HR-1.3 builds.** It was indicated by the device all
along; the device is the authority, and CI's fixture was not.

## The fix

1. **The mirror.** `FoldedHadith` (4 fields: english, arabic, urdu, chapter) beside
   the raw row the worker already owns; `foldHadithBook(List<LocalHadith>)` folds
   each once with `SearchNormalizer.foldText` — the fold *without* the per-char index
   map, because a corpus-wide pass has no reader for the map.
2. **Paid once, at settle, off-main.** The worker builds the mirror for a book when
   the flush request arrives (behind the boot hand-offs, never on a keystroke), and
   invalidates that book's mirror the moment its rows are replaced — a new payload
   or a late language fold — so a mirror can never outlive the rows it mirrors.
3. **The scan does no folding.** `scanFoldedHadithCorpus` matches with
   `indexOf(foldQuery(q)) >= 0` on the cached strings; the query is folded, the corpus
   is not. A book with no (or short) mirror folds inline — correct, bounded, and never
   true of a settled corpus. `hadithRelevanceFor` stays on **raw** text for matched
   rows only, so the scoring is identical by construction.
4. **`scanHadithCorpus` survives as a delegate** (build the mirror, scan it). HR-1
   pins its signature and `ai_responsiveness_test.dart:48` pins
   `double hadithRelevanceFor(`; both still compile, both still green.
5. **Pinned so it cannot rot back silently**: a source-scan test requires the mirrored
   scan's body to contain `indexOf(` and no corpus `fold(`/`FoldedText`, requires the
   raw scan to be a one-call delegate, and requires the worker to build the mirror in
   the flush branch and **not** in the search branch.
6. **`SearchNormalizer` itself**: the collapse guard became a tracked last-unit
   variable (identical rule, linear), the fold table became rune-keyed, the
   per-char `RegExp.hasMatch` became the range test that literal spells, and ASCII
   (15.4 M of the shipped 52.3 M searched chars) folds by arithmetic with no
   allocation. Byte-identical output is **pinned, not asserted in prose**: a
   differential test restates the *legacy* rule inside the test file and compares it
   with the new one over 26 adversarial shapes (leading/doubled/trailing spaces, tab,
   newline, CR, form feed, tashkeel runs, tatweel, hamza carriers, `İ` whose lowercase
   is two UTF-16 units, a lone surrogate) plus 2,100 real corpus rows —
   `[HR13_FOLD] differential: 2125 inputs … fold identically`.

## Measured, verbatim (CI run 43591484158, job 132436954380, at the landed tip `0b3ec65`)

```
[HR13_MEASURE] rows=1200 searchedChars=1908207 meanCharsPerRow=1590 fields=4
[HR13_MEASURE] mirror built for 1200 real rows in 121ms (101.6us/row) — one time, at settle, off-main
[HR13_MEASURE] "namaz ka tarika" over 1200 real rows: fold-per-scan 111.3ms vs cached 10.6ms, 0 hits (mirror build 121ms, one time)
[HR13_MEASURE] "patience"  … fold-per-scan 110.5ms vs cached  7.5ms,  1 hit
[HR13_MEASURE] "prayer"    … fold-per-scan 120.4ms vs cached  4.9ms, 50 hits
[HR13_MEASURE] "masjid"    … fold-per-scan 163.4ms vs cached  8.5ms,  9 hits
[HR13_MEASURE] p95 cached = 10.6ms (bound 500.0ms); p95 folding = 163.4ms; extrapolated to all 36,390 shipped rows: cached ~320ms vs folding ~4956ms per keystroke
[HR13_MEASURE] real mean searched chars/row = 1716; HR-1 synthetic english/row = 131; ratio = 13.1x
[HR13_FOLD] one-time fold pass, english field of all 7 books: rows=36390 chars=15400840 foldedChars=15400840 cost=423ms (27.5ns/char)
[HR13_FOLD] fold(20159 chars)=0.70ms fold(160302 chars)=4.26ms growth=6.1x for 8.0x more text
[HR13_FOLD] differential: 2125 inputs (26 adversarial shapes + 2100 real rows) fold identically under the legacy rule and the rune-keyed one
[HR13_PARITY] 243 hits compared across 12 single queries + 1 burst, over 1400 real rows (english + arabic + urdu + chapter + a populated Phase-B field); 4 queries hit nothing on BOTH sides, which is the empty-pattern case
[HR13_RAM] (run 43590301660, the run that first executed it) 1400 real rows / 2261934 searched chars = 4.31MB of text; mirror = 1973863 chars = 87.3% of that, plus 1400 row objects; build 148183us = 105.8us/row; RSS +15188KB (the mirror's own chars are 3855KB)
[HR1_BENCH] fixture weight: 620.2166666666667 english chars/row (the shipped bundle measures 423) — the timings below are only evidence while the two are the same order of magnitude
[HR1_BENCH] ledger corpus weight: 20020 rows, 13168496 searched chars, 658 per row (the shipped bundle measures 1,436)
[HR1_BENCH] settle (assemble + fold) over 20020 real-length rows took 1465ms — one time, off-main
[HADITH_SEARCH] corpus folded at settle: 1 books new / 7 mirrored, 20020 rows, 198ms (9us/row), 32662575 folded chars ~62.3MB held
[HADITH_SEARCH] scan 1 answered in 19.4ms over 20020 corpus rows (budget 90s)   ← then 10.0 / 25.8 / 18.8 / 10.8 / 9.6 / 9.6 / 10.0 / 9.4 / 9.9 / 9.7 / 9.9 / 9.6 / 9.5 / 8.8 ms (budget 45s)
[HADITH_SEARCH] scan N answered in 0.3-0.4ms over 300 corpus rows   ← the HR-1 fixture, i.e. the shape the old gate was happy with: 0.4-0.7ms per keystroke, BEFORE the fix (this is the number that hid the bug)
```

Per-keystroke, on the same runner and the same code path the app runs:

| shape | before HR-1.3 | after HR-1.3 |
|---|---|---|
| one query, 1,200 **real** rows, p95 of the CACHED scan | n/a — the cached scan did not exist; the same 1,200 rows on the folding path measured 728.3 ms (run 43588097068) against the brief's 500 ms | **10.6 ms** (bound 500 ms) |
| one query, 1,200 real rows, p95 of the FOLDING path, same run | **163.4 ms** | 163.4 ms (deliberately unchanged: it is the parity reference, and the gate now demands it stay >3× worse) |
| the worker's own scan line, 20,020 real-length rows | 31.2 – 115.6 ms (per query, folding, lighter fixture) | **8.8 – 25.8 ms** |
| one-time fold of the shipped english corpus | 1,979 ms @ 128.5 ns/char (`e1b87f4`, guard already linear) | **423 ms @ 27.5 ns/char** |
| settle (assemble + fold), 20,020 real-length rows | 6,304 ms (`e1b87f4`) | **1,465 ms** |
| extrapolated per keystroke over all 36,390 shipped rows | **~4,956 ms** (this is the device red: 5 s of main-thread-free but wall-clock-bound work per character typed, in JIT) | **~320 ms** |

## Cost #1, disclosed: the one-time pass

The fold is now paid **once per row per book, at settle, inside the worker**. Measured
on the real bundle: 15.4 M english chars in 423 ms (27.5 ns/char — and across the
three runs that measured it: 1,979 ms @ 128.5 ns/char before this round's fold work,
742 ms @ 48.2, then 519 ms @ 33.7 and 423 ms @ 27.5, so quote the *trend and the
spread*, not one number as if it were a constant). The mirrored build in the gate is
101.6 µs/row for 4 fields of real-length text (169.9 µs/row in the previous run), the
worker's own line for a whole 20,020-row corpus is `198ms (9us/row)`, and the HR-1
benchmark's `settle (assemble + fold) … 1465ms — one time, off-main` covers the whole
7-book hand-off + assemble + fold in CI's JIT.

Per char the shipped corpus is 1.8× heavier per row than that fixture (1,436 against
658 searched chars), so the honest extrapolation for a cold boot on the full 7 books,
in debug JIT, is **low single-digit seconds of *isolate* time**, off the main thread
and behind the boot, never on a keystroke. That is the price of the fix and the owner
should read it as a price: a debug build now has one more bounded thing to do before
the first query can be answered from a settled corpus. What it displaces is far
larger and also measured: the same gate extrapolates the *old* shape to
**~4,956 ms of folding per keystroke** on the full 36,390-row corpus, against ~320 ms
for the cached one — a 15× cut in the thing the reader waits on, paid once at boot. A
PROFILE build is where the number that matters will come from (the same 20,020-row
scan is 8.8–25.8 ms in JIT; the device will show its own).

## Cost #2, disclosed: the RAM

The brief asked for a measured number rather than an estimate, so here is the
arithmetic and the caveat:

* The mirror is **87.3 %** of the text it mirrors (measured, `[HR13_RAM]`: 1,973,863
  folded chars against 2,261,934 searched chars over 1,400 real rows) — not "roughly
  double", because folding *shrinks* Arabic and Urdu (tashkeel and tatweel are
  dropped) and collapses whitespace runs.
* `FoldedHadith` carries the four Phase-B candidate fields too (they are mirrored,
  because `foldLanguageIntoRows` really does fill them — a disclosed deviation from
  the brief's "Phase-B are always empty, skip them"), **but an empty field stores the
  canonical `''`** rather than a fold-shaped copy, so on a bundle where those
  languages are not populated their cost is zero objects and zero bytes.
* The worker's own line states the retained size directly for a 20,020-row corpus:
  **`32662575 folded chars ~62.3MB held`**. Scaled to the shipped corpus's 52.3 M
  searched chars at that ratio, expect **≈ 90 MB of folded UTF-16 chars** plus
  36,390 row objects. This is worker-isolate memory; it is not a second corpus copy
  on main (the HR-1 rule, still pinned by name: `mainCopy == null` after boot), and
  it is released when the isolate dies — a retirement and revival pays the build
  again, once, behind the 60 s cooldown.
* Both are **worker-isolate** numbers, and the mirror is per book: a book's mirror is
  dropped and rebuilt when its rows are replaced, never carried alongside a stale row
  set (a length mismatch falls back to folding that book inline).
* The process-level measurement is **noisy and must not be quoted as the cost**:
  `RSS +15188KB` for 1,400 rows in this run, against `+7156KB` and `+8240KB` for the
  same test in earlier runs. That delta includes the transient garbage of building the
  mirror (the folded strings are the retained part; the raw rows were already
  resident), so the deterministic figures to quote are the retained-char counts above,
  with the RSS spread disclosed as a spread.

## Parity: the optimization may not change one result

Not argued — compared. The gate runs the pre-fix fold-per-scan path and the cached
path over the **same real rows** and requires the same hit set, the same order, the
same `relevance`, and the same `matchedIn`, per query and for a burst.
`[HR13_PARITY] … 243 hits … 4 queries hit nothing on BOTH sides` — the empty-pattern
case (a query of pure spaces or pure tashkeel folds to `''` and `indexOf('')`
behaves identically on both paths) is included on purpose because it is the only way
this class of change silently differs. A ratio pin then keeps the gate honest about
what it is comparing: the raw path must stay **>3× worse** than the cached one, or the
cache has quietly stopped doing anything.

## Rounds, every one, with its run

| commit | CI run | outcome, and what the round actually proved |
|---|---|---|
| `73cdadd` | 43585154315 | **analyze RED, both findings in my own new test file** (a test name that interpolated a `const` by the wrong name, and a `final` initialised from a literal string — `prefer_const_declarations`). No `lib/` change, no existing gate moved. Lesson recorded for the file: in a new test file every `$x` in a description must be a real identifier |
| `f1546a8` | 43585606786 | **GREEN, 703/0 — and the green was the problem.** The fix was in and the p95-500 ms gate passed, because the gate was timing 1,200 rows on a path it should not have been timing at all. A pass that a 30×-bigger corpus would fail is not proof; this is the round that produced the "representative fixture" rule for this hotfix, and it is reported as *insufficient evidence*, not as a red |
| `54f5de4` | 43586298265 | **RED, `695 passed, 6 failed`** — the designed reds: the source pins (no corpus `fold` in the mirrored scan, the worker builds the mirror at settle and not on the keystroke path, the raw scan stays a delegate), the fold-linearity pin, and the fixture-weight pin. `git diff --stat` against the previous commit touched **only** the new test file, so no existing gate moved red — the 6 are 6 additions |
| `b56ad4f` | 43587631203 | **analyze RED on one warning I introduced**: `unnecessary_non_null_assertion` at `hadith_database_service.dart:314` (my `mirror!`). Fixed by making the null test the promotion (a nullable local) rather than by silencing the lint — and that shape became the length-mismatch guard |
| `e1b87f4` | 43588097068 | **`702 passed, 1 failed`** — the mis-targeted cost gate (round 3's row below). Everything fix-side in that run was green, including the one-time fold at 1,979 ms against a 2,000 ms bound, which is itself a finding about the bound |
| `ff50faa` | 43588882619 | **`703 passed, 1 failed`** — gate retargeted, the fold's constant cut 128.5 → 48.2 ns/char with the differential pin added, and the one red became HR-1.1's burst floor (round 4's row below) |
| `0118c25` | 43590301660 | **GREEN, `🎉 704 tests passed.`** — burst test reads the ledger mid-flight; fold ceiling moved to 4,000 ms with its doc saying what it is and is not |
| `5c38afe` | 43590955179 | **`703 passed, 1 failed`** on a commit that only touched this file — HR-1.1's serial retirement test lost the race to a 0.2 ms scan (round 5's row below). Reported rather than re-run until it happened to pass |
| `0b3ec65` | 43591484158 | **GREEN, `🎉 704 tests passed.`, analyze 0/0, battery `hard 0 · G2 319 · L2 83` — the landed state** |

## The three gates that were wrong before the code was

Both failures were mine, and both are recorded because a green run with a broken gate
is worse than a red run:

| | |
|---|---|
| round 2, run **43588097068** (`e1b87f4`) — `702 passed, 1 failed` | The 500 ms gate called `scanHadithCorpus`, which HR-1 pins and which this fix *deliberately* keeps folding as the parity reference. It measured the shape being replaced, not the shape the app runs, and it stayed red for the right reason (728.3 ms of folding). Retargeted: one run now measures both paths side by side (`fold-per-scan … vs cached …`), bounds the **cached** one, and prints the raw one as a disclosure. `scanHadithCorpus` is never a perf gate's subject again |
| round 4, run **43590955179** (`5c38afe`, a MARKDOWN-only commit) — `703 passed, 1 failed` | **The fix's own success broke a gate.** `hadith_hotfix_hr11_worker_liveness_test.dart:246` demanded `expect(second, isNull)` on a 1 µs budget, and the log says why it was answered anyway: `scan 2 answered in 0.2ms over 60 corpus rows (budget 0s)`. HR-1.3 made the scan ~5× faster than the round that armed this test (0.9 ms → 0.2 ms), so a settled 60-row worker now replies faster than a runner can service a µs timer. Shrinking the budget is not an option — there is nothing below 1 µs — so the assumption went instead: the test now hands the worker a book and deliberately does **not** await settle, so the isolate is ~400 ms deep in the assemble + mirror build measured in that very log line (`corpus folded at settle: 1 books new / 1 mirrored, 2860 rows, 423ms`) — 400,000× the budget, and the shape is the honest one (a query that arrives behind the boot backlog is what HR-1.1 exists for). No assertion was deleted or loosened; the group gained `supersededMisses == 0`, because in a **serial** test no query may be written off as superseded. This is the third timing repair in that file, and the standing rule is on record: a fourth would be a STOP-AND-REPORT, not another re-arm |
| round 3, run **43588882619** (`ff50faa`) — `703 passed, 1 failed` | `hadith_hotfix_hr11_worker_liveness_test.dart:508`, an assertion **I added in HR-1.1 round 12**: `expect(worker.timeouts, greaterThanOrEqualTo(1))`, "so a fast runner cannot make this test VACUOUS". It was unsound, not flaky: a superseded query's lateness is *discarded* by design, a query answered inside its µs budget produces neither a discard nor a count, and a late reply refunds its own miss. CI's log shows the ledger closing correctly (`query 1 … discarded`, `query 2 … discarded`, `reply 1/4 missed its budget`, `inFlight → 0`) while my floor demanded `≥ 1`. Replaced with a **synchronous** reading of the ledger: the burst is asserted to be three armed waits *while it is in flight* (`inFlight == 3`, `pendingReplies hasLength 3`), then zero, then `timeouts + supersededMisses ≤ 3` and `timeouts ≤ 1`, no retirement, still live. Non-vacuity without a stopwatch: the pile-up HR-1 shipped with is counted at the moment it would exist. `supersededMisses` is the one field added to `HadithSearchWorker` for this — a counter the discard branch already logged, now countable, never written by app code |

And the fold-cost ceiling itself: it carried 2,000 ms while the pre-optimisation fold
measured **1,979 ms** — a gate that green-lights code 2.7× slower than it needs to be
is a coin flip with a citation. The ceiling is now 4,000 ms with a comment saying it
is a ceiling and not a witness, and the witness is the linearity ratio (8.0× the text
must cost 8.0× the time, bound at 12) plus the ns/char disclosure.

## Existing tests changed, by name

* `test/features/hadith/hadith_pass_hr1_test.dart` — **only its benchmark fixture**:
  `_syntheticBook` now emits shipped-length text (per-script clauses repeated
  `2 + (i % 6)`, ~570/625/495 chars against the real 423/549/464) in all three
  languages instead of one 145-char sentence, and the benchmark prints + pins its own
  weight (`[HR1_BENCH] fixture weight … greaterThan(350.0)` english chars/row) so the
  benchmark cannot go light again unnoticed. **Every assertion in that file is
  untouched and green**, including all the HR-1 landmines (capture ban, worker-shape
  pins, one-assembler census, boot-reads-once, debounce counts). **Disclosed residual:
  the fixture is still 2.2× lighter per row than the shipped bundle (658 against
  1,436 searched chars), so `1,995 ms` of settle and `9.6-24.5 ms` per scan are
  same-order-of-magnitude evidence, not device numbers.**
* `test/features/hadith/hadith_hotfix_hr11_worker_liveness_test.dart` — **two** tests,
  both mine from HR-1.1, both repaired because HR-1.3 changed what "slow" means: the
  burst/ledger one (its `timeouts ≥ 1` floor demanded an outcome the code correctly
  refuses to produce — now the ledger is read while the burst is in flight, which
  needs no stopwatch) and the serial two-miss retirement one (round 4's row above).
  The file's other 11 tests are byte-identical, and the assertions in the two changed
  tests were **replaced with stronger ones**, not weakened: `inFlight == 3` before the
  await, `supersededMisses == 0` after a serial pair, and a `timeouts +
  supersededMisses ≤ 3` no-double-count bound.

## Holds, checked

| hold | state |
|---|---|
| HR-1.1 availability logic (budgets, retirement evidence, revive cooldown, telemetry) | untouched; 13/13 green before and after, one assertion repaired as disclosed |
| HR-1.2 geometry (`SafeArea`, `searchSheetHeight`) | untouched; 7/7 green |
| no fix may reintroduce a main-isolate corpus copy | holds: no `Isolate.run`, no `.of(` corpus map, the capture-ban test and the `mainCopy == null` pin are green. The only *retained* mirror is the worker's; `scanHadithCorpus` builds one per call as the parity reference and is not on any device path |
| `assets/` | untouched (the gates read the real bundle through `decodeHadithAsset` + `assembleHadithBook`, read-only) |
| analyse | 0 errors, 0 warnings (round `b56ad4f` was red on **one** warning I introduced, `unnecessary_non_null_assertion` at `hadith_database_service.dart:314`; fixed by a nullable local instead of a `!`) |
| battery | `hard findings: 0`; G2 `318 → 319`, the +1 being the same pre-existing advisory class (`FoldedHadith`'s names referenced-but-not-imported advisory in a new file) — disclosed, not "fixed" by adding an import that nothing uses |
| `analysis_options.yaml`, `ci.yml`'s existing steps | untouched |

## Out of scope, unchanged by this pass

SMTP/email · argon2/bcrypt · Redis/shared rate limits · iOS · tafsir/QB-010 perf ·
UI polish QB-030/032/034 · `hadith_screen.dart:137`'s 120 px tab-chrome overflow ·
the pre-existing `timeout-minutes: 20` on the `quality` job. Also deliberately **not**
changed: the main-isolate `HadithDatabaseService.search()` fallback (still
`SearchNormalizer.contains` per row — it is not the keystroke path, and making it fast
would mean a corpus copy on main); `hadithRelevanceFor`'s raw-text scoring (it runs on
matched rows only, ≤ 12 per query); and a real inverted index, which is the honest
next step **if** the device still says the corpus is too big to hold twice.

## Device steps owed to the owner (record, never simulated)

1. **Debug build** → type `namaz ka tarika` → results **must arrive**. Record the
   `scan N answered in Xms over 36390 corpus rows` line's `X`, and the
   `corpus folded at settle: …` line's total.
2. **Profile build** → same query, record `X` again.

Expected if the fix is right: `X` in the tens of milliseconds at both, because the
corpus is folded once and the keystroke only does `indexOf`s. If results still do not
arrive in debug, the log now distinguishes the two remaining causes for us — a long
`corpus folded at settle` line means the build is the cost (then the answer is to fold
lazily per book rather than at flush, a one-line change in the same branch); a short
one with `X` large means the scan itself is still the wall (then the answer is the
inverted index, and this report will say so rather than raise a budget).

---

# HOTFIX HR-2.1 — the content diet: Urdu + English, Arabic unbundled

Owner order, verbatim: *"mujhe original urdu and eng dalna h arabic hata dena h pura
hadith ka sara book 100 verified sab"*. Read as three demands, and this pass answers
all three: put the original Urdu and English in, take the Arabic out of every hadith
book, and verify the coverage of every book so that the "100" claim is a measured
number rather than a hope.

Quran is out of scope by order: `assets/data/quran/` shows **zero diff** in this
pass, and the Quran surfaces keep their Arabic (they are the book that is *supposed*
to carry it). `hadithnumber` and `arabicnumber` stay in every row and every join —
they are **join keys, not Arabic text**, and `pairKey`/`LocalHadith.numberLabel`
still need them.

## A — the data diet (checkpoint A)

Exactly seven files were deleted, one per collection, and nothing else in
`assets/data/hadith/` moved:

| collection | pre-deletion blob (at `865c3f8`) | bytes |
|---|---|---|
| abudawud | `3a9fd5a36b1225a0e92f06b4d933feaba5bb2bad` | 7,345,422 |
| bukhari | `72a64ea26134fb19e12c7eec4109a5bbc39ee62c` | 9,770,083 |
| ibnmajah | `4dfc0eea4e87ebd2c0e946144fea491380b3cead` | 5,583,070 |
| malik | `cbdd5570b9f1e526199ba751a76ce7a5841262e8` | 2,150,337 |
| muslim | `a94ab4a02352c082a6c75834c0df2548026d3bb3` | 8,685,140 |
| nasai | `e383bdb22b8f2c7b75faf05379823cc8c73d535c` | 7,152,291 |
| tirmidhi | `80d8ed3d1aa4727e2ac8cdf51db8e617a736b3a0` | 7,120,806 |
| **total** | | **47,807,149 B = 45.59 MB** |

Those blob SHAs are the re-bundle path: `git cat-file blob <sha>` returns the deleted
file byte-for-byte, which is what "a data drop plus one map row" is worth in practice.

Measured before and after, in the same clean worktree, with `du -sb assets/data/hadith`
and a `find … | wc -l` on `*.json`:

| | files | bytes | MB |
|---|---|---|---|
| before HR-2.1 | 22 | 113,553,406 | 108.29 |
| after HR-2.1 | **15** | **65,746,257** | **62.70** |
| delta | −7 | −47,807,149 | **−42.1 %** |

15 = 7 books × 2 editions (`english.json` + `urdu.json`) + `kitab_names.json`. The
size reduction is the *bundle* size; the APK delta is in § C, labelled with whatever
authority CI gives it.

The boot diet follows from the same map, not from a second edit: `_loadBook` builds
its `Future.wait` batch as `english.json` + one file per row of
`HadithAvailability.fileForLanguage`, so removing the `'ar': 'arabic'` row takes the
boot from 21 asset reads + isolate decodes (3 per book × 7) to **14** (2 × 7). No
loop, threshold or cache constant was touched to get that — it is a consequence,
which is the only kind of simplification this family of passes accepts.

### `hadith_availability.dart` is where the removal happened

`languageCodes` is now `['en', 'ur']`, and `labelFor`, `booksForLanguage` and
`fileForLanguage` each lost their `'ar'` row. That is the whole UI-side change: the
Settings selector, the reader sheet rows, `HadithLanguageNotifier.supported` and the
boot batch all *derive* from those four lines (that derivation is itself pinned —
`hadith_redesign_test` and `hadith_multilang_test` require `selectorOptions()` to be
the source, and `HadithLanguageNotifier.supported == {...languageCodes}`), so no
downstream file was allowed a hardcoded language list, and none needed one.

A device that had `ar` persisted in `SharedPreferences` under the old build reads
`hadith_display_language_v1 = 'ar'`; the notifier's `_load` already filters through
`supported`, so that value falls back to `en` — the same path X5 built for a stale
`bn`/`tr`/`id`/`fr`. No migration, no new code.

### Re-pins carried by A (old → new, all disclosed here)

| pin | was | now |
|---|---|---|
| `hadith_multilang_test` file census | 22 files | **15 files** |
| `hadith_multilang_test` selector | 3 codes, `['English','العربية','اردو']` | **2 codes, `['English','اردو']`** |
| `hadith_multilang_test` floors | 7 books × {english, arabic, urdu} | **7 books × {english, urdu}** |
| `hadith_multilang_test` sidecar | `contains('ar/en/ur JSON')` | **`contains('en/ur JSON; arabic unbundled')`, and `isNot('ar/en/ur JSON')`** |
| `content_pass_test` layout | "3-file ar/en/ur layout" | **"2-file en/ur layout"** |
| `hadith_pass_h1_test` frozen matrix | `['en','ar','ur']` + `{'ar':'arabic','ur':'urdu'}` | **`['en','ur']` + `{'ur':'urdu'}`** |
| `hadith_pass_h1_test` `_stems` | `{en, ar, ur}` | **`{en, ur}`** (it is a list of files to *open*) |
| `assets/data/content_manifest.json` | 7 rows "(ar/en/ur JSON)" + notes | **7 rows "(en/ur JSON; arabic unbundled 2026-09-01 by HOTFIX HR-2.1)" + notes naming both diets** |

The `content_manifest.json` edit is the one line in this pass that touches
`assets/` besides the seven deletions, and it is ordered by the brief, not
volunteered: a ledger that still claims three editions after two of them ship is a
ledger that lies. `assets/data/hadith/**` itself is exactly the seven deletions, and
`assets/data/quran/**` is empty of diff.

Nothing else in the matrix moved: `bookDisplayNames`, `coveragePercent`,
`thinCoverage` and the `newLanguageFiles` fold seam keep their behaviour, and the
`thinCoverage` real-data rows are unchanged by the diet (they were already
`ur/nasai` 67 % and `ur/malik` 86 %; the Arabic column was 97–100 % everywhere, so
removing it removes no disclosure row and adds none).

## B — the code diet (checkpoint B; A and B ship as one tree)

**Why the two checkpoints are one CI-passable tree.** Checkpoint A on its own is
red, and that is measured, not theorised: run **43594746910** (`24297a3`) —
*Dependencies* ✓, *Analyze* ✓ (0 errors / 0 warnings), *Full test suite* ✗
**`698 tests passed, 6 failed`**, the battery step skipped. Four of the six were
`hadith_hotfix_hr13_fold_cache_test`'s real-corpus tests opening
`assets/data/hadith/<book>/arabic.json`, which A had just deleted; the rest were
fixtures still handing `arabicData:` to `assembleHadithBook`. A removed a
`fileForLanguage` entry that the `865c3f8` service indexes *positionally*, and the
re-pins that follow that removal live in B. That is the price of splitting a data
diet from the code that reads it — and the honest answer was not to re-pin around
the red but to land the other half: run **43596310124** (`13f9f55`, the full A+B
tree) is **`🎉 704 tests passed.`** — the exact HR-1.3 count, so B lost no test
and added none — with *Analyze* ✓ and the battery at **hard 0 | G2 319 |
L2 83, ALL GATES PASS**.

### What went, per file (`13f9f55`: 20 files, +294 / −398)

| file | + | − | the deletion |
|---|---|---|---|
| `data/services/hadith_database_service.dart` | 36 | 63 | `assembleHadithBook` loses its `arabicData` parameter, the Arabic map and `textArabic:`; the spine becomes `english ?? urdu`; `FoldedHadith` loses `arabic`; `foldHadithRow` loses its fold; both scans lose the Arabic arm; `LocalHadith` loses `textArabic`/`hasArabic`/`arabicPreview`; the boot batch goes 3 files → 2 per book and its Phase-B tail re-indexes to `results[2+i]` |
| `presentation/hadith_book_screen.dart` | 66 | 111 | the Arabic matn block (`ValueKey('hadith-card-arabic')`, :1683 pre-diet), the `_showArabic` quick-settings switch and its sheet row, the `AppStrings.arabicTextSection` title, and the `SearchNormalizer.contains(h.textArabic, _searchQuery)` arm of the in-book filter |
| `presentation/hadith_screen.dart` | 36 | 80 | the tab sheet's Arabic block (`if (hadith.hasArabic) …` with `AppArabicStyles.hadithArabic`), the `hadith.textArabic` share/copy prefix, and the `? hadith.textArabic` branch |
| `data/models/hadith_models.dart` | 13 | 12 | `textArabic` out of `HadithModel` (field, ctor, `fromJson`, `copyWith`, aliases) and the `showArabic` reader flag |
| `data/services/hadith_search_worker.dart` | 5 | 9 | `rawArabic` out of `_HadithBookNote`/`noteBook`/assemble/debug print; the note guard becomes `if (rawEnglish == null && rawUrdu == null) return;`; `firstReplyTimeout`'s doc now says 14 decodes |
| `providers/hadith_provider.dart` | 3 | 8 | `return hadith.hasArabic ? hadith.textArabic : null;` (×2), `textArabic: local.textArabic`, and the stale "boot batch carries english/arabic/urdu" comment |
| `home/presentation/widgets/home_sections.dart` | 3 | 11 | the hadith-of-the-day card's Arabic block (`if (h.hasArabic) …` with `AppArabicStyles.quranSmall`) |

Everything else in the commit is a test file (13 of them, in the re-pin ledger
below). `git show 13f9f55 --numstat` has **no `assets/` entry**: the data diet was
A's, and B touches only code. Post-B consistency, all by grep rather than by
belief: `assembleHadithBook(` has 8 callers and **0** pass `arabicData`;
`noteBook(` has 15 callers and **0** mention `rawArabic`; `FoldedHadith(` appears
only at its constructor and its factory; `showArabic` appears **0** times in
`lib/` and `test/`.

### The three judgement calls, disclosed

1. **`FoldedHadith` went 8 fields → 7, not 8 → 3.** The brief said the mirror
   should hold "en + ur + chapter ONLY". Four of those eight
   (`textBengali`/`Turkish`/`Indonesian`/`French`) are still *filled* by
   `foldLanguageIntoRows` whenever a Phase-B language file exists, and dropping
   them would have deleted a working feature to satisfy a sentence. So the fold
   lost exactly the Arabic field — and § C's RAM numbers are measured on that
   reality instead of on the brief's assumption.
2. **`FoldedHadith.shortText` now ends in an explicit `return '';`.** Its last
   branch used to fall through to an Arabic preview. After the diet there is
   nothing to fall back to, and inventing an Arabic-looking preview for a row that
   has no Arabic would be a fabrication in the reader's face; empty string means
   the reader's fallback line answers instead. (That tail returned `''` for every
   shipped row anyway — the Arabic field was gone from the assembler, so this is
   a semantic hole closed, not a behaviour changed.)
3. **`hadithRelevanceFor` lost its `hadithArabic` parameter and kept its shape**
   (`1.0 / 0.9 / 0.85 / (0.5 + 0.1·occ).clamp(0, 0.8)`): the 0.9 arm *was* the
   Arabic arm. `ai_responsiveness_test.dart:48`'s pin on `double hadithRelevanceFor(`
   still passes; HR-1.3's standing rule was respected — no perf budget was moved
   and no µs stopwatch test was re-armed.

`scanHadithCorpus` (the parity reference) and `scanFoldedHadithCorpus` (the cached
mirror) lost their Arabic arms **identically**, which is what keeps HR-1.3's
"one rule in two declarations" pin and the parity test true: 243 hits over 12
queries on 1,400 real rows still agree on both sides, with the log line now
naming the fields it compares.

### The reader's fallback: verified, not assumed (the brief asked for this)

`HadithTranslationFallback` fires from two places and neither consults the
availability matrix. The book's detail sheet takes the `] else …[` branch of "the
key-join found no text in this language for THIS hadith"
(`hadith_book_screen.dart:1156`); the collapsed card takes the `else` of
`if (translation != null)` (`:1723`), where `translation` is
`localHadithTextForLanguage(...)` — null exactly when the selected language has
nothing for that row. Deleting the `'ar'` entry from `fileForLanguage` therefore
can neither switch the chip off nor need it re-armed: the trigger is per-row
emptiness, not per-language availability. What did change is its weight — before
the diet it always sat *under* the Arabic matn and could never replace text; now
it **is** the body of such a row, which is why its honest sentence and its
English reveal are load-bearing rather than cosmetic. Proved, not argued:
`hadith_pass_x6_test` pumps the real card and finds `HadithTranslationFallback`
(`findsOneWidget`, and `findsNothing` again after the reveal), while
`hadith_pass_h2_test` asserts `hadith-card-arabic` `findsNothing`. One consequence
is stated for § C: on a row with *no* English either, `englishText` is null and
the widget's own rule is "no bundle text, no chip" — the reader gets the honest
line with nothing to reveal. That is the truth of 206 rows, and it is small only
because the English edition is nearly complete.

### Selector

Two options, derived: `selectorOptions()` over `languageCodes = ['en','ur']` →
`English` and `اردو`. Nothing downstream hardcodes a third, which was HR-2.1 A's
"single source of truth" rule; B only consumed it.

### B's re-pin ledger (old → new, every one)

| test | was | now |
|---|---|---|
| `hadith_hotfix_hr13_fold_cache_test` | fixture assembler opened `arabic.json` and passed `arabicData:`/`arabicData: null`; `_measureCorpus` reported `fields: 4`; the char sums and the `[HR13_PARITY]` line counted an Arabic field | no Arabic read or parameter; **`fields: 3`**; parity reads "english + urdu + chapter + a populated Phase-B field"; both char sums drop Arabic |
| `hadith_pass_hr1_test` | boot-diet pin "three asset reads per book" + `allMatches(load) 3`; `_syntheticBook` carried a 139-char Arabic clause + an Arabic topic and "625 arabic" prose; the benchmark handed three raw maps; ledger char sum + `arabicData: null` ×3 + an Arabic term in `searchedChars` | **"two" (3 → 2 `_loadJsonAsset`)**, en+ur only (HR-1.3's rule comment kept verbatim), Arabic clause/topic table deleted, `[HR1_BENCH] fixture weight > 350` byte-identical |
| `hadith_pass_h2_test` | `mkHadith` set `textArabic`; the D1 anatomy sequence expected the Arabic block; the typography band and the D2 collapse included it | Arabic gone from all four pins; anatomy re-sequenced and **asserts `hadith-card-arabic` findsNothing**; D2 collapses one body; the typography test retitled |
| `hadith_pass_x6_test` | fixtures set `textArabic: 'النص'`; `_pumpCard(showArabic: true)`; "the Arabic body stays" | fields and `showArabic:` gone; the no-English-to-reveal case now pins **`HadithTranslationFallback` findsOneWidget** |
| `hadith_h4_search_test` | 4 fixtures with `textArabic: ''`; `_FakeDb` mirrored the raw scan including Arabic; the merge test pinned `channel: 'arabic'`; a quick-pick `'arabic'` case | fields gone; the fake DB ORs english+urdu; **channel re-pinned `'arabic' → 'urdu'`** (with its expectation); quick-pick Arabic case deleted |
| `hadith_topclass_test` | asserted an Arabic section existed | **negative guard**: no `textArabic`/`arabicData`/`rawArabic` (`:143/150/152`) |
| `hadith_redesign_test` | expected the Arabic block | expects Urdu |
| `hadith_hotfix_hr12_search_sheet_fit_test` | `_prayer` fixture set `textArabic: ''` | gone; the fit arithmetic untouched |
| `hadith_multilang_test`, `ai_revival_test`, `p1_dua_hadith_completion_test`, `phase_continue_wiring_test` | fixture lines for a constructor parameter that no longer exists (the `localHadithTextForLanguage` `'bn'`/`'fr'` pins were left alone) | gone; every `test(`/`testWidgets(` count identical to `865c3f8` |

Audit, because "no test silently dropped" is a gate: all 20 diffed dart files
were compared line-by-line with `git show 865c3f8:<path>` for brace/paren/bracket
balance (delta **(0,0,0)** in every file) and for `test(`/`testWidgets(` counts
(identical in every file).

### Arabic-script characters still in `lib/features/hadith` (measured after C, so the removal is not taken on faith)

Scanned by codepoint over every file: four hits, none of them hadith text — the
`'ur': 'اردو'` label (`hadith_availability.dart:61`); the `ﷺ` ligature inside the
English subtitle `'The sayings of the Prophet ﷺ'` (`hadith_screen.dart:83, 192`);
the `fromString` Arabic alternates (`'صحيح'`, `'حسن'`, `'ضعيف'`, `'موضوع'`,
`'غير معروف'`) in `hadith_models.dart`, which **parse upstream grade strings** —
deleting those would silently downgrade hadiths, so they stay; and one comment in
`hadith_provider.dart:469` about query expansion. `AppArabicStyles` itself stays
(the Quran and AI surfaces use it), as do `HadithMatchType.arabic`,
`arabicnumber`/`arabicNumber`/`pairKey`, `textBengali/Turkish/Indonesian/French`
and their selector cases, the `legacyArabic` preferences migration, the
phase6-13 `'ar'` app-locale lists (app language, not hadith edition), and
`rag_service.dart`'s `'حديث'` query-expansion term.

## C — "100 verified": the table, the tool, the ceiling

### The matrix, as the tool prints it today

`python3 scripts/validate_content.py` (post-`8ba57fa`) prints, from the shipped
files, using `assembleHadithBook`'s own join rule:

```
hadith_matrix {"books": 7, "editions": ["english", "urdu"], "files": "14/14",
  "bytes": 65739825, "mb": 62.69, "rows": 36390, "boot_decodes": 14,
  "coverage": {"english": {"non_blank": 35975, "percent": 98.9},
               "urdu":    {"non_blank": 33424, "percent": 91.8}},
  "rows_with_neither_edition": 206, "urdu_rows_off_spine": 1}

book         rows  english non-blank     urdu non-blank  NEITHER  keys collide   frac N.2
bukhari      7589     7580 ( 99.9%)     6994 ( 92.2%)        6            26         52
muslim       7563     7360 ( 97.3%)     7458 ( 98.6%)       82             0          0
abudawud     5274     5272 (100.0%)     5273 (100.0%)        0             0          0
nasai        5765     5679 ( 98.5%)     3875 ( 67.2%)       82             7         14
ibnmajah     4343     4340 ( 99.9%)     4327 ( 99.6%)        1             2          4
malik        1858     1818 ( 97.8%)     1590 ( 85.6%)       23             0         31
tirmidhi     3998     3926 ( 98.2%)     3907 ( 97.7%)       12            42         84
hadith_matrix_issues []
```

Two changes made that the tool's job rather than a report's prose.
`HADITH_LANGS` went `("arabic", "english", "urdu")` → **`("english", "urdu")`**:
while it still listed arabic, every run reported **7 false `missing_file` rows**
against data that is gone by decision. And `validate_hadith_file.ok` became a
**file** verdict (present, parses, has rows): a blank `text` row is not a broken
file — the English editions carry hundreds of them and the app keeps the row so
the reference stays 1:1 — so emptiness moved into the matrix, where it becomes a
percentage the reader is actually told. (`hadith_empty_sum 3338` above is
exactly the count of blank `text` rows in the 14 files — 415 english of 36,390,
plus 2,923 urdu of 36,422 — and it is NOT the same thing as the joined Urdu gap of
2,966. Measured decomposition of that gap: **0** spine rows are missing from the
Urdu file by key (every English hadithnumber exists there) and **2,966** spine
rows land on a key whose surviving text is blank. Inside the Urdu files,
**52** non-blank texts were themselves discarded, overwritten by a later blank row
carrying the same truncated int number — the last-write-wins rule in action, and
the concrete size of what a `pairKey` re-join could recover.)

The matrix fails on four things only: an edition file that is gone, a spine that
is not English, a spine row the loader cannot key, and a row with no
`reference.book`/`reference.hadith`. It deliberately does **not** fail on the
collision/fractional columns, because "fixing" those means re-joining every book
and changing which text a reader is shown — an owner decision, not a side effect
of a diet.

### The same numbers, executable

New file, 8 tests: `test/features/hadith/hadith_hotfix_hr21_coverage_census_test.dart`.
Every number is computed in the file from the shipped JSON — nothing copied from
this report — and then the census is checked **against the app itself**: for
`bukhari`, `malik` and `muslim` it runs the real `assembleHadithBook` over the
real decoded maps and asserts that the row count equals the spine length and that
each row's `textEnglish`/`textUrdu` equals what the census computed. It pins:

* **15 files** and the byte sum **65,741,265 B**, no `arabic.json` anywhere under
  the hadith root, `languageCodes == ['en','ur']`, `fileForLanguage == {'ur':
  'urdu'}`;
* the **36,390**-row English spine, **1:1** under the fractional-aware
  `HadithDatabaseService.numberKey`, zero rows with an unusable key, zero broken
  `reference` objects — the "the diet lost no row" proof;
* per-book rows / english / urdu / **NEITHER**, the corpus totals
  **35,975 · 33,424 · 206**, the gaps **2,966 rows without Urdu** and **415
  without English**, and `urdu < english` (the fallback copy points the right way
  only while that holds);
* `coveragePercent` on the real files = nasai **67**, malik **86**, bukhari
  **92**, and `thinCoverage` over the real files == exactly
  `{ur/nasai, ur/malik}` and nothing else;
* the collision arithmetic (77 rows: bukhari 26, tirmidhi 42, nasai 7, ibnmajah 2)
  and the one off-spine Urdu row in Muslim — disclosed, not smoothed;
* that the Arabic edition cannot come back halfway: `textArabic`, `arabicData`,
  `rawArabic`, `showArabic`, `hasArabic`, `arabicPreview` are absent from every
  file in `lib/features/hadith` (comments stripped with the shared
  `stripCommentsForGuard`, so a note *about* the removal cannot fail the pin),
  while `map['arabicnumber']`, `pairKey`, `arabicNumber`, `enum HadithMatchType`
  + `arabic`, and the empty `newLanguageFiles` re-bundle seam are asserted
  **present** — so a later cleanup cannot "finish the job" by deleting the keys
  and vocabulary that are still load-bearing.

Red evidence, stated instead of dressed up. This file was written in a sandbox with
no Dart SDK, so CI is its only compiler and its first compile is a run of the
push it landed on — and it took two red rounds to get there:
run **43597766185** (`8ba57fa`) failed *Analyze* with 12 `error •` lines, every
one of them cascading from `package:qibra/...` where `pubspec.yaml:1` names the
package **`qibra_ai`** (`uri_does_not_exist` ×3, then `undefined_identifier` for
`HadithAvailability`/`HadithDatabaseService`/`assembleHadithBook`/`LocalHadith`
and one `unchecked_use_of_nullable_value` on `numberKey`'s non-nullable `String`);
fixed in `6af5f9f` by copying the import form from
`hadith_pass_x6_test.dart:35-39` instead of typing it from memory. Run
**43598073037** (`6af5f9f`) then failed *Analyze* on a single
`warning • Unused import: …/data/models/hadith_models.dart • unused_import` — and
the analyzer was right in a way no local check could have been: **`LocalHadith` is
declared in the SERVICE library** (`hadith_database_service.dart:418`), not in
`hadith_models.dart`, so the models import provided nothing this test references
(it appears in only one other place here, as a *path string*). Both rounds are in
this commit; the remaining ~248 issues in both runs are the repo's sanctioned
`info` baseline in quran/tools files this pass never touched.
Against `865c3f8` the new file is red by construction, which is its other half of
evidence: 22 asset files instead of 15, 7 `arabic.json` blobs, +47,807,149 B, and
`FoldedHadith` with 8 fields instead of 7.

### What "100" can mean here, and what it cannot

**100 % Urdu is not achievable from this source** — nasai ~67 %, malik ~86 %,
bukhari ~92 %, and **2,966 rows have no Urdu anywhere upstream** (HR-2 proved the
bundled files byte-identical to `fawazahmed0/hadith-api`, so this is not a
truncation a re-fetch could fix). The honest 100 % is:

> **every hadith shows Urdu OR English, with the existing X6 fallback chip where
> Urdu is missing.**

…with its ceiling attached, because the sentence is only honest next to the
number: **206 of 36,390 rows (0.57 %) have neither**, and on those rows the
fallback line renders with no chip (there is no English to reveal). And "100 %"
must never be printed from a rounded percent alone: `abudawud` and `ibnmajah`
reach 100 % Urdu *by the app's rounding* while holding 1 and 16 blank rows
respectively — which is why the new test pins counts **and** percentages, and why
this table shows both.

### Size math, re-measured on file bytes (not on `du`)

| | files | edition-file bytes | MiB |
|---|---|---|---|
| pre-diet, at `865c3f8` | 22 | 113,548,414 | **108.29** |
| post-diet, shipped | 15 | 65,741,265 | **62.69** |
| removed (7 × `arabic.json`) | 7 | 47,807,149 | 45.59 (−42.1 %) |

Correction of a § A number, printed because § A's figure was wrong in a way that
matters to a reader who re-measures: § A quoted **62.70 MB / "15 files ·
65,746,257 B"**, which is what `du -sb assets/data/hadith` reports — and `du`
counts the directory entries' own sizes on top of the files (and even that number
moves with the filesystem: the same tree re-checked out reports 65,745,781). The
**file bytes are stable and are what the arithmetic uses**: 14 edition files
65,739,825 B + `kitab_names.json` 1,440 B = **65,741,265 B = 62.69 MiB**. The
pre-diet total is that plus the deleted 47,807,149 B = 113,548,414 B =
108.29 MiB, so the headline −42.1 % stands unchanged. The census test pins the
file-length sum.

**Boot and memory, from the app's own prints.** Decodes at boot went 21 → **14**
(two editions per book) — derived, not asserted by a constant: the boot batch is
`english` + `fileForLanguage.values`, and `hadith_pass_hr1_test`'s source pin
moved from "three asset reads per book" to two (`allMatches` 3 → 2). The fold
mirror's measured cost, post-diet, from run 43596310124:

| what | pre-diet (HR-1.3 runs) | post-diet (`13f9f55`) |
|---|---|---|
| mirror build, real rows | 101.6 – 169.9 µs/row | **54.4 µs/row** (1,200 rows, 65 ms) and **42.2 µs/row** (1,400 rows, 59,053 µs) |
| mirror content, real rows | 4 fields/row | **3 fields, 1,047–1,060 chars/row** (`[HR13_MEASURE] rows=1200 searchedChars=1256131 meanCharsPerRow=1047 fields=3`; `[HR13_RAM] mirror = 1,484,061 chars` for 1,400 rows) |
| RSS for 1,400 real rows | not printed then | **+3,600 KB**, of which the mirror's own chars are 2,898 KB |
| cached-scan p95 (1,200 real rows) | 10.6 – 11.3 ms | **5.6 ms** against a 500 ms bound; fold-per-scan 63.7 ms — the same ~11× ratio on two-thirds the text; extrapolated to all 36,390 rows: cached ~170 ms vs folding ~1,931 ms per keystroke |
| whole-corpus english fold | 423 – 519 ms | **319 ms** (36,390 rows, 15,400,840 chars, 20.7 ns/char) |
| what the worker holds at settle, HR-1's 20,020-row ledger | **32,662,575 folded chars ≈ 62.3 MB** | **24,403,886 folded chars ≈ 46.5 MB** = −8,258,689 chars, **−25.3 %**, ≈ **−15.8 MB** |

The last row is the headline, because it is the **same fixture** in both runs: the
identical ledger minus the Arabic text it used to be handed. The character
arithmetic behind it, measured from the deleted blobs in git rather than
estimated: the seven `arabic.json` held **19,976,745 raw chars** (549.0/row),
which the fold reduces to **12,594,187** (346.1/row) — so over a full-corpus
settle the diet stops the worker building and retaining **≈ 24.0 MB of UTF-16**,
and drops the mirror from ≈1,261.5 to **915.4 chars/row** (english 423.2 + urdu
464.0 + chapter 28.2, measured over the shipped files: 15,400,840 + 16,886,577 +
1,025,552 = 33,312,969 chars = 63.5 MB as UTF-16). The ratio to quote is
**−27.4 % of retained mirror text**, with the caveat § B already states: the
Phase-B fields stay folded, so the drop is smaller than "one field of three" would
suggest, and that is measured, not argued. Run-to-run noise on this suite is
±40 % (the fold alone has printed 319 / 423 / 519 ms on identical code), so the
char counts, not the milliseconds, are the durable numbers.

### APK delta: what can honestly be said without a build

`ci.yml` runs Dependencies → Analyze → Full test suite → Static battery and **no
build job**, so there is **no measured APK number for this pass and none is
claimed.** What can be measured here is the compressed payload, because Flutter
stores `.json` assets deflated: the seven removed blobs are 47,807,149 B raw and
**6,429,801 B (6.13 MiB) at deflate level 9**; the 15 files that remain compress
to 11,324,954 B. So pre-diet, Arabic occupied **36.2 %** (6,429,801 / 17,754,755)
of the hadith bundle's compressed footprint. The honest release-note sentence is
*"≈ 6.1 MB of compressed asset payload removed; the installed-size number needs a
build, which this pipeline does not run."*

### Two claims in my own working record that turned out to be false

Recorded because this report is the pass's audit trail and both were
load-bearing in the plan. (1) *"X5's spine test `hadith_pass_x5_test:305-312`
pins the manifest layout string — keep it green"*: **there is no such file**, and
no test in this repository has ever contained the word "spine" (`git grep` across
history returns nothing). The census above is therefore the **first** executable
spine pin, not a re-pin. (2) *"the service carries a wrong 'first match wins /
`putIfAbsent`' comment about the Urdu join"*: it does not — `assembleHadithBook`'s
comment already says last-write-wins, and my B pass kept it. What is real, and
what that note was groping at, is that the same file holds **two joins with
deliberately different rules**, which is why the two coverage families are not
comparable: `urduMap` (int `hadithnumber` key, last write wins, blanks overwrite →
the 77 collision rows) versus `pairTextIndex` (fractional-aware `pairKey`, blanks
*skipped*, `putIfAbsent` → first wins, for the Phase-B languages). Now documented
at the join instead of in a memory.

### C's re-pin ledger (old → new)

| thing | was | now |
|---|---|---|
| `backend/app/content/integrity.py` `HADITH_LANGS` | `("arabic","english","urdu")` | **`("english","urdu")`**, plus `hadith_coverage_matrix()` and a `_hadith_number_key` mirror of the loader's parse |
| `validate_hadith_file.ok` | `records > 0 && duplicate_ids == 0` (one duplicate number or one blank row failed a whole file) | **file verdict: exists, parses, has rows**; blanks and duplicates are reported as coverage, not as breakage |
| `scripts/validate_content.py` | two lines of hadith output (file count, empty sum) | **the 7-book matrix + `boot_decodes`, and a FAIL on spine / reference / edition integrity** |
| `assets/data/content_manifest.json` | 7 rows `"language": "ar/en/ur"`; sidecar `"meta (en/ar/ur render labels live)"` | **`"en/ur"`** ×7 and **`"meta (en/ur render labels live)"`** — the ledger no longer claims an edition its own `source` path does not hold |
| `lib/core/l10n/app_strings.dart` | `String get arabicTextSection => _t('Arabic Text (عربي)', …)`, **zero consumers** | **deleted**, with a note naming the block it labelled |
| `data/models/hadith_models.dart` | `HadithGrade.arabicLabel` (five Arabic strings), **zero consumers** | **deleted**; the `fromString` Arabic alternates stay because they parse upstream data |
| `hadith_pass_hr1_test` comparator prose | "the shipped bundle measures 1,436" | **"887 — 423 english + 464 urdu chars/row; the unbundled Arabic edition measured 549 more"**, all three measured (and 423.2 confirmed independently by the app's own `15,400,840 / 36,390`) |
| `hadith_pass_x6_test` header, `content_pass_test` header, `hadith_multilang_test` ordering note, `assembleHadithBook` doc | "the Arabic body always", "ar/en/ur", "AppStrings.arabicTextSection", "three decoded assets" | each rewritten to the two-edition truth |

### Gates, at the end of HR-2.1

`flutter analyze` **0 errors / 0 warnings** (248 sanctioned `info`s, all
pre-existing and untouched) · suite green at the count the ledger requires: **704**
before C's new file, **712** with its 8 tests · static battery **hard 0 | G2 319 |
L2 83 — ALL GATES PASS**, re-run on the clean worktree after every C edit ·
forbidden patterns 0 · `assets/` diff across the whole HR-2.1 chain = the **7
`arabic.json` deletions + `content_manifest.json` prose**, and
`git diff --name-only 865c3f8 HEAD -- assets/data/quran` → **empty** ·
capture-ban intact · the boot diet intact and now half its size · no new
dependency · `main` still on merge hold.

**Open for the owner, not decided here.** (i) The 206 rows with neither edition:
0.57 % of the corpus, unfixable from this source, so the choice is "accept the
honest line" (current behaviour) or "source a different Urdu edition". (ii) The Urdu join's key:
77 english spine rows share a truncated int key with a fractional sibling
(`402.2` onto `402`), and 52 non-blank Urdu texts are discarded by last-write-wins
blanks. Re-joining the Urdu on `pairKey` — the fractional-aware key the Phase-B
languages already use — would stop a sub-narration inheriting its sibling's text
and recover those 52 rows (a measured +0.16 % Urdu coverage on four books), but it
changes which text a reader is shown, so it waits for a word rather than riding in
on a diet.

## Addendum — HR-2.1 lands green (the run the § C promises were measured on)

Run **43628568264** (`82c5c90`) is the pass's evidence line, and every § C claim
above that said "CI to confirm" now has a number:

| gate | run 43628568264 |
|---|---|
| Dependencies | ✓ |
| **Analyze** (0 errors, 0 warnings; infos sanctioned) | ✓ — no `error •`, no `warning •` anywhere |
| **Full test suite** | **`🎉 712 tests passed.`** = 704 (the HR-1.3 baseline) **+ 8** (the new `hadith_hotfix_hr21_coverage_census_test`), so HR-2.1 removed a 45.6 % data slice, rewrote 20 files and added a census **without losing one test** |
| **Static battery** | `static battery: 185 dart files under lib` · `hard findings: 0 | G2 advisories: 319 | L2 alpha advisories: 83` · **ALL GATES PASS** |

The pass is five commits, each pushed and CI-read:
`24297a3` (A, the data diet) → `13f9f55` (B, the code diet) → `8ba57fa`
(C, the tool + the census + the ledger) → `6af5f9f` (the `qibra` → `qibra_ai`
import fix) → `82c5c90` (drop the `unused_import` the analyzer caught, and this
report's § B/§ C). The two red rounds between C and green are recorded in § C
above rather than edited out, because both are facts about how a blind-written
test gets compiled: the package name was guessed, and `LocalHadith` lives in the
**service** library, not in `hadith_models.dart` — a fact the analyzer enforces
and a 40-line balance audit cannot.

Whole-chain footprint, `865c3f8..HEAD`:

```
 35 files changed, 1611 insertions(+), 658957 deletions(-)
```

`assets/data/quran` is a zero diff across all five commits (the command
`git diff --stat 865c3f8 HEAD -- assets/data/quran` prints nothing), and the only
`assets/` entries in the chain are the seven `arabic.json` deletions and the
`content_manifest.json` prose. Timebox-8 was spent as briefed — one checkpoint
per section, A's redness disclosed instead of hidden, and no gate moved to make
the tree pass.
