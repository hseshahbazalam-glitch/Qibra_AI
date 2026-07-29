import 'package:flutter/material.dart';

class Reciter {
  final String id;
  final String name;
  final String arabicName;
  final String country;
  final String flag;
  final String baseUrl;
  final Color themeColor;

  const Reciter({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.country,
    required this.flag,
    required this.baseUrl,
    required this.themeColor,
  });

  String getSurahUrl(int surahNumber) {
    final padded = surahNumber.toString().padLeft(3, '0');
    return '$baseUrl/$padded.mp3';
  }
}

const List<Reciter> famousReciters = [
  Reciter(
    id: 'mishary',
    name: 'Mishary Al-Afasy',
    arabicName: 'مشاري العفاسي',
    country: 'Kuwait',
    flag: '🇰🇼',
    baseUrl: 'https://server8.mp3quran.net/afs',
    themeColor: Color(0xFFFFD166),
  ),
  Reciter(
    id: 'sudais',
    name: 'Abdul Rahman Al-Sudais',
    arabicName: 'عبد الرحمن السديس',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server11.mp3quran.net/sds',
    themeColor: Color(0xFF52B788),
  ),
  Reciter(
    id: 'abdul_basit',
    name: 'Abdul Basit',
    arabicName: 'عبد الباسط',
    country: 'Egypt',
    flag: '🇪🇬',
    baseUrl: 'https://server7.mp3quran.net/basit',
    themeColor: Color(0xFF7C3AED),
  ),
  Reciter(
    id: 'maher',
    name: 'Maher Al-Muaiqly',
    arabicName: 'ماهر المعيقلي',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server12.mp3quran.net/maher',
    themeColor: Color(0xFFA78BFA),
  ),
  Reciter(
    id: 'saad',
    name: 'Saad Al-Ghamdi',
    arabicName: 'سعد الغامدي',
    country: 'Saudi Arabia',
    flag: '🇸🇦',
    baseUrl: 'https://server7.mp3quran.net/s_gmd',
    themeColor: Color(0xFF4ECDC4),
  ),
];
