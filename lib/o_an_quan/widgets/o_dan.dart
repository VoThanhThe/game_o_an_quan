import 'package:flutter/material.dart';

import 'stones.dart';

class ODan extends StatelessWidget {
  final int index;
  final int? handIndex;
  final String? handType;
  final int soLuong;
  final bool isMoving;
  final bool canSelect;
  final bool isSelected;
  final Animation<double> glowAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> stoneAnimation;
  final VoidCallback? onTap;

  const ODan({
    super.key,
    required this.index,
    required this.soLuong,
    required this.isMoving,
    required this.canSelect,
    required this.isSelected,
    required this.glowAnimation,
    required this.pulseAnimation,
    required this.stoneAnimation,
    this.onTap,
    this.handIndex,
    this.handType,
  });

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: canSelect
            ? const LinearGradient(
                colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
              )
            : const LinearGradient(
                colors: [Color(0xFF8B5A3C), Color(0xFF6B4423)],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canSelect ? Colors.amber : Colors.black54,
          width: canSelect ? 2 : 1,
        ),
        boxShadow: canSelect
            ? [
                BoxShadow(
                  color: Colors.amber.withAlpha((0.3 * 255).toInt()),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Stones(count: soLuong, isAnimating: isMoving),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha((0.5 * 255).toInt()),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                soLuong.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                ),
              ),
            ),
          ),
          if (isMoving)
            AnimatedBuilder(
              animation: glowAnimation,
              builder: (_, __) => Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.yellow.withAlpha(
                      (glowAnimation.value * 255).toInt(),
                    ),
                    width: 3,
                  ),
                ),
              ),
            ),
          if (handIndex == index && handType != null)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  handType == "distribute"
                      ? 'assets/images/hand_distribute.png'
                      : 'assets/images/hand_capture.png',
                  height: 30, // Kích thước bàn tay
                  fit: BoxFit.contain,
                ),
              ),
            ),
        ],
      ),
    );

    if (index == 5 || index == 11) return child;

    return GestureDetector(
      onTap: canSelect ? onTap : null, // Disable tap when canSelect is false
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (_, __) => Transform.scale(
          scale: isSelected ? pulseAnimation.value : 1.0,
          child: child,
        ),
      ),
    );
  }
}
