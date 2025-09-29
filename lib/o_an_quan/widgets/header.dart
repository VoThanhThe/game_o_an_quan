import 'package:flutter/material.dart';
import '../difficulty_screen.dart';
import 'score_card.dart';

class GameHeader extends StatelessWidget {
  final String name;
  final int scoreTop;
  final bool playerTurn;
  final int timeLeft;
  final AIDifficulty? currentDifficulty;

  const GameHeader({
    super.key,
    required this.scoreTop,
    required this.playerTurn,
    required this.timeLeft,
    required this.name,
    this.currentDifficulty,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ScoreCard(player: name, score: scoreTop, isActive: !playerTurn),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF8B5A26,
                    ).withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(
                        0xFF8B5A26,
                      ).withAlpha((0.2 * 255).toInt()),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        "Ô Ăn Quan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentDifficulty != null)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor().withAlpha(
                              (0.2 * 255).toInt(),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getDifficultyColor(),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getDifficultyText(),
                            style: TextStyle(
                              color: _getDifficultyColor(),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "⏱️ $timeLeft giây",
                  style: const TextStyle(
                    color: Color(0xFF8B5A26),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor() {
    switch (currentDifficulty) {
      case AIDifficulty.easy:
        return const Color(0xFF10B981);
      case AIDifficulty.normal:
        return const Color(0xFFF59E0B);
      case AIDifficulty.hard:
        return const Color(0xFFEF4444);
      case null:
        throw UnimplementedError();
    }
  }

  String _getDifficultyText() {
    switch (currentDifficulty) {
      case AIDifficulty.easy:
        return "DỄ";
      case AIDifficulty.normal:
        return "THƯỜNG";
      case AIDifficulty.hard:
        return "KHÓ";
      case null:
        throw UnimplementedError();
    }
  }
}
