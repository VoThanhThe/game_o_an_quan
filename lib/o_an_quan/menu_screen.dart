import 'package:flutter/material.dart';

import 'difficulty_screen.dart';
import 'how_to_play_screen.dart';
import 'leader_board.dart';
import 'play_game_1vs1.dart';
import 'service/audio_service.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _buttonController;
  late Animation<double> _logoAnimation;
  late Animation<Offset> _slideAnimation;

  // 👇 thêm cho scroll hint
  bool _showScrollHint = true;
  late AnimationController _arrowController;
  late Animation<Offset> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    AudioService().playMenu();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _buttonController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _buttonController.forward();
    });

    // 👇 init arrow bounce
    _arrowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _arrowAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0),
          end: const Offset(0, 0.2),
        ).animate(
          CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    AudioService().stopMenu();
    _logoController.dispose();
    _buttonController.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;

              return Stack(
                children: [
                  // Main responsive content
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: isLandscape
                        ? Row(
                            children: [
                              // Left: large header
                              Expanded(
                                flex: 5,
                                child: _buildHeader(
                                  large: true,
                                  accent: Color(0xFF8B5A26),
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Right: buttons stacked
                              Expanded(
                                flex: 4,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildButtonSection(
                                    accent: Color(0xFF8B5A26),
                                    isLandscape: true,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildHeader(
                                  large: false,
                                  accent: Color(0xFF8B5A26),
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: SlideTransition(
                                  position: _slideAnimation,
                                  child: _buildButtonSection(
                                    accent: Color(0xFF8B5A26),
                                  ),
                                ),
                              ),
                              _buildFooter(),
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required bool large, required Color accent}) {
    return AnimatedBuilder(
      animation: _logoAnimation,
      builder: (context, child) => Transform.scale(
        scale: _logoAnimation.value,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Game icon with countryside touches
            Container(
              width: large ? 180 : 120,
              height: large ? 180 : 120,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    accent.withAlpha((0.98 * 255).toInt()),
                    accent.withAlpha((0.62 * 255).toInt()),
                  ],
                  center: Alignment(-0.2, -0.1),
                  radius: 0.9,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withAlpha((0.25 * 255).toInt()),
                    blurRadius: 26,
                    spreadRadius: 6,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withAlpha((0.08 * 255).toInt()),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.diamond,
                size: large ? 72 : 54,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Title with hometown feel and friendly font size
            Text(
              'Ô ĂN QUAN',
              style: TextStyle(
                fontSize: large ? 56 : 44,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 3,
                shadows: [
                  Shadow(
                    blurRadius: 12,
                    color: Colors.black.withAlpha((0.25 * 255).toInt()),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Trò chơi truyền thống - Hương vị quê nhà',
              style: TextStyle(
                fontSize: large ? 16 : 14,
                color: Colors.white.withAlpha((0.9 * 255).toInt()),
                fontStyle: FontStyle.italic,
                letterSpacing: 0.6,
                shadows: [
                  Shadow(
                    blurRadius: 12,
                    color: Colors.black.withAlpha((0.25 * 255).toInt()),
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonSection({
    required Color accent,
    bool isLandscape = false,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.pixels >= scroll.metrics.maxScrollExtent - 20) {
          // Đang ở cuối => ẩn hint
          if (_showScrollHint) {
            setState(() => _showScrollHint = false);
          }
        } else {
          if (!_showScrollHint) {
            setState(() => _showScrollHint = true);
          }
        }
        return true;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isLandscape ? 8 : 24,
              vertical: isLandscape ? 0 : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuButton(
                  context,
                  'Chơi với AI',
                  'Thử thách trí tuệ với trí tuệ nhân tạo AI',
                  Icons.smart_toy,
                  LinearGradient(
                    colors: [
                      accent.withAlpha((0.95 * 255).toInt()),
                      accent.withAlpha((0.6 * 255).toInt()),
                    ],
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DifficultyScreen(),
                      ),
                    );
                  },
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Chơi 1vs1',
                  'Đối đầu với bạn bè trên cùng thiết bị',
                  Icons.people,
                  LinearGradient(
                    colors: [
                      Colors.white.withAlpha((0.12 * 255).toInt()),
                      accent.withAlpha((0.6 * 255).toInt()),
                    ],
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PlayGame1vs1()),
                    );
                  },
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Bảng xếp hạng',
                  'Tốp đại cao thủ được vinh danh',
                  Icons.leaderboard,
                  LinearGradient(
                    colors: [
                      accent.withAlpha((0.85 * 255).toInt()),
                      accent.withAlpha((0.45 * 255).toInt()),
                    ],
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    );
                  },
                  accent: accent,
                ),
                const SizedBox(height: 12),
                _buildMenuButton(
                  context,
                  'Hướng dẫn chơi',
                  'Nắm rõ luật chơi và cách thắng nhanh chóng',
                  Icons.menu_book,
                  LinearGradient(
                    colors: [
                      Colors.white.withAlpha((0.12 * 255).toInt()),
                      accent.withAlpha((0.6 * 255).toInt()),
                    ],
                  ),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HowToPlayScreen(),
                      ),
                    );
                  },
                  accent: accent,
                ),
                // const SizedBox(height: 12),
                // _buildMenuButton(
                //   context,
                //   'Cấu hình',
                //   'Tùy chỉnh đồ hoạ, độ khó, và âm thanh',
                //   Icons.settings,
                //   LinearGradient(
                //     colors: [
                //       accent.withAlpha((0.85 * 255).toInt()),
                //       accent.withAlpha((0.45 * 255).toInt()),
                //     ],
                //   ),
                //   () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (_) => const SettingsScreen()),
                //     );
                //   },
                //   accent: accent,
                // ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // 👇 Arrow hint
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showScrollHint ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: SlideTransition(
                position: _arrowAnimation,
                child: Align(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withAlpha((0.25 * 255).toInt()),
                    ),
                    child: Icon(
                      Icons.keyboard_double_arrow_down,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap, {
    required Color accent,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: BoxDecoration().gradient ?? (gradient as LinearGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accent.withAlpha((0.18 * 255).toInt()),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withAlpha((0.14 * 255).toInt()),
            highlightColor: Colors.white.withAlpha((0.06 * 255).toInt()),
            onTap: enabled
                ? () {
                    AudioService().playEffect(SoundType.pack);
                    onTap();
                  }
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha((0.14 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withAlpha((0.06 * 255).toInt()),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withAlpha((0.92 * 255).toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withAlpha((0.85 * 255).toInt()),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        '© ${DateTime.now().year} - Phiên bản 1.0',
        style: TextStyle(
          color: Colors.white.withAlpha((0.7 * 255).toInt()),
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
