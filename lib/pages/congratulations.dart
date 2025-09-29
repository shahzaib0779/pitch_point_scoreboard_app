import 'package:flutter/material.dart';
import 'package:pitch_point/pages/main_page.dart';

class CongratulationsPage extends StatefulWidget {
  final String teamName;
  const CongratulationsPage({super.key, required this.teamName});

  @override
  State<CongratulationsPage> createState() => _CongratulationsPageState();
}

class _CongratulationsPageState extends State<CongratulationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Card(
            elevation: 15,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            color: Colors.red[600], // red card on black bg
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Congratulations",
                    style: TextStyle(
                      fontSize: 26,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // white text on red
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    "${widget.teamName} Wins!",
                    style: TextStyle(
                      fontSize: 22,
                      fontFamily: 'Montserrat',
                      fontWeight: FontWeight.w600,
                      color: Colors.black, // black text for contrast
                    ),
                  ),
                  const SizedBox(height: 6,),
                  Text(
                    "Victory belongs to the best!",
                    textAlign: TextAlign.center,
                    style:TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20,),
                  IconButton(onPressed:() {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                      (Route<dynamic> route) => false,
                    );
                    
                  }, icon: Icon(Icons.home,color: Theme.of(context).colorScheme.primary,),
                  padding: EdgeInsets.symmetric(horizontal: 30,vertical: 10),

                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onSurface
                  ),
                  )
               
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
