import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundType { background, menu, win, lose, draw, pickUp, pack }

class AudioService with WidgetsBindingObserver {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;

  AudioService._internal() {
    WidgetsBinding.instance.addObserver(this);
    _loadSoundSetting();
  }

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _menuPlayer = AudioPlayer();
  bool _isBackgroundPlaying = false;
  bool _isMenuPlaying = false;
  bool _soundEnabled = true;

  final Map<SoundType, String> _sounds = {
    SoundType.background: "assets/audios/beo_dat_may_troi.mp3",
    SoundType.menu: "assets/audios/menu.mp3",
    SoundType.win: "assets/audios/win.mp3",
    SoundType.lose: "assets/audios/lose.mp3",
    SoundType.draw: "assets/audios/draw.mp3",
    SoundType.pickUp: "assets/audios/pick_up.mp3",
    SoundType.pack: "assets/audios/pack.mp3",
  };

  Future<void> _loadSoundSetting() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
  }

  Future<void> enableSound() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = true;
    await prefs.setBool('soundEnabled', true);
    if (_isBackgroundPlaying) {
      await resumeBackground();
    }
    if (_isMenuPlaying) {
      await resumeMenu();
    }
  }

  Future<void> disableSound() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = false;
    await prefs.setBool('soundEnabled', false);
    await pauseBackground();
    await pauseMenu();
  }

  Future<void> playBackground() async {
    if (!_soundEnabled) return;
    try {
      await stopMenu();
      await _bgPlayer.setAsset(_sounds[SoundType.background]!);
      await _bgPlayer.setLoopMode(LoopMode.one);
      await _bgPlayer.play();
      _isBackgroundPlaying = true;
    } catch (e) {
      debugPrint("Lỗi phát nhạc nền: $e");
    }
  }

  Future<void> pauseBackground() async {
    if (_bgPlayer.playing) {
      await _bgPlayer.pause();
    }
  }

  Future<void> resumeBackground() async {
    if (_soundEnabled && _isBackgroundPlaying && !_bgPlayer.playing) {
      await _bgPlayer.play();
    }
  }

  Future<void> stopBackground() async {
    await _bgPlayer.stop();
    _isBackgroundPlaying = false;
  }

  Future<void> playMenu() async {
    if (!_soundEnabled) return;
    try {
      await stopBackground();
      await _menuPlayer.setAsset(_sounds[SoundType.menu]!);
      await _menuPlayer.setLoopMode(LoopMode.one);
      await _menuPlayer.play();
      _isMenuPlaying = true;
    } catch (e) {
      debugPrint("Lỗi phát nhạc menu: $e");
    }
  }

  Future<void> pauseMenu() async {
    if (_menuPlayer.playing) {
      await _menuPlayer.pause();
    }
  }

  Future<void> resumeMenu() async {
    if (_soundEnabled && _isMenuPlaying && !_menuPlayer.playing) {
      await _menuPlayer.play();
    }
  }

  Future<void> stopMenu() async {
    await _menuPlayer.stop();
    _isMenuPlaying = false;
  }

  Future<void> playEffect(SoundType type) async {
    if (!_soundEnabled ||
        type == SoundType.background ||
        type == SoundType.menu) {
      return;
    }
    try {
      final player = AudioPlayer();
      await player.setAsset(_sounds[type]!);
      await player.play();
      player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          player.dispose();
        }
      });
    } catch (e) {
      debugPrint("Lỗi phát hiệu ứng: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      pauseBackground();
      pauseMenu();
    } else if (state == AppLifecycleState.resumed) {
      resumeBackground();
      resumeMenu();
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _bgPlayer.dispose();
    await _menuPlayer.dispose();
  }
}
