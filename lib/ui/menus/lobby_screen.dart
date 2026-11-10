import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../models/matchmaking/game_server.dart';
import '../../models/matchmaking/server_manager.dart';

class LobbyScreen extends StatelessWidget {
  final GameServer server;
  final ServerManager serverManager;

  const LobbyScreen({
    super.key,
    required this.server,
    required this.serverManager,
  });

  void leaveLobby(BuildContext context) {
    serverManager.leaveServer(server);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('You left the server.')));

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = serverManager.currentPlayer;
    final isHost = server.isHost(currentPlayer.id);
    final players = server.players;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Server Lobby'),
          centerTitle: true,
          backgroundColor: const Color(0xFF276B50),
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.groups,
                      size: 65,
                      color: Color(0xFF276B50),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      server.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(server.isPublic ? 'Public Server' : 'Private Server'),
                    const SizedBox(height: 8),
                    Text(
                      isHost ? 'You are the Host' : 'You are a Player',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF276B50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.key),
                  title: const Text('Server Code'),
                  subtitle: Text(
                    server.code,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: 'Copy server code',
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: server.code));

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Server code copied to clipboard!'),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Players',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text('${players.length}/${Constants.maxPlayers}'),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: players.isEmpty
                    ? const Center(child: Text('No players in this server.'))
                    : ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];
                          final playerIsHost = server.isHost(player.id);

                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(player.name),
                            trailing: playerIsHost
                                ? const Text(
                                    'HOST',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF276B50),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => leaveLobby(context),
                  child: const Text('LEAVE SERVER'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
