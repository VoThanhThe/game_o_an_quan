import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'service/audio_service.dart';
import 'difficulty_screen.dart';
import 'widgets/choose_direction_dialog.dart';
import 'widgets/end_game_dialog.dart';
import 'widgets/footer.dart';
import 'widgets/header.dart';
import 'widgets/o_dan.dart';
import 'widgets/o_quan.dart';

class PlayGameAi extends StatefulWidget {
  final AIDifficulty difficulty;
  const PlayGameAi({super.key, required this.difficulty});
  @override
  State<PlayGameAi> createState() => _PlayGameAiState();
}

class _PlayGameAiState extends State<PlayGameAi>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Game state - matching 1vs1
  List<int> soLuongDa = [5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 0];
  List<bool> oQuanConDaTo = List.generate(12, (i) => i == 5 || i == 11);
  int? movingIndex;
  int? selectedIndex;
  bool isAnimating = false;
  bool playerTurn = true; // true = người dưới, false = người trên (AI)
  int scoreBottom = 0;
  int scoreTop = 0;
  Timer? _turnTimer;
  int timeLeft = 25;
  bool gameStarted = false; // Track if game has started
  bool gameEnded = false; // Prevent multiple end dialogs
  bool chonHuongDangMo = false;
  bool isFirstTurn = true; // chặn ăn quan ở lượt đầu
  int? handIndex; // Ô đang hiển thị bàn tay
  String? handType; // "distribute" hoặc "capture"
  bool isDialogOpen = false; // Flag to track if EndGameDialog is open

  // Animation controllers - matching 1vs1
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _stoneAnimController;
  late Animation<double> _stoneAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  // Enhanced AI settings
  AIDifficulty currentDifficulty = AIDifficulty.normal;

  // Transposition Table for avoiding repeated calculations
  final Map<String, TranspositionEntry> _transpositionTable = {};

  // Killer moves storage (moves that caused alpha-beta cutoffs)
  final List<List<MoveDecision?>> _killerMoves = List.generate(
    20,
    (_) => [null, null],
  );

  // History table for move ordering
  final Map<int, int> _historyTable = {};

  int get aiDepth {
    switch (currentDifficulty) {
      case AIDifficulty.easy:
        return 2; // Slightly increased for better play
      case AIDifficulty.normal:
        return 7; // Better tactical depth
      case AIDifficulty.hard:
        return 10; // Deeper strategic analysis
    }
  }

  int get aiThinkingTime {
    switch (currentDifficulty) {
      case AIDifficulty.easy:
        return 500;
      case AIDifficulty.normal:
        return 800; // Faster response
      case AIDifficulty.hard:
        return 2000; // Much faster than before (was 2000ms)
    }
  }

  @override
  void initState() {
    super.initState();
    // AudioService().playBackground();
    currentDifficulty = widget.difficulty;
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _stoneAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _stoneAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _stoneAnimController, curve: Curves.bounceOut),
    );
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _glowController.repeat(reverse: true);
    WidgetsBinding.instance.addObserver(this);
    _startGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService().stopBackground();
    _turnTimer?.cancel();
    _pulseController.dispose();
    _stoneAnimController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // Lắng nghe thay đổi trạng thái App
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Người dùng nhấn Home hoặc chuyển app
      _turnTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // Quay lại app
      _resumeTimer();
    }
  }

  void _resumeTimer() {
    if (gameEnded || timeLeft <= 0) return;
    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameEnded) {
        timer.cancel();
        return;
      }
      if (timeLeft > 0) {
        safeSetState(() => timeLeft--);
        if (timeLeft <= 15) {
          if (timeLeft % 5 == 0) {
            makeVibrate();
          }
        }
      } else {
        timer.cancel();
        _xuLyHetGio();
      }
    });
  }

  void _startTimer() {
    if (gameEnded) return; // Don't start timer if game ended
    _turnTimer?.cancel();
    safeSetState(() => timeLeft = 25);
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (gameEnded) {
        // Stop timer if game ends
        timer.cancel();
        return;
      }
      if (timeLeft > 0) {
        safeSetState(() => timeLeft--);
        if (timeLeft <= 15) {
          if (timeLeft % 5 == 0) {
            makeVibrate();
          }
        }
      } else {
        timer.cancel();
        _xuLyHetGio();
      }
    });
  }

  // Rung thông báo sắp hết thời gian còn 15s -> 10s -> 5s -> 0s
  void makeVibrate() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(); // Rung mặc định
    }
  }

  /// Khi hết giờ
  void _xuLyHetGio() {
    if (gameEnded) return; // Prevent multiple dialogs
    if (playerTurn) {
      _showKetThuc(KetThucGame.lose);
    } else {
      _showKetThuc(KetThucGame.win);
    }
  }

  /// Hàm đổi lượt
  void _doiLuot() {
    if (gameEnded) return; // Don't switch turns if game ended
    safeSetState(() => playerTurn = !playerTurn);
    _startTimer();
  }

  // Bắt đầu trò chơi
  void _startGame() {
    setState(() {
      gameStarted = true;
      gameEnded = false; // Reset end dialog flag
      soLuongDa = [5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 0];
      oQuanConDaTo = List.generate(12, (i) => i == 5 || i == 11);
      scoreBottom = 0;
      scoreTop = 0;
      playerTurn = true;
      isFirstTurn = true;
    });
    // Clear AI tables when starting new game
    _clearAITables();
    _startTimer();
  }

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
              GameHeader(
                name: "AI (Trên)",
                scoreTop: scoreTop,
                playerTurn: playerTurn,
                timeLeft: timeLeft,
                currentDifficulty: currentDifficulty,
              ),
              Expanded(child: _buildBanCo()),
              GameFooter(scoreBottom: scoreBottom, playerTurn: playerTurn),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanCo() {
    return Center(
      child: AspectRatio(
        aspectRatio: 3.5,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B5A3C), Color(0xFF6B4423), Color(0xFF4A2C17)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF2D1810), width: 6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.5 * 255).toInt()),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: OQuan(
                  index: 11,
                  soLuong: soLuongDa[11],
                  conDaTo: oQuanConDaTo[11],
                  isMoving: movingIndex == 11,
                  handIndex: handIndex,
                  handType: handType,
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          for (int i = 10; i >= 6; i--)
                            Expanded(
                              child: ODan(
                                index: i,
                                soLuong: soLuongDa[i],
                                isMoving: movingIndex == i,
                                canSelect:
                                    !isAnimating &&
                                    soLuongDa[i] > 0 &&
                                    (!playerTurn && i >= 6 && i <= 10),
                                isSelected: selectedIndex == i,
                                glowAnimation: _glowAnimation,
                                pulseAnimation: _pulseAnimation,
                                stoneAnimation: _stoneAnimation,
                                onTap: () async {
                                  await _handleODanTap(i);
                                },
                                handIndex: handIndex,
                                handType: handType,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          for (int i = 0; i <= 4; i++)
                            Expanded(
                              child: ODan(
                                index: i,
                                soLuong: soLuongDa[i],
                                isMoving: movingIndex == i,
                                canSelect:
                                    !isAnimating &&
                                    soLuongDa[i] > 0 &&
                                    (playerTurn && i >= 0 && i <= 4),
                                isSelected: selectedIndex == i,
                                glowAnimation: _glowAnimation,
                                pulseAnimation: _pulseAnimation,
                                stoneAnimation: _stoneAnimation,
                                onTap: () async {
                                  await _handleODanTap(i);
                                },
                                handIndex: handIndex,
                                handType: handType,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: OQuan(
                  index: 5,
                  soLuong: soLuongDa[5],
                  conDaTo: oQuanConDaTo[5],
                  isMoving: movingIndex == 5,
                  handIndex: handIndex,
                  handType: handType,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleODanTap(int index) async {
    AudioService().playEffect(SoundType.pack);
    bool canSelect =
        !isAnimating &&
        gameStarted &&
        !gameEnded &&
        soLuongDa[index] > 0 &&
        ((playerTurn && index >= 0 && index <= 4) ||
            (!playerTurn && index >= 6 && index <= 10));

    if (!canSelect || !playerTurn || gameEnded) {
      return;
    }

    safeSetState(() => selectedIndex = index);
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 300));

    if (gameEnded) {
      _pulseController.stop();
      _pulseController.reset();
      safeSetState(() => selectedIndex = null);
      return;
    }

    String? huong = await _chonHuong();

    _pulseController.stop();
    _pulseController.reset();
    safeSetState(() => selectedIndex = null);

    if (huong != null && !gameEnded) {
      bool toRight = huong == "right";
      if (!playerTurn) {
        toRight = !toRight;
      }
      await _raiQuan(index, toRight);
    }
  }

  Future<String?> _chonHuong() async {
    chonHuongDangMo = true;
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ChooseDirectionDialog(),
    );
    // khi dialog đóng (kể cả nhấn ra ngoài) thì set lại cờ
    chonHuongDangMo = false;
    return result;
  }

  Future<void> _raiQuan(int startIndex, bool toRight) async {
    if (gameEnded) return; // Stop if game ended
    _turnTimer?.cancel();
    safeSetState(() => isAnimating = true);
    int stones = soLuongDa[startIndex];
    soLuongDa[startIndex] = 0;
    int currentIndex = startIndex;
    while (stones > 0 && !gameEnded) {
      await Future.delayed(const Duration(milliseconds: 300));
      currentIndex = _nextIndex(currentIndex, toRight);
      safeSetState(() {
        movingIndex = currentIndex;
        handIndex = currentIndex;
        handType = "distribute";
        soLuongDa[currentIndex]++;
      });
      _stoneAnimController.forward().then((_) => _stoneAnimController.reset());
      await Future.delayed(const Duration(milliseconds: 200));
      safeSetState(() {
        handIndex = null; // Ẩn bàn tay sau 200ms
        handType = null;
      });
      stones--;
    }
    if (!gameEnded) {
      await _xuLyKetThuc(currentIndex, toRight);
    }
    safeSetState(() {
      movingIndex = null;
      isAnimating = false;
    });
    if (!gameEnded) {
      _kiemTraKetThuc();
    }
    // Trigger AI move if it's AI's turn and game hasn't ended
    if (!playerTurn && !isAnimating && !gameEnded) {
      _maybeAIDoMove();
    }
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
        await _raiQuan(next, toRight);
      } else {
        _doiLuot();
      }
    } else {
      int next2 = _nextIndex(next, toRight);
      if (soLuongDa[next2] > 0) {
        // ⚡ chỉ chặn ăn quan ở lượt đầu
        if (isFirstTurn && (next2 == 5 || next2 == 11)) {
          _doiLuot();
          isFirstTurn = false;
        } else {
          await _anQuan(next2, toRight);
          await _checkForCapture(next2, toRight);
          isFirstTurn = false; // sau lượt đầu cho ăn quan thoải mái
        }
      } else {
        _doiLuot();
        isFirstTurn = false; // sau lượt đầu thì bật luật ăn quan
      }
    }
  }

  Future<void> _checkForCapture(int pos, bool toRight) async {
    int next = _nextIndex(pos, toRight);
    if (soLuongDa[next] == 0) {
      int next2 = _nextIndex(next, toRight);
      if (soLuongDa[next2] > 0) {
        if (isFirstTurn) {
          // 🚫 lượt đầu không cho ăn quan
          _doiLuot();
          isFirstTurn = false;
        } else {
          await _anQuan(next2, toRight);
          await _checkForCapture(next2, toRight);
        }
      } else {
        _doiLuot();
        isFirstTurn = false;
      }
    } else {
      _doiLuot();
      isFirstTurn = false;
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

    safeSetState(() {
      handIndex = captureIndex; // Hiển thị bàn tay khi ăn
      handType = "capture";
      if (playerTurn) {
        scoreBottom += an;
      } else {
        scoreTop += an;
      }
      AudioService().playEffect(SoundType.pickUp);
    });
    await Future.delayed(const Duration(milliseconds: 400));
    safeSetState(() {
      handIndex = null; // Ẩn bàn tay sau 400ms
      handType = null;
    });
  }

  void _kiemTraKetThuc() {
    bool quanTraiHet =
        !oQuanConDaTo[5] && soLuongDa[5] == 0; // Human's mandarin square
    bool quanPhaiHet =
        !oQuanConDaTo[11] && soLuongDa[11] == 0; // AI's mandarin square

    // End game only if both mandarin squares are completely empty
    if (quanTraiHet && quanPhaiHet) {
      _ketThucDoAnQuan();
      return;
    }

    bool duoiHet = soLuongDa
        .sublist(0, 5)
        .every((e) => e == 0); // Human's folk squares empty
    bool trenHet = soLuongDa
        .sublist(6, 11)
        .every((e) => e == 0); // AI's folk squares empty

    safeSetState(() {
      // Handle case where both sides' folk squares are empty
      if (duoiHet && trenHet) {
        bool anyReplenished = false;

        // Replenish human side if possible
        if (scoreBottom > 0) {
          int soQuanHoi = scoreBottom >= 5 ? 5 : scoreBottom;
          scoreBottom -= soQuanHoi;
          int remaining = soQuanHoi;
          for (int i = 0; i <= 4; i++) {
            if (remaining > 0) {
              soLuongDa[i] = 1;
              remaining--;
              anyReplenished = true;
            } else {
              soLuongDa[i] = 0;
            }
          }
        }

        // Replenish AI side if possible
        if (scoreTop > 0) {
          int soQuanHoi = scoreTop >= 5 ? 5 : scoreTop;
          scoreTop -= soQuanHoi;
          int remaining = soQuanHoi;
          for (int i = 6; i <= 10; i++) {
            if (remaining > 0) {
              soLuongDa[i] = 1;
              remaining--;
              anyReplenished = true;
            } else {
              soLuongDa[i] = 0;
            }
          }
        }

        // Recheck after replenishing
        duoiHet = soLuongDa.sublist(0, 5).every((e) => e == 0);
        trenHet = soLuongDa.sublist(6, 11).every((e) => e == 0);

        // If no sides were replenished and both folk squares are still empty, collect mandarin squares and end
        if (duoiHet && trenHet && !anyReplenished) {
          scoreBottom += soLuongDa[5];
          if (oQuanConDaTo[5]) scoreBottom += 10;
          scoreTop += soLuongDa[11];
          if (oQuanConDaTo[11]) scoreTop += 10;

          soLuongDa[5] = 0;
          soLuongDa[11] = 0;
          oQuanConDaTo[5] = false;
          oQuanConDaTo[11] = false;

          _turnTimer?.cancel();
          _showKetThuc(
            scoreBottom > scoreTop
                ? KetThucGame.win
                : scoreTop > scoreBottom
                ? KetThucGame.lose
                : KetThucGame.draw,
          );
          return;
        }

        // If AI's turn after replenishing, trigger AI move
        if (!playerTurn && anyReplenished) {
          _triggerAIMove();
        }
        return;
      }

      // Handle individual side depletion
      if (duoiHet && scoreBottom > 0) {
        int soQuanHoi = scoreBottom >= 5 ? 5 : scoreBottom;
        scoreBottom -= soQuanHoi;
        int remaining = soQuanHoi;
        for (int i = 0; i <= 4; i++) {
          if (remaining > 0) {
            soLuongDa[i] = 1;
            remaining--;
          } else {
            soLuongDa[i] = 0;
          }
        }
        if (!playerTurn) {
          _triggerAIMove();
        }
      } else if (duoiHet) {
        _thuaDoHetQuan();
      }

      if (trenHet && scoreTop > 0) {
        int soQuanHoi = scoreTop >= 5 ? 5 : scoreTop;
        scoreTop -= soQuanHoi;
        int remaining = soQuanHoi;
        for (int i = 6; i <= 10; i++) {
          if (remaining > 0) {
            soLuongDa[i] = 1;
            remaining--;
          } else {
            soLuongDa[i] = 0;
          }
        }
        if (!playerTurn) {
          _triggerAIMove();
        }
      } else if (trenHet) {
        _thuaDoHetQuan();
      }
    });
  }

  // Placeholder for AI move logic
  void _triggerAIMove() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate AI thinking
    List<int> validMoves = [];
    for (int i = 6; i <= 10; i++) {
      if (soLuongDa[i] > 0) validMoves.add(i);
    }
    if (validMoves.isNotEmpty) {
      int aiIndex = validMoves[Random().nextInt(validMoves.length)];
      bool toRight = Random().nextBool();
      await _raiQuan(aiIndex, toRight);
    } else {
      _thuaDoHetQuan();
    }
  }

  void _ketThucDoAnQuan() {
    if (gameEnded) return; // Prevent multiple dialogs
    int remainingBottom = soLuongDa.sublist(0, 5).fold(0, (a, b) => a + b);
    int remainingTop = soLuongDa.sublist(6, 11).fold(0, (a, b) => a + b);
    _turnTimer?.cancel();
    scoreBottom += remainingBottom;
    scoreTop += remainingTop;
    _showKetThuc(
      scoreBottom > scoreTop
          ? KetThucGame.win
          : scoreTop > scoreBottom
          ? KetThucGame.lose
          : KetThucGame.draw,
    );
  }

  void _thuaDoHetQuan() {
    if (gameEnded) return; // Prevent multiple dialogs
    int tongConLai = soLuongDa.fold(0, (a, b) => a + b);
    soLuongDa = List.filled(12, 0);
    _turnTimer?.cancel();
    if (playerTurn) {
      scoreTop += tongConLai;
      _showKetThuc(KetThucGame.lose);
    } else {
      scoreBottom += tongConLai;
      _showKetThuc(KetThucGame.win);
    }
  }

  void _showKetThuc(KetThucGame result) {
    if (isDialogOpen) return;
    if (gameEnded) return; // Already showing end dialog
    gameEnded = true; // Set flag to prevent multiple dialogs
    // Đóng dialog chọn hướng nếu đang mở
    if (chonHuongDangMo) {
      chonHuongDangMo = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
    isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EndGameDialog(
        result: result,
        scoreBottom: scoreBottom,
        scoreTop: scoreTop,
        onExit: () {
          Navigator.pop(context); // đóng dialog
          Navigator.pop(context); // quay lại màn trước
          AudioService().playMenu();
          isDialogOpen = false;
        },
        onReplay: () {
          Navigator.pop(context);
          gameEnded = false; // Reset flag
          // AudioService().playBackground();
          _startGame();
          isDialogOpen = false;
        },
      ),
    );
  }

  // Enhanced AI Logic with better minimax and evaluation
  void _maybeAIDoMove() {
    if (!mounted || playerTurn || isAnimating || gameEnded) {
      return; // Add gameEnded check
    }
    Future.delayed(Duration(milliseconds: aiThinkingTime), () async {
      if (!mounted || playerTurn || isAnimating || gameEnded) {
        return; // Double check
      }
      _turnTimer?.cancel();
      final state = GameState.fromLists(
        soLuongDa,
        oQuanConDaTo,
        scoreBottom,
        scoreTop,
        playerTurn,
      );
      final aiMove = _findBestMove(state, aiDepth);
      if (aiMove != null && !gameEnded) {
        // Check gameEnded before making move
        bool toRight = aiMove.toRight;
        // AI (người trên) - đảo hướng như trong 1vs1
        if (!playerTurn) {
          toRight = !toRight;
        }
        await _raiQuan(aiMove.startIndex, toRight);
      } else if (!gameEnded) {
        _xuLyHetGio();
      }
    });
  }

  // Enhanced move finding with iterative deepening and better move ordering
  MoveDecision? _findBestMove(GameState state, int depth) {
    final moves = state.getLegalMoves();
    if (moves.isEmpty) return null;

    // Easy difficulty: controlled randomness
    if (currentDifficulty == AIDifficulty.easy) {
      moves.shuffle(Random());
      if (Random().nextDouble() < 0.7) {
        // 70% random moves
        return moves.first;
      }
    }

    // Iterative deepening for better performance and move ordering
    MoveDecision? bestMove;
    Map<MoveDecision, int> moveHistory = {};

    // Start with shallow search for move ordering
    for (int currentDepth = 1; currentDepth <= depth; currentDepth += 2) {
      final result = _iterativeSearch(state, currentDepth, moveHistory);
      if (result != null) {
        bestMove = result.move;
        moveHistory[result.move] =
            (moveHistory[result.move] ?? 0) + result.score;
      }

      // For hard mode, use time-based cutoff for efficiency
      if (currentDifficulty == AIDifficulty.hard && currentDepth >= 8) {
        break; // Good enough depth reached
      }
    }

    return bestMove ?? moves.first;
  }

  // Iterative search with enhanced pruning
  SearchResult? _iterativeSearch(
    GameState state,
    int depth,
    Map<MoveDecision, int> history,
  ) {
    final moves = state.getLegalMoves();
    if (moves.isEmpty) return null;

    // Enhanced move ordering with history heuristic
    List<MoveScore> moveScores = [];
    for (final move in moves) {
      final nxt = state.clone();
      nxt.applyMove(move.startIndex, move.toRight);

      int score = nxt.evaluate(currentDifficulty);

      // Add history bonus for good moves from previous iterations
      score += (history[move] ?? 0) * 10;

      // Add killer move heuristic (moves that caused cutoffs)
      if (_isKillerMove(move)) {
        score += 1000;
      }

      moveScores.add(MoveScore(move, score));
    }

    // Sort moves by score (best first for better pruning)
    moveScores.sort((a, b) => b.score.compareTo(a.score));

    int alpha = -999999;
    int beta = 999999;
    MoveDecision? best;
    int bestScore = -999999;

    for (final moveScore in moveScores) {
      final nxt = state.clone();
      nxt.applyMove(moveScore.move.startIndex, moveScore.move.toRight);

      int val = _enhancedMinimax(nxt, depth - 1, alpha, beta, false, 0);

      if (val > bestScore) {
        bestScore = val;
        best = moveScore.move;
      }

      alpha = max(alpha, val);
      if (beta <= alpha) {
        _addKillerMove(moveScore.move); // Store killer move
        break;
      }
    }

    return best != null ? SearchResult(best, bestScore) : null;
  }

  // Enhanced minimax with multiple optimizations
  int _enhancedMinimax(
    GameState state,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
    int ply,
  ) {
    // Terminal node check
    if (state.isTerminal()) {
      return state.getTerminalValue();
    }

    // Depth limit with selective extension
    if (depth <= 0) {
      if (currentDifficulty == AIDifficulty.hard) {
        // Extend search on critical positions
        if (state.hasCaptureOpportunity() || state.isEndgamePosition()) {
          return _enhancedQuiescence(state, alpha, beta, maximizing, 6);
        }
      }
      return state.evaluate(currentDifficulty);
    }

    // Transposition table lookup (for repeated positions)
    final stateKey = state.getStateKey();
    final cachedResult = _transpositionTable[stateKey];
    if (cachedResult != null && cachedResult.depth >= depth) {
      if (cachedResult.flag == TTFlag.exact) return cachedResult.value;
      if (cachedResult.flag == TTFlag.lowerBound &&
          cachedResult.value >= beta) {
        return cachedResult.value;
      }
      if (cachedResult.flag == TTFlag.upperBound &&
          cachedResult.value <= alpha) {
        return cachedResult.value;
      }
    }

    final moves = state.getLegalMoves();
    if (moves.isEmpty) return state.evaluate(currentDifficulty);

    // Enhanced move ordering with multiple heuristics
    List<MoveScore> orderedMoves = _orderMoves(state, moves, ply);

    int originalAlpha = alpha;
    int bestValue = maximizing ? -999999 : 999999;
    MoveDecision? bestMove;

    for (final moveScore in orderedMoves) {
      final nxt = state.clone();
      nxt.applyMove(moveScore.move.startIndex, moveScore.move.toRight);

      int eval;

      // Late Move Reduction (LMR) for better performance
      if (depth > 3 &&
          orderedMoves.indexOf(moveScore) > 3 &&
          !moveScore.move.isCapture(state)) {
        // Search with reduced depth first
        eval = _enhancedMinimax(
          nxt,
          depth - 2,
          alpha,
          beta,
          !maximizing,
          ply + 1,
        );

        // If it's still good, research with full depth
        if ((maximizing && eval > alpha) || (!maximizing && eval < beta)) {
          eval = _enhancedMinimax(
            nxt,
            depth - 1,
            alpha,
            beta,
            !maximizing,
            ply + 1,
          );
        }
      } else {
        eval = _enhancedMinimax(
          nxt,
          depth - 1,
          alpha,
          beta,
          !maximizing,
          ply + 1,
        );
      }

      if (maximizing) {
        if (eval > bestValue) {
          bestValue = eval;
          bestMove = moveScore.move;
        }
        alpha = max(alpha, eval);
      } else {
        if (eval < bestValue) {
          bestValue = eval;
          bestMove = moveScore.move;
        }
        beta = min(beta, eval);
      }

      if (beta <= alpha) {
        _addKillerMove(moveScore.move);
        break; // Alpha-beta cutoff
      }
    }

    // Store in transposition table
    TTFlag flag = TTFlag.exact;
    if (bestValue <= originalAlpha) {
      flag = TTFlag.upperBound;
    } else if (bestValue >= beta)
      flag = TTFlag.lowerBound;

    _transpositionTable[stateKey] = TranspositionEntry(
      bestValue,
      depth,
      flag,
      bestMove,
    );

    return bestValue;
  }

  // Enhanced quiescence search with better pruning
  int _enhancedQuiescence(
    GameState state,
    int alpha,
    int beta,
    bool maximizing,
    int qsDepth,
  ) {
    int standPat = state.evaluate(currentDifficulty);

    if (qsDepth <= 0) return standPat;

    if (maximizing) {
      if (standPat >= beta) return beta;
      alpha = max(alpha, standPat);
    } else {
      if (standPat <= alpha) return alpha;
      beta = min(beta, standPat);
    }

    // Only search high-value captures and critical moves
    final moves = state.getCriticalMovesOnly();
    if (moves.isEmpty) return standPat;

    List<MoveScore> sortedMoves = [];
    for (final move in moves) {
      final nxt = state.clone();
      nxt.applyMove(move.startIndex, move.toRight);
      int score = nxt.evaluate(currentDifficulty) - standPat; // Delta pruning
      if (score > -200) {
        // Only consider moves that don't lose too much
        sortedMoves.add(MoveScore(move, score));
      }
    }

    sortedMoves.sort(
      (a, b) =>
          maximizing ? b.score.compareTo(a.score) : a.score.compareTo(b.score),
    );

    int bestValue = standPat;
    for (final moveScore in sortedMoves.take(5)) {
      // Limit search width
      final nxt = state.clone();
      nxt.applyMove(moveScore.move.startIndex, moveScore.move.toRight);

      int eval = _enhancedQuiescence(
        nxt,
        alpha,
        beta,
        !maximizing,
        qsDepth - 1,
      );

      if (maximizing) {
        bestValue = max(bestValue, eval);
        alpha = max(alpha, eval);
      } else {
        bestValue = min(bestValue, eval);
        beta = min(beta, eval);
      }

      if (beta <= alpha) break;
    }

    return bestValue;
  }

  // Enhanced move ordering with multiple heuristics
  List<MoveScore> _orderMoves(
    GameState state,
    List<MoveDecision> moves,
    int ply,
  ) {
    List<MoveScore> scored = [];

    for (final move in moves) {
      int score = 0;
      final nxt = state.clone();
      nxt.applyMove(move.startIndex, move.toRight);

      // Primary: position evaluation
      score += nxt.evaluate(currentDifficulty) * 10;

      // Capture moves get highest priority
      if (move.isCapture(state)) {
        score += 10000 + move.getCaptureValue(state);
      }

      // Killer moves from previous searches
      if (_isKillerMove(move)) {
        score += 5000;
      }

      // History heuristic (moves that were good in similar positions)
      score += (_historyTable[move.startIndex] ?? 0);

      // Positional bonuses
      if (move.startIndex >= 6 && move.startIndex <= 10) {
        // AI moves
        // Prefer moves closer to opponent's mandarin
        if (move.startIndex == 6 || move.startIndex == 10) score += 100;

        // Prefer moves that maintain mobility
        if (state.stones[move.startIndex] >= 3) score += 50;
      }

      scored.add(MoveScore(move, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored;
  }

  void _addKillerMove(MoveDecision move) {
    final ply = 0; // Simplified - in real implementation track ply
    if (_killerMoves[ply][0] != move) {
      _killerMoves[ply][1] = _killerMoves[ply][0];
      _killerMoves[ply][0] = move;
    }
  }

  bool _isKillerMove(MoveDecision move) {
    final ply = 0; // Simplified
    return _killerMoves[ply].contains(move);
  }

  // Clear tables periodically to avoid memory issues
  void _clearAITables() {
    if (_transpositionTable.length > 10000) {
      _transpositionTable.clear();
    }
    if (_historyTable.length > 1000) {
      _historyTable.clear();
    }
  }
}

class MoveDecision {
  final int startIndex;
  final bool toRight;
  MoveDecision(this.startIndex, this.toRight);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoveDecision &&
          runtimeType == other.runtimeType &&
          startIndex == other.startIndex &&
          toRight == other.toRight;

  @override
  int get hashCode => startIndex.hashCode ^ toRight.hashCode;
}

class MoveScore {
  final MoveDecision move;
  final int score;
  MoveScore(this.move, this.score);
}

class GameState {
  List<int> stones;
  List<bool> oQuan;
  int scoreBottom;
  int scoreTop;
  bool playerTurn;

  GameState({
    required this.stones,
    required this.oQuan,
    required this.scoreBottom,
    required this.scoreTop,
    required this.playerTurn,
  });

  factory GameState.fromLists(
    List<int> s,
    List<bool> oq,
    int sb,
    int st,
    bool pt,
  ) {
    return GameState(
      stones: List<int>.from(s),
      oQuan: List<bool>.from(oq),
      scoreBottom: sb,
      scoreTop: st,
      playerTurn: pt,
    );
  }

  GameState clone() {
    return GameState(
      stones: List<int>.from(stones),
      oQuan: List<bool>.from(oQuan),
      scoreBottom: scoreBottom,
      scoreTop: scoreTop,
      playerTurn: playerTurn,
    );
  }

  String getStateKey() {
    return '${stones.join(',')}_${oQuan.join(',')}_${scoreBottom}_${scoreTop}_$playerTurn';
  }

  bool isEndgamePosition() {
    int totalStones =
        stones.sublist(0, 5).fold(0, (a, b) => a + b) +
        stones.sublist(6, 11).fold(0, (a, b) => a + b);
    return totalStones <= 15 || scoreBottom + scoreTop >= 40;
  }

  List<MoveDecision> getCriticalMovesOnly() {
    List<MoveDecision> critical = [];
    final allMoves = getLegalMoves();

    for (final move in allMoves) {
      if (move.isCapture(this) ||
          move.isMandarinThreat(this) ||
          move.isDefensive(this)) {
        critical.add(move);
      }
    }

    return critical.isEmpty ? allMoves.take(3).toList() : critical;
  }

  bool isEmpty(int idx) {
    return stones[idx] == 0 && (idx != 5 && idx != 11 || !oQuan[idx]);
  }

  bool hasCapturable(int idx) {
    return stones[idx] > 0 || (idx == 5 || idx == 11 && oQuan[idx]);
  }

  List<MoveDecision> getLegalMoves() {
    List<MoveDecision> moves = [];
    if (playerTurn) {
      // Human player moves (bottom)
      for (int i = 0; i <= 4; i++) {
        if (stones[i] > 0) {
          moves.add(MoveDecision(i, true));
          moves.add(MoveDecision(i, false));
        }
      }
    } else {
      // AI player moves (top)
      for (int i = 6; i <= 10; i++) {
        if (stones[i] > 0) {
          moves.add(MoveDecision(i, true));
          moves.add(MoveDecision(i, false));
        }
      }
    }
    return moves;
  }

  // Get only moves that lead to captures (for quiescence)
  List<MoveDecision> getCaptureMovesOnly() {
    List<MoveDecision> captureMoves = [];
    final allMoves = getLegalMoves();
    for (final move in allMoves) {
      final temp = clone();
      temp.applyMove(move.startIndex, move.toRight);
      if ((temp.scoreTop != scoreTop) || (temp.scoreBottom != scoreBottom)) {
        captureMoves.add(move);
      }
    }
    return captureMoves;
  }

  // Check if state has immediate capture opportunity
  bool hasCaptureOpportunity() {
    return getCaptureMovesOnly().isNotEmpty;
  }

  int _nextIndexSim(int current, bool toRight) {
    return toRight
        ? (current + 1) % stones.length
        : (current - 1 + stones.length) % stones.length;
  }

  void applyMove(int startIndex, bool toRight) {
    if (stones[startIndex] == 0) return;
    bool currentPlayer = playerTurn;
    int s = stones[startIndex];
    stones[startIndex] = 0;
    int cur = startIndex;
    // Distribute stones
    while (s > 0) {
      cur = _nextIndexSim(cur, toRight);
      stones[cur]++;
      s--;
    }
    // Handle end-of-turn logic
    _handleEndTurnLogic(cur, toRight, currentPlayer);
  }

  void _handleEndTurnLogic(int lastIndex, bool toRight, bool currentPlayer) {
    int next = _nextIndexSim(lastIndex, toRight);

    if (!isEmpty(next)) {
      if (next != 5 && next != 11) {
        // Continue distributing
        int s2 = stones[next];
        stones[next] = 0;
        int c = next;
        while (s2 > 0) {
          c = _nextIndexSim(c, toRight);
          stones[c]++;
          s2--;
        }
        _handleEndTurnLogic(c, toRight, currentPlayer);
      } else {
        playerTurn = !playerTurn;
      }
    } else {
      int next2 = _nextIndexSim(next, toRight);
      if (hasCapturable(next2)) {
        _capture(next2, currentPlayer);
        _checkForMoreCaptures(next2, toRight, currentPlayer);
      } else {
        playerTurn = !playerTurn;
      }
    }
  }

  void _checkForMoreCaptures(int pos, bool toRight, bool currentPlayer) {
    int next = _nextIndexSim(pos, toRight);
    if (isEmpty(next)) {
      int next2 = _nextIndexSim(next, toRight);
      if (hasCapturable(next2)) {
        _capture(next2, currentPlayer);
        _checkForMoreCaptures(next2, toRight, currentPlayer);
      } else {
        playerTurn = !playerTurn;
      }
    } else {
      playerTurn = !playerTurn;
    }
  }

  void _capture(int captureIndex, bool currentPlayer) {
    int captured = stones[captureIndex];
    stones[captureIndex] = 0;
    if (captureIndex == 5 || captureIndex == 11) {
      if (oQuan[captureIndex]) {
        captured += 10;
        oQuan[captureIndex] = false;
      }
    }
    if (currentPlayer) {
      scoreBottom += captured;
    } else {
      scoreTop += captured;
    }
  }

  bool isTerminal() {
    // Check if both mandarin squares are empty
    bool leftEmpty = (!oQuan[5] && stones[5] == 0);
    bool rightEmpty = (!oQuan[11] && stones[11] == 0);
    if (leftEmpty && rightEmpty) return true;
    // Check if one side has no moves and cannot buy
    bool bottomEmpty = stones.sublist(0, 5).every((e) => e == 0);
    bool topEmpty = stones.sublist(6, 11).every((e) => e == 0);
    if (bottomEmpty && scoreBottom < 5) return true;
    if (topEmpty && scoreTop < 5) return true;
    return false;
  }

  int getTerminalValue() {
    int remBottom = stones.sublist(0, 5).fold(0, (a, b) => a + b);
    int remTop = stones.sublist(6, 11).fold(0, (a, b) => a + b);
    int finalBottom = scoreBottom + remBottom;
    int finalTop = scoreTop + remTop;
    // Return value from AI perspective (AI is top)
    return (finalTop - finalBottom) * 10000;
  }

  // Enhanced evaluation with endgame-specific logic
  int evaluate(AIDifficulty difficulty) {
    if (isEndgamePosition()) {
      return _evaluateEndgame();
    }

    int remBottom = stones.sublist(0, 5).fold(0, (a, b) => a + b);
    int remTop = stones.sublist(6, 11).fold(0, (a, b) => a + b);
    int scoreDiff = (scoreTop - scoreBottom) * 100;
    int stonesDiff = (remTop - remBottom) * 15;
    int mandarin5 = (oQuan[5] ? 10 : 0) + stones[5];
    int mandarin11 = (oQuan[11] ? 10 : 0) + stones[11];
    int mandarinDiff = (mandarin11 - mandarin5) * 50;

    // Mobility evaluation
    int mobilityTop = 0;
    int mobilityBottom = 0;
    for (int i = 6; i <= 10; i++) {
      if (stones[i] > 0) {
        mobilityTop += stones[i];
      }
    }
    for (int i = 0; i <= 4; i++) {
      if (stones[i] > 0) mobilityBottom += stones[i];
    }
    int mobilityDiff = (mobilityTop - mobilityBottom) * 25;

    switch (difficulty) {
      case AIDifficulty.easy:
        return scoreDiff + stonesDiff + Random().nextInt(61) - 30;
      case AIDifficulty.normal:
        return scoreDiff +
            stonesDiff +
            mandarinDiff +
            mobilityDiff +
            _evaluateThreats();
      case AIDifficulty.hard:
        // Advanced strategic evaluation
        int positionalValue = 0;
        for (int i = 6; i <= 10; i++) {
          if (stones[i] > 0) {
            int captureValue = _evaluateCaptureOpportunity(i);
            positionalValue += captureValue * 2;
            if (stones[i] > 5) {
              positionalValue -= (stones[i] - 5) * 5;
            }
            if (i == 6 || i == 10) positionalValue += 15;
          }
        }

        int defensiveValue = 0;
        for (int i = 0; i <= 4; i++) {
          if (stones[i] > 0) {
            int vulnerability = _evaluateVulnerability(i);
            defensiveValue -= vulnerability * 2;
          }
        }

        int controlValue = 0;
        if (stones[4] > 0) controlValue -= 20;
        if (stones[6] > 0) controlValue += 30;
        if (stones[0] > 0) controlValue -= 20;
        if (stones[10] > 0) controlValue += 30;

        int threatValue = _evaluateThreats() * 2;
        int totalStones = remTop + remBottom;
        int endgameFactor = totalStones < 20 ? 50 : 0;

        if (scoreBottom < 5 && remBottom == 0) {
          threatValue += 100;
        }
        if (scoreTop >= 5 && remTop == 0) threatValue += 50;

        return scoreDiff +
            stonesDiff +
            mandarinDiff +
            positionalValue +
            defensiveValue +
            controlValue +
            mobilityDiff +
            threatValue +
            endgameFactor;
    }
  }

  int _evaluateEndgame() {
    int score = 0;

    // In endgame, prioritize score difference even more
    score += (scoreTop - scoreBottom) * 200;

    // Control of remaining stones is critical
    int remainingTop = stones.sublist(6, 11).fold(0, (a, b) => a + b);
    int remainingBottom = stones.sublist(0, 5).fold(0, (a, b) => a + b);
    score += (remainingTop - remainingBottom) * 50;

    // Mandarin control is decisive in endgame
    if (oQuan[11]) score += 150; // AI's mandarin
    if (oQuan[5]) score -= 150; // Opponent's mandarin

    // Tempo advantage (having the move in endgame)
    if (!playerTurn) score += 25; // AI's turn is good

    return score;
  }

  int _evaluateCaptureOpportunity(int position) {
    int value = 0;
    for (bool toRight in [true, false]) {
      int simulatePos = position;
      int remainingStones = stones[position];
      while (remainingStones > 0) {
        simulatePos = _nextIndexSim(simulatePos, toRight);
        remainingStones--;
      }
      int next = _nextIndexSim(simulatePos, toRight);
      if (isEmpty(next)) {
        int next2 = _nextIndexSim(next, toRight);
        if (hasCapturable(next2)) {
          value += stones[next2] * 5;
          if (next2 == 5 || next2 == 11) {
            if (oQuan[next2]) value += 100;
          }
          int chainNext = _nextIndexSim(next2, toRight);
          if (isEmpty(chainNext)) {
            int chainNext2 = _nextIndexSim(chainNext, toRight);
            if (hasCapturable(chainNext2)) value += stones[chainNext2] * 3;
          }
        }
      }
    }
    return value;
  }

  int _evaluateVulnerability(int position) {
    int vulnerability = 0;
    if (stones[position] > 4) {
      vulnerability += (stones[position] - 4) * 4;
    }
    int left = _nextIndexSim(position, false);
    int right = _nextIndexSim(position, true);
    if (isEmpty(left) || isEmpty(right)) vulnerability += 10;
    return vulnerability;
  }

  int _evaluateThreats() {
    int threats = 0;
    for (int i = 6; i <= 10; i++) {
      threats += _evaluateCaptureOpportunity(i);
    }
    for (int i = 0; i <= 4; i++) {
      threats -= _evaluateCaptureOpportunity(i);
    }
    if (oQuan[5] && _isMandarinThreatened(5)) {
      threats -= 80;
    }
    if (oQuan[11] && _isMandarinThreatened(11)) {
      threats += 80;
    }
    return threats;
  }

  bool _isMandarinThreatened(int mandarinIdx) {
    final opponentStart = (mandarinIdx == 5) ? 0 : 6;
    final opponentEnd = (mandarinIdx == 5) ? 4 : 10;
    for (int i = opponentStart; i <= opponentEnd; i++) {
      if (stones[i] > 0) {
        for (bool toRight in [true, false]) {
          int simPos = i;
          int rem = stones[i];
          while (rem > 0) {
            simPos = _nextIndexSim(simPos, toRight);
            rem--;
          }
          int next = _nextIndexSim(simPos, toRight);
          if (isEmpty(next) && _nextIndexSim(next, toRight) == mandarinIdx) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

// Enhanced MoveDecision with tactical analysis
extension MoveDecisionEnhancements on MoveDecision {
  bool isCapture(GameState state) {
    final temp = state.clone();
    int oldScoreTop = temp.scoreTop;
    int oldScoreBottom = temp.scoreBottom;
    temp.applyMove(startIndex, toRight);
    return temp.scoreTop != oldScoreTop || temp.scoreBottom != oldScoreBottom;
  }

  int getCaptureValue(GameState state) {
    final temp = state.clone();
    int oldScoreTop = temp.scoreTop;
    int oldScoreBottom = temp.scoreBottom;
    temp.applyMove(startIndex, toRight);
    return (temp.scoreTop - oldScoreTop) + (temp.scoreBottom - oldScoreBottom);
  }

  bool isMandarinThreat(GameState state) {
    final temp = state.clone();
    temp.applyMove(startIndex, toRight);
    return temp._isMandarinThreatened(5) && state.oQuan[5];
  }

  bool isDefensive(GameState state) {
    if (startIndex < 6) return false;
    return state.stones[startIndex] >= 4;
  }
}

// Supporting classes
class SearchResult {
  final MoveDecision move;
  final int score;
  SearchResult(this.move, this.score);
}

class TranspositionEntry {
  final int value;
  final int depth;
  final TTFlag flag;
  final MoveDecision? bestMove;

  TranspositionEntry(this.value, this.depth, this.flag, this.bestMove);
}

enum TTFlag { exact, lowerBound, upperBound }
