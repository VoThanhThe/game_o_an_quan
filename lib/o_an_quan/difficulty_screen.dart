import 'package:flutter/material.dart';

import 'play_game_ai.dart';
import 'service/audio_service.dart';

enum AIDifficulty { easy, normal, hard }

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Nền gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
              ),
            ),
          ),

          // Nội dung chính
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              // Nút chọn độ khó
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12).copyWith(top: 2),
                  child: Column(
                    children: [
                      _buildDifficultyOption(
                        context,
                        AIDifficulty.easy,
                        "Dễ",
                        "AI chơi đơn giản, thích hợp cho người mới",
                        Icons.child_friendly,
                        [const Color(0xFF34D399), const Color(0xFF059669)],
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayGameAi(
                                difficulty: AIDifficulty.easy,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDifficultyOption(
                        context,
                        AIDifficulty.normal,
                        "Thường",
                        "AI cân bằng, trải nghiệm tiêu chuẩn",
                        Icons.balance,
                        [const Color(0xFFFBBF24), const Color(0xFFD97706)],
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayGameAi(
                                difficulty: AIDifficulty.normal,
                              ),
                            ),
                          );
                        },
                      ),

                      _buildDifficultyOption(
                        context,
                        AIDifficulty.hard,
                        "Khó",
                        "AI thông minh, thử thách cao cho cao thủ",
                        Icons.psychology_alt,
                        [const Color(0xFFF87171), const Color(0xFFB91C1C)],
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlayGameAi(
                                difficulty: AIDifficulty.hard,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              AudioService().playEffect(SoundType.pack);
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          Expanded(
            child: Text(
              'Chọn Cấp Độ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B5A26),
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption(
    BuildContext context,
    AIDifficulty difficulty,
    String title,
    String description,
    IconData icon,
    List<Color> gradientColors,
    VoidCallback onSelect,
  ) {
    return AnimatedContainer(
      width: MediaQuery.of(context).size.width / 2,
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withAlpha((0.6 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white.withAlpha((0.14 * 255).toInt()),
          highlightColor: Colors.white.withAlpha((0.06 * 255).toInt()),
          onTap: () {
            AudioService().playEffect(SoundType.pack);
            onSelect();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 40, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
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
    );
  }
}
