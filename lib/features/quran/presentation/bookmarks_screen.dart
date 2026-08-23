// lib/features/quran/presentation/bookmarks_screen.dart
// Compatibility wrapper. Quran / Hadith / Dua bookmarks live in BookmarksHubScreen.

import 'package:flutter/material.dart';

import '../../bookmarks/presentation/bookmarks_hub_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) => const BookmarksHubScreen();
}
