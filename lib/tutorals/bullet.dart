import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/material.dart';

import 'enemy.dart';
import 'space_shooter_game.dart';

class Bullet extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  Bullet({super.position})
    : super(size: Vector2(25, 50), anchor: Anchor.center);
  @override
  Future<void> render(Canvas canvas) async {
    super.render(canvas);
    // Vẽ khung đỏ quanh enemy
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color.fromARGB(255, 246, 75, 2),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    animation = await game.loadSpriteAnimation(
      'bullet.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        stepTime: .2,
        textureSize: Vector2(8, 16),
      ),
    );
    add(RectangleHitbox(collisionType: CollisionType.active));
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.y += dt * -500;

    if (position.y < -height) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is Enemy) {
      debugPrint("💥 Bullet hit Enemy!");
      other.removeFromParent();
      removeFromParent();
    }
  }
}
