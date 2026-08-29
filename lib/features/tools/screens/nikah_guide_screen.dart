import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';

class NikahGuideScreen extends StatefulWidget {
  const NikahGuideScreen({super.key});

  @override
  State<NikahGuideScreen> createState() => _NikahGuideScreenState();
}

class _NikahGuideScreenState extends State<NikahGuideScreen> {
  int _expandedIndex = -1;

  final List<_NikahSection> _sections = [
    _NikahSection(
      title: 'Before Nikah',
      subtitle: 'Preparation & Selection',
      emoji: '💚',
      color: QibraColors.light.primary,
      items: [
        _NikahItem(
          'Istikhara Prayer',
          'Pray 2 rakaat and make dua Istikhara seeking Allah\'s guidance in choosing a spouse.',
          'اللَّهُمَّ إِنِّي أَسْتَخِيرُكَ بِعِلْمِكَ وَأَسْتَقْدِرُكَ بِقُدْرَتِكَ',
          'Allahumma inni astakhiruka bi ilmika wa astaqdiruka bi qudratika...',
          Icons.mosque_rounded,
        ),
        _NikahItem(
          'Choosing a Spouse',
          'The Prophet ﷺ said: "A woman is married for four reasons: her wealth, lineage, beauty, and religion. Choose the one with religion, may your hands be rubbed with dust (i.e., prosper)." — Bukhari',
          '',
          '',
          Icons.favorite_rounded,
        ),
        _NikahItem(
          'Meeting the Prospect',
          'It is permissible to see the person you intend to marry. The meeting should be in the presence of a mahram. Keep it halal and respectful.',
          '',
          '',
          Icons.people_rounded,
        ),
        _NikahItem(
          'Family Involvement',
          'Involve families from both sides. Islam encourages family approval and blessings. The Wali (guardian) plays a key role.',
          '',
          '',
          Icons.family_restroom_rounded,
        ),
      ],
    ),
    _NikahSection(
      title: 'Nikah Ceremony',
      subtitle: 'The Marriage Contract',
      emoji: '💍',
      color: QibraColors.light.accent,
      items: [
        _NikahItem(
          'Essential Conditions',
          '1. Mutual consent of bride & groom\n2. Wali (guardian) of the bride\n3. Two Muslim male witnesses\n4. Mahr (dowry) agreed upon\n5. Ijab & Qubool (offer & acceptance)',
          '',
          '',
          Icons.checklist_rounded,
        ),
        _NikahItem(
          'Khutbah al-Nikah',
          'The Imam delivers a sermon before the Nikah. It includes praise of Allah, Shahadah, and advice from Quran & Sunnah.',
          'الْحَمْدُ لِلَّهِ نَحْمَدُهُ وَنَسْتَعِينُهُ وَنَسْتَغْفِرُهُ',
          'Alhamdulillahi nahmaduhu wa nasta\'eenuhu wa nastaghfiruhu...',
          Icons.record_voice_over_rounded,
        ),
        _NikahItem(
          'Ijab & Qubool',
          'The Wali offers (Ijab) the bride in marriage. The groom accepts (Qubool). Both must say it clearly in the presence of witnesses.',
          '',
          '',
          Icons.handshake_rounded,
        ),
        _NikahItem(
          'Mahr (Dowry)',
          'Mahr is the bride\'s right — a gift from the groom. It can be anything of value agreed upon. The best mahr is one that is easy and not burdensome.',
          '',
          '',
          Icons.card_giftcard_rounded,
        ),
        _NikahItem(
          'Dua After Nikah',
          'The Prophet ﷺ taught this dua for the newlywed:',
          'بَارَكَ اللَّهُ لَكَ وَبَارَكَ عَلَيْكَ وَجَمَعَ بَيْنَكُمَا فِي خَيْرٍ',
          'Barakallahu laka wa baraka alayka wa jama\'a baynakuma fi khayr',
          Icons.celebration_rounded,
        ),
      ],
    ),
    _NikahSection(
      title: 'After Nikah',
      subtitle: 'Rights & Responsibilities',
      emoji: '🏡',
      color: QibraColors.light.primarySoft,
      items: [
        _NikahItem(
          'Walimah (Wedding Feast)',
          'The Prophet ﷺ said: "Arrange a Walimah even if with one sheep." It is Sunnah to have a feast after the marriage to announce it.',
          '',
          '',
          Icons.restaurant_rounded,
        ),
        _NikahItem(
          'Husband\'s Rights',
          '• Kind and respectful treatment\n• Obedience in what is right\n• Guarding his honor and property\n• Being supportive and loving',
          '',
          '',
          Icons.man_rounded,
        ),
        _NikahItem(
          'Wife\'s Rights',
          '• Mahr (dowry) — her exclusive right\n• Financial maintenance (nafaqah)\n• Kind and gentle treatment\n• Fair treatment if multiple wives\n• Privacy and respect',
          '',
          '',
          Icons.woman_rounded,
        ),
        _NikahItem(
          'Building a Muslim Home',
          '• Pray together as a family\n• Read Quran regularly\n• Resolve conflicts with patience\n• Show love and mercy\n• Raise children with Islamic values',
          '',
          '',
          Icons.home_rounded,
        ),
      ],
    ),
    _NikahSection(
      title: 'Islamic Etiquettes',
      subtitle: 'Sunnah Practices',
      emoji: '📿',
      color: QibraColors.light.primarySoft,
      items: [
        _NikahItem(
          'Wedding Night Dua',
          'When entering upon your spouse for the first time:',
          'اللَّهُمَّ إِنِّي أَسْأَلُكَ خَيْرَهَا وَخَيْرَ مَا جَبَلْتَهَا عَلَيْهِ وَأَعُوذُ بِكَ مِنْ شَرِّهَا وَشَرِّ مَا جَبَلْتَهَا عَلَيْهِ',
          'Allahumma inni as\'aluka khairaha wa khaira ma jabaltaha alayhi, wa a\'udhu bika min sharriha wa sharri ma jabaltaha alayhi',
          Icons.nights_stay_rounded,
        ),
        _NikahItem(
          'Keep it Simple',
          'The Prophet ﷺ said: "The best marriage is the one made easiest." Avoid extravagance, showing off, and unnecessary expenses.',
          '',
          '',
          Icons.volunteer_activism_rounded,
        ),
        _NikahItem(
          'Avoid Haram Practices',
          '• No free mixing of genders\n• No music/dancing (according to many scholars)\n• No extravagance or waste\n• No showing off (riya)\n• Keep gatherings modest',
          '',
          '',
          Icons.block_rounded,
        ),
        _NikahItem(
          'Announce the Marriage',
          'The Prophet ﷺ said: "Announce this marriage, hold it in the mosques, and beat the duff for it." — Tirmidhi. Making it public is important.',
          '',
          '',
          Icons.campaign_rounded,
        ),
      ],
    ),
  ];

  final List<_QuickFact> _quickFacts = [
    _QuickFact('Wali', 'Guardian required', '👨', QibraColors.light.primary),
    _QuickFact('Mahr', 'Bride\'s right', '💎', QibraColors.light.accent),
    _QuickFact('Witnesses', '2 males needed', '👥', QibraColors.light.primarySoft),
    _QuickFact('Consent', 'Both must agree', '✅', QibraColors.light.primarySoft),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewCard(),
                const SizedBox(height: 16),
                _buildQuickFactsRow(),
                const SizedBox(height: 24),
                ..._sections.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSectionCard(e.value, e.key),
                      ),
                    ),
                const SizedBox(height: 16),
                _buildIslamicNote(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final colors = QibraColors.of(context);
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded,
              color: colors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.card, colors.background],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نِكَاح',
                    style: TextStyle(
                      color: colors.accent,
                      fontSize: 26,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    'Nikah Guide',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Marriage in Islam',
                    style: TextStyle(
                      color: colors.textPrimary.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.card, Color(0xFF3D1528)],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: colors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💍', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A Sacred Bond',
                      style: TextStyle(
                        color: colors.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Half of Your Deen',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The Prophet ﷺ said: "When a man marries, he has completed half of his religion, so let him fear Allah regarding the remaining half." — Bayhaqi',
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFactsRow() {
    final colors = QibraColors.of(context);
    return Row(
      children: _quickFacts.map((f) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: f == _quickFacts.last ? 0 : 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: f.color.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: f.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                Text(f.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 6),
                Text(
                  f.title,
                  style: TextStyle(
                    color: f.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  f.subtitle,
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.35),
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionCard(_NikahSection section, int index) {
    final colors = QibraColors.of(context);
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _expandedIndex = isExpanded ? -1 : index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isExpanded
              ? section.color.withValues(alpha: 0.06)
              : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isExpanded
                ? section.color.withValues(alpha: 0.3)
                : colors.textPrimary.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(section.emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.subtitle,
                        style: TextStyle(
                          color: section.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        section.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${section.items.length} items',
                    style: TextStyle(
                      color: section.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: section.color,
                  size: 24,
                ),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              ...section.items
                  .map((item) => _buildNikahItem(item, section.color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNikahItem(_NikahItem item, Color color) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                if (item.arabic.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.arabic,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: color,
                            height: 1.6,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        ),
                        if (item.transliteration.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.transliteration,
                            style: TextStyle(
                              color: colors.textPrimary.withValues(alpha: 0.4),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIslamicNote() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardMuted.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: colors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📖', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text(
                'Quran',
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"And among His Signs is that He created for you mates from among yourselves, that you may dwell in tranquility with them, and He has put love and mercy between your hearts." — Quran 30:21',
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.6),
              fontSize: 12,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'وَمِنْ آيَاتِهِ أَنْ خَلَقَ لَكُم مِّنْ أَنفُسِكُمْ أَزْوَاجًا',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: colors.accent,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────
class _NikahSection {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final List<_NikahItem> items;
  const _NikahSection({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.items,
  });
}

class _NikahItem {
  final String title;
  final String description;
  final String arabic;
  final String transliteration;
  final IconData icon;
  const _NikahItem(this.title, this.description, this.arabic,
      this.transliteration, this.icon);
}

class _QuickFact {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  const _QuickFact(this.title, this.subtitle, this.emoji, this.color);
}
