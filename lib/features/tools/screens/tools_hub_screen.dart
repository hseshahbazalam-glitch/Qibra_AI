import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _ToolCard(tool: _tools[index]),
                childCount: _tools.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF0A0E1A),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B4332), Color(0xFF0A0E1A)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF00E676), width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.apps_rounded,
                                color: Color(0xFF00E676), size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Islamic Tools',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'اَلأَدَوَات',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 22,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  const Text(
                    'Your Islamic Toolkit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
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
}

// ─── Tool Model ───────────────────────────────────────────────
class IslamicTool {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final Color bgColor;
  final String route;
  final bool isReady;

  const IslamicTool({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.bgColor,
    required this.route,
    this.isReady = false,
  });
}

// ─── Tools List ───────────────────────────────────────────────
const List<IslamicTool> _tools = [
  IslamicTool(
    title: 'Zakat\nCalculator',
    subtitle: 'Calculate your Zakat',
    emoji: '💚',
    color: Color(0xFF00E676),
    bgColor: Color(0xFF1B4332),
    route: '/tools/zakat',
    isReady: true,
  ),
  IslamicTool(
    title: 'Hajj\nGuide',
    subtitle: 'Step by step rituals',
    emoji: '🕋',
    color: Color(0xFFFFD166),
    bgColor: Color(0xFF3D2B00),
    route: '/tools/hajj',
    isReady: true, // ✅
  ),
  IslamicTool(
    title: 'Umrah\nGuide',
    subtitle: 'Complete Umrah steps',
    emoji: '🕌',
    color: Color(0xFF74C0FC),
    bgColor: Color(0xFF0D2137),
    route: '/tools/umrah',
    isReady: true, // ✅
  ),
  IslamicTool(
    title: 'Nikah\nGuide',
    subtitle: 'Marriage in Islam',
    emoji: '📅',
    color: Color(0xFFFF9EBC),
    bgColor: Color(0xFF2D0A1A),
    route: '/tools/nikah',
    isReady: true, // ✅
  ),
  IslamicTool(
    title: 'Habit\nTracker',
    subtitle: 'Track Islamic habits',
    emoji: '📊',
    color: Color(0xFFA78BFA),
    bgColor: Color(0xFF1A0D35),
    route: '/tools/habits',
    isReady: true, // ✅ Changed
  ),
  IslamicTool(
    title: 'Ramadan\nTimer',
    subtitle: 'Suhoor & Iftar times',
    emoji: '🌙',
    color: Color(0xFFFFD166),
    bgColor: Color(0xFF2B2000),
    route: '/tools/ramadan',
    isReady: true, // ✅ Changed
  ),
  IslamicTool(
    title: 'Sadaqah\nTracker',
    subtitle: 'Log your charity',
    emoji: '💰',
    color: Color(0xFF4ECDC4),
    bgColor: Color(0xFF0A2422),
    route: '/tools/sadaqah',
    isReady: true, // ✅ Changed
  ),
  IslamicTool(
    title: 'Dhikr\nCounter',
    subtitle: 'Digital tasbeeh',
    emoji: '📿',
    color: Color(0xFFFF8C42),
    bgColor: Color(0xFF2D1200),
    route: '/tools/dhikr',
    isReady: true, // ✅ Changed
  ),
  IslamicTool(
    title: 'Halal\nScanner',
    subtitle: 'Scan products',
    emoji: '📷',
    color: Color(0xFF10B981),
    bgColor: Color(0xFF052E16),
    route: '/tools/halal',
    isReady: true,
  ),
  IslamicTool(
    title: 'Asma\nul Husna',
    subtitle: '99 Names of Allah',
    emoji: '📿',
    color: Color(0xFFA78BFA),
    bgColor: Color(0xFF1A0D35),
    route: '/tools/asma',
    isReady: true,
  ),
  IslamicTool(
    title: 'Islamic\nNames',
    subtitle: 'Find baby names',
    emoji: '🧒',
    color: Color(0xFF74C0FC),
    bgColor: Color(0xFF0D2137),
    route: '/tools/names',
    isReady: true,
  ),
  IslamicTool(
    title: 'Faraid\nCalculator',
    subtitle: 'Islamic inheritance',
    emoji: '⚖️',
    color: Color(0xFFA78BFA),
    bgColor: Color(0xFF1A0D35),
    route: '/tools/inheritance',
    isReady: true,
  ),
];

// ─── Tool Card Widget ─────────────────────────────────────────
class _ToolCard extends StatelessWidget {
  final IslamicTool tool;

  const _ToolCard({required this.tool});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (tool.isReady) {
          context.push(tool.route);
        } else {
          _showComingSoon(context, tool.title);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: tool.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tool.color.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: tool.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tool.color.withValues(alpha: 0.08),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji + Coming Soon Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(tool.emoji, style: const TextStyle(fontSize: 32)),
                      if (!tool.isReady)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tool.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Soon',
                            style: TextStyle(
                              color: tool.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (tool.isReady)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tool.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Ready',
                            style: TextStyle(
                              color: tool.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    tool.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Subtitle
                  Text(
                    tool.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Bottom bar accent
                  Container(
                    height: 3,
                    width: 40,
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${name.replaceAll('\n', ' ')} — Coming Soon! 🌙',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
