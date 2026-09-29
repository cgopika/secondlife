import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/secondlife_logo.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _ctrl.forward();

    // After animation, check auth state and navigate to Home or the FIRST / Welcome screen
    Future.delayed(const Duration(milliseconds: 1400), () {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween(begin: 0.86, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.8)),
                  child: SizedBox(height: 160, width: 160, child: SecondLifeLogo(size: 160)),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)),
                child: const Text('SecondLife', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.darkText)),
              ),
              const SizedBox(height: 6),
              FadeTransition(
                opacity: CurvedAnimation(parent: _ctrl, curve: const Interval(0.7, 1.0)),
                child: const Text('Give materials a second life.', style: TextStyle(color: AppColors.secondaryText)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
