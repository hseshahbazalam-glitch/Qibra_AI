# Phase 0 — UI/UX Audit (2026-09-01, build e0c9138)

Method: every screen in the inventory was audited against code (`hex/alpha/emoji/raw-fontSize/state` counters below are exact `grep` numbers from the final tree) and the 4 owner screenshots. No code was changed in this phase.

## Legend
- **hex** = hardcoded `Color(0xFF…)` occurrences (rule 1 violation count)
- **α** = `withValues(alpha:)` occurrences (spaghetti where a token may exist)
- **fs** = raw `fontSize:` one-offs outside AppTextStyles (rule 3 violations)
- **em** = emoji characters in the file (rule: one icon language)

## Global findings (hit several screens at once)

| ID | Finding | Evidence |
|---|---|---|
| G1 | **`QibraCard(accentBorder:true)` paints a gold hairline around whole cards** — `QibraColors.dark.accent = 0xFFC6A15B`; used by Quran tab ×2, Hadith tab ×1, Home ×1. This is the gold-border creep visible in your screenshots. Fix in the shared widget once; 4 screens calm instantly. | qibra_ui.dart:234 |
| G2 | **Shared kit exists but adoption is ~0**: `AppPrimaryButton` 0 uses in features, `QibraAppBar` 0, `QibraSectionHeader` 5, `QibraEmptyState` 4, `QibraStatus` 5. 10 screens use `QibraPage`; 20+ roll their own. | grep counts |
| G3 | **Section headers reinvented**: local `letterSpacing: 2.0` overlines in splash, habits, calendar, salah_schedule, zakat, profile_setup (+more) — QibraSectionHeader does this already. | grep |
| G4 | **No skeletons anywhere** (0 `Skeleton` hits in lib/features); 6 screens use `CircularProgressIndicator`. Rule 7 currently failing app-wide. | grep |
| G5 | **No shared stat card or list row** → Quran streak trio, prayer stats, calendar stats, tools grid, more rows each hand-roll containers with own radii (9/10/12/14/16/20/24 all observed). Rules 2+4. | grep of `BorderRadius.circular` |
| G6 | Tap-target risk on Gesture-dense screens: qibla/mushaf/ayah_sheet/hadith_book/tafseer all render ~12–26px tappable glyphs via GestureDetector with no 48dp constraint. Rule 8. | tapmin scan |
| G7 | Two countdown formats: Home hero shows `2h 22m left` (QibraCountdownRing, shared) while Prayer tab shows hand-rolled `02:22:25` ring on top of the moon art. Same component should serve both. | screenshots |

## Screen-by-screen

### Auth (7)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 1 | **Splash** (770L, hex7, α18, fs6) | 7 stray hexes; 18 alpha washes; local `letterSpacing` overline; "QIBRA AI" lockup + tagline hand-laid; no press states needed but sizing one-offs (fs 8/9/10/12) drift from scale | Tokenize remaining 7 hexes; reuse QibraNavy tokens; tagline → AppTextStyles; keep logo+SafeImage(cacheWidth 288) | onboarding (wordmark), QibraNightSky | 7 |
| 2 | **Onboarding** (995L, hex0, α24, fs1) | α-spaghetti for chip washes; 3 art pages at 450 cacheWidth OK; dots/CTA sizes OK; copy block spacing 12/16/20 mixed → 16; page-view chrome not from kit | Replace washes w/ tokens (`primarySoft`/`cardElevated`); unify CTA to AppPrimaryButton; skip/next → QibraSoftButton | splash, login header pattern | 7.5 |
| 3 | **Login** (934L, hex0, α16) | Already AppSpacing-based; auth widgets exist (AuthTextField/AuthButton/AuthHeader/AuthSocialButton) but each carries own α-washes (16); "guest" affordance low contrast | Sweep α→tokens inside the 4 auth_* widgets (fixes register/forgot/verify too); tighten social row gap to 12 | register, forgot, verify (auth kit) | 7.5 |
| 4 | **Register** (1154L, hex0, α22) | Same as login + password-requirements block is 10px one-off text; long form has no section rhythm (16) | Auth-kit sweep + requirements as QibraCard list w/ check icons | login (auth kit) | 7.5 |
| 5 | **Forgot password** (1190L, hex0, α39, spinner1) | 39 α uses = most of auth suite; raw spinner in button; success state is plain text | α→tokens; success → QibraStatus variant; button spinner stays (it's inside a button — acceptable) | auth kit | 7 |
| 6 | **Verify OTP** (1353L, hex1, α39, spinners2) | 1 hex; 39 α; two raw spinners; 4-box code field hand-built with `fontSize:40` one-off; resend timer is a 12px label | Tokenize; code boxes → shared `QibraCodeField`-style layout w/ AppTextStyles.number; resend → QibraSoftButton | auth kit | 7 |
| 7 | **Profile setup** (1025L+form, hex0, α46) | Two files of α; local overline header; avatars row gaps 4/8; choice chips custom | α→tokens; header → QibraSectionHeader; chips → QibraChip | onboarding, settings | 7 |

### Tabs + home children (6)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 8 | **Home** (270L + hero 457 + sections 939, hex4, α16) | Gold triple-stack on Daily-ayah card (gold label + gold book glyph + G1 gold border); Hijri chip text renders *under* the moon art (collision, visible top-right of hero); "open the first su…" mid-word truncation in Start-reading; hero art is app-wide (correct — keep only here) | Remove accentBorder (G1); overline → textSecondary + emerald glyph; move chips left of moon or dim moon behind chip zone; Start-reading title → maxLines 1 + shorter string "Continue — Al-Fatiha"; strip home_sections' 4 hexes | ALL tabs via QibraPage/QibraCard; prayer strip rows (mini), quran daily card (mini) | 8 |
| 9 | **Quran tab** (698L, hex0, α3) | G1 gold borders on 2 cards; streak trio = 3 competing accents (orange flame, emerald book, gold medal) + 3 radii; Arabic surah name in Browse rows still `goldText` (line ~…surah rows render Arabic gold — same bug class as P1's reader fix); "Recitation is not bundled" pill = right, keep | Gold→hairline; streak row → new shared **QibraStatCard** (emerald number, textSecondary label, one accent max); Browse-row Arabic → textPrimary; keep 20/24 rhythm | home daily-ayah section, hadith tab (card+actions row), QibraStatCard | 7.5 |
| 10 | **Prayer tab** (856L, hex0, α12) | Two UNKNOWN surfaces (hero chip + full-width location card) = dead weight duplication; `02:22:25` ring text sits on the gold moon (low contrast, G7); 4-dot pagination under hero is decorative (no pager exists); alarm toggle circles ~26px (rule 8); hero uses its own night-sky variant not the shared one | Merge location: one tappable location row in hero chips only; countdown → shared QibraCountdownRing w/ "2h 22m" + secondary `HH:MM:SS` under it (one format across app); delete the fake dots; toggle → 48dp InkResponse; flat navy surfaces, no hero art below the hero (currently a second faint mosque image behind "Today's times"?— verify) | qibla, schedule, tahajjud (prayer time row = schedule_prayer_tile exists), QibraCountdownRing | 7 |
| 11 | **Hadith tab** (770L, hex0, α3) | G1 gold border on Today card; collection dots violet/blue (breaks "violet = AI only"); per-collection color map at :40-56 is arbitrary; art crop letterboxed mid-gradient; grade chip gold = keep (tiny badge ✓) | Drop accentBorder; dots → single emerald/hairline language (or 1px left rule); collection accent map deleted; Read/Bookmark/Share row → shared **QibraActionRow** (same as Quran tab) | quran tab (card + QibraActionRow), hadith_book | 7.5 |
| 12 | **AI tab** (1047L, hex2, α14, fs18) | 18 raw fontSizes incl. raw `TextStyle(...height:1.6)` message bodies; 2 hexes; message bubbles hand-built, no QibraPage header; source chips 10px one-offs; input bar custom | Full token pass: AppTextStyles everywhere; bubbles → theme tokens (user=cardElevated, AI=card+emerald hairline); sources → QibraChip; keep violet (only legal violet surface) | QibraChip, app_button, nothing else shares it (island by design) | 6.5 |
| 13 | **More** (210L, clean) | Best-in-class already (QibraPage/SectionHeader/Card); only nit: tile rows use own _MoreGroup row layout vs future shared tile | Adopt shared QibraListTile when promoted (D) | home, tools hub | 8 |
| 13b | Home children: daily-ayah & next-prayer live as sections here | See #8/#10 — continue-reading + daily-ayah routes both deep-link into reader/quran surfaces | — | — | — |

### Quran suite (5)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 14 | **Reader** surah_reader (725L, **hex76**, fs25, em1, InkWell5) | Worst token offender in the Quran suite: 76 hard-coded hexes (legacy mushaf palette), 25 raw sizes, 1 emoji residue; ayah rows custom; no empty state for missing-surah case | Full QibraNavy conversion (same proven map as P2 sweep: bg→card, fg→textPrimary/emerald/gold accents); ayah row → shared **QibraAyahRow** w/ options-tap; AppTextStyles for Arabic scale (size slider lives in settings — keep) | ayah_options_sheet, mushaf, tafseer, surah_list | 6 |
| 15 | **Search** quran_search (1294L, hex0, **α34**, fs4) | α-spaghetti for chip/hl washes; own header; result rows 14px one-offs; no skeleton on typing debounce | Tokens; topic chips → QibraChip; highlight stays emerald (already fixed P1); loading = shimmer rows | reader, surah_list | 6.5 |
| 16 | **Mushaf** reader (1088L, hex1, **em17**, fs16, α25) | 17 emoji in page chrome (juz markers/sajdah glyphs as text); raw `fontSize: 12-18` sprinkles; page-nav bar hand-rolled | Emoji → Icons (flag/ mosque book icons); token pass; page bar → QibraIconButton ×3 + AppTextStyles; page art SafeImage already cacheWidth ✓ | reader (shared ayah rendering), QibraScreenHeader | 5.5 |
| 17 | **Continue reading** (route :178) | Resolves to reader with saved position — no distinct chrome; verify empty case ("no history" → QibraStatus today? not present) | Add empty/resume state via QibraStatus; else inherits #14 redesign | reader | (6) |
| 18 | **Daily ayah** (route :188) | Shares Home card design incl. G1 gold border; standalone screen currently just reuses section widget — OK | Inherits Home fix; give it the QibraPage wrapper + share/bookmark actions row | home, quran tab | (7.5) |

### Prayer suite (5)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 19 | **Qibla** (1547L, **hex92, α47, em3** 🧭🕋, fs11) | Single worst screen: 92 hexes + 47 alphas + emoji + 11 tiny GestureTargets; compass hand-painted with hexes; 7 error strings raw | Rebuild on tokens: compass = CustomPainter w/ QibraNavy tokens only, degree readout = AppTextStyles.number, direction row → schedule_prayer_tile-style row; emoji→Icons; skeleton while sensor init | prayer tab (hero pattern), QibraStatus | 4 |
| 20 | **Mosques** (412L, hex0, α4, spinner1) | Mostly clean; spinner→skeleton; list rows need 48dp+hairline; map absent (fine — list-first) | Adopt QibraListTile + QibraStatus(empty) | prayer tab | 7 |
| 21 | **Schedule** salah_schedule (1147L, hex18, α14, fs11, local overline) | 18 hexes; own overline header; month grid custom radii; selected-day state unclear | Token pass; header → QibraSectionHeader; day rows reuse prayer-time row pattern; selected = emerald left-rule | prayer tab, calendar | 6 |
| 22 | **Statistics** (659L, hex0, α6, fs11) | 11 raw sizes; chart bars hand-built w/ per-widget radii; big number 48 one-off (keep 48 via style) | QibraStatCard for the 4-up grid; bars → emerald tokens with hairline track | #21, tools, calendar | 6.5 |
| 23 | **Tahajjud** (933L, **hex27**, α10, fs11) | 27 hexes; ElevatedButton x2 off-kit; countdown again bespoke (G7) | Token pass; reuse QibraCountdownRing "Xh Ym"; buttons → AppPrimaryButton/AppSoftButton | prayer tab, QibraCountdownRing | 6 |

### Dua (2 + list)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 24 | **/dua home** (831L, α16, fs8, em4 as data keys only) | Post-P2 it's token-clean but: category cards radii 14/16 mixed; counts in 10px one-offs; no skeleton | Radii→16; counts→bodySmall; QibraStatCard lite for hero; category grid = QibraCard grid pattern shared w/ tools hub | tools hub (grid), dua detail | 7 |
| 25 | **/dua list** (427L, hex2, α5, fs8 incl **56/36**) | `fontSize:56` + `36` hero numerals off-scale; 2 hexes | Tokenize; hero number → AppTextStyles.displayLarge | #24, #26 | 6.5 |
| 26 | **/dua detail** (700L, α10, fs4) | Clean post-P2; share/copy action row should become QibraActionRow; Arabic block bg wash α → cardElevated | Small polish only | #9/#11 action row | 7 |

### Tools (5 + hub)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 27 | **/tools hub** (155L, clean) | Good; tile grid = one-off spacing (8/4 gaps) | Adopt shared tile (same as duas grid) when promoted | #24, more | 8 |
| 28 | **Zakat** (1093L, **fs32**, α44) | Typography chaos: 32 raw sizes, 44 washes; form fields own-styled; results panel radii 14 | Form scaffold → shared **QibraFormField** (already needed by auth/register + inheritance + profile-setup); numbers via scale; keep engine untouched | inheritance, register, profile setup | 6 |
| 29 | **Inheritance** (1222L+802L results, **fs47 combined**, α65, hex1) | Same as zakat but worse (results part-file = 29 fs one-offs + 44 α) | Same form kit + QibraStatCard for share rows | zakat | 6 |
| 30 | **Habits** (756L, **em26**, hex6, α33, fs21) | 26 emoji (icons + streak glyphs), 6 legacy hexes, own overline, spinner | Full emoji→Icons sweep; token pass; week strip → schedule_prayer_tile sibling pattern; empty → QibraStatus | prayer stats, calendar | 4.5 |
| 31 | **Tasbih** (838L+detail, α35, fs6, size:80 tap number) | Counter surface itself good; detail part heavy α; count font 80 one-off (keep as displayLarge token); tap ring 48? mostly OK | α→tokens (washes over card), unify counter typography into AppTextStyles.displayLarge; keep haptics | prayer stats (stat card) | 7 |

### Misc (4 + strays)

| # | Screen | Current problems (concrete) | Redesign plan | Shares components with | /10 |
|---|---|---|---|---|---|
| 32 | **Calendar** (994L, α15, fs12, local overline) | Day-cell radii mixed; event rows custom; overline G3 | QibraSectionHeader; day cells on 12-radius; events → QibraListTile w/ gold dot (≤5%) | schedule, stats | 6.5 |
| 33 | **Profile** (174L) | Clean post-P1; avatar header 14px gap one-off; adopt shared tile for its 2 rows | Trivial alignment pass | more, settings | 8 |
| 34 | **Settings** (1299L, α23, fs10, 6×ElevatedButton) | Raw ElevatedButtons off-kit; section grouping via local containers; 23 washes; font-size control good | Buttons→AppPrimaryButton/AppTextBtn; groups→QibraCard+Switch tile (app_switch_tile exists!); keep privacy/logout confirm sheet | notifications, profile | 7 |
| 35 | **Notification settings** (718L, α21, fs17, spinner1) | Post-P2 clean color-wise; many small text one-offs; spinner; toggle rows 11px labels | fs→scale; skeleton; AppSwitchListTile adoption | settings | 7 |
| 36 | **Bookmarks hub** (535L, clean) | Tabs + lists; empty handled (4× 'empty') | Align rows to shared tile | — | 8 |
| 37 | **Hadith book** (876L, fs29) | 29 raw sizes; row tap 12px chevrons (G6); art list thumbnails need cacheWidth audit | fs→scale; QibraListTile; SafeImage(cacheWidth 512 pattern) | hadith tab, collections rows | 6.5 |
| 38 | **Tafseer** (1064L, hex5, **em7**, fs19, spinner1) | Stray screen — not in your inventory but routed/reachable (ayah sheet → tafseer). 5 hexes, 7 emoji, raw styles | Same class as reader conversion; share w/ reader typography | reader, ayah sheet | 5 |
| 39 | **Ayah options sheet** (719L, **em11**, fs10, α17) | 11 emoji in action grid + tap targets 12-26px (G6); radius 12 ok | Emoji→Icons w/ labels; 48dp action cells; sheet chrome → standard `showModalBottomSheet + QibraColors.card` | reader, mushaf | 5.5 |

**Not in inventory but reachable** (need your scope call): /tools children — sadaqah tracker, ramadan timer, hajj/umrah/nikah guides, halal scanner, asma ul husna, islamic name finder (all under `lib/features/tools/screens/`); tafseer (#38); duas list (#25); hadith book (#37); notification settings (#35). I audited them anyway — recommend folding them into Stages C/D rather than shipping an app where the hub's tiles open un-skinned siblings.

## Component promotions (rules 4+7) — new/changed in `lib/shared/widgets`

1. **QibraCard.accentBorder fix** — gold → `emerald.withValues(0.35)` hairline (or delete param; G1).
2. **QibraSectionHeader adoption** — delete the 10 local overlines (G3); add optional `action` slot (already exists? verify) and `overline` semantics.
3. **QibraStatCard** (new) — icon + number + label + optional delta; used: quran streak trio, prayer stats, calendar day, tools results, habits.
4. **QibraListTile** (new) — leading icon 40/12-radius, title bodyMedium, subtitle bodySmall, trailing chevron/switch, min height 48, 12 gap; replaces: more rows, mosques, calendar events, bookmarks rows, settings groups, hadith book rows, dua list rows.
5. **QibraSkeleton** (new) — shimmer boxes + `QibraSkeletonList(count:)`; replaces every `CircularProgressIndicator` in list screens (keep in-button spinners); G4.
6. **QibraActionRow** (new) — Read/Bookmark/Share/Copy trio: label above 22-icon cell, 48dp; used quran tab, hadith tab, dua detail, bookmarks, reader bottom bar.
7. **One countdown** — QibraCountdownRing gains `mode: compact|precise`; prayer tab + tahajjud consume it (G7).

## Staged execution plan (after your approval)

| Stage | Screens | Big wins |
|---|---|---|
| **A** — tabs+home children (7 files + qibra_ui kit) | #8–13 (+daily-ayah/continue surfaces), G1 G7 fixes, QibraStatCard/ActionRow born here | Gold-border creep gone app-wide via G1; streak trio + action rows unified |
| **B** — Quran suite (6 files) | #14–18 + #38 tafseer + #39 ayah sheet | hex76→0 reader; mushaf/emoji sweep; QibraAyahRow |
| **C** — Prayer suite (5 files) | #19–23 + #37 hadith book folded in B/C boundary | Qibla rebuild (worst screen), skeletons everywhere in suite |
| **D** — tools+duas+misc (12 files) | #24–36 | QibraListTile/FormField adoption; habits emoji sweep; un-skinned tools children folded in |
| **E** — auth suite (7 files) | #1–7 | Auth-kit pass kills ~160 α-spaghetti in 5 files at once |

Every stage: `flutter analyze` 0 errors (static-verified; note SDK unavailable in sandbox — device run remains your gate), phase17/18/19 green (dry-run battery extended with per-stage residual scans: hex=0, em=0, fs one-offs≤style exceptions list), per-screen BEFORE→AFTER description.

## Ratings summary (lowest first — priority order if you want to re-rank)
Qibla 4 · Habits 4.5 · Tafseer 5 · Ayah-sheet 5.5 · Mushaf 5.5 · Reader 6 · Schedule 6 · Tahajjud 6 · Zakat 6 · Inheritance 6 · AI 6.5 · Search 6.5 · Dua-list 6.5 · Stats 6.5 · Hadith-book 6.5 · Calendar 6.5 · Splash 7 · Onboarding 7.5 · Login 7.5 · Register 7.5 · Forgot 7 · Verify 7 · Profile-setup 7 · Prayer 7 · Quran 7.5 · Hadith 7.5 · Dua-home 7 · Dua-detail 7 · Tasbih 7 · Mosques 7 · Settings 7 · Notifications 7 · More 8 · Tools-hub 8 · Profile 8 · Bookmarks 8.

## Decisions I need from you
1. **Scope additions**: fold #25/#35/#37/#38/#39 + the 8 unlisted /tools children into stages as proposed? (Rule 9 says yes.)
2. **G1**: fix accentBorder to emerald hairline, or delete the param entirely (all call sites get plain navy border)?
3. **Streak/medal/flame multi-accent (Quran tab)**: unify to emerald + textSecondary (my plan), or keep orange flame as an allowed "utility accent" token?
4. **Prayer tab fake 4-dot pagination** under the hero (no pager exists): delete (my recommendation) or wire a real 2-page hero?
5. **Mushaf 17 emoji**: some may be glyph-like separators in page chrome — OK to replace with Material icons even where they're "decorative rules"?
6. Stage order A→B→C→D→E acceptable, or move AI (currently stage A) to its own polish pass given it needs 18 fs + message-bubble spec?
