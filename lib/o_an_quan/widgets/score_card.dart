import 'package:flutter/material.dart';

class ScoreCard extends StatelessWidget {
  final String player;
  final int score;
  final bool isActive;

  const ScoreCard({
    super.key,
    required this.player,
    required this.score,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
            : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            player,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
