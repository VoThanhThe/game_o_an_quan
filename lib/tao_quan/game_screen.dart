import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';

class TaoQuanGame extends StatefulWidget {
  const TaoQuanGame({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TaoQuanGameState createState() => _TaoQuanGameState();
}

class _TaoQuanGameState extends State<TaoQuanGame> with TickerProviderStateMixin {
  // Game variables
  late AnimationController _swimController;
  late AnimationController _backgroundController;
  late Animation<double> _swimAnimation;
  late Animation<double> _backgroundAnimation;

  Timer? _gameTimer;
  Timer? _obstacleTimer;

  // Player position and movement
  double playerY = 0.0;
  double playerVelocity = 0.0;
  final double gravity = 0.5;
  final double jumpStrength = -8.0;

  // Game state
  bool isGameStarted = false;
  bool isGameOver = false;
  int score = 0;
  int highScore = 0;
  double distance = 0.0;

  // Obstacles
  List<Obstacle> obstacles = [];

  // Game dimensions
  double screenHeight = 0;
  double screenWidth = 0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _swimController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _swimAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _swimController, curve: Curves.easeInOut),
    );

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);
  }

  void _startGame() {
    setState(() {
      isGameStarted = true;
      isGameOver = false;
      score = 0;
      distance = 0.0;
      playerY = 0.0;
      playerVelocity = 0.0;
      obstacles.clear();
    });

    _gameTimer = Timer.periodic(Duration(milliseconds: 16), (timer) {
      _updateGame();
    });

    _obstacleTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _addObstacle();
    });
  }

  void _updateGame() {
    if (!isGameStarted || isGameOver) return;

    setState(() {
      // Update player physics
      playerVelocity += gravity;
      playerY += playerVelocity;

      // Keep player within screen bounds
      if (playerY > screenHeight / 2 - 100) {
        playerY = screenHeight / 2 - 100;
        playerVelocity = 0;
      }
      if (playerY < -screenHeight / 2 + 50) {
        playerY = -screenHeight / 2 + 50;
        playerVelocity = 0;
      }

      // Update distance and score
      distance += 1.0;
      score = (distance / 10).round();

      // Update obstacles
      for (int i = obstacles.length - 1; i >= 0; i--) {
        obstacles[i].x -= 3.0;

        // Remove obstacles that are off screen
        if (obstacles[i].x < -100) {
          obstacles.removeAt(i);
        }
        // Check collision
        else if (_checkCollision(obstacles[i])) {
          _gameOver();
          return;
        }
      }
    });
  }

  void _addObstacle() {
    if (!isGameStarted || isGameOver) return;

    double obstacleY = Random().nextDouble() * 200 - 100;
    obstacles.add(
      Obstacle(x: screenWidth + 50, y: obstacleY, type: Random().nextInt(3)),
    );
  }

  bool _checkCollision(Obstacle obstacle) {
    double playerCenterX = 100;
    double playerCenterY = playerY;
    double playerRadius = 30;

    double obstacleLeft = obstacle.x - 25;
    double obstacleRight = obstacle.x + 25;
    double obstacleTop = obstacle.y - 25;
    double obstacleBottom = obstacle.y + 25;

    return playerCenterX + playerRadius > obstacleLeft &&
        playerCenterX - playerRadius < obstacleRight &&
        playerCenterY + playerRadius > obstacleTop &&
        playerCenterY - playerRadius < obstacleBottom;
  }

  void _jump() {
    if (!isGameStarted || isGameOver) return;

    setState(() {
      playerVelocity = jumpStrength;
    });

    _swimController.forward().then((_) {
      _swimController.reverse();
    });

    HapticFeedback.heavyImpact();
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
      if (score > highScore) {
        highScore = score;
      }
    });

    _gameTimer?.cancel();
    _obstacleTimer?.cancel();

    HapticFeedback.heavyImpact();
  }

  void _resetGame() {
    _gameTimer?.cancel();
    _obstacleTimer?.cancel();

    setState(() {
      isGameStarted = false;
      isGameOver = false;
      score = 0;
      distance = 0.0;
      playerY = 0.0;
      playerVelocity = 0.0;
      obstacles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: GestureDetector(
        onTap: _jump,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF87CEEB), Color(0xFF4682B4), Color(0xFF191970)],
            ),
          ),
          child: Stack(
            children: [
              // Animated background clouds
              _buildBackground(),

              // Game area
              Center(
                child: SizedBox(
                  width: screenWidth,
                  height: screenHeight * 0.7,
                  child: Stack(
                    children: [
                      // Water waves
                      _buildWaterWaves(),

                      // Obstacles
                      ..._buildObstacles(),

                      // Player (Ông Táo on carp)
                      _buildPlayer(),

                      // Game UI overlay
                      if (!isGameStarted) _buildStartScreen(),
                      if (isGameOver) _buildGameOverScreen(),
                    ],
                  ),
                ),
              ),

              // Score display
              if (isGameStarted && !isGameOver) _buildScoreDisplay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Positioned(
          top: 50 + sin(_backgroundAnimation.value * 2 * pi) * 10,
          left: -50 + _backgroundAnimation.value * 100,
          child: Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.8 * 255).toInt()),
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaterWaves() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(screenWidth, screenHeight * 0.7),
          painter: WavePainter(_backgroundAnimation.value),
        );
      },
    );
  }

  List<Widget> _buildObstacles() {
    return obstacles.map((obstacle) {
      return Positioned(
        left: obstacle.x,
        top: screenHeight * 0.35 + obstacle.y,
        child: SizedBox(
          width: 50,
          height: 50,
          child: _getObstacleWidget(obstacle.type),
        ),
      );
    }).toList();
  }

  Widget _getObstacleWidget(int type) {
    switch (type) {
      case 0:
        return Container(
          decoration: BoxDecoration(
            color: Colors.brown[800],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.terrain, color: Colors.green[700], size: 30),
        );
      case 1:
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[600],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.circle, color: Colors.grey[800], size: 35),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            color: Colors.red[300],
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(Icons.warning, color: Colors.red[800], size: 25),
        );
    }
  }

  Widget _buildPlayer() {
    return AnimatedBuilder(
      animation: _swimAnimation,
      builder: (context, child) {
        return Positioned(
          left: 50,
          top: screenHeight * 0.35 + playerY,
          child: Transform.rotate(
            angle: playerVelocity * 0.1,
            child: SizedBox(
              width: 100,
              height: 60,
              child: Stack(
                children: [
                  // Carp fish
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Stack(
                        children: [
                          // Fish scales pattern
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [Colors.orange[400]!, Colors.red[400]!],
                              ),
                            ),
                          ),
                          // Fish eye
                          Positioned(
                            right: 15,
                            top: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Fish tail
                          Positioned(
                            left: -10,
                            top: 10,
                            child: Transform.scale(
                              scale: 0.8 + _swimAnimation.value * 0.2,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.red[500],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    bottomLeft: Radius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Ông Táo character
                  Positioned(
                    top: 0,
                    left: 20,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        children: [
                          // Body
                          Container(
                            width: 40,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.red[700],
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          // Head
                          Positioned(
                            top: -5,
                            left: 10,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.brown[200],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Hat
                          Positioned(
                            top: -10,
                            left: 8,
                            child: Container(
                              width: 24,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.yellow[700],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartScreen() {
    return Container(
      color: Colors.black.withAlpha((0.7 * 255).toInt()),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🐟 Cuộc Đua Ông Táo 🐟',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[300],
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.red,
                    offset: Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Chạm màn hình để điều khiển\nÔng Táo cưỡi cá chép lên trời!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'BẮT ĐẦU CUỘC ĐUA',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (highScore > 0) ...[
              SizedBox(height: 20),
              Text(
                'Kỷ lục: $highScore điểm',
                style: TextStyle(fontSize: 16, color: Colors.yellow[200]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverScreen() {
    return Container(
      color: Colors.black.withAlpha((0.8 * 255).toInt()),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '🎊 Chúc Mừng! 🎊',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[300],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Điểm May Mắn: $score',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _getLuckyMessage(score),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.yellow[100]),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'ĐUA TIẾP',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text('VỀ MENU', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay() {
    return Positioned(
      top: 50,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red[600]?.withAlpha((0.9 * 255).toInt()),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.yellow[400]!, width: 2),
        ),
        child: Column(
          children: [
            Text(
              'ĐIỂM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.yellow[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLuckyMessage(int score) {
    if (score >= 100) {
      return "🌟 Thần Tài Phù Hộ!\nVạn Sự Như Ý! 🌟";
    } else if (score >= 50) {
      return "🎉 Tài Lộc Đầy Nhà!\nAn Khang Thịnh Vượng! 🎉";
    } else if (score >= 25) {
      return "🧧 May Mắn Quanh Năm!\nSức Khỏe Dồi Dào! 🧧";
    } else {
      return "🎋 Chúc Năm Mới An Lành!\nHạnh Phúc Viên Mãn! 🎋";
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _obstacleTimer?.cancel();
    _swimController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }
}

class Obstacle {
  double x;
  double y;
  int type;

  Obstacle({required this.x, required this.y, required this.type});
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[200]!.withAlpha((0.3 * 255).toInt())
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < 3; i++) {
      path.reset();
      double waveHeight = 20 + i * 10;
      double frequency = 0.02 + i * 0.01;

      for (double x = 0; x <= size.width; x += 1) {
        double y =
            size.height * 0.5 +
            sin((x * frequency) + (animationValue * 2 * pi) + (i * pi / 2)) *
                waveHeight;

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
