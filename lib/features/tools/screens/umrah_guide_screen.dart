import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UmrahGuideScreen extends StatefulWidget {
  const UmrahGuideScreen({super.key});

  @override
  State<UmrahGuideScreen> createState() => _UmrahGuideScreenState();
}

class _UmrahGuideScreenState extends State<UmrahGuideScreen> {
  int _expandedIndex = -1;

  final List<_UmrahStep> _steps = const [
    _UmrahStep(
      number: 1,
      title: 'Enter Ihram',
      emoji: '🧕',
      color: Color(0xFF2F6B5D),
      description:
          'Before reaching Meeqat, take a bath (ghusl), put on Ihram garments. Men wear two white unstitched cloths. Women wear regular modest clothing.',
      details: [
        'Make ghusl (bath) before Meeqat',
        'Men: Two white unstitched cloths',
        'Women: Any modest clothing, no niqab/gloves in Ihram',
        'Apply unscented products only',
        'Pray 2 rakaat Sunnah (optional)',
        'Make Niyyah (intention) for Umrah',
      ],
      dua: 'لَبَّيْكَ اللَّهُمَّ عُمْرَةً',
      duaTransliteration: 'Labbayk Allahumma Umratan',
      duaTranslation: 'Here I am O Allah, for Umrah',
    ),
    _UmrahStep(
      number: 2,
      title: 'Recite Talbiyah',
      emoji: '🗣️',
      color: Color(0xFFC6A15B),
      description:
          'Continuously recite the Talbiyah from the moment you enter Ihram until you begin Tawaf.',
      details: [
        'Recite loudly (men) / softly (women)',
        'Keep reciting until you reach Ka\'bah',
        'Stop Talbiyah when you start Tawaf',
        'Focus on meaning while reciting',
      ],
      dua:
          'لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ، لَبَّيْكَ لَا شَرِيكَ لَكَ لَبَّيْكَ، إِنَّ الْحَمْدَ وَالنِّعْمَةَ لَكَ وَالْمُلْكَ، لَا شَرِيكَ لَكَ',
      duaTransliteration:
          'Labbayk Allahumma Labbayk, Labbayk la shareeka laka Labbayk, Innal hamda wan-ni\'mata laka wal-mulk, la shareeka lak',
      duaTranslation:
          'Here I am, O Allah, here I am. Here I am, You have no partner. Indeed all praise, grace and sovereignty belong to You. You have no partner.',
    ),
    _UmrahStep(
      number: 3,
      title: 'Tawaf (7 Rounds)',
      emoji: '🕋',
      color: Color(0xFF123F36),
      description:
          'Perform 7 rounds (circuits) around the Ka\'bah in anti-clockwise direction, starting from Hajar al-Aswad (Black Stone).',
      details: [
        'Start at Hajar al-Aswad (Black Stone corner)',
        'Go anti-clockwise around Ka\'bah',
        'Complete 7 full rounds',
        'Men: Idtiba (right shoulder bare) during Tawaf',
        'Men: Raml (brisk walk) in first 3 rounds',
        'Make dua freely — no fixed dua required',
        'Between Yamani corner & Black Stone recite specific dua',
        'After Tawaf: Pray 2 rakaat behind Maqam Ibrahim',
        'Drink Zamzam water',
      ],
      dua:
          'رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ',
      duaTransliteration:
          'Rabbana aatina fid-dunya hasanatan wa fil-akhirati hasanatan wa qina adhaban-nar',
      duaTranslation:
          'Our Lord, give us good in this world and good in the Hereafter, and save us from the punishment of the Fire.',
    ),
    _UmrahStep(
      number: 4,
      title: 'Sa\'i (Safa & Marwah)',
      emoji: '🚶',
      color: Color(0xFF2F6B5D),
      description:
          'Walk between the hills of Safa and Marwah 7 times. Start at Safa and end at Marwah.',
      details: [
        'Start at Safa hill — face Ka\'bah, make dua',
        'Walk to Marwah (1st lap)',
        'Men: Jog between green lights',
        'At Marwah: Face Ka\'bah, make dua',
        'Walk back to Safa (2nd lap)',
        'Continue until 7 laps (end at Marwah)',
        'Make dua throughout',
        'Safa → Marwah = 1 lap',
      ],
      dua: 'إِنَّ الصَّفَا وَالْمَرْوَةَ مِنْ شَعَائِرِ اللَّهِ',
      duaTransliteration: 'Innas-Safa wal-Marwata min sha\'a\'irillah',
      duaTranslation: 'Indeed, Safa and Marwah are among the symbols of Allah.',
    ),
    _UmrahStep(
      number: 5,
      title: 'Halq or Taqsir',
      emoji: '✂️',
      color: Color(0xFFC6A15B),
      description:
          'After completing Sa\'i, shave the head (Halq) or trim the hair (Taqsir) to exit the state of Ihram.',
      details: [
        'Men: Shaving head (Halq) is preferred',
        'Men: Trimming hair (Taqsir) is also valid',
        'Women: Cut a fingertip length from hair ends',
        'After this, all Ihram restrictions are lifted',
        'You have completed your Umrah!',
        'Make dua of gratitude',
      ],
      dua: 'الْحَمْدُ لِلَّهِ الَّذِي هَدَانَا لِهٰذَا',
      duaTransliteration: 'Alhamdulillahil-ladhi hadana li-hadha',
      duaTranslation: 'All praise is due to Allah who guided us to this.',
    ),
  ];

  final List<_UmrahTip> _tips = const [
    _UmrahTip('🕐', 'Best Time', 'Ramadan Umrah = reward of Hajj'),
    _UmrahTip('👟', 'Comfortable Shoes', 'You will walk a lot'),
    _UmrahTip('💧', 'Stay Hydrated', 'Carry water bottle always'),
    _UmrahTip('📱', 'Download Maps', 'Masjid al-Haram layout'),
    _UmrahTip('🤲', 'Make Lots of Dua', 'Especially during Tawaf'),
    _UmrahTip('📖', 'Learn Duas Before', 'Practice pronunciations'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3EC),
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
                _buildQuickSteps(),
                const SizedBox(height: 24),
                _buildSectionLabel('📋', 'DETAILED GUIDE'),
                const SizedBox(height: 12),
                ..._steps.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildStepCard(e.value, e.key),
                      ),
                    ),
                const SizedBox(height: 20),
                _buildSectionLabel('💡', 'TIPS'),
                const SizedBox(height: 12),
                _buildTipsGrid(),
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
      backgroundColor: const Color(0xFFF5F3EC),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFF19312C).withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_rounded,
              color: const Color(0xFF19312C), size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEEF1EA), Color(0xFFF5F3EC)]),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('عُمْرَة',
                      style: TextStyle(
                          color: Color(0xFF2F6B5D),
                          fontSize: 26,
                          fontFamily: 'Amiri')),
                  const Text('Umrah Guide',
                      style: TextStyle(
                          color: const Color(0xFF19312C),
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Text('Step-by-Step',
                      style: TextStyle(
                          color: const Color(0xFF19312C).withValues(alpha: 0.4),
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
            colors: [Color(0xFFEEF1EA), Color(0xFF152E4A)]),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF2F6B5D).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🕌', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('The Minor Pilgrimage',
                      style: TextStyle(
                          color: Color(0xFF2F6B5D),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  Text('Sunnah Mu\'akkadah',
                      style: TextStyle(
                          color: const Color(0xFF19312C),
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Umrah can be performed any time of the year. It consists of 4 main rituals: Ihram, Tawaf, Sa\'i, and Halq/Taqsir.',
            style: TextStyle(
                color: const Color(0xFF19312C).withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSteps() {
    final quickSteps = ['Ihram', 'Talbiyah', 'Tawaf', 'Sa\'i', 'Halq'];
    final emojis = ['🧕', '🗣️', '🕋', '🚶', '✂️'];

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickSteps.length,
        itemBuilder: (ctx, i) {
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFDF9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF2F6B5D).withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emojis[i], style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 4),
                Text(quickSteps[i],
                    style: const TextStyle(
                        color: const Color(0xFF19312C),
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: const Color(0xFF19312C).withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0)),
      ],
    );
  }

  Widget _buildStepCard(_UmrahStep step, int index) {
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
              ? step.color.withValues(alpha: 0.06)
              : const Color(0xFFFEFDF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isExpanded
                  ? step.color.withValues(alpha: 0.3)
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
                      color: step.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Text(step.emoji,
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Step ${step.number}',
                          style: TextStyle(
                              color: step.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                      Text(step.title,
                          style: const TextStyle(
                              color: const Color(0xFF19312C),
                              fontSize: 16,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: step.color,
                    size: 24),
              ],
            ),
            if (!isExpanded) ...[
              const SizedBox(height: 8),
              Text(step.description,
                  style: TextStyle(
                      color: const Color(0xFF19312C).withValues(alpha: 0.4), fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Text(step.description,
                  style: TextStyle(
                      color: const Color(0xFF19312C).withValues(alpha: 0.6),
                      fontSize: 12,
                      height: 1.5)),
              const SizedBox(height: 14),
              ...step.details.map((d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                              color: step.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(d,
                                style: TextStyle(
                                    color: const Color(0xFF19312C).withValues(alpha: 0.5),
                                    fontSize: 12,
                                    height: 1.4))),
                      ],
                    ),
                  )),
              if (step.dua.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: step.color.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Text(step.dua,
                          style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              color: step.color,
                              height: 1.6),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(step.duaTransliteration,
                          style: TextStyle(
                              color: const Color(0xFF19312C).withValues(alpha: 0.4),
                              fontSize: 10,
                              fontStyle: FontStyle.italic),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 4),
                      Text(step.duaTranslation,
                          style: TextStyle(
                              color: const Color(0xFF19312C).withValues(alpha: 0.5),
                              fontSize: 11),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTipsGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _tips.map((tip) {
        return Container(
          width: (MediaQuery.of(context).size.width - 50) / 2,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFDF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF19312C).withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tip.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 8),
              Text(tip.title,
                  style: const TextStyle(
                      color: const Color(0xFF19312C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              Text(tip.subtitle,
                  style: TextStyle(
                      color: const Color(0xFF19312C).withValues(alpha: 0.35),
                      fontSize: 10),
                  maxLines: 2),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildIslamicNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFF2F6B5D).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📖', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text('Hadith',
                  style: TextStyle(
                      color: Color(0xFF2F6B5D),
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"Umrah to Umrah is an expiation for the sins committed between them." — Bukhari & Muslim',
            style: TextStyle(
                color: const Color(0xFF19312C).withValues(alpha: 0.6),
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
class _UmrahStep {
  final int number;
  final String title;
  final String emoji;
  final Color color;
  final String description;
  final List<String> details;
  final String dua;
  final String duaTransliteration;
  final String duaTranslation;
  const _UmrahStep({
    required this.number,
    required this.title,
    required this.emoji,
    required this.color,
    required this.description,
    required this.details,
    required this.dua,
    required this.duaTransliteration,
    required this.duaTranslation,
  });
}

class _UmrahTip {
  final String emoji;
  final String title;
  final String subtitle;
  const _UmrahTip(this.emoji, this.title, this.subtitle);
}
