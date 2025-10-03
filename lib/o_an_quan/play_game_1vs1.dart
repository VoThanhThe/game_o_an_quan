import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

import 'service/audio_service.dart';
import 'widgets/choose_direction_dialog.dart';
import 'widgets/end_game_dialog.dart';
import 'widgets/footer.dart';
import 'widgets/header.dart';
import 'widgets/o_dan.dart';
import 'widgets/o_quan.dart';

class PlayGame1vs1 extends StatefulWidget {
  const PlayGame1vs1({super.key});

  @override
  State<PlayGame1vs1> createState() => _PlayGame1vs1State();
}

class _PlayGame1vs1State extends State<PlayGame1vs1>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // mặc định: mỗi ô dân có 5 quân, ô quan: 0 sỏi (có 1 đá to = 10 điểm)
  List<int> soLuongDa = [5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 0];
  List<bool> oQuanConDaTo = List.generate(12, (i) => i == 5 || i == 11);

  int? movingIndex;
  int? selectedIndex;
  bool isAnimating = false;
  bool playerTurn = true; // true = người dưới, false = người trên
  int scoreBottom = 0;
  int scoreTop = 0;
  Timer? _turnTimer;
  int timeLeft = 25; // mặc định 25 giây
  bool chonHuongDangMo = false;
  bool isFirstTurn = true; // chặn ăn quan ở lượt đầu
  int? handIndex; // Ô đang hiển thị bàn tay
  String? handType; // "distribute" hoặc "capture"
  bool isDialogOpen = false; // Flag to track if EndGameDialog is open

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _stoneAnimController;
  late Animation<double> _stoneAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    AudioService().playBackground();
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
    _startTimer(); // bắt đầu timer từ đầu
  }

  @override
  void dispose() {
    AudioService().stopBackground();
    WidgetsBinding.instance.removeObserver(this);
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

  // Lắng nghe thay đổi trạng thái App khi app pause
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Người dùng nhấn Home hoặc chuyển app
      _turnTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // Quay lại app tiếp tục đếm thời gian
      _resumeTimer();
    }
  }

  /// Tiếp tục đếm từ `timeLeft` hiện tại
  void _resumeTimer() {
    if (timeLeft <= 0) return;

    _turnTimer?.cancel();
    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  /// Bắt đầu đếm ngược cho người chơi hiện tại
  void _startTimer() {
    _turnTimer?.cancel();
    safeSetState(() => timeLeft = 25);

    _turnTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
    if (playerTurn) {
      _showKetThuc(KetThucGame.lose);
    } else {
      _showKetThuc(KetThucGame.win);
    }
  }

  /// Hàm đổi lượt
  void _doiLuot() {
    safeSetState(() => playerTurn = !playerTurn);
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
                name: "Người trên",
                scoreTop: scoreTop,
                playerTurn: playerTurn,
                timeLeft: timeLeft,
              ),
              Expanded(child: _buildBanCo()),
              GameFooter(scoreBottom: scoreBottom, playerTurn: playerTurn),
            ],
          ),
        ),
      ),
    );
  }

  /// Bàn cờ
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
    safeSetState(() => selectedIndex = index);
    _pulseController.repeat(reverse: true);

    await Future.delayed(const Duration(milliseconds: 300));
    String? huong = await _chonHuong();

    _pulseController.stop();
    _pulseController.reset();
    safeSetState(() => selectedIndex = null);

    if (huong != null) {
      bool toRight = huong == "right";
      if (!playerTurn) toRight = !toRight; // đảo hướng cho người trên
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

    chonHuongDangMo = false;
    return result;
  }

  Future<void> _raiQuan(int startIndex, bool toRight) async {
    _turnTimer?.cancel(); // tạm dừng khi đang đi nước
    safeSetState(() => isAnimating = true);

    int stones = soLuongDa[startIndex];
    soLuongDa[startIndex] = 0;
    int currentIndex = startIndex;

    while (stones > 0) {
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

    await _xuLyKetThuc(currentIndex, toRight);
    safeSetState(() {
      movingIndex = null;
      isAnimating = false;
    });

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
        isFirstTurn = false;
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
        !oQuanConDaTo[5] &&
        soLuongDa[5] == 0; // Bottom player's mandarin square
    bool quanPhaiHet =
        !oQuanConDaTo[11] && soLuongDa[11] == 0; // Top player's mandarin square

    // End game only if both mandarin squares are completely empty
    if (quanTraiHet && quanPhaiHet) {
      _ketThucDoAnQuan();
      return;
    }

    bool duoiHet = soLuongDa
        .sublist(0, 5)
        .every((e) => e == 0); // Bottom player's folk squares empty
    bool trenHet = soLuongDa
        .sublist(6, 11)
        .every((e) => e == 0); // Top player's folk squares empty

    safeSetState(() {
      // Handle case where both sides' folk squares are empty
      if (duoiHet && trenHet) {
        bool anyReplenished = false;

        // Replenish bottom player if possible
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

        // Replenish top player if possible
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
      } else if (duoiHet) {
        _thuaDoHetQuan();
        return;
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
      } else if (trenHet) {
        _thuaDoHetQuan();
        return;
      }
    });
  }

  void _ketThucDoAnQuan() {
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
    // thu quân về ô quan
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
          Navigator.pop(context); // đóng dialog
          safeSetState(() {
            soLuongDa = [5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5, 0];
            oQuanConDaTo = List.generate(12, (i) => i == 5 || i == 11);
            scoreBottom = 0;
            scoreTop = 0;
            playerTurn = true;
            isFirstTurn = true;
            isDialogOpen = false;
          });
          AudioService().playBackground();
          _startTimer();
        },
      ),
    );
  }
}
