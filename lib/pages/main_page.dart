// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pitch_point/pages/Teams_Page.dart';
import 'package:pitch_point/util/footer.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(
          'Welcome Back!',
           style:TextStyle( fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
            fontSize: 20)
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50,vertical: 90),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
            RichText(
          textAlign: TextAlign.center,
          text:  TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              fontFamily: 'Montserrat',
            ),
            children: [
              TextSpan(
                text: 'Pitch\n',
                style: TextStyle(color:Theme.of(context).colorScheme.primary),
              ),
              TextSpan(
                text: '  Point🏏',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),
      
              _buildButton(
                context,
                icon: Icons.play_arrow,
                label: "Start New Match",
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> TeamsPage()));
                },
              ),
              const SizedBox(height: 15),
              _buildButton(
                context,
                icon: Icons.history,
                label: "See Previous Stats",
                onPressed: () {
                  
                },
              ),
              const SizedBox(height: 15),
              _buildButton(
                context,
                icon: Icons.exit_to_app,
                label: "Exit",
                onPressed: () {
                  SystemNavigator.pop();
                },
              ),

              FooterText()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context,
    {required IconData icon, required String label, required VoidCallback onPressed}) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.hovered)) {
          return const Color.fromARGB(255, 155, 15, 5);
        }
        if (states.contains(MaterialState.pressed)) {
          return Colors.black;
        }
        return Theme.of(context).colorScheme.primary;
      }),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
      ),
      elevation: MaterialStateProperty.all(6),
      shape: MaterialStateProperty.all(
        const StadiumBorder(
          side: BorderSide(width: 1.5, color: Colors.black26),
        ),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 22),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color:Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Montserrat',
          ),
        ),
      ],
    ),
  );
}
}