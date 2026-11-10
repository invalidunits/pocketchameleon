import 'dart:math';

import '../../constants.dart';
import 'game_server.dart';
import 'player.dart';

class ServerManager {
  final Random _random = Random.secure();
  final List<GameServer> _servers = [];

  late final Player currentPlayer;
  GameServer? _activeServer;

  ServerManager() {
    currentPlayer = Player(id: _generatePlayerId(), name: generateRandomName());
  }

  List<GameServer> get servers => List.unmodifiable(_servers);

  List<GameServer> get publicServers =>
      List.unmodifiable(_servers.where((server) => server.isPublic));

  GameServer? get activeServer => _activeServer;

  String generateRandomName() {
    final adjective = Constants
        .nameAdjectives[_random.nextInt(Constants.nameAdjectives.length)];

    final noun = Constants
        .nameNouns[_random.nextInt(Constants.nameNouns.length)];

    final number =
        Constants.randomNameNumberMin +
        _random.nextInt(
          Constants.randomNameNumberMax -
              Constants.randomNameNumberMin +
              1,
        );

    return '$adjective$noun$number';
  }

  String _generatePlayerId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomPart = _random.nextInt(1000000000);

    return '$timestamp-$randomPart';
  }

  bool updatePlayerName(String newName) {
    final trimmedName = newName.trim();

    if (trimmedName.isEmpty ||
        trimmedName.length > Constants.maxPlayerNameLength) {
      return false;
    }

    currentPlayer.name = trimmedName;

    for (final server in _servers) {
      server.updatePlayerName(currentPlayer.id, trimmedName);
    }

    return true;
  }

  String generateCode() {
    String code;

    do {
      code = List.generate(
        Constants.serverCodeLength,
        (_) =>
            Constants.codeCharacters[_random.nextInt(
              Constants.codeCharacters.length,
            )],
      ).join();
    } while (_servers.any((server) => server.code == code));

    return code;
  }

  GameServer createServer(String name, bool isPublic) {
    if (_activeServer != null) {
      throw StateError('You are already in a server.');
    }

    final server = GameServer(
      name: name.trim(),
      code: generateCode(),
      isPublic: isPublic,
      host: currentPlayer,
    );

    _servers.add(server);
    _activeServer = server;

    return server;
  }

  GameServer? findServer(String code) {
    final normalizedCode = code.trim().toUpperCase();

    for (final server in _servers) {
      if (server.code == normalizedCode) {
        return server;
      }
    }

    return null;
  }

  bool joinServer(GameServer server) {
    if (_activeServer != null) {
      return false;
    }

    if (!_servers.contains(server)) {
      return false;
    }

    if (server.players.length >= Constants.maxPlayers) {
      return false;
    }

    if (server.hasPlayer(currentPlayer.id)) {
      return false;
    }

    server.addPlayer(currentPlayer);
    _activeServer = server;

    return true;
  }

  void leaveServer(GameServer server) {
    if (_activeServer != server) {
      return;
    }

    server.removePlayer(currentPlayer.id);
    _activeServer = null;

    if (server.players.isEmpty) {
      _servers.remove(server);
      return;
    }

    if (server.hostPlayerId == currentPlayer.id) {
      server.hostPlayerId = server.players.first.id;
    }
  }
}
