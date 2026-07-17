# QIBRA AI — PHASE 8 QURAN MODULE DETAILED PLAN

**Approach:** FULL PREMIUM (No MVP)
**Duration:** 4 weeks
**Total Files:** 25+
**Total Lines:** ~12,000+

═══════════════════════════════════════
PHASE 8.1 — DATA LAYER + QURAN HOME
═══════════════════════════════════════

## Files (5 files, ~2500 lines)

### 1. surah_model.dart (~200 lines)
class SurahModel {
int number; // 1-114
String nameArabic; // اَلْفَاتِحَة
String nameEnglish; // Al-Fatihah
String nameTranslation; // The Opener
String revelationType; // Makki/Madani
int totalAyahs;
int juzStart, juzEnd;
int pageStart, pageEnd;
String bismillah;
List<AyahModel> ayahs;
}

Includes:

fromJson / toJson
copyWith
equals/hashCode
toString
text


### 2. ayah_model.dart (~250 lines)
class AyahModel {
int number; // Global ayah number
int numberInSurah;
int surahNumber;
String arabicText;
String simpleText; // Without diacritics
int juz;
int page;
int ruku;
Map<String, String> translations; // Language -> Text
List<WordModel> words; // Word by word
bool isBookmarked;
bool isSajdah;
}

text


### 3. quran_local_data.dart (~500 lines)
class QuranLocalData {
// 114 Surahs metadata
static List<SurahModel> getAllSurahs()

// Get specific surah with ayahs
static Future<SurahModel> getSurah(int number)

// Popular surahs
static List<int> popularSurahIds = [1, 18, 36, 55, 67, 112]

// Load from bundled JSON
static Future<void> initialize()

// Search functionality
static List<AyahModel> search(String query)
}

text


### 4. quran_provider.dart (~400 lines)
Riverpod providers:

quranDataProvider (all surahs)
currentSurahProvider (state notifier)
surahListProvider (filtered/sorted)
lastReadProvider (from local storage)
readingProgressProvider
bookmarksProvider
searchQueryProvider
text


### 5. quran_home_screen.dart (~1200 lines)
Premium features:

Hero card (3D book effect + gradient)
Continue reading (with progress)
Streak counter (fire emoji + days)
Popular surahs carousel
Juz progress
Bookmarks preview
Daily ayah recommendation
Reading stats
Search bar
Bottom sheet quick actions
Staggered entrance animations
Pull to refresh
Beautiful glassmorphism
text


═══════════════════════════════════════
PHASE 8.2 — SURAH LIST SCREEN
═══════════════════════════════════════

## Files (2 files, ~1800 lines)

### 1. surah_list_screen.dart (~1400 lines)
Features:
- All 114 surahs with beautiful cards
- Sticky header with search
- Filter chips (All/Makki/Madani)
- Sort dropdown (Number/Alphabetical/Revelation)
- Category tabs (All/Favorites/Recent)
- Alphabet quick jump sidebar
- Search with real-time filtering
- Voice search
- Reading progress per surah
- Favorites toggle
- Long press for preview
- Staggered animations
- Beautiful empty states

### 2. surah_card_widget.dart (~400 lines)
Features:
- Beautiful design with number badge
- Arabic name + English name + Translation
- Ayah count badge
- Makki/Madani badge (color coded)
- Reading progress bar
- Favorite star
- Play button (audio preview)
- Bookmark indicator
- Hover effects
- Ripple animation

═══════════════════════════════════════
PHASE 8.3 — SURAH DETAIL (BIGGEST!)
═══════════════════════════════════════

## Files (4 files, ~4000 lines)

### 1. surah_detail_screen.dart (~2000 lines)
Features:
- Beautiful sticky header (surah name)
- Reading progress bar (top)
- Bismillah header
- Ayah cards (large Uthmanic Arabic)
- Multiple translations (side by side/stacked)
- Word-by-word tap
- Bookmark per ayah
- Share ayah (image generation)
- Copy ayah
- Play audio (per ayah + range)
- Tafseer bottom sheet
- Font size controls
- Night mode
- Focus mode (single ayah)
- Continuous mushaf mode
- Ayah number circles (Arabic style)
- Sajdah indicator
- Notes on ayahs

### 2. ayah_card_widget.dart (~800 lines)
- Large Uthmanic Arabic (Amiri font)
- Translation display
- Ayah number circle (Arabic ornament)
- Bookmark button
- Share button
- Play button
- Actions bottom sheet
- Selection state
- Highlight for currently playing
- Beautiful spacing

### 3. tafseer_bottom_sheet.dart (~600 lines)
- Multiple tafseer sources
- Tabs (Ibn Kathir, Jalalayn, etc.)
- Beautiful typography
- Expandable sections
- Reference numbers
- Share tafseer

### 4. word_by_word_popup.dart (~600 lines)
- Beautiful popup on word tap
- Arabic word large
- Transliteration
- English meaning
- Grammar info
- Related words
- Audio pronunciation

═══════════════════════════════════════
PHASE 8.4 — JUZ LIST SCREEN
═══════════════════════════════════════

## Files (2 files, ~1500 lines)

### 1. juz_list_screen.dart (~1000 lines)
Features:
- All 30 Juz with beautiful cards
- Progress bar per Juz
- First ayah preview
- Which surahs each Juz contains
- Reading time estimation
- Arabic Juz names (الجزء)
- Sort options
- Search
- Bookmarks

### 2. juz_card_widget.dart (~500 lines)
- Juz number badge
- Arabic + English name
- Surah range
- Progress indicator
- Ayah count
- Reading time
- Beautiful design

═══════════════════════════════════════
PHASE 8.5 — SEARCH SCREEN
═══════════════════════════════════════

## Files (2 files, ~1500 lines)

### 1. quran_search_screen.dart (~1000 lines)
Features:
- Beautiful search bar with voice
- Recent searches
- Suggested searches
- Real-time results
- Highlighted matches
- Preview snippets
- Filter chips
- Advanced filters
- Save searches
- Popular topics

### 2. quran_search_bar.dart (~500 lines)
- Search input with animations
- Voice input button
- Clear button
- Filter icon
- Suggestions dropdown

═══════════════════════════════════════
PHASE 8.6 — BOOKMARKS SCREEN
═══════════════════════════════════════

## Files (2 files, ~1500 lines)

### 1. bookmarks_screen.dart (~1000 lines)
Features:
- Beautiful bookmarks grid
- Folders/Categories
- Create custom folders
- Add notes per bookmark
- Tags system
- Filter by folder/tag
- Sort options
- Export bookmarks
- Share collections
- Beautiful empty state

### 2. bookmark_card_widget.dart (~500 lines)
- Ayah preview
- Personal note
- Tags
- Folder badge
- Edit/delete actions
- Beautiful design

═══════════════════════════════════════
PHASE 8.7 — AUDIO PLAYER
═══════════════════════════════════════

## Files (5 files, ~2500 lines)

### 1. audio_player_screen.dart (~1000 lines)
Full-screen player features:
- Beautiful cover art
- Waveform visualization
- Play/pause/seek controls
- Repeat modes
- Speed control
- Qari info
- Now playing surah/ayah
- Queue list
- Playlist support
- Sleep timer
- Download button

### 2. audio_mini_player.dart (~500 lines)
- Persistent mini player
- Bottom of screen
- Quick controls
- Progress bar
- Expand to full screen

### 3. audio_player_widget.dart (~400 lines)
- Reusable player component
- Multiple styles
- Custom controls

### 4. qari_selector_sheet.dart (~300 lines)
- 30+ Qaris list
- Preview audio
- Filter by style
- Download status

### 5. audio_service.dart (~300 lines)
- just_audio integration
- Background playback
- Queue management
- Download management
- Playlist management

═══════════════════════════════════════
TOTAL PHASE 8 STATS
═══════════════════════════════════════

Files: 25+ files
Lines: ~12,000+ lines
Screens: 7 screens
Widgets: 15+ reusable widgets
Providers: 6 Riverpod providers
Duration: 4 weeks
Quality: PREMIUM (production ready)

═══════════════════════════════════════
QUALITY BENCHMARKS
═══════════════════════════════════════

Compare to:
✅ Muslim Pro (features)
✅ Quran.com (design)
✅ iQuran (audio)
✅ Spotify (player UI)
✅ Apple Books (typography)

Our advantages:
✅ Modern Flutter design
✅ Glassmorphism
✅ Premium animations
✅ Offline first
✅ AI-ready architecture
✅ Beautiful Arabic typography
✅ Multiple translations
✅ 30+ Qaris
✅ Personal notes on ayahs
✅ Advanced searc