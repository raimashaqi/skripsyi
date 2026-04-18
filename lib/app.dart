import 'package:flutter/material.dart';
import 'features/home/presentation/screens/home_screen.dart';

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    // This could be a wrapper for MultiBlocProvider or a Router
    return const HomeScreen();
  }
}
