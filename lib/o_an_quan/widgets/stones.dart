import 'package:flutter/material.dart';

class Stones extends StatelessWidget {
  final int count;
  final bool isAnimating;

  const Stones({super.key, required this.count, required this.isAnimating});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final stoneSize = screenWidth / 6; // chia 6 để có khoảng cách

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1,
      ),
      itemCount: count,
      itemBuilder: (_, index) => Image.asset(
        "assets/images/stone_small.png",
        width: stoneSize,
        height: stoneSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
