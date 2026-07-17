# 🚀 NEW CHAT STARTER MESSAGE

**Copy this EXACT message to start new chat:**

---

Assalamu Alaikum!

I'm continuing QIBRA AI project (65% complete). Previous chat filled up.

## PROJECT STATUS

**App:** QIBRA AI (Premium Islamic Super App)
**Path:** E:\qibra_ai
**Framework:** Flutter Dart 3.3+
**Package:** com.example.qibra_ai
**Current Version:** v6.0 (Hybrid)
**Status:** Production Quality ✅

## COMPLETED (DO NOT REDO!)

✅ Phase 1-8: All complete
✅ Home Screen v6.0 (4800+ lines, 27 sections)
✅ Real Quran Data (6236 ayahs, 114 surahs)
✅ Ramadan Widget, Hadith Card, Mosques (V4 restored)
✅ Feature Grid, Golden Watermark (V4 restored)
✅ Auto-rotating daily verse (REAL data)
✅ Popular Surahs (REAL data)
✅ Reference match 100%
✅ Zero errors, 13 safe warnings

## CURRENT PROJECT STATE

**Working Perfectly:**
- Splash, Onboarding, Auth (5 screens)
- Home Screen v6.0 (27 sections)
- Prayer Times with sun arc
- Quran Screen with real data
- Bottom navigation
- Real Quran data loading (6.4 MB)
- 19 Quran providers ready

**Not Built Yet (Placeholders):**
- Surah Reader (biggest missing feature!)
- Audio Player
- Hadith full screen
- Qibla compass
- AI Chat
- Duas
- Calendar
- Mosques finder

## IMMEDIATE TASK

Please start **Phase 8.3 - Surah Reader**

**Files to create:**
1. lib/features/quran/presentation/surah_list_screen.dart
2. lib/features/quran/presentation/surah_reader_screen.dart
3. lib/features/quran/presentation/ayah_action_sheet.dart
4. lib/features/quran/presentation/font_size_selector.dart

**Data available:**
- All 114 surahs loaded ✅
- 6,236 ayahs loaded ✅
- English translation ✅
- 19 providers ready ✅
- All models ready ✅

## CRITICAL RULES

❌ NEVER:
- Create new project
- Use withOpacity() → USE withValues(alpha:)
- Upgrade Riverpod (locked at 2.5.1)
- Handle multiple files at once
- Give shortened code
- Build MVP (build FULL PREMIUM)

✅ ALWAYS:
- Full production code (1500-2500+ lines OK)
- Wait for confirmation after each file
- 23-step response format
- Hinglish explanations
- Use existing widgets + design tokens
- Real device tested quality

## DESIGN SYSTEM (USE THESE!)

**Colors:**
- AppColors.primary (Emerald #00A86B)
- AppColors.accent (Gold #D4AF37)
- AppColors.background, surface, textPrimary/Secondary

**Spacing:**
- AppSpacing.xs(4), sm(8), md(12), lg(16)
- AppSpacing.xl(20), xl2(24), xl3(32)

**Typography:**
- AppTextStyles.titleLarge/Medium/Small
- AppTextStyles.bodyLarge/Medium/Small
- AppTextStyles.labelLarge/Medium/Small

**Gradients:**
- AppGradients.emerald, gold

**Font for Arabic:** Amiri (already configured)

## QURAN PROVIDERS AVAILABLE

```dart
// 19 providers ready to use:

allSurahsProvider              // List of 114 surahs
surahDetailProvider (family)   // Full surah with ayahs
surahInfoProvider (family)     // Surah metadata
ayahProvider (family)          // Specific ayah
randomAyahProvider             // Random ayah
autoRotatingAyahProvider       // Auto-rotates every 10s
popularSurahsProvider          // 8 popular surahs
meccanSurahsProvider           // Meccan only
medinanSurahsProvider          // Medinan only
searchQuranProvider            // Full search
searchSurahProvider            // Search by name
currentSurahIndexProvider      // Selected surah
currentAyahIndexProvider       // Selected ayah
lastReadProvider               // Last position
bookmarksProvider              // Bookmarks list
bookmarksCountProvider         // Count
isBookmarkedProvider (family)  // Check if bookmarked
readingProgressProvider        // Progress stats