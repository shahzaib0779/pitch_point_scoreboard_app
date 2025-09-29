import 'package:flutter/material.dart';
import 'package:pitch_point/Providers/scoreboard_provider.dart';
import 'package:pitch_point/Providers/team_names_provider.dart';
import 'package:pitch_point/animations/coin_animation.dart';
import 'package:provider/provider.dart';

void main() {
  runApp( MultiProvider(
    providers: [
    ChangeNotifierProvider(create: (context) => TeamNamesProvider()),
    ChangeNotifierProvider(create: (context)=>ScoreboardProvider()),
    ],
    child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
            primaryColor: const Color(0xFFD32F2F),
            scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: const Color(0xFFD32F2F),
              secondary: const Color(0xFFF44336),
            ),
        ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: CoinAnimation(),
    );
  }
}

