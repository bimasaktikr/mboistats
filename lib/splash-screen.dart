import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double opacity = 1.0;
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        opacity = 0.0;
      });

      Future.delayed(Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/main'); 
      });
    });

    controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedOpacity(
              opacity: opacity,
              duration: Duration(seconds: 1),
              child: Image.asset(
                'assets/images/Mbois-stat Logo_Fix Putih.png',
                width: 200,
                height: 200,
              ),
            ),
            AnimatedPositioned(
              top: 130,
              duration: Duration(seconds: 1),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: Duration(seconds: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}