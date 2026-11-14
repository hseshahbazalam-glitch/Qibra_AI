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
| coverage pins | unchanged — nasai/urdu 67 %, malik/urdu 86 %, bukhari/urdu 92 % |
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
