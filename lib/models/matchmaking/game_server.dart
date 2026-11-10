import 'player.dart';

class GameServer {
  final String name;
  final String code;
  final bool isPublic;

  String hostPlayerId;

  final List<Player> _players = [];

  GameServer({
    required this.name,
    required this.code,
    required this.isPublic,
    required Player host,
  }) : hostPlayerId = host.id {
    _players.add(host);
  }

  List<Player> get players => List.unmodifiable(_players);

  bool isHost(String playerId) {
    return hostPlayerId == playerId;
  }

  void addPlayer(Player player) {
    if (!_players.any((p) => p.id == player.id)) {
      _players.add(player);
    }
  }

  void removePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
  }

  void updatePlayerName(String playerId, String newName) {
    for (final player in _players) {
      if (player.id == playerId) {
        player.name = newName;
      }
    }
  }

  bool hasPlayer(String playerId) {
    return _players.any((p) => p.id == playerId);
  }
}
