import 'package:flutter/material.dart';
import 'dart:math';

import 'package:pitch_point/pages/main_page.dart';

class CoinAnimation extends StatefulWidget {
  const CoinAnimation({super.key});

  @override
  State<CoinAnimation> createState() => _CoinAnimationState();
}

class _CoinAnimationState extends State<CoinAnimation>
    with TickerProviderStateMixin {
  late AnimationController _coinController;
  late AnimationController _textController;

  late Animation<double> _dropAnimation;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _taglineFadeAnimation;

  final String tagline = "Where Every Run Counts!"; //tagline

  @override
  void initState() {
    super.initState();

    _coinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // 1. Drop (0 - 0.8s) faster with bounce effect
    _dropAnimation = Tween<double>(begin: -200, end: 0).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: const Interval(0.0, 0.2, curve: Curves.bounceOut),
      ),
    );

    // 2. Flip (0.8 - 2.6s, 3 spins)
    _flipAnimation = Tween<double>(begin: 0, end: 2 * pi * 3).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: const Interval(0.2, 0.65, curve: Curves.easeInOut),
      ),
    );

    // 3a. Scale/Throw (2.6 - 4.0s)
    _scaleAnimation = Tween<double>(begin: 1.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
      ),
    );

    // 3b. Fade with zoom (coin)
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Tagline fade out starting exactly at zoom start (0.65 to 0.7)
    _taglineFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _coinController,
        curve: const Interval(0.65, 0.7, curve: Curves.easeIn),
      ),
    );

    // Text typing controller (start after drop, finish before zoom)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _coinController.addStatusListener((status) {
      if (status == AnimationStatus.forward) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) _textController.forward();
        });
      }
    });

    // Add navigation on animation complete
    _coinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
      }
    });

    // Delay the start of the coin animation by 0.7 seconds
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _coinController.forward();
    });
  }

  @override
  void dispose() {
    _coinController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _coinController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Coin
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _dropAnimation.value),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..rotateY(_flipAnimation.value)
                        // ignore: deprecated_member_use
                        ..scale(_scaleAnimation.value),
                      child: child,
                    ),
                  ),
                ),

                // Typing tagline
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, _) {
                    int count = (tagline.length *
                            _textController.value.clamp(0.0, 1.0))
                        .floor();
                    return Opacity(
                      opacity: _taglineFadeAnimation.value,
                      child: Text(
                        tagline.substring(0, count),
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          color: Color.fromARGB(255, 200, 0, 0), // deep red
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
          child: Image.asset(
            "assets/images/coin.png",
            width: 170,
            height: 170,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
