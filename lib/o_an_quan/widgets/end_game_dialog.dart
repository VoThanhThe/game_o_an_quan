import 'package:flutter/material.dart';

import '../service/audio_service.dart';

enum KetThucGame { win, lose, draw }

class EndGameDialog extends StatelessWidget {
  final KetThucGame result;
  final int scoreBottom;
  final int scoreTop;
  final VoidCallback onExit;
  final VoidCallback onReplay;

  const EndGameDialog({
    super.key,
    required this.result,
    required this.scoreBottom,
    required this.scoreTop,
    required this.onExit,
    required this.onReplay,
  });

  @override
  Widget build(BuildContext context) {
    late String title;
    late String subTitle;
    late IconData icon;
    late List<Color> gradientColors;
    late Color mainColor;
    AudioService().stopBackground();
    switch (result) {
      case KetThucGame.win:
        title = "Chiến thắng!";
        subTitle = "🎉 Bạn đã trở thành nhà vô địch!";
        icon = Icons.emoji_events;
        gradientColors = [const Color(0xFFFFE29F), const Color(0xFFFFB74D)];
        mainColor = const Color(0xFFFFB800);
        AudioService().playEffect(SoundType.win);
        break;

      case KetThucGame.lose:
        title = "Thua cuộc!";
        subTitle = "😢 Thật tiếc, hãy thử lại nhé!";
        icon = Icons.sentiment_dissatisfied;
        gradientColors = [const Color(0xFFFECDD3), const Color(0xFFF87171)];
        mainColor = const Color(0xFFEF4444);
        AudioService().playEffect(SoundType.lose);
        break;

      case KetThucGame.draw:
        title = "Hòa!";
        subTitle = "🤝 Ngang tài ngang sức, thật kịch tính!";
        icon = Icons.handshake; // Flutter 3.17+
        gradientColors = [const Color(0xFF93C5FD), const Color(0xFFA78BFA)];
        mainColor = const Color(0xFF3B82F6);
        AudioService().playEffect(SoundType.draw);
        break;
    }

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.25 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + Title
            Icon(icon, color: mainColor, size: 60),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Scoreboard
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.85 * 255).toInt()),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "Tỷ số: $scoreBottom - $scoreTop",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AudioService().playEffect(SoundType.pack);
                      onExit();
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      "Rời khỏi",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      AudioService().playEffect(SoundType.pack);
                      onReplay();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      "Chơi lại",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
