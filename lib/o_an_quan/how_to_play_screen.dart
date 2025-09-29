import 'package:flutter/material.dart';

import 'service/audio_service.dart';

class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<Animation<double>> _sectionAnimations;
  late Animation<Offset> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Create staggered animations for sections
    _sectionAnimations = List.generate(
      4,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeOutBack),
        ),
      ),
    );

    _buttonSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF6B4423);
    final Color accentColor = const Color(0xFF8B5A26);
    final Color goldColor = const Color(0xFFD4AF37);
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Hướng dẫn chơi Ô Ăn Quan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryColor.withAlpha((0.95 * 255).toInt()),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: isLandscape ? 48 : 56,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, accentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: BackButton(
          color: Colors.white, // màu icon
          onPressed: () {
            AudioService().playEffect(SoundType.pack);
            Navigator.pop(context); // quay lại màn trước
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: isLandscape
              ? _buildLandscapeLayout(
                  screenSize,
                  primaryColor,
                  accentColor,
                  goldColor,
                )
              : _buildPortraitLayout(primaryColor, accentColor, goldColor),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    Size screenSize,
    Color primaryColor,
    Color accentColor,
    Color goldColor,
  ) {
    return Row(
      children: [
        // Left side - Header and game info
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Game board visualization
                _buildGameBoardVisualization(),
                const Spacer(),
                SlideTransition(
                  position: _buttonSlideAnimation,
                  child: _buildBackButton(primaryColor, accentColor),
                ),
              ],
            ),
          ),
        ),
        // Right side - Instructions in 2 columns
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildAnimatedHeader(isCompact: true),
                const SizedBox(height: 16),
                // Two column layout for sections
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        children: [
                          _buildCompactSection(
                            index: 0,
                            icon: Icons.flag_rounded,
                            title: "Mục tiêu",
                            content:
                                "Thu thập được nhiều quân nhất sau khi ván chơi kết thúc.",
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          _buildCompactSection(
                            index: 2,
                            icon: Icons.tungsten,
                            title: "Cách rải quân",
                            content:
                                "1. Chọn 1 ô dân thuộc quyền mình\n"
                                "2. Rải lần lượt từng quân vào các ô tiếp theo\n"
                                "3. Nếu rơi vào ô có quân → tiếp tục rải\n"
                                "4. Nếu rơi vào ô trống → có thể ăn quân ô sau\n"
                                "*Lưu ý: Lượt rải đầu tiên không được ăn khi rơi vào ô quan, vì trường hợp quan non",
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Right column
                    Expanded(
                      child: Column(
                        children: [
                          _buildCompactSection(
                            index: 1,
                            icon: Icons.grid_view_rounded,
                            title: "Bố cục bàn chơi",
                            content:
                                "• 2 ô quan lớn ở 2 đầu\n"
                                "• 10 ô dân nhỏ ở giữa (mỗi ô có 5 quân)\n"
                                "• Ô quan ban đầu chỉ có 1 viên đá to",
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          _buildCompactSection(
                            index: 3,
                            icon: Icons.emoji_events_rounded,
                            title: "Kết thúc ván",
                            content:
                                "• Khi cả 2 ô quan hết hoặc không còn quân để tiếp tục\n"
                                "• Người thắng là người có nhiều quân nhất",
                            color: const Color(0xFFD4AF37),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(
    Color primaryColor,
    Color accentColor,
    Color goldColor,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildAnimatedHeader(),
          const SizedBox(height: 30),
          _buildAnimatedSection(
            index: 0,
            icon: Icons.flag_rounded,
            title: "Mục tiêu",
            content: "Thu thập được nhiều quân nhất sau khi ván chơi kết thúc.",
            color: Colors.green,
          ),
          const SizedBox(height: 20),
          _buildAnimatedSection(
            index: 1,
            icon: Icons.grid_view_rounded,
            title: "Bố cục bàn chơi",
            content:
                "• Bàn có 2 ô quan lớn ở 2 đầu.\n"
                "• 10 ô dân nhỏ ở giữa, mỗi ô có 5 quân.\n"
                "• Ô quan ban đầu không có quân, chỉ có 1 viên đá to (quan).",
            color: Colors.blue,
          ),
          const SizedBox(height: 20),
          _buildAnimatedSection(
            index: 2,
            icon: Icons.refresh_rounded,
            title: "Cách rải quân",
            content:
                "1. Người chơi chọn 1 ô dân thuộc quyền mình.\n"
                "2. Lấy toàn bộ quân trong ô, rải lần lượt từng quân vào các ô tiếp theo theo chiều đã chọn (trái hoặc phải).\n"
                "3. Nếu rơi vào ô có sẵn quân → tiếp tục bốc toàn bộ quân trong ô đó để rải tiếp.\n"
                "4. Nếu rơi vào ô trống:\n"
                "   • Nếu sau ô trống có ô có quân → được ăn toàn bộ quân ở ô đó.\n"
                "   • Nếu sau ô trống lại tiếp tục là ô trống → mất lượt.",
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          _buildAnimatedSection(
            index: 3,
            icon: Icons.emoji_events_rounded,
            title: "Kết thúc ván",
            content:
                "• Khi cả 2 ô quan đã bị ăn hết hoặc không còn quân để tiếp tục, ván chơi kết thúc.\n"
                "• Người thắng là người có nhiều quân nhất.",
            color: goldColor,
          ),
          const SizedBox(height: 40),
          SlideTransition(
            position: _buttonSlideAnimation,
            child: Center(child: _buildBackButton(primaryColor, accentColor)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGameBoardVisualization() {
    return FadeTransition(
      opacity: _sectionAnimations[1],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withAlpha((0.9 * 255).toInt()),
              Colors.white.withAlpha((0.7 * 255).toInt()),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFD4AF37).withAlpha((0.3 * 255).toInt()),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            const Text(
              "Bàn chơi Ô Ăn Quan",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4423),
              ),
            ),
            const SizedBox(height: 16),
            // Simple board visualization
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left Quan
                _buildQuanBox(),
                const SizedBox(width: 8),
                // Middle Dan boxes
                Column(
                  children: [
                    Row(children: List.generate(5, (index) => _buildDanBox())),
                    const SizedBox(height: 8),
                    Row(children: List.generate(5, (index) => _buildDanBox())),
                  ],
                ),
                const SizedBox(width: 8),
                // Right Quan
                _buildQuanBox(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuanBox() {
    return Container(
      width: 30,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF8B5A26).withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B5A26), width: 2),
      ),
      child: const Center(
        child: Text(
          "Quan",
          style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDanBox() {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withAlpha((0.3 * 255).toInt()),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD4AF37), width: 1),
      ),
      child: const Center(child: Text("5", style: TextStyle(fontSize: 8))),
    );
  }

  Widget _buildBackButton(Color primaryColor, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          colors: [primaryColor, accentColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withAlpha((0.4 * 255).toInt()),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
          size: 22,
        ),
        label: const Text(
          "Quay lại menu",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        onPressed: () {
          AudioService().playEffect(SoundType.pack);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildAnimatedHeader({bool isCompact = false}) {
    return FadeTransition(
      opacity: _sectionAnimations[0],
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withAlpha((0.9 * 255).toInt()),
              Colors.white.withAlpha((0.7 * 255).toInt()),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).toInt()),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFD4AF37).withAlpha((0.3 * 255).toInt()),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 12 : 15),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.sports_esports_rounded,
                size: isCompact ? 32 : 40,
                color: const Color(0xFF6B4423),
              ),
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              "Trò chơi dân gian Việt Nam",
              style: TextStyle(
                fontSize: isCompact ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B4423),
              ),
            ),
            SizedBox(height: isCompact ? 4 : 8),
            Text(
              "Hãy tìm hiểu cách chơi Ô Ăn Quan truyền thống",
              style: TextStyle(
                fontSize: isCompact ? 12 : 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSection({
    required int index,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _sectionAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _sectionAnimations[index].value,
          child: Opacity(
            opacity: _sectionAnimations[index].value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha((0.95 * 255).toInt()),
                    Colors.white.withAlpha((0.85 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((0.2 * 255).toInt()),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: color.withAlpha((0.3 * 255).toInt()),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color.withAlpha((0.9 * 255).toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withAlpha((0.05 * 255).toInt()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF424242),
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

  Widget _buildAnimatedSection({
    required int index,
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: _sectionAnimations[index],
      builder: (context, child) {
        return Transform.scale(
          scale: _sectionAnimations[index].value,
          child: Opacity(
            opacity: _sectionAnimations[index].value.clamp(0.0, 1.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withAlpha((0.95 * 255).toInt()),
                    Colors.white.withAlpha((0.85 * 255).toInt()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha((0.2 * 255).toInt()),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: color.withAlpha((0.3 * 255).toInt()),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha((0.15 * 255).toInt()),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color.withAlpha((0.9 * 255).toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withAlpha((0.05 * 255).toInt()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      content,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF424242),
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
}
