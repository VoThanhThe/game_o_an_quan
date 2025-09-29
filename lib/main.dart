import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'o_an_quan/menu_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khóa xoay ngang
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Fullscreen
  await Flame.device.fullScreen();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ô Ăn Quan',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const MenuScreen(),
      // home: PlayGameAi(),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:flame/game.dart';

// import 'tutorals/space_shooter_game.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Ô Ăn Quan',
//       theme: ThemeData(primarySwatch: Colors.brown),
//       home: GameWidget(game: SpaceShooterGame()),
//     );
//   }
// }
