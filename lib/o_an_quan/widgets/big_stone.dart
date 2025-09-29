import 'package:flutter/material.dart';

class BigStone extends StatelessWidget {
  const BigStone({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final stoneSize = screenWidth / 8; // Chia cho 8 để lấy tỷ lệ phù hợp

    return Container(
      width: stoneSize,
      // height: stoneSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0xFF7C3AED), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Center(
        child: Text(
          '💎',
          style: TextStyle(fontSize: stoneSize / 2.5), // chữ cũng scale theo
        ),
      ),
    );
  }
}
