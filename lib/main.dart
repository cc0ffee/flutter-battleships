import 'package:flutter/material.dart';
import 'utils/sessionmanager.dart';
import 'views/login.dart';
import 'views/home.dart';

class Battleships extends StatefulWidget {
  const Battleships({super.key});

  @override
  State<Battleships> createState() => _BattleshipsState();
}

class _BattleshipsState extends State<Battleships> {
  bool sessionPresent = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final getSession = await SessionManager.isLoggedIn();
    if (mounted) {
      setState(() {
        sessionPresent = getSession;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battleships',
      home: sessionPresent ? HomeScreen() : const LoginPage(),
    );
  }
}

void main() {
  runApp(const Battleships());
}
