import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:minigame_tet/tutorals/player.dart';

import 'enemy.dart';

class SpaceShooterGame extends FlameGame
    with PanDetector, HasCollisionDetection {
  late Player player;

  // @override
  // void render(Canvas canvas) {
  //   final rect = Rect.fromLTWH(0, 0, size.x, size.y);
  //   final paint = Paint()
  //     ..shader = LinearGradient(
  //       colors: [Colors.blue.shade900, Colors.blue.shade200],
  //       begin: Alignment.topCenter,
  //       end: Alignment.bottomCenter,
  //     ).createShader(rect);

  //   canvas.drawRect(rect, paint);

  //   super.render(canvas); // render các component khác
  // }

  @override
  Future<void> onLoad() async {
    final parallax = await loadParallaxComponent(
      [ParallaxImageData('background_2.png')],
      fill: LayerFill.width,
      baseVelocity: Vector2(0, -20), // tốc độ cuộn
      repeat: ImageRepeat.repeat,
      velocityMultiplierDelta: Vector2(0, 1.0),
    );

    add(parallax);
    player = Player();
    add(player);
    add(
      SpawnComponent(
        factory: (index) {
          return Enemy();
        },
        period: 1,
        area: Rectangle.fromLTWH(0, -Enemy.enemySize, size.x, Enemy.enemySize),
      ),
    );
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    player.move(info.delta.global);
  }

  @override
  void onPanStart(DragStartInfo info) {
    player.startShooting();
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.stopShooting();
  }
}
