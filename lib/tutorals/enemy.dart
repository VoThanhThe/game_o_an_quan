import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';
import 'bullet.dart';
import 'space_shooter_game.dart';

class Enemy extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  Enemy({super.position})
    : super(size: Vector2.all(enemySize), anchor: Anchor.center);

  static const enemySize = 50.0;

  @override
  Future<void> render(Canvas canvas) async {
    super.render(canvas);
    // Vẽ khung đỏ quanh enemy
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color.fromARGB(255, 169, 246, 2),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    animation = await game.loadSpriteAnimation(
      'enemy.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: .2,
        textureSize: Vector2.all(16),
      ),
    );
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += dt * 250;

    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bullet) {
      debugPrint("💀 Enemy bị bắn hạ!");
      removeFromParent();
      other.removeFromParent();
    }
  }
}
