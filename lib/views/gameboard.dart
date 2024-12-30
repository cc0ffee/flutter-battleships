import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:battleships/utils/sessionmanager.dart';
import 'package:flutter/material.dart';

import 'login.dart';

class GameBoard extends StatefulWidget {
  final int gameId;
  const GameBoard({super.key, required this.gameId});

  @override
  State createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  List<List<bool>> board = List.generate(5, (_) => List<bool>.filled(5, false));
  Future<Map<String, dynamic>>? gameDetails;
  final List<String> rows = ['A', 'B', 'C', 'D', 'E'];
  final List<String> columns = ['1', '2', '3', '4', '5'];
  int? selectedColumn;
  int? selectedRow;
  int toggleCount = 0;

  @override
  void initState() {
    super.initState();
    gameDetails = getGameDetails();
  }

  void toggleTile(int row, int column) {
    setState(() {
      if (toggleCount < 1 || board[row][column]) {
        board[row][column] = !board[row][column];
        toggleCount += board[row][column] ? 1 : -1;
        selectedColumn = board[row][column] ? column : null;
        selectedRow = board[row][column] ? row : null;
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

  Future<Map<String, dynamic>> getGameDetails() async {
    final url = Uri.parse('http://IP_ADDRESS/games/${widget.gameId}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await SessionManager.getSessionToken()}'
    };
    final res = await http.get(url, headers: headers);

    if (res.statusCode == 401) {
      _doLogout();
      if (!context.mounted) return {};
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session expired: Please log in again.')));
      return {};
    }

    if (res.statusCode == 200) {
      final Map<String, dynamic> gameData = jsonDecode(res.body);
      Map<String, dynamic> gameDetails = {
        'id': gameData['id'],
        'status': gameData['status'],
        'position': gameData['position'],
        'turn': gameData['turn'],
        'ships': gameData['ships'] != null
            ? List<String>.from(gameData['ships'])
            : [],
        'wrecks': gameData['wrecks'] != null
            ? List<String>.from(gameData['wrecks'])
            : [],
        'shots': gameData['shots'] != null
            ? List<String>.from(gameData['shots'])
            : [],
        'sunk':
            gameData['sunk'] != null ? List<String>.from(gameData['sunk']) : [],
      };
      return gameDetails;
    } else {
      print(res.statusCode);
      return {};
    }
  }

  Widget _EmojiText(int row, int column, dynamic snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Container();
    } else {
      final Map<String, dynamic> details = snapshot.data!;
      final coord =
          '${String.fromCharCode('A'.codeUnitAt(0) + row)}${column + 1}';
      final ship = (details['ships'].contains(coord) &&
              !details['wrecks'].contains(coord))
          ? '🚢'
          : '';
      final wreck = details['wrecks'].contains(coord) ? '💥' : '';
      final shot =
          (details['shots'].contains(coord) && !details['sunk'].contains(coord))
              ? '💣'
              : '';
      final sunk = details['sunk'].contains(coord) ? '🔥' : '';

      return Center(
        child: Text(
          '$ship$wreck$shot$sunk',
          style: const TextStyle(fontSize: 20),
        ),
      );
    }
  }

  Future<void> putShot() async {
    if (selectedRow == null && selectedColumn == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No position selected')));
      return;
    }
    String coord;
    final details = await gameDetails;
    coord = String.fromCharCode('A'.codeUnitAt(0) + selectedRow!) +
        (selectedColumn! + 1).toString();

    if (details!['shots'].contains(coord) || details!['sunk'].contains(coord)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Already sent missle here, pick another!'),
      ));
      return;
    }

    final url = Uri.parse('http://IP_ADDRESS/games/${widget.gameId}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await SessionManager.getSessionToken()}'
    };

    final body = jsonEncode({'shot': coord});
    final res = await http.put(url, headers: headers, body: body);
    if (res.statusCode == 401) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Session expired: Please log in again.')));
      _doLogout();
      return;
    }
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body['won'] == true) {
        setState(() {
          gameDetails = getGameDetails();
          toggleTile(selectedRow!, selectedColumn!);
        });
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(title: const Text("You Won!"), actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, "OK");
                    },
                    child:
                        const Text("OK", style: TextStyle(color: Colors.blue)))
              ]);
            });
        return;
      }
      if (body['sunk_ship'] == true) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ship hit!')));
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No enemy ship hit...')));
      }
      setState(() {
        gameDetails = getGameDetails();
        toggleTile(selectedRow!, selectedColumn!);
      });
    } else {
      print(res.statusCode);
    }
    ;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Play Game'),
          centerTitle: true,
        ),
        body: FutureBuilder<Map<String, dynamic>>(
            future: gameDetails,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasData) {
                return Column(
                  children: [
                    Expanded(
                        child: Center(
                      child: Container(
                        child: GridView.builder(
                          itemCount: 36,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            int row = index ~/ 6;
                            int column = index % 6;
                            if (row == 0) {
                              if (column == 0) {
                                return Container();
                              } else {
                                return Center(child: Text(columns[column - 1]));
                              }
                            } else if (column == 0) {
                              return Center(child: Text(rows[row - 1]));
                            } else {
                              return InkWell(
                                onTap: () => (snapshot.data != null &&
                                        snapshot.data!['status'] == 3 &&
                                        snapshot.data!['turn'] ==
                                            snapshot.data!['position'])
                                    ? toggleTile(row - 1, column - 1)
                                    : null,
                                child: Container(
                                    color: board[row - 1][column - 1]
                                        ? Colors.blue
                                        : Colors.transparent,
                                    child: (snapshot.data != null)
                                        ? _EmojiText(
                                            row - 1, column - 1, snapshot)
                                        : Container()),
                              );
                            }
                          },
                        ),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        onPressed: ((snapshot.data != null &&
                                snapshot.data!['status'] == 3 &&
                                snapshot.data!['turn'] ==
                                    snapshot.data!['position']))
                            ? putShot
                            : null,
                        child: const Text('Submit'),
                      ),
                    ),
                  ],
                );
              } else {
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }
            }));
  }
}
