import 'package:flame/components.dart';

import 'bullet.dart';
import 'space_shooter_game.dart';

class Player extends SpriteAnimationComponent
    with HasGameReference<SpaceShooterGame> {
  late final SpawnComponent _bulletSpawner;
  Player() : super(size: Vector2(100, 150), anchor: Anchor.bottomCenter);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final frames = <Sprite>[];
    for (int i = 1; i <= 10; i++) {
      frames.add(await game.loadSprite('idle_$i.png'));
    }

    animation = SpriteAnimation.spriteList(
      frames,
      stepTime: 0.1, // tốc độ chuyển frame
    );

    position = game.size / 2;
    _bulletSpawner = SpawnComponent(
      period: .2,
      selfPositioning: true,
      factory: (index) {
        return Bullet(position: position.clone() + Vector2(0, -height * 0.6));
      },
      autoStart: false,
    );

    game.add(_bulletSpawner);
  }

  void move(Vector2 delta) {
    position.add(delta);
  }

  void startShooting() {
    _bulletSpawner.timer.start();
  }

  void stopShooting() {
    _bulletSpawner.timer.stop();
  }
}
