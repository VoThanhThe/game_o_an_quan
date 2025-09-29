import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import 'service/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool _soundEnabled = true;
  double _volume = 0.5;
  bool _vibrationEnabled = true;
  bool _animationsEnabled = true;
  String _bigStone = 'big_stone_1.png';
  String _smallStone = 'small_stone_1.png';
  String _board = 'gradient_1';
  String _background = 'gradient_1';
  String _difficulty = 'medium';
  String _language = 'vi';

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> bigStoneOptions = [
    'big_stone_1.png',
    'big_stone_2.png',
    'big_stone_3.png',
    'big_stone_4.png',
  ];
  final List<String> smallStoneOptions = [
    'small_stone_1.png',
    'small_stone_2.png',
    'small_stone_3.png',
    'small_stone_4.png',
  ];
  final List<String> boardOptions = [
    'gradient_1',
    'gradient_2',
    'board_1.png',
    'board_2.png',
    'board_3.png',
    'wooden_board.png',
  ];
  final List<String> backgroundOptions = [
    'gradient_1',
    'gradient_2',
    'gradient_3',
    'gradient_4',
    'nature_1',
    'temple_bg',
  ];
  final List<String> difficultyOptions = ['easy', 'medium', 'hard', 'expert'];
  final List<String> languageOptions = ['vi', 'en'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _volume = prefs.getDouble('volume') ?? 0.5;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _animationsEnabled = prefs.getBool('animationsEnabled') ?? true;
      _bigStone = prefs.getString('bigStone') ?? 'big_stone_1.png';
      _smallStone = prefs.getString('smallStone') ?? 'small_stone_1.png';
      _board = prefs.getString('board') ?? 'gradient_1';
      _background = prefs.getString('background') ?? 'gradient_1';
      _difficulty = prefs.getString('difficulty') ?? 'medium';
      _language = prefs.getString('language') ?? 'vi';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('vibrationEnabled', _vibrationEnabled);
    await prefs.setBool('animationsEnabled', _animationsEnabled);
    await prefs.setString('bigStone', _bigStone);
    await prefs.setString('smallStone', _smallStone);
    await prefs.setString('board', _board);
    await prefs.setString('background', _background);
    await prefs.setString('difficulty', _difficulty);
    await prefs.setString('language', _language);
  }

  void _resetToDefaults() async {
    HapticFeedback.mediumImpact();

    showDialog(
      context: context,
      builder: (context) => _buildConfirmDialog(
        'Khôi phục mặc định',
        'Bạn có chắc muốn khôi phục tất cả cài đặt về mặc định?',
        () async {
          setState(() {
            _soundEnabled = true;
            _volume = 0.5;
            _vibrationEnabled = true;
            _animationsEnabled = true;
            _bigStone = 'big_stone_1.png';
            _smallStone = 'small_stone_1.png';
            _board = 'gradient_1';
            _background = 'gradient_1';
            _difficulty = 'medium';
            _language = 'vi';
          });
          await _saveSettings();
          if (_soundEnabled) {
            AudioService().enableSound();
          } else {
            AudioService().disableSound();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: _getBackgroundGradient(_background),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildSettingsBody()),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              '⚙️ Cài Đặt Game',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.refresh, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSection('🔊 Âm Thanh & Hiệu Ứng', [
            _buildSwitchCard(
              '🎵 Âm thanh',
              'Bật/tắt âm thanh nền và hiệu ứng',
              _soundEnabled,
              Icons.volume_up,
              (value) {
                setState(() => _soundEnabled = value);
                if (value) {
                  AudioService().enableSound();
                } else {
                  AudioService().disableSound();
                }
                _saveSettings();
                if (_vibrationEnabled) HapticFeedback.lightImpact();
              },
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _soundEnabled ? null : 0,
              child: _soundEnabled
                  ? _buildVolumeSlider()
                  : const SizedBox.shrink(),
            ),
            _buildSwitchCard(
              '📳 Rung',
              'Phản hồi rung khi chạm',
              _vibrationEnabled,
              Icons.vibration,
              (value) {
                setState(() => _vibrationEnabled = value);
                _saveSettings();
                if (value) HapticFeedback.mediumImpact();
              },
            ),
            _buildSwitchCard(
              '✨ Hiệu ứng chuyển động',
              'Bật/tắt các hiệu ứng animation',
              _animationsEnabled,
              Icons.auto_awesome,
              (value) {
                setState(() => _animationsEnabled = value);
                _saveSettings();
                if (_vibrationEnabled) HapticFeedback.lightImpact();
              },
            ),
          ]),
          const SizedBox(height: 20),
          _buildSection('🎨 Giao Diện', [
            _buildVisualOption('🪨 Cục đá ô quan', bigStoneOptions, _bigStone, (
              value,
            ) {
              setState(() => _bigStone = value);
              _saveSettings();
            }),
            _buildVisualOption('💎 Viên sỏi', smallStoneOptions, _smallStone, (
              value,
            ) {
              setState(() => _smallStone = value);
              _saveSettings();
            }),
            _buildVisualOption('🏁 Bàn ô quan', boardOptions, _board, (value) {
              setState(() => _board = value);
              _saveSettings();
            }),
            _buildVisualOption('🌅 Hình nền', backgroundOptions, _background, (
              value,
            ) {
              setState(() => _background = value);
              _saveSettings();
            }),
          ]),
          const SizedBox(height: 20),
          _buildSection('🎯 Game Play', [
            _buildDropdownCard(
              '🤖 Độ khó AI',
              'Chọn mức độ thách thức',
              difficultyOptions,
              _difficulty,
              Icons.psychology,
              (value) {
                setState(() => _difficulty = value!);
                _saveSettings();
              },
            ),
            _buildDropdownCard(
              '🌐 Ngôn ngữ',
              'Chọn ngôn ngữ hiển thị',
              languageOptions,
              _language,
              Icons.language,
              (value) {
                setState(() => _language = value!);
                _saveSettings();
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value
                ? Colors.green.withOpacity(0.7)
                : Colors.grey.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.amber,
            activeTrackColor: Colors.amber.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.white, size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.amber,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: Colors.amber,
                    overlayColor: Colors.amber.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _volume,
                    onChanged: (value) {
                      setState(() => _volume = value);
                      _saveSettings();
                    },
                    min: 0.0,
                    max: 1.0,
                  ),
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.white, size: 20),
            ],
          ),
          Text(
            'Âm lượng: ${(_volume * 100).round()}%',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownCard(
    String title,
    String subtitle,
    List<String> options,
    String value,
    IconData icon,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: value,
            dropdownColor: Colors.brown[800],
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox.shrink(),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(_getDisplayName(option)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildVisualOption(
    String title,
    List<String> options,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == value;

                return GestureDetector(
                  onTap: () {
                    onChanged(option);
                    if (_vibrationEnabled) HapticFeedback.selectionClick();
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.amber.withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.amber
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _getPreviewWidget(option),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Xong',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmDialog(
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    return AlertDialog(
      backgroundColor: Colors.brown[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(content, style: const TextStyle(color: Colors.white70)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _getPreviewWidget(String option) {
    if (option.contains('gradient')) {
      return Container(
        decoration: BoxDecoration(gradient: _getBackgroundGradient(option)),
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.image, color: Colors.grey)),
      );
    }
  }

  String _getDisplayName(String option) {
    switch (option) {
      case 'easy':
        return 'Dễ';
      case 'medium':
        return 'Trung bình';
      case 'hard':
        return 'Khó';
      case 'expert':
        return 'Chuyên gia';
      case 'vi':
        return 'Tiếng Việt';
      case 'en':
        return 'English';
      default:
        return option
            .replaceAll('.png', '')
            .replaceAll('gradient_', 'Gradient ');
    }
  }

  LinearGradient _getBackgroundGradient(String option) {
    switch (option) {
      case 'gradient_1':
        return const LinearGradient(
          colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_2':
        return const LinearGradient(
          colors: [Color(0xFFE6F3FA), Color(0xFF80C4E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_3':
        return const LinearGradient(
          colors: [Color(0xFFF3E8FF), Color(0xFFB39DDB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'gradient_4':
        return const LinearGradient(
          colors: [Color(0xFFFFE5E5), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'nature_1':
        return const LinearGradient(
          colors: [Color(0xFFE8F5E8), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'temple_bg':
        return const LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
