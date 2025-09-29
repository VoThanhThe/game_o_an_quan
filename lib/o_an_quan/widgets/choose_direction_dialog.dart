import 'package:flutter/material.dart';

import '../service/audio_service.dart';

class ChooseDirectionDialog extends StatelessWidget {
  const ChooseDirectionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E7), Color(0xFFFFE0A0)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- Title ---
            Row(
              children: const [
                Icon(Icons.explore, color: Colors.orange, size: 26),
                SizedBox(width: 8),
                Text(
                  "Chọn hướng đi",
                  style: TextStyle(
                    color: Colors.brown,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Content ---
            const Text(
              "Bạn muốn rải quân theo hướng nào?",
              style: TextStyle(color: Colors.brown, fontSize: 15),
            ),
            const SizedBox(height: 20),

            // --- Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                DirectionButton(
                  text: "Trái",
                  value: "left",
                  icon: Icons.arrow_back,
                ),
                DirectionButton(
                  text: "Phải",
                  value: "right",
                  icon: Icons.arrow_forward,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DirectionButton extends StatelessWidget {
  final String text;
  final String value;
  final IconData icon;

  const DirectionButton({
    super.key,
    required this.text,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AudioService().playEffect(SoundType.pack);
              Navigator.pop(context, value);
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.orangeAccent.withAlpha((0.2 * 255).toInt()),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD27F), Color(0xFFFFA751)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha((0.3 * 255).toInt()),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: value == 'left'
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.end,
                children: [
                  if (value == 'left') ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (value == 'right') ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
