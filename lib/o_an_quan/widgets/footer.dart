import 'package:flutter/material.dart';
import 'score_card.dart';

class GameFooter extends StatelessWidget {
  final int scoreBottom;
  final bool playerTurn;

  const GameFooter({
    super.key,
    required this.scoreBottom,
    required this.playerTurn,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ScoreCard(
              player: "Người Dưới",
              score: scoreBottom,
              isActive: playerTurn,
            )
          ],
        ),
      ),
    );
  }
}
