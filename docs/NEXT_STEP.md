# QIBRA AI — NEXT STEP

**Current:** Phase 7 Complete + Reference Image Received
**Next:** PREMIUM UI REDESIGN + Bug Fix + Option B + Phase 8

---

## 🎨 NEW DESIGN DIRECTION

User has provided REFERENCE IMAGE showing premium design quality target:
- Photorealistic hero images
- 3D-rendered Islamic elements
- Circular progress rings
- Ornamental star badges
- Character illustrations
- Feature cards with 3D icons
- Golden Arabic calligraphy accents

---

## IMMEDIATE PRIORITIES

### 🔴 PRIORITY 1 — Fix Scroll-Stuck Bug (URGENT)

**Problem:** App stuck on scroll (Chrome)
**Files:**
1. lib/features/home/presentation/home_screen.dart
2. lib/features/prayer/presentation/prayer_screen.dart

**Fix:** Change Timer.periodic(seconds: 1) → seconds: 30

---

### 🎨 PRIORITY 2 — Setup Image Assets

**Create folders:**
- assets/images/hero/
- assets/images/illustrations/
- assets/images/patterns/

**Update pubspec.yaml** to include new asset paths

**Generate 10+ AI images using DALL-E/Midjourney**

---

### 🏗️ PRIORITY 3 — Create New Reusable Widgets

Create these premium widgets:
- AppHeroImageCard (background image + gradient overlay)
- AppCircularProgressRing (for countdowns)
- AppOrnamentalStarBadge (for Surah numbers)
- AppRecentSurahCard (horizontal card with star)
- AppVerticalProgressBar (for daily stats)
- AppListenCard (recitation card with play)
- AppFeatureIllustrationCard (3D icon feature card)
- AppEmptyState (with illustration)
- AppErrorState (with illustration)

---

### 🎯 PRIORITY 4 — REDESIGN Home Screen

Match REFERENCE IMAGE 1:
- Hero mosque night background
- Circular countdown ring (not linear)
- Ornamental Surah number badges
- Vertical progress bars for daily stats
- 3D illustration feature grid
- Golden Arabic calligraphy elements

---

### 🎯 PRIORITY 5 — Option B Enhancements

1. Ramadan Widget (with lantern hero image)
2. Nearby Mosque Card (with mosque image)
3. Error State (with broken book illustration)
4. Empty State (with praying character)

---

### 🎯 PRIORITY 6 — Phase 8: Quran Module

Match REFERENCE IMAGE 2:
- Al-Fatihah hero card with glowing Quran 3D
- Circular category buttons
- Reading progress card
- Recently Read horizontal cards
- Daily Verse with mosque background
- Listen to Quran with waveform

---

## COMMAND FOR AI

Use the comprehensive prompt provided in handoff docs.
Follow 23-step response format.
ONE FILE at a time.
Provide DALL-E prompts for every image needed.

---

## KEY DESIGN RULES

1. NEVER use flat basic icons — use 3D illustrations
2. ALWAYS add hero images to major cards
3. Use gradient overlays for text on images
4. Prefer circular progress over linear
5. Use ornamental Islamic shapes
6. Golden accents on emerald base
7. Cinematic depth and lighting