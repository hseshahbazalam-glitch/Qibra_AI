// lib/features/tools/logic/nikah_guide_data.dart
// Pure data for the Nikah guide, merged into the Tools hub by the LEAN
// PASS (standalone NikahGuideScreen + /tools/nikah route deleted).
// Strings transcribed verbatim from the old screen at a4703de.
import 'package:flutter/material.dart';

@immutable
class NikahGuideItem {
  const NikahGuideItem(
      this.title, this.body, this.arabic, this.transliteration, this.icon);

  final String title;
  final String body;
  final String arabic;
  final String transliteration;
  final IconData icon;
}

@immutable
class NikahGuideSection {
  const NikahGuideSection(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.items});

  final String title;
  final String subtitle;
  final IconData icon;
  final List<NikahGuideItem> items;
}

@immutable
class NikahQuickFact {
  const NikahQuickFact(this.label, this.note, this.icon);

  final String label;
  final String note;
  final IconData icon;
}

const nikahGuideSections = <NikahGuideSection>[
NikahGuideSection(
  title: 'Before Nikah',
  subtitle: 'Preparation & Selection',
  icon: Icons.favorite_rounded,
  items: [
    NikahGuideItem(
      'Istikhara Prayer',
      'Pray 2 rakaat and make dua Istikhara seeking Allah\'s guidance in choosing a spouse.',
      'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ',
      'Allahumma inni astakhiruka bi ilmika wa astaqdiruka bi qudratika...',
      Icons.mosque_rounded,
    ),
    NikahGuideItem(
      'Choosing a Spouse',
      'The Prophet ﷺ said: "A woman is married for four reasons: her wealth, lineage, beauty, and religion. Choose the one with religion, may your hands be rubbed with dust (i.e., prosper)." — Bukhari',
      '',
      '',
      Icons.favorite_rounded,
    ),
    NikahGuideItem(
      'Meeting the Prospect',
      'It is permissible to see the person you intend to marry. The meeting should be in the presence of a mahram. Keep it halal and respectful.',
      '',
      '',
      Icons.people_rounded,
    ),
    NikahGuideItem(
      'Family Involvement',
      'Involve families from both sides. Islam encourages family approval and blessings. The Wali (guardian) plays a key role.',
      '',
      '',
      Icons.family_restroom_rounded,
    ),
  ],
),
NikahGuideSection(
  title: 'Nikah Ceremony',
  subtitle: 'The Marriage Contract',
  icon: Icons.diamond_rounded,
  items: [
    NikahGuideItem(
      'Essential Conditions',
      '1. Mutual consent of bride & groom\n2. Wali (guardian) of the bride\n3. Two Muslim male witnesses\n4. Mahr (dowry) agreed upon\n5. Ijab & Qubool (offer & acceptance)',
      '',
      '',
      Icons.checklist_rounded,
    ),
    NikahGuideItem(
      'Khutbah al-Nikah',
      'The Imam delivers a sermon before the Nikah. It includes praise of Allah, Shahadah, and advice from Quran & Sunnah.',
      'الْحَمْدُ لِلَّهِ نَحْمَدُهُ وَنَسْتَعِينُهُ وَنَسْتَغْفِرُهُ',
      'Alhamdulillahi nahmaduhu wa nasta\'eenuhu wa nastaghfiruhu...',
      Icons.record_voice_over_rounded,
    ),
    NikahGuideItem(
      'Ijab & Qubool',
      'The Wali offers (Ijab) the bride in marriage. The groom accepts (Qubool). Both must say it clearly in the presence of witnesses.',
      '',
      '',
      Icons.handshake_rounded,
    ),
    NikahGuideItem(
      'Mahr (Dowry)',
      'Mahr is the bride\'s right — a gift from the groom. It can be anything of value agreed upon. The best mahr is one that is easy and not burdensome.',
      '',
      '',
      Icons.card_giftcard_rounded,
    ),
    NikahGuideItem(
      'Dua After Nikah',
      'The Prophet ﷺ taught this dua for the newlywed:',
      'بَارَكَ اللَّهُ لَكَ وَبَارَكَ عَلَيْكَ وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ',
      'Barakallahu laka wa baraka alayka wa jama\'a baynakuma fi khayr',
      Icons.celebration_rounded,
    ),
  ],
),
NikahGuideSection(
  title: 'After Nikah',
  subtitle: 'Rights & Responsibilities',
  icon: Icons.house_rounded,
  items: [
    NikahGuideItem(
      'Walimah (Wedding Feast)',
      'The Prophet ﷺ said: "Arrange a Walimah even if with one sheep." It is Sunnah to have a feast after the marriage to announce it.',
      '',
      '',
      Icons.restaurant_rounded,
    ),
    NikahGuideItem(
      'Husband\'s Rights',
      '• Kind and respectful treatment\n• Obedience in what is right\n• Guarding his honor and property\n• Being supportive and loving',
      '',
      '',
      Icons.man_rounded,
    ),
    NikahGuideItem(
      'Wife\'s Rights',
      '• Mahr (dowry) — her exclusive right\n• Financial maintenance (nafaqah)\n• Kind and gentle treatment\n• Fair treatment if multiple wives\n• Privacy and respect',
      '',
      '',
      Icons.woman_rounded,
    ),
    NikahGuideItem(
      'Building a Muslim Home',
      '• Pray together as a family\n• Read Quran regularly\n• Resolve conflicts with patience\n• Show love and mercy\n• Raise children with Islamic values',
      '',
      '',
      Icons.home_rounded,
    ),
  ],
),
NikahGuideSection(
  title: 'Islamic Etiquettes',
  subtitle: 'Sunnah Practices',
  icon: Icons.self_improvement_rounded,
  items: [
    NikahGuideItem(
      'Wedding Night Dua',
      'When entering upon your spouse for the first time:',
      'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَهَا وَخَيْرَ مَا جَبَلْتَهَا عَلَيْهِ وَأَعُوذُ بِكَ مِنْ شَرِّهَا وَشَرِّ مَا جَبَلْتَهَا عَلَيْهِ',
      'Allahumma inni as\'aluka khairaha wa khaira ma jabaltaha alayhi, wa a\'udhu bika min sharriha wa sharri ma jabaltaha alayhi',
      Icons.nights_stay_rounded,
    ),
    NikahGuideItem(
      'Keep it Simple',
      'The Prophet ﷺ said: "The best marriage is the one made easiest." Avoid extravagance, showing off, and unnecessary expenses.',
      '',
      '',
      Icons.volunteer_activism_rounded,
    ),
    NikahGuideItem(
      'Avoid Haram Practices',
      '• No free mixing of genders\n• No music/dancing (according to many scholars)\n• No extravagance or waste\n• No showing off (riya)\n• Keep gatherings modest',
      '',
      '',
      Icons.block_rounded,
    ),
    NikahGuideItem(
      'Announce the Marriage',
      'The Prophet ﷺ said: "Announce this marriage, hold it in the mosques, and beat the duff for it." — Tirmidhi. Making it public is important.',
      '',
      '',
      Icons.campaign_rounded,
    ),
  ],
),,
];

const nikahQuickFacts = <NikahQuickFact>[
NikahQuickFact('Wali', 'Guardian required', Icons.person_rounded),
NikahQuickFact('Mahr', 'Bride\'s right', Icons.diamond_rounded),
NikahQuickFact('Witnesses', '2 males needed', Icons.groups_rounded),
NikahQuickFact('Consent', 'Both must agree', Icons.check_circle_rounded),,
];
