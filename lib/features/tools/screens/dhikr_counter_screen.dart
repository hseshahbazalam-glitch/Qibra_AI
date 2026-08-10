import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DhikrCounterScreen extends StatefulWidget {
  const DhikrCounterScreen({super.key});

  @override
  State<DhikrCounterScreen> createState() => _DhikrCounterScreenState();
}

class _DhikrCounterScreenState extends State<DhikrCounterScreen>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  int _totalCount = 0;
  int _targetCount = 33;
  int _selectedDhikrIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const String _totalKey = 'dhikr_total_count';

  final List<_DhikrItem> _dhikrList = const [
    _DhikrItem(
      name: 'SubhanAllah',
      arabic: 'سُبْحَانَ اللَّهِ',
      meaning: 'Glory be to Allah',
      target: 33,
      color: Color(0xFF52B788),
    ),
    _DhikrItem(
      name: 'Alhamdulillah',
      arabic: 'الْحَمْدُ لِلَّهِ',
      meaning: 'All praise is due to Allah',
      target: 33,
      color: Color(0xFFFFD700),
    ),
    _DhikrItem(
      name: 'Allahu Akbar',
      arabic: 'اللَّهُ أَكْبَرُ',
      meaning: 'Allah is the Greatest',
      target: 33,
      color: Color(0xFF74C0FC),
    ),
    _DhikrItem(
      name: 'La ilaha illAllah',
      arabic: 'لَا إِلٰهَ إِلَّا اللَّهُ',
      meaning: 'There is no god but Allah',
      target: 100,
      color: Color(0xFFA78BFA),
    ),
    _DhikrItem(
      name: 'Astaghfirullah',
      arabic: 'أَسْتَغْفِرُ اللَّهَ',
      meaning: 'I seek forgiveness from Allah',
      target: 100,
      color: Color(0xFFFF9EBC),
    ),
    _DhikrItem(
      name: 'La Hawla wa La Quwwata',
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      meaning: 'There is no power except with Allah',
      target: 100,
      color: Color(0xFF4ECDC4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadTotal();
    _targetCount = _dhikrList[_selectedDhikrIndex].target;
  }

  Future<void> _loadTotal() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _totalCount = prefs.getInt(_totalKey) ?? 0);
  }

  Future<void> _saveTotal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalKey, _totalCount);
  }

  void _increment() {
    HapticFeedback.lightImpact();
    _pulseController.forward().then((_) => _pulseController.reverse());

    setState(() {
      _count++;
      _totalCount++;
    });
    _saveTotal();

    if (_count == _targetCount) {
      HapticFeedback.heavyImpact();
      _showCompletionDialog();
    }
  }

  void _resetCount() {
    HapticFeedback.mediumImpact();
    setState(() => _count = 0);
  }

  void _selectDhikr(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDhikrIndex = index;
      _targetCount = _dhikrList[index].target;
      _count = 0;
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141926),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Text('🎉', style: TextStyle(fontSize: 40)),
            SizedBox(height: 8),
            Text(
              'MashaAllah!',
              style: TextStyle(
                color: Color(0xFF52B788),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'You completed $_targetCount counts of\n${_dhikrList[_selectedDhikrIndex].name}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetCount();
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Color(0xFF52B788),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dhikr = _dhikrList[_selectedDhikrIndex];
    final progress = _targetCount > 0 ? _count / _targetCount : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // ── Dhikr Selector ──
                  _buildDhikrSelector(),
                  const SizedBox(height: 24),

                  // ── Arabic Text ──
                  Text(
                    dhikr.arabic,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 32,
                      color: dhikr.color,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dhikr.meaning,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // ── Counter Circle ──
                  _buildCounterCircle(dhikr, progress),
                  const SizedBox(height: 24),

                  // ── Progress Bar ──
                  _buildProgressBar(dhikr, progress),
                  const SizedBox(height: 20),

                  // ── Action Buttons ──
                  _buildActionButtons(dhikr),

                  const Spacer(),

                  // ── Total Stats ──
                  _buildTotalStats(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
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
              colors: [Color(0xFF2D1200), Color(0xFF0A0E1A)],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أَذْكَار',
                    style: TextStyle(
                      color: Color(0xFFFF8C42),
                      fontSize: 20,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    'Dhikr Counter',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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

  // ─── Dhikr Selector ────────────────────────────────────────
  Widget _buildDhikrSelector() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dhikrList.length,
        itemBuilder: (context, index) {
          final d = _dhikrList[index];
          final selected = index == _selectedDhikrIndex;
          return GestureDetector(
            onTap: () => _selectDhikr(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? d.color.withValues(alpha: 0.2)
                    : const Color(0xFF141926),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      selected ? d.color : Colors.white.withValues(alpha: 0.08),
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(
                d.name,
                style: TextStyle(
                  color:
                      selected ? d.color : Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Counter Circle ─────────────────────────────────────────
  Widget _buildCounterCircle(_DhikrItem dhikr, double progress) {
    return GestureDetector(
      onTap: _increment,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF141926),
            border: Border.all(
              color: dhikr.color.withValues(alpha: 0.3),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: dhikr.color.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Progress ring
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: dhikr.color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation(dhikr.color),
                ),
              ),
              // Count
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_count',
                    style: TextStyle(
                      color: dhikr.color,
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of $_targetCount',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TAP',
                    style: TextStyle(
                      color: dhikr.color.withValues(alpha: 0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Progress Bar ───────────────────────────────────────────
  Widget _buildProgressBar(_DhikrItem dhikr, double progress) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_count / $_targetCount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: dhikr.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: dhikr.color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(dhikr.color),
          ),
        ),
      ],
    );
  }

  // ─── Action Buttons ─────────────────────────────────────────
  Widget _buildActionButtons(_DhikrItem dhikr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset
        GestureDetector(
          onTap: _resetCount,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.refresh_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Minus
        GestureDetector(
          onTap: () {
            if (_count > 0) {
              HapticFeedback.lightImpact();
              setState(() {
                _count--;
                _totalCount--;
              });
              _saveTotal();
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: dhikr.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: dhikr.color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.remove_rounded, color: dhikr.color, size: 22),
          ),
        ),
      ],
    );
  }

  // ─── Total Stats ────────────────────────────────────────────
  Widget _buildTotalStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141926),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem('📿', 'Session', '$_count'),
          Container(
              width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
          _statItem('🌟', 'Total', '$_totalCount'),
          Container(
              width: 1, height: 30, color: Colors.white.withValues(alpha: 0.1)),
          _statItem('🎯', 'Target', '$_targetCount'),
        ],
      ),
    );
  }

  Widget _statItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Dhikr Item Model ─────────────────────────────────────────
class _DhikrItem {
  final String name;
  final String arabic;
  final String meaning;
  final int target;
  final Color color;

  const _DhikrItem({
    required this.name,
    required this.arabic,
    required this.meaning,
    required this.target,
    required this.color,
  });
}
