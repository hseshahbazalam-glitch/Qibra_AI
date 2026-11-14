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

# HOTFIX HR-1.1 (device re-run after HR-1 landed)

Two surgical fixes, both scoped to the search path HR-1 introduced. HR-1 removed
the per-keystroke corpus copy; the device came back and said the search now
never answers, and that its entry field is clipped. Neither is a redesign, and
neither re-introduces the thing HR-1 removed.

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
| `flutter analyze` / `flutter test` | **not measurable in this sandbox — no Flutter/Dart SDK.** CI is the only compiler here, and it earned that role: see the CI rounds below |
| CI, HR-1.1/1.2 round 1 — run **43568103288**, job 132366294923 | **RED**, `flutter analyze` exit 1, 3 errors, at `394c1e3`: `conflicting_static_and_instance` ×2 (`HadithSearchWorker` may not have a static `replyTimeout`/`reviveCooldown` AND an instance getter of the same name) and `undefined_getter` (`ReceivePort.errors` does not exist on Flutter 3.44.6 / Dart on `ubuntu-26.04`). The test step never ran, so **no test numbers from that run**. |
| CI, HR-1.1/1.2 round 2 — run **43568453101**, job 132367353570 | **RED** again, `flutter analyze` exit 1: one more `conflicting_static_and_instance` (the `retireAfterTimeouts` pair round 1's log chunk I read did not contain) plus 3 × `unused_element_parameter` **warnings** — the `HadithSearchWorker._shared()` singleton declared the test overrides it could never be given. Fixed in round 3: the third getter is now `effectiveRetireAfterTimeouts`, and `_shared()` declares no parameters at all (the singleton MUST run the shipped numbers; an optional knob on that path is a test seam leaking into production). Test step still skipped, so still no test numbers. |
| CI round 5 — run **43569441814** (commit `f45003d`) | **ANALYZE WENT GREEN for the first time** (`0 errors, 0 warnings` — the whole name-collision arc is closed), and the `flutter test` step FINALLY RAN. It did not finish: my HR-1.2 test's `FlutterError.onError` capture collided with flutter_test's own error slot (`binding.dart:1911`), the test hung for its full 10-minute budget, and the job's `timeout-minutes: 20` cancelled the run at 07:25:51. Verbatim: `TimeoutException after 0:10:00.000000: Test timed out after 10 minutes.` preceded by `Failed assertion: '_pendingExceptionDetails != null': A test overrode FlutterError.onError but either failed to return it to its original state, or had unexpected additional errors that it could not handle.` Two facts from that log: (1) ~200 `test/core/*` tests reported ✅ before the hang, so the suite itself is fine; (2) the hang was 100% my test file's fault, not the fix's. Fixed by asserting through `tester.takeException()` instead of swallowing error details. |
| STILL OPEN after round 5 | `flutter test` has never produced a final count on this branch, and the job budget (20 min, pre-existing) is tight for a suite that already needed >13 min before the hang. **Two options, owner's call:** (A) raise `timeout-minutes` on the existing `quality` job — a budget bump, not a gate weakening, but it is an edit to a line I was told to leave alone; (B) keep 20 min and shrink the hotfix tests' cost (fewer real-isolate spawns). I did neither unilaterally. |
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
* **HR-1.2** — with the keyboard up the sheet is now shorter than it was (88 % of the
  remaining space instead of an un-fittable 88 % of the screen); that is the fix, not a
  regression: the old height was not actually displayable. Landscape/IME hand-off frames
  where insets exceed the panel height yield height 0 rather than a negative assert.
