import 'package:battleships/views/newgame.dart';
import 'package:battleships/views/login.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/sessionmanager.dart';
import 'gameboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>>? futureGames;
  List? filteredGames;
  bool _completedGames = false;
  String? username;

  @override
  void initState() {
    super.initState();
    futureGames = _loadGames();
  }

  Future<List<dynamic>> _loadGames() async {
    final res = await http.get(Uri.parse('http://IP_ADDRESS/games'), headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await SessionManager.getSessionToken()}'
    });
    if (res.statusCode == 401) {
      _doLogout();
      return [];
    }
    final games = json.decode(res.body);
    String? sessionUsername = await SessionManager.getUsernameString();
    setState(() {
      username = sessionUsername;
    });
    return games['games'];
  }

  void _refreshGames() {
    setState(() {
      futureGames = _loadGames();
    });
  }

  Future<void> _deleteGame(int gameId) async {
    final url = Uri.parse('http://IP_ADDRESS/games/$gameId');
    final res = await http.delete(url, headers: {
      'Authorization': 'Bearer ${await SessionManager.getSessionToken()}',
      'Content-Type': 'application/json'
    });

    if (res.statusCode == 200) {
      _refreshGames();
      return;
    }
  }

  Future<void> _doLogout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => const LoginPage(),
    ));
  }

  void _toggleGames() {
    setState(() {
      _completedGames = !_completedGames;
      Navigator.pop(context);
    });
  }

  Future<void> _sendNewGameScreen(bool aiMatch) async {
    if (aiMatch) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select AI'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  ListTile(
                    title: Text('Random'),
                    onTap: () {
                      Navigator.of(context).pop('Random');
                    },
                  ),
                  ListTile(
                    title: Text('Perfect'),
                    onTap: () {
                      Navigator.of(context).pop('Perfect');
                    },
                  ),
                  ListTile(
                    title: Text('Oneship (A1)'),
                    onTap: () {
                      Navigator.of(context).pop('Oneship');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ).then((selectedAI) async {
        Navigator.pop(context);
        final dynamic result = await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => NewGameBoard(aiName: selectedAI)));
        _refreshGames();
      });
    } else {
      Navigator.pop(context);
      final dynamic result = await Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => NewGameBoard()));
      _refreshGames();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Battleships'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshGames,
            )
          ],
        ),
        drawer: Drawer(
            child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                child: Center(
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Battleships',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                SizedBox(height: 8),
                Text('logged in as $username')
              ],
            ))),
            ListTile(
                title: const Text('New game'),
                leading: const Icon(Icons.add),
                onTap: () => _sendNewGameScreen(false)),
            ListTile(
                title: const Text('New game (AI)'),
                leading: const Icon(Icons.computer),
                onTap: () => _sendNewGameScreen(true)),
            ListTile(
                title: _completedGames
                    ? const Text('Show active games')
                    : const Text('Show completed games'),
                leading: const Icon(Icons.list),
                onTap: _toggleGames),
            ListTile(
                title: const Text('Log out'),
                leading: const Icon(Icons.logout),
                onTap: _doLogout)
          ],
        )),
        body: FutureBuilder<List<dynamic>>(
            future: futureGames,
            initialData: const [],
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                filteredGames = _completedGames
                    ? snapshot.data!
                        .where((game) =>
                            game['status'] == 1 || game['status'] == 2)
                        .toList()
                    : snapshot.data!
                        .where((game) =>
                            game['status'] != 1 && game['status'] != 2)
                        .toList();
                if (filteredGames!.isEmpty) {
                  return const Center(
                    child: Text('No games here...'),
                  );
                }
                return ListView.builder(
                    itemCount: filteredGames!.length,
                    itemBuilder: (context, index) {
                      final game = filteredGames![index];
                      String gameInfo;
                      int position = game['position'];

                      if (game['status'] == 1) {
                        if (position == 1) {
                          gameInfo = 'You won';
                        } else {
                          gameInfo = "Opponent won";
                        }
                      } else if (game['status'] == 2) {
                        if (position == 1) {
                          gameInfo = 'Opponent won';
                        } else {
                          gameInfo = "You won";
                        }
                      } else if (game['status'] == 0) {
                        gameInfo = 'Matchmaking';
                      } else {
                        gameInfo = position == game['turn']
                            ? 'myTurn'
                            : 'opponentTurn';
                      }
                      return !_completedGames
                          ? Dismissible(
                              key: UniqueKey(),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                              ),
                              onDismissed: (direction) {
                                setState(() {
                                  _deleteGame(game['id']);
                                });
                              },
                              child: ListTile(
                                title: Text((game['status'] == 0)
                                    ? '#${game['id'].toString()} Waiting for opponent'
                                    : '#${game['id'].toString()} ${game['player1']} vs. ${game['player2']}'),
                                trailing: Text(gameInfo),
                                onTap: () async {
                                  final dynamic result = await Navigator.of(
                                          context)
                                      .push(MaterialPageRoute(
                                          builder: (_) =>
                                              GameBoard(gameId: game['id'])));
                                  _refreshGames();
                                },
                              ),
                            )
                          : ListTile(
                              title: Text(
                                  '#${game['id'].toString()} ${game['player1']} vs. ${game['player2']}'),
                              trailing: Text(gameInfo),
                              onTap: () async {
                                final dynamic result =
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                GameBoard(gameId: game['id'])));
                                _refreshGames();
                              },
                            );
                    });
              } else {
                return Center(
                  child: Text('${snapshot.error}'),
                );
              }
            }));
  }
}
