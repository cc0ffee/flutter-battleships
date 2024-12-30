import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:battleships/utils/sessionmanager.dart';
import 'package:flutter/material.dart';

import '../models/GameGrid.dart';
import 'login.dart';

class NewGameBoard extends StatefulWidget {
  final String? aiName;
  const NewGameBoard({super.key, this.aiName});

  @override
  State createState() => _NewGameBoardState();
}

class _NewGameBoardState extends State<NewGameBoard> {
  late GameGrid gameGrid;

  @override
  void initState() {
    super.initState();
    gameGrid = GameGrid.init();
  }

  void toggleTile(int row, int column) {
    setState(() {
      if (gameGrid.toggleCount < 5 || gameGrid.board[row][column]) {
        gameGrid.board[row][column] = !gameGrid.board[row][column];
        gameGrid.toggleCount += gameGrid.board[row][column] ? 1 : -1;
      }
    });
  }

  Future<void> _doLogout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const LoginPage(),
    ));
  }

  Future<void> submitGame() async {
    List<String> ships = [];
    if (gameGrid.toggleCount < 5) {
      return;
    }
    for (int row = 0; row < gameGrid.board.length; row++) {
      for (int column = 0; column < gameGrid.board[row].length; column++) {
        if (gameGrid.board[row][column]) {
          String coord = String.fromCharCode('A'.codeUnitAt(0) + row) +
              (column + 1).toString();
          ships.add(coord);
        }
      }
    }
    final url = Uri.parse('http://IP_ADDRESS/games');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await SessionManager.getSessionToken()}'
    };
    final body = !(widget.aiName == null)
        ? jsonEncode({'ships': ships, 'ai': widget.aiName?.toLowerCase()})
        : jsonEncode({'ships': ships});
    final res = await http.post(url, headers: headers, body: body);
    if (res.statusCode == 401) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session expired: Please log in again.')));
      _doLogout();
      return;
    }
    if (res.statusCode == 200) {
      Navigator.of(context).pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Place ships'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
                child: Center(
              child: Container(
                child: GridView.builder(
                  itemCount: 36,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    int row = index ~/ 6; // Adjusted for 6 columns
                    int column = index % 6; // Adjusted for 6 columns
                    if (row == 0) {
                      if (column == 0) {
                        return Container();
                      } else {
                        return Center(
                            child: Text(gameGrid.columns[column - 1]));
                      }
                    } else if (column == 0) {
                      return Center(child: Text(gameGrid.rows[row - 1]));
                    } else {
                      return InkWell(
                        onTap: () => toggleTile(row - 1, column - 1),
                        child: Container(
                          color: gameGrid.board[row - 1][column - 1]
                              ? Colors.blue
                              : Colors.transparent,
                          child: Center(child: Text('')),
                        ),
                      );
                    }
                  },
                ),
              ),
            )),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: (gameGrid.toggleCount == 5) ? submitGame : null,
                child: const Text('Submit'),
              ),
            ),
          ],
        ));
  }
}
