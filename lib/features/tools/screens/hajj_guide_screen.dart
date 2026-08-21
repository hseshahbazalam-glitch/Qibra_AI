import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HajjGuideScreen extends StatefulWidget {
  const HajjGuideScreen({super.key});

  @override
  State<HajjGuideScreen> createState() => _HajjGuideScreenState();
}

class _HajjGuideScreenState extends State<HajjGuideScreen> {
  int _expandedIndex = -1;

  final List<_HajjDay> _hajjDays = const [
    _HajjDay(
      day: '8th Dhul Hijjah',
      title: 'Yawm al-Tarwiyah',
      emoji: '🕋',
      color: Color(0xFFFFD166),
      steps: [
        _HajjStep(
          'Enter Ihram',
          'Put on Ihram from your place of stay in Makkah. Make niyyah for Hajj.',
          'لَبَّيْكَ اللَّهُمَّ حَجًّا',
          'Labbayk Allahumma Hajjan',
          Icons.checkroom_rounded,
        ),
        _HajjStep(
          'Recite Talbiyah',
          'Keep reciting Talbiyah throughout the journey.',
          'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ',
          'Labbayk Allahumma Labbayk...',
          Icons.record_voice_over_rounded,
        ),
        _HajjStep(
          'Go to Mina',
          'Travel to Mina before Dhuhr. Pray Dhuhr, Asr, Maghrib, Isha (shortened) and stay overnight.',
          '',
          '',
          Icons.location_on_rounded,
        ),
      ],
    ),
    _HajjDay(
      day: '9th Dhul Hijjah',
      title: 'Yawm al-Arafah',
      emoji: '⛰️',
      color: Color(0xFF00E676),
      steps: [
        _HajjStep(
          'Go to Arafah',
          'After Fajr in Mina, proceed to Arafah. This is the MOST important day of Hajj.',
          '',
          '',
          Icons.directions_walk_rounded,
        ),
        _HajjStep(
          'Wuquf (Standing) at Arafah',
          'Stand in supplication from Dhuhr until Maghrib. Make abundant dua. The Prophet ﷺ said: "Hajj is Arafah."',
          'لَا إِلٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
          'La ilaha illAllahu wahdahu la shareeka lahu...',
          Icons.back_hand_rounded,
        ),
        _HajjStep(
          'Go to Muzdalifah',
          'After sunset, proceed to Muzdalifah. Pray Maghrib & Isha combined. Collect pebbles (49-70). Sleep under open sky.',
          '',
          '',
          Icons.nights_stay_rounded,
        ),
      ],
    ),
    _HajjDay(
      day: '10th Dhul Hijjah',
      title: 'Yawm al-Nahr (Eid)',
      emoji: '🐑',
      color: Color(0xFFEF4444),
      steps: [
        _HajjStep(
          'Rami al-Jamarat',
          'Stone the large pillar (Jamrat al-Aqabah) with 7 pebbles, saying Takbir with each throw.',
          'بِسْمِ اللَّهِ، اللَّهُ أَكْبَرُ',
          'Bismillah, Allahu Akbar',
          Icons.gps_fixed_rounded,
        ),
        _HajjStep(
          'Animal Sacrifice',
          'Offer Qurbani/Hady (sacrifice). This can also be arranged through authorized services.',
          '',
          '',
          Icons.volunteer_activism_rounded,
        ),
        _HajjStep(
          'Halq or Taqsir',
          'Men: Shave head (Halq) or trim hair (Taqsir). Women: Cut a fingertip length of hair.',
          '',
          '',
          Icons.content_cut_rounded,
        ),
        _HajjStep(
          'Tawaf al-Ifadah',
          'Perform Tawaf (7 rounds) around the Ka\'bah. This is a pillar (rukn) of Hajj.',
          '',
          '',
          Icons.refresh_rounded,
        ),
        _HajjStep(
          'Sa\'i',
          'Walk between Safa and Marwah (7 times). Then return to Mina.',
          '',
          '',
          Icons.swap_horiz_rounded,
        ),
      ],
    ),
    _HajjDay(
      day: '11th-13th Dhul Hijjah',
      title: 'Ayyam al-Tashreeq',
      emoji: '🏕️',
      color: Color(0xFFD4AF37),
      steps: [
        _HajjStep(
          'Stay in Mina',
          'Spend the nights in Mina. Engage in dhikr, dua, and worship.',
          '',
          '',
          Icons.bed_rounded,
        ),
        _HajjStep(
          'Rami (Stoning) Daily',
          'Stone all three Jamarat each day (7 pebbles each = 21 per day). Start with small, then medium, then large.',
          'اللَّهُ أَكْبَرُ',
          'Allahu Akbar',
          Icons.gps_fixed_rounded,
        ),
        _HajjStep(
          'Tawaf al-Wida (Farewell)',
          'Before leaving Makkah, perform farewell Tawaf. This is the final act of Hajj.',
          '',
          '',
          Icons.mosque_rounded,
        ),
      ],
    ),
  ];

  final List<_HajjChecklist> _checklist = [
    _HajjChecklist('Ihram (2 white cloths)', false),
    _HajjChecklist('Passport & Visa copies', false),
    _HajjChecklist('Medicines & First aid', false),
    _HajjChecklist('Comfortable sandals', false),
    _HajjChecklist('Small Quran / Phone app', false),
    _HajjChecklist('Dua book', false),
    _HajjChecklist('Umbrella / Sunblock', false),
    _HajjChecklist('Water bottle', false),
    _HajjChecklist('Toiletries (unscented)', false),
    _HajjChecklist('Money belt / Pouch', false),
    _HajjChecklist('ID card / Wristband', false),
    _HajjChecklist('Snacks for energy', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildOverviewCard(),
                const SizedBox(height: 20),
                _buildPillarsCard(),
                const SizedBox(height: 24),
                _buildSectionLabel('📋', 'DAY BY DAY GUIDE'),
                const SizedBox(height: 12),
                ..._hajjDays.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDayCard(e.value, e.key),
                      ),
                    ),
                const SizedBox(height: 20),
                _buildSectionLabel('✅', 'PACKING CHECKLIST'),
                const SizedBox(height: 12),
                _buildChecklistCard(),
                const SizedBox(height: 20),
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
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E1A),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D2B00), Color(0xFF0A0E1A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('حَجّ',
                      style: TextStyle(
                          color: Color(0xFFFFD166),
                          fontSize: 26,
                          fontFamily: 'Amiri')),
                  const Text('Hajj Guide',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('Complete Step-by-Step',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF3D2B00), Color(0xFF2B1F00)]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🕋', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The Fifth Pillar',
                      style: TextStyle(
                          color: Color(0xFFFFD166),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text('of Islam',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Hajj is obligatory once in a lifetime for every Muslim who is physically and financially able. It takes place during 8th-13th Dhul Hijjah.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsCard() {
    final pillars = [
      const _PillarItem('Ihram', '🧕', 'Enter sacred state'),
      const _PillarItem('Arafah', '⛰️', 'Standing at Arafah'),
      const _PillarItem('Tawaf', '🕋', '7 rounds of Ka\'bah'),
      const _PillarItem('Sa\'i', '🚶', 'Safa & Marwah'),
    ];

    return Row(
      children: pillars.map((p) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: p == pillars.last ? 0 : 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141926),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFFFFD166).withValues(alpha: 0.12)),
            ),
            child: Column(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(p.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                Text(p.desc,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 8),
                    textAlign: TextAlign.center,
                    maxLines: 1),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0)),
      ],
    );
  }

  Widget _buildDayCard(_HajjDay day, int index) {
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
              ? day.color.withValues(alpha: 0.06)
              : const Color(0xFF141926),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isExpanded
                  ? day.color.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.05)),
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
                      color: day.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Text(day.emoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(day.day,
                          style: TextStyle(
                              color: day.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      Text(day.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: day.color,
                    size: 24),
              ],
            ),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              ...day.steps.map((step) => _buildStepItem(step, day.color)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(_HajjStep step, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(step.icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(step.description,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        height: 1.4)),
                if (step.arabic.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Text(step.arabic,
                            style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                color: color,
                                height: 1.5),
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center),
                        if (step.transliteration.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(step.transliteration,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center),
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

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: _checklist.asMap().entries.map((e) {
          final item = e.value;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => item.isDone = !item.isDone);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: item.isDone
                          ? const Color(0xFF00E676)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: item.isDone
                              ? const Color(0xFF00E676)
                              : Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: item.isDone
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      color: item.isDone
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration:
                          item.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIslamicNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFFFD166).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📖', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text('Quran',
                  style: TextStyle(
                      color: Color(0xFFFFD166),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"And proclaim to the people the Hajj; they will come to you on foot and on every lean camel; they will come from every distant pass." — Quran 22:27',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────
class _HajjDay {
  final String day;
  final String title;
  final String emoji;
  final Color color;
  final List<_HajjStep> steps;
  const _HajjDay(
      {required this.day,
      required this.title,
      required this.emoji,
      required this.color,
      required this.steps});
}

class _HajjStep {
  final String title;
  final String description;
  final String arabic;
  final String transliteration;
  final IconData icon;
  const _HajjStep(this.title, this.description, this.arabic,
      this.transliteration, this.icon);
}

class _HajjChecklist {
  final String label;
  bool isDone;
  _HajjChecklist(this.label, this.isDone);
}

class _PillarItem {
  final String name;
  final String emoji;
  final String desc;
  const _PillarItem(this.name, this.emoji, this.desc);
}
