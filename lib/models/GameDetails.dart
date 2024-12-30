class GameDetails {
  final int id;
  final int status;
  final String position;
  final int turn;
  final List<String> ships;
  final List<String> wrecks;
  final List<String> shots;
  final List<String> sunk;

  GameDetails({
    required this.id,
    required this.status,
    required this.position,
    required this.turn,
    required this.ships,
    required this.wrecks,
    required this.shots,
    required this.sunk,
  });

  factory GameDetails.fromJson(Map<String, dynamic> json) {
    return GameDetails(
      id: json['id'],
      status: json['status'],
      position: json['position'],
      turn: json['turn'],
      ships: json['ships'] != null ? List<String>.from(json['ships']) : [],
      wrecks: json['wrecks'] != null ? List<String>.from(json['wrecks']) : [],
      shots: json['shots'] != null ? List<String>.from(json['shots']) : [],
      sunk: json['sunk'] != null ? List<String>.from(json['sunk']) : [],
    );
  }
}
