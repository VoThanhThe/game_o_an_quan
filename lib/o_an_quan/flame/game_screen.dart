import 'dart:async' as dart_async;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../service/audio_service.dart';

enum KetThucGame { win, lose, draw }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late OAnQuanGame game;

  @override
  void initState() {
    super.initState();
    game = OAnQuanGame(
      onGameEnd: _showKetThuc,
      onUpdateScores: (bottom, top) => setState(() {
        scoreBottom = bottom;
        scoreTop = top;
      }),
    );
    AudioService().playBackground();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    AudioService().stopBackground();
    WidgetsBinding.instance.removeObserver(this);
    game.turnTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      game.turnTimer?.cancel();
      AudioService().pauseBackground();
    } else if (state == AppLifecycleState.resumed) {
      game.resumeTimer();
      AudioService().resumeBackground();
    }
  }

  int scoreBottom = 0;
  int scoreTop = 0;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
            ),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: GameWidget(
                  game: game,
                  backgroundBuilder: (context) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF8B5A3C),
                          Color(0xFF6B4423),
                          Color(0xFF4A2C17),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildScoreCard("Người Trên", scoreTop, false),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5A26).withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color(0xFF8B5A26).withAlpha((0.2 * 255).toInt()),
                    ),
                  ),
                  child: const Text(
                    "Ô Ăn Quan",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "⏱️ ${game.timeLeft} giây",
                  style: const TextStyle(
                    color: Color(0xFF8B5A26),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 56),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(String player, int score, bool isBottom) {
    bool isActive =
        (isBottom && game.playerTurn) || (!isBottom && !game.playerTurn);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
              )
            : LinearGradient(colors: [Colors.grey[600]!, Colors.grey[700]!]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha((0.3 * 255).toInt()),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            player,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [_buildScoreCard("Người Dưới", scoreBottom, true)],
        ),
      ),
    );
  }

  void _showKetThuc(KetThucGame result) {
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
        icon = Icons.handshake;
        gradientColors = [const Color(0xFF93C5FD), const Color(0xFFA78BFA)];
        mainColor = const Color(0xFF3B82F6);
        AudioService().playEffect(SoundType.win);
        break;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
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
                        Navigator.pop(context);
                        game.resetGame();
                        setState(() {
                          scoreBottom = 0;
                          scoreTop = 0;
                        });
                        AudioService().playBackground();
                        game.startTimer();
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
      ),
    );
  }
}

class OAnQuanGame extends FlameGame with TapDetector, PanDetector {
  List<int> soLuongDa = [5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 0];
  List<bool> oQuanConDaTo = List.generate(12, (i) => i == 5 || i == 11);
  int? selectedIndex;
  int? movingIndex;
  bool isAnimating = false;
  bool playerTurn = true;
  int scoreBottom = 0;
  int scoreTop = 0;
  dart_async.Timer? turnTimer;
  int timeLeft = 25;
  final Function(KetThucGame) onGameEnd;
  final Function(int, int) onUpdateScores;

  // Board layout
  List<CellComponent> cells = [];
  List<SpriteComponent> movingStones = [];

  OAnQuanGame({required this.onGameEnd, required this.onUpdateScores});

  @override
  Future<void> onLoad() async {
    // Load sprites
    final stoneSprite = await loadSprite('stone_small.png');
    final bigStoneSprite = await loadSprite('stone_big.png');

    // Board layout (3.5 aspect ratio, 12 cells)
    final cellWidth = size.x / 7; // 5 small cells + 2 large cells
    final cellHeight = size.y / 2;
    final largeCellWidth = cellWidth * 1.5;

    // Create cells
    // Bottom row (indices 0-4)
    for (int i = 0; i < 5; i++) {
      cells.add(
        CellComponent(
          position: Vector2(largeCellWidth + i * cellWidth, cellHeight),
          size: Vector2(cellWidth, cellHeight),
          index: i,
          stoneSprite: stoneSprite,
          isLarge: false,
          game: this,
        ),
      );
    }
    // Top row (indices 6-10, reversed)
    for (int i = 0; i < 5; i++) {
      cells.add(
        CellComponent(
          position: Vector2(largeCellWidth + (4 - i) * cellWidth, 0),
          size: Vector2(cellWidth, cellHeight),
          index: 6 + i,
          stoneSprite: stoneSprite,
          isLarge: false,
          game: this,
        ),
      );
    }
    // Large cells (indices 5 and 11)
    cells.add(
      CellComponent(
        position: Vector2(0, 0),
        size: Vector2(largeCellWidth, size.y),
        index: 11,
        stoneSprite: stoneSprite,
        bigStoneSprite: bigStoneSprite,
        isLarge: true,
        game: this,
      ),
    );
    cells.add(
      CellComponent(
        position: Vector2(size.x - largeCellWidth, 0),
        size: Vector2(largeCellWidth, size.y),
        index: 5,
        stoneSprite: stoneSprite,
        bigStoneSprite: bigStoneSprite,
        isLarge: true,
        game: this,
      ),
    );

    addAll(cells);
    startTimer();
  }

  void startTimer() {
    turnTimer?.cancel();
    timeLeft = 25;
    turnTimer = dart_async.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        update(0); // Trigger UI update
      } else {
        timer.cancel();
        _xuLyHetGio();
      }
    });
  }

  void resumeTimer() {
    if (timeLeft <= 0) return;
    turnTimer?.cancel();
    turnTimer = dart_async.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        timeLeft--;
        update(0);
      } else {
        timer.cancel();
        _xuLyHetGio();
      }
    });
  }

  void _xuLyHetGio() {
    if (playerTurn) {
      onGameEnd(KetThucGame.lose);
    } else {
      onGameEnd(KetThucGame.win);
    }
  }

  void _doiLuot() {
    playerTurn = !playerTurn;
    startTimer();
  }

  Future<void> raiQuan(int startIndex, bool toRight) async {
    turnTimer?.cancel();
    isAnimating = true;

    int stones = soLuongDa[startIndex];
    soLuongDa[startIndex] = 0;
    int currentIndex = startIndex;

    while (stones > 0) {
      currentIndex = _nextIndex(currentIndex, toRight);
      final targetCell = cells.firstWhere((cell) => cell.index == currentIndex);
      final stone = SpriteComponent(
        sprite: await loadSprite('stone_small.png'),
        size: Vector2(10, 10),
        position: cells.firstWhere((cell) => cell.index == startIndex).center,
      );
      add(stone);
      movingStones.add(stone);

      await stone.moveTo(targetCell.center, 0.4);
      soLuongDa[currentIndex]++;
      movingIndex = currentIndex;
      update(0);
      remove(stone);
      movingStones.remove(stone);
      stones--;
    }

    await _xuLyKetThuc(currentIndex, toRight);
    movingIndex = null;
    isAnimating = false;
    _kiemTraKetThuc();
  }

  int _nextIndex(int current, bool toRight) {
    return toRight
        ? (current + 1) % soLuongDa.length
        : (current - 1 + soLuongDa.length) % soLuongDa.length;
  }

  Future<void> _xuLyKetThuc(int index, bool toRight) async {
    int next = _nextIndex(index, toRight);
    if (soLuongDa[next] > 0) {
      if (next != 5 && next != 11) {
        await raiQuan(next, toRight);
      } else {
        _doiLuot();
      }
    } else {
      int next2 = _nextIndex(next, toRight);
      if (soLuongDa[next2] > 0) {
        await _anQuan(next2, toRight);
        await _checkForCapture(next2, toRight);
      } else {
        _doiLuot();
      }
    }
  }

  Future<void> _checkForCapture(int pos, bool toRight) async {
    int next = _nextIndex(pos, toRight);
    if (soLuongDa[next] == 0) {
      int next2 = _nextIndex(next, toRight);
      if (soLuongDa[next2] > 0) {
        await _anQuan(next2, toRight);
        await _checkForCapture(next2, toRight);
      } else {
        _doiLuot();
      }
    } else {
      _doiLuot();
    }
  }

  Future<void> _anQuan(int captureIndex, bool toRight) async {
    int an = soLuongDa[captureIndex];
    soLuongDa[captureIndex] = 0;

    if (captureIndex == 5 || captureIndex == 11) {
      if (oQuanConDaTo[captureIndex]) {
        an += 10;
        oQuanConDaTo[captureIndex] = false;
      }
    }

    if (playerTurn) {
      scoreBottom += an;
    } else {
      scoreTop += an;
    }
    onUpdateScores(scoreBottom, scoreTop);
    AudioService().playEffect(SoundType.pickUp);
  }

  void _kiemTraKetThuc() {
    bool quanTraiHet = !oQuanConDaTo[5] && soLuongDa[5] == 0;
    bool quanPhaiHet = !oQuanConDaTo[11] && soLuongDa[11] == 0;

    if (quanTraiHet && quanPhaiHet) {
      _ketThucDoAnQuan();
      return;
    }

    bool duoiHet = soLuongDa.sublist(0, 5).every((e) => e == 0);
    bool trenHet = soLuongDa.sublist(6, 11).every((e) => e == 0);

    if (duoiHet) {
      if (scoreBottom > 0) {
        int soQuanHoi = scoreBottom >= 5 ? 5 : scoreBottom;
        scoreBottom -= soQuanHoi;
        for (int i = 0; i <= 4; i++) {
          soLuongDa[i] = soQuanHoi > 0 ? 1 : 0;
          soQuanHoi--;
        }
        onUpdateScores(scoreBottom, scoreTop);
      } else {
        _thuaDoHetQuan();
      }
    } else if (trenHet) {
      if (scoreTop > 0) {
        int soQuanHoi = scoreTop >= 5 ? 5 : scoreTop;
        scoreTop -= soQuanHoi;
        for (int i = 6; i <= 10; i++) {
          soLuongDa[i] = soQuanHoi > 0 ? 1 : 0;
          soQuanHoi--;
        }
        onUpdateScores(scoreBottom, scoreTop);
      } else {
        _thuaDoHetQuan();
      }
    }
  }

  void _ketThucDoAnQuan() {
    int remainingBottom = soLuongDa.sublist(0, 5).fold(0, (a, b) => a + b);
    int remainingTop = soLuongDa.sublist(6, 11).fold(0, (a, b) => a + b);
    turnTimer?.cancel();
    scoreBottom += remainingBottom;
    scoreTop += remainingTop;
    onUpdateScores(scoreBottom, scoreTop);
    onGameEnd(
      scoreBottom > scoreTop
          ? KetThucGame.win
          : scoreTop > scoreBottom
          ? KetThucGame.lose
          : KetThucGame.draw,
    );
  }

  void _thuaDoHetQuan() {
    int tongConLai = soLuongDa.fold(0, (a, b) => a + b);
    soLuongDa = List.filled(12, 0);
    turnTimer?.cancel();
    if (playerTurn) {
      scoreTop += tongConLai;
      onUpdateScores(scoreBottom, scoreTop);
      onGameEnd(KetThucGame.lose);
    } else {
      scoreBottom += tongConLai;
      onUpdateScores(scoreBottom, scoreTop);
      onGameEnd(KetThucGame.win);
    }
  }

  void resetGame() {
    soLuongDa = [5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 0];
    oQuanConDaTo = List.generate(12, (i) => i == 5 || i == 11);
    scoreBottom = 0;
    scoreTop = 0;
    playerTurn = true;
    isAnimating = false;
    selectedIndex = null;
    movingIndex = null;
    onUpdateScores(scoreBottom, scoreTop);
    startTimer();
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (isAnimating) return;
    final cell = cells.firstWhereOrNull(
      (c) => c.containsPoint(info.eventPosition.global),
    );
    if (cell != null && _canSelectCell(cell.index)) {
      selectedIndex = cell.index;
      cell.isSelected = true;
      update(0);
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (selectedIndex == null || isAnimating) return;
    final velocity = info.velocity.x;
    if (velocity.abs() > 100) {
      final toRight = velocity > 0;
      final index = selectedIndex!;
      selectedIndex = null;
      for (var c in cells) {
        c.isSelected = false;
      }
      raiQuan(index, playerTurn ? toRight : !toRight);
    }
  }

  bool _canSelectCell(int index) {
    return soLuongDa[index] > 0 &&
        ((playerTurn && index >= 0 && index <= 4) ||
            (!playerTurn && index >= 6 && index <= 10));
  }
}

class CellComponent extends SpriteComponent with HasGameRef<OAnQuanGame> {
  final int index;
  final bool isLarge;
  final Sprite stoneSprite;
  final Sprite? bigStoneSprite;
  bool isSelected = false;

  CellComponent({
    required Vector2 position,
    required Vector2 size,
    required this.index,
    required this.stoneSprite,
    this.bigStoneSprite,
    required this.isLarge,
    required OAnQuanGame game,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    sprite = await gameRef.loadSprite('cell${isLarge ? '_large' : ''}.png');
    paint = Paint()
      ..color = isLarge
          ? Colors.amber.withOpacity(0.8)
          : Colors.brown.withOpacity(0.8);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final count = gameRef.soLuongDa[index];
    final isMoving = gameRef.movingIndex == index;
    gameRef._canSelectCell(index);

    // Draw stones
    final stoneSize = Vector2(10, 10);
    final rows = (count / 5).ceil();
    final gridWidth = 5 * 12.0;
    final gridHeight = rows * 12.0;
    final startX = center.x - gridWidth / 2;
    final startY = center.y - gridHeight / 2;

    for (int i = 0; i < count; i++) {
      final row = i ~/ 5;
      final col = i % 5;
      final stonePos = Vector2(
        startX + col * 12.0 + 6,
        startY + row * 12.0 + 6,
      );
      stoneSprite.render(
        canvas,
        position: stonePos,
        size: stoneSize,
        anchor: Anchor.center,
      );
    }

    if (isLarge && gameRef.oQuanConDaTo[index] && bigStoneSprite != null) {
      bigStoneSprite!.render(
        canvas,
        position: Vector2(center.x, center.y - 20),
        size: Vector2(20, 20),
        anchor: Anchor.center,
      );
    }

    // Draw count
    final textPainter = TextPainter(
      text: TextSpan(
        text: (count + (isLarge && gameRef.oQuanConDaTo[index] ? 10 : 0))
            .toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.x - textPainter.width - 4, size.y - textPainter.height - 4),
    );

    // Highlight for selected or moving
    if (isSelected || isMoving) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()
          ..color = (isSelected ? Colors.yellow : Colors.white).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }
}

extension on SpriteComponent {
  Future<void> moveTo(Vector2 target, double duration) async {
    final start = position.clone();
    final distance = target - start;
    double elapsed = 0;

    while (elapsed < duration) {
      await Future.delayed(const Duration(milliseconds: 16));
      elapsed += 0.016;
      position = start + distance * (elapsed / duration);
      // gameRef.update(0);
    }
    position = target;
  }
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
