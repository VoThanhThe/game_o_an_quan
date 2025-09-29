import 'package:flutter/material.dart';

import 'service/audio_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> scores = [
    {
      'name': 'Nguyễn Văn A',
      'score': 285,
      'wins': 15,
      'losses': 3,
      'winRate': 83.3,
      'avatar': '🎯',
    },
    {
      'name': 'Trần Thị B',
      'score': 267,
      'wins': 12,
      'losses': 4,
      'winRate': 75.0,
      'avatar': '🏆',
    },
    {
      'name': 'Lê Văn C',
      'score': 245,
      'wins': 10,
      'losses': 5,
      'winRate': 66.7,
      'avatar': '⭐',
    },
    {
      'name': 'Phạm Thị D',
      'score': 230,
      'wins': 9,
      'losses': 6,
      'winRate': 60.0,
      'avatar': '🎪',
    },
    {
      'name': 'Hoàng Văn E',
      'score': 215,
      'wins': 8,
      'losses': 7,
      'winRate': 53.3,
      'avatar': '🎨',
    },
    {
      'name': 'Vũ Thị F',
      'score': 198,
      'wins': 7,
      'losses': 8,
      'winRate': 46.7,
      'avatar': '🎭',
    },
    {
      'name': 'Đặng Văn G',
      'score': 180,
      'wins': 6,
      'losses': 9,
      'winRate': 40.0,
      'avatar': '🎪',
    },
    {
      'name': 'Bùi Thị H',
      'score': 165,
      'wins': 5,
      'losses': 10,
      'winRate': 33.3,
      'avatar': '🎯',
    },
  ];

  String selectedPeriod = 'Tất cả';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFFFF3CC), Color(0xFFD9A84B)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              // _buildTopThree(),
              _buildRankingList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              AudioService().playEffect(SoundType.pack);
              Navigator.pop(context);
            },
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Bảng Xếp Hạng',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.refresh, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Thời gian: ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withAlpha((0.3 * 255).toInt()),
              ),
            ),
            child: DropdownButton<String>(
              value: selectedPeriod,
              dropdownColor: Colors.purple[400],
              underline: SizedBox(),
              icon: Icon(Icons.arrow_drop_down, color: Colors.white),
              style: TextStyle(color: Colors.white, fontSize: 14),
              items: ['Tất cả', 'Hôm nay', 'Tuần này', 'Tháng này'].map((
                String value,
              ) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.white)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedPeriod = newValue!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThree() {
    if (scores.isEmpty) return SizedBox();

    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Hạng 2
          if (scores.length > 1)
            _buildPodiumPlace(scores[1], 2, 100, Colors.grey[400]!),
          SizedBox(width: 10),
          // Hạng 1
          _buildPodiumPlace(scores[0], 1, 120, Colors.amber),
          SizedBox(width: 10),
          // Hạng 3
          if (scores.length > 2)
            _buildPodiumPlace(scores[2], 3, 80, Colors.orange[400]!),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    Map<String, dynamic> player,
    int rank,
    double height,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: Column(
            children: [
              // Avatar và thông tin
              Container(
                width: 80,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          player['avatar'],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      player['name'].split(' ').last,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${player['score']}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              // Podium
              Container(
                width: 60,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      rank == 1
                          ? Icons.emoji_events
                          : rank == 2
                          ? Icons.military_tech
                          : Icons.workspace_premium,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRankingList() {
    if (scores.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 80,
                color: Colors.white.withAlpha((0.5 * 255).toInt()),
              ),
              SizedBox(height: 16),
              Text(
                'Chưa có điểm nào',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white.withAlpha((0.8 * 255).toInt()),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hãy chơi game để xuất hiện trên bảng xếp hạng!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlpha((0.6 * 255).toInt()),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24).copyWith(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header của danh sách
            Container(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      'Hạng',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A26),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Người chơi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A26),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Điểm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A26),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Tỷ lệ thắng',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8B5A26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Danh sách xếp hạng
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: scores.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          (1 - _animationController.value) * 300,
                          0,
                        ),
                        child: _buildRankingItem(scores[index], index + 1),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankingItem(Map<String, dynamic> player, int rank) {
    Color rankColor = rank <= 3
        ? (rank == 1
              ? Colors.amber
              : rank == 2
              ? Colors.grey[400]!
              : Colors.orange[400]!)
        : Colors.grey[600]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        color: rank <= 3 ? rankColor.withAlpha((0.05 * 255).toInt()) : null,
      ),
      child: Row(
        children: [
          // Số thứ hạng
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: rank <= 3 ? rankColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: rank <= 3 ? rankColor : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Center(
              child: rank <= 3
                  ? Icon(
                      rank == 1
                          ? Icons.looks_one
                          : rank == 2
                          ? Icons.looks_two
                          : Icons.looks_3,
                      color: Colors.white,
                      size: 20,
                    )
                  : Text(
                      '$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          SizedBox(width: 16),

          // Avatar và tên
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.purple[100],
                    borderRadius: BorderRadius.circular(22.5),
                  ),
                  child: Center(
                    child: Text(
                      player['avatar'],
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        '${player['wins']}T - ${player['losses']}B',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Điểm số
          SizedBox(
            width: 100,
            child: Text(
              '${player['score']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: rank <= 3 ? rankColor : Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Tỷ lệ thắng
          Container(
            width: 100,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: player['winRate'] >= 70
                  ? Colors.green[100]
                  : player['winRate'] >= 50
                  ? Colors.orange[100]
                  : Colors.red[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${player['winRate'].toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: player['winRate'] >= 70
                    ? Colors.green[700]
                    : player['winRate'] >= 50
                    ? Colors.orange[700]
                    : Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
