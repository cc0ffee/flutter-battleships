import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../utils/sessionmanager.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  Future<void> _login(BuildContext context) async {
    final user = userController.text;
    final pass = passController.text;

    final url = Uri.parse('http://IP_ADDRESS/login');
    final res = await http.post(url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': user, 'password': pass}));

    if (res.statusCode == 200) {
      final sessionToken = jsonDecode(res.body)['access_token'];
      await SessionManager.setSessionToken(sessionToken, user);
      if (!context.mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed')),
      );
    }
  }

  Future<void> _register(BuildContext context) async {
    final user = userController.text;
    final pass = passController.text;

    if ((user.length < 3 || pass.length < 3) ||
        (user.contains(" ") || pass.contains(" "))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Registration failed')));
    } else {
      final url = Uri.parse('http://IP_ADDRESS/register');
      final res = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': user, 'password': pass}));

      if (res.statusCode == 200) {
        final sessionToken = jsonDecode(res.body)['access_token'];
        await SessionManager.setSessionToken(sessionToken, user);
        if (!context.mounted) return;
        Navigator.of(context)
            .pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration sucessful')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Login'),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _login(context),
                    child: const Text('Log in'),
                  ),
                  ElevatedButton(
                    onPressed: () => _register(context),
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
