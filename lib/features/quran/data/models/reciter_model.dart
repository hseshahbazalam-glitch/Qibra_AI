import 'package:flutter/material.dart';

class Reciter {
  final String id;
  final String name;
  final String arabicName;
  final String country;
  final String flag;
  final String baseUrl;
  final Color themeColor;
  final bool isPremium;
  final int bitrate;

  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.country,
    required this.flag,
    required this.baseUrl,
    required this.themeColor,
    this.isPremium = false,
    this.bitrate = 128,
  });

  // Get audio URL for specific surah
  String getSurahUrl(int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    return '$baseUrl/$padded.mp3';
  }
}

// ═══════════════════════════════════════════════════════════
// TOP 10 FAMOUS QARIS
// ═══════════════════════════════════════════════════════════
const List<Reciter> famousReciters = [
  Reciter(
    id: 'sudais',
    name: 'Abdul Rahman Al-Sudais',
    arabicName: 'عبد الرحمن السديس',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server11.mp3quran.net/sds',
    themeColor: Color(0xFF52B788),
    bitrate: 128,
  ),
  Reciter(
    id: 'mishary',
    name: 'Mishary Rashid Al-Afasy',
    arabicName: 'مشاري راشد العفاسي',
    country: 'Kuwait',
    flag: '🇰🇼',
    baseUrl: 'https://server8.mp3quran.net/afs',
    themeColor: Color(0xFFFFD166),
    bitrate: 128,
  ),
  Reciter(
    id: 'abdul_basit',
    name: 'Abdul Basit Abdul Samad',
    arabicName: 'عبد الباسط عبد الصمد',
    country: 'Egypt',
    flag: '🇪🇬',
    baseUrl: 'https://server7.mp3quran.net/basit',
    themeColor: Color(0xFF7C3AED),
    bitrate: 192,
  ),
  Reciter(
    id: 'saud_shuraim',
    name: 'Saud Al-Shuraim',
    arabicName: 'سعود الشريم',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server7.mp3quran.net/shur',
    themeColor: Color(0xFF74C0FC),
    bitrate: 128,
  ),
  Reciter(
    id: 'maher_muaiqly',
    name: 'Maher Al-Muaiqly',
    arabicName: 'ماهر المعيقلي',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server12.mp3quran.net/maher',
    themeColor: Color(0xFFA78BFA),
    bitrate: 128,
  ),
  Reciter(
    id: 'saad_ghamdi',
    name: 'Saad Al-Ghamdi',
    arabicName: 'سعد الغامدي',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server7.mp3quran.net/s_gmd',
    themeColor: Color(0xFF4ECDC4),
    bitrate: 128,
  ),
  Reciter(
    id: 'ahmed_ajmi',
    name: 'Ahmed Al-Ajmi',
    arabicName: 'أحمد العجمي',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server10.mp3quran.net/ajm',
    themeColor: Color(0xFFFF8C42),
    bitrate: 128,
  ),
  Reciter(
    id: 'muhammad_ayoub',
    name: 'Muhammad Ayoub',
    arabicName: 'محمد أيوب',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server11.mp3quran.net/ayyub',
    themeColor: Color(0xFFEF4444),
    bitrate: 128,
  ),
  Reciter(
    id: 'yasser_dossari',
    name: 'Yasser Al-Dossari',
    arabicName: 'ياسر الدوسري',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server11.mp3quran.net/yasser',
    themeColor: Color(0xFFFF9EBC),
    bitrate: 128,
  ),
  Reciter(
    id: 'khalifa_tunaiji',
    name: 'Khalifa Al-Tunaiji',
    arabicName: 'خليفة الطنيجي',
    country: 'UAE',
    flag: '🇦🇪',
    baseUrl: 'https://server12.mp3quran.net/tnjy',
    themeColor: Color(0xFF38BDF8),
    bitrate: 128,
  ),
];
