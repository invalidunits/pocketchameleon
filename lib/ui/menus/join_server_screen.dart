import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/matchmaking/game_server.dart';
import '../../models/matchmaking/server_manager.dart';
import 'lobby_screen.dart';

class JoinServerScreen extends StatefulWidget {
  final ServerManager serverManager;

  const JoinServerScreen({super.key, required this.serverManager});

  @override
  State<JoinServerScreen> createState() => _JoinServerScreenState();
}

class _JoinServerScreenState extends State<JoinServerScreen> {
  final _codeController = TextEditingController();

  List<GameServer> get publicServers => widget.serverManager.publicServers;

  void openLobby(GameServer server) {
    final success = widget.serverManager.joinServer(server);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This server is full or unavailable.')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LobbyScreen(server: server, serverManager: widget.serverManager),
      ),
    );
  }

  void joinWithCode() {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a server code.')),
      );
      return;
    }

    final server = widget.serverManager.findServer(code);

    if (server == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Server not found.')));
      return;
    }

    openLobby(server);
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final servers = publicServers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Server'),
        centerTitle: true,
        backgroundColor: const Color(0xFF276B50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join with a Code',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: Constants.serverCodeLength,
                    decoration: const InputDecoration(
                      hintText: 'Enter server code',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: joinWithCode,
                  child: const Text('JOIN'),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Public Servers',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () {
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: servers.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 55, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No public servers available.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: servers.length,
                      itemBuilder: (context, index) {
                        final server = servers[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.groups),
                            ),
                            title: Text(server.name),
                            subtitle: Text(
                              '${server.players.length}/'
                              '${Constants.maxPlayers} players',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => openLobby(server),
                              child: const Text('JOIN'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
