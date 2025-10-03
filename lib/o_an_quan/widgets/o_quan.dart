import 'package:flutter/material.dart';
import 'big_stone.dart';
import 'small_stones.dart';

class OQuan extends StatelessWidget {
  final int index;
  final int? handIndex;
  final String? handType;
  final int soLuong;
  final bool conDaTo;
  final bool isMoving;

  const OQuan({
    super.key,
    required this.index,
    required this.soLuong,
    required this.conDaTo,
    required this.isMoving,
    this.handIndex,
    this.handType,
  });

  @override
  Widget build(BuildContext context) {
    int tongDiem = conDaTo ? (10 + soLuong) : soLuong;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700), // Gold
            Color(0xFFFFB000),
            Color(0xFFFF8C00),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFB45309), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withAlpha((0.4 * 255).toInt()),
            blurRadius: 8,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withAlpha((0.2 * 255).toInt()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (conDaTo) const BigStone(),
                  if (soLuong > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SmallStones(count: soLuong),
                    ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.3 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tongDiem.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMoving)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  width: 4,
                ),
              ),
            ),
          if (handIndex == index && handType != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  handType == "distribute"
                      ? 'assets/images/hand_distribute.png'
                      : 'assets/images/hand_capture.png',
                  height: 40, // Kích thước lớn hơn cho ô quan
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
