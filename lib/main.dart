import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

// ============================================================
// GAME CONSTANTS
// ============================================================

class GameConstants {
  static const int maxPlayers = 4;
  static const int serverCodeLength = 6;
  static const int maxServerNameLength = 24;
  static const int maxPlayerNameLength = 24;
  static const int randomNameNumberMin = 10;
  static const int randomNameNumberMax = 99;

  static const String codeCharacters =
      'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static const List<String> nameAdjectives = [
    'Sneaky',
    'Clever',
    'Hidden',
    'Silent',
    'Swift',
    'Slippery',
    'Curious',
    'Lucky',
    'Sleepy',
    'Mysterious',
    'Stealthy',
    'Invisible',
    'Visible',
    'Obvious',
  ];

  static const List<String> nameNouns = [
    'Chameleon',
    'Gecko',
    'Rat',
    'Ox',
    'Tiger',
    'Rabbit',
    'Dragon',
    'Snake',
    'Horse',
    'Goat',
    'Monkey',
    'Rooster',
    'Dog',
    'Pig',
  ];
}

// ============================================================
// PLAYER MODEL
// ============================================================

class Player {
  final String id;
  String name;

  Player({
    required this.id,
    required this.name,
  });
}

// ============================================================
// SERVER MODEL
// ============================================================

class GameServer {
  final String name;
  final String code;
  final bool isPublic;

  String hostPlayerId;

  // Private player list.
  // Other classes cannot directly modify this list.
  final List<Player> _players = [];

  GameServer({
    required this.name,
    required this.code,
    required this.isPublic,
    required Player host,
  }) : hostPlayerId = host.id {
    _players.add(host);
  }

  // Provides a read-only version of the player list.
  List<Player> get players =>
      List.unmodifiable(_players);

  // Checks whether a player is the host.
  bool isHost(String playerId) {
    return hostPlayerId == playerId;
  }

  // Adds a player.
  void _addPlayer(Player player) {
    if (!_players.any((p) => p.id == player.id)) {
      _players.add(player);
    }
  }

  // Removes a player.
  void _removePlayer(String playerId) {
    _players.removeWhere((p) => p.id == playerId);
  }

  // Updates a player's name.
  void _updatePlayerName(String playerId, String newName) {
    for (final player in _players) {
      if (player.id == playerId) {
        player.name = newName;
      }
    }
  }

  // Returns whether a player is in this server.
  bool hasPlayer(String playerId) {
    return _players.any((p) => p.id == playerId);
  }
}

// ============================================================
// SERVER MANAGER
// ============================================================

class ServerManager {
  final Random _random = Random.secure();

  final List<GameServer> _servers = [];

  late final Player currentPlayer;

  GameServer? _activeServer;

  ServerManager() {
    currentPlayer = Player(
      id: _generatePlayerId(),
      name: generateRandomName(),
    );
  }

  // Read-only server list.
  List<GameServer> get servers =>
      List.unmodifiable(_servers);

  // Only public servers are displayed in the browser.
  List<GameServer> get publicServers =>
      List.unmodifiable(
        _servers.where((server) => server.isPublic),
      );

  GameServer? get activeServer => _activeServer;

  // ----------------------------------------------------------
  // PLAYER NAME GENERATION
  // ----------------------------------------------------------

  String generateRandomName() {
    final adjective = GameConstants.nameAdjectives[
        _random.nextInt(GameConstants.nameAdjectives.length)];

    final noun = GameConstants.nameNouns[
        _random.nextInt(GameConstants.nameNouns.length)];

    final number = GameConstants.randomNameNumberMin +
        _random.nextInt(
          GameConstants.randomNameNumberMax -
              GameConstants.randomNameNumberMin +
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
        trimmedName.length >
            GameConstants.maxPlayerNameLength) {
      return false;
    }

    currentPlayer.name = trimmedName;

    // Update the player's name in any server they belong to.
    for (final server in _servers) {
      server._updatePlayerName(
        currentPlayer.id,
        trimmedName,
      );
    }

    return true;
  }

  // ----------------------------------------------------------
  // SERVER CODE GENERATION
  // ----------------------------------------------------------

  String generateCode() {
    String code;

    do {
      code = List.generate(
        GameConstants.serverCodeLength,
        (_) => GameConstants.codeCharacters[
            _random.nextInt(
              GameConstants.codeCharacters.length,
            )],
      ).join();
    } while (_servers.any((server) => server.code == code));

    return code;
  }

  // ----------------------------------------------------------
  // CREATE SERVER
  // ----------------------------------------------------------

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

    // Automatically join the server as host.
    _activeServer = server;

    return server;
  }

  // ----------------------------------------------------------
  // FIND SERVER
  // ----------------------------------------------------------

  GameServer? findServer(String code) {
    final normalizedCode = code.trim().toUpperCase();

    for (final server in _servers) {
      if (server.code == normalizedCode) {
        return server;
      }
    }

    return null;
  }

  // ----------------------------------------------------------
  // JOIN SERVER
  // ----------------------------------------------------------

  bool joinServer(GameServer server) {
    if (_activeServer != null) {
      return false;
    }

    if (!_servers.contains(server)) {
      return false;
    }

    if (server.players.length >= GameConstants.maxPlayers) {
      return false;
    }

    if (server.hasPlayer(currentPlayer.id)) {
      return false;
    }

    server._addPlayer(currentPlayer);

    _activeServer = server;

    return true;
  }

  // ----------------------------------------------------------
  // LEAVE SERVER
  // ----------------------------------------------------------

  void leaveServer(GameServer server) {
    if (_activeServer != server) {
      return;
    }

    server._removePlayer(currentPlayer.id);

    _activeServer = null;

    // Automatically close an empty server.
    if (server.players.isEmpty) {
      _servers.remove(server);
      return;
    }

    // Transfer host ownership if the host leaves.
    if (server.hostPlayerId == currentPlayer.id) {
      server.hostPlayerId = server.players.first.id;
    }
  }
}

// ============================================================
// APP ROOT
// ============================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ServerManager serverManager = ServerManager();

  bool musicEnabled = true;
  bool sfxEnabled = true;

  void updateSettings(
    bool music,
    bool sfx,
    String playerName,
  ) {
    setState(() {
      musicEnabled = music;
      sfxEnabled = sfx;

      serverManager.updatePlayerName(playerName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AR Chameleon',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF276B50),
        ),
        scaffoldBackgroundColor: const Color(0xFFF3F5EF),
      ),
      home: MainMenu(
        serverManager: serverManager,
        musicEnabled: musicEnabled,
        sfxEnabled: sfxEnabled,
        onSettingsChanged: updateSettings,
      ),
    );
  }
}
// ============================================================
// MAIN MENU
// ============================================================

class MainMenu extends StatelessWidget {
  final ServerManager serverManager;

  final bool musicEnabled;
  final bool sfxEnabled;

  final Function(bool, bool, String) onSettingsChanged;

  const MainMenu({
    super.key,
    required this.serverManager,
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF193B35),
              Color(0xFF356E52),
              Color(0xFF829E67),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              const Icon(
                Icons.remove_red_eye,
                color: Color(0xFFD9A441),
                size: 65,
              ),

              const SizedBox(height: 15),

              const Text(
                'AR\nCHAMELEON',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'HIDE IN PLAIN SIGHT',
                style: TextStyle(
                  color: Colors.white70,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),

              const Spacer(flex: 3),

              MenuButton(
                text: 'CREATE SERVER',
                icon: Icons.add_circle_outline,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateServerScreen(
                        serverManager: serverManager,
                      ),
                    ),
                  );
                },
              ),

              MenuButton(
                text: 'JOIN SERVER',
                icon: Icons.people_outline,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JoinServerScreen(
                        serverManager: serverManager,
                      ),
                    ),
                  );
                },
              ),

              MenuButton(
                text: 'SETTINGS',
                icon: Icons.settings_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SettingsScreen(
                        musicEnabled: musicEnabled,
                        sfxEnabled: sfxEnabled,
                        playerName: serverManager.currentPlayer.name,
                        onSettingsChanged: onSettingsChanged,
                      ),
                    ),
                  );
                },
              ),

              const Spacer(flex: 3),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    Text(
                      'Player Name:\n${serverManager.currentPlayer.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 45),
                    const Text(
                      'AR CHAMELEON',
                      style: TextStyle(
                        color: Colors.white60,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REUSABLE MENU BUTTON
// ============================================================

class MenuButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 35,
        vertical: 9,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD9A441),
            foregroundColor: const Color(0xFF193B35),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CREATE SERVER SCREEN
// ============================================================

class CreateServerScreen extends StatefulWidget {
  final ServerManager serverManager;

  const CreateServerScreen({
    super.key,
    required this.serverManager,
  });

  @override
  State<CreateServerScreen> createState() =>
      _CreateServerScreenState();
}

class _CreateServerScreenState
    extends State<CreateServerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool isPublic = true;

  void create() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final server = widget.serverManager.createServer(
      _nameController.text.trim(),
      isPublic,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          server: server,
          serverManager: widget.serverManager,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Server'),
        centerTitle: true,
        backgroundColor: const Color(0xFF276B50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.add_circle_outline,
                size: 60,
                color: Color(0xFF276B50),
              ),

              const SizedBox(height: 15),

              const Text(
                'Create a Server',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'Server Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                maxLength: GameConstants.maxServerNameLength,
                decoration: const InputDecoration(
                  hintText: 'Enter server name',
                  prefixIcon: Icon(Icons.edit),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a server name';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Server Visibility',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              RadioListTile<bool>(
                title: const Text('Public'),
                subtitle: const Text(
                  'Anyone can find and join this server.',
                ),
                value: true,
                groupValue: isPublic,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    isPublic = value;
                  });
                },
              ),

              RadioListTile<bool>(
                title: const Text('Private'),
                subtitle: const Text(
                  'Only people with the server code can join.',
                ),
                value: false,
                groupValue: isPublic,
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    isPublic = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: create,
                  child: const Text(
                    'CREATE SERVER',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ============================================================
// JOIN SERVER SCREEN
// ============================================================

class JoinServerScreen extends StatefulWidget {
  final ServerManager serverManager;

  const JoinServerScreen({
    super.key,
    required this.serverManager,
  });

  @override
  State<JoinServerScreen> createState() =>
      _JoinServerScreenState();
}

class _JoinServerScreenState extends State<JoinServerScreen> {
  final _codeController = TextEditingController();

  List<GameServer> get publicServers =>
      widget.serverManager.publicServers;

  void openLobby(GameServer server) {
    final success = widget.serverManager.joinServer(server);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This server is full or unavailable.',
          ),
        ),
      );

      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LobbyScreen(
          server: server,
          serverManager: widget.serverManager,
        ),
      ),
    );
  }

  void joinWithCode() {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a server code.'),
        ),
      );

      return;
    }

    final server = widget.serverManager.findServer(code);

    if (server == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server not found.'),
        ),
      );

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
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization:
                        TextCapitalization.characters,
                    maxLength: GameConstants.serverCodeLength,
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
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
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
                          Icon(
                            Icons.search_off,
                            size: 55,
                            color: Colors.grey,
                          ),

                          SizedBox(height: 10),

                          Text(
                            'No public servers available.',
                          ),
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
                              '${GameConstants.maxPlayers} players',
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

// ============================================================
// SETTINGS SCREEN
// ============================================================

class SettingsScreen extends StatefulWidget {
  final bool musicEnabled;
  final bool sfxEnabled;
  final String playerName;

  final Function(bool, bool, String) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.playerName,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool music;
  late bool sfx;

  late String playerName;

  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();

    music = widget.musicEnabled;
    sfx = widget.sfxEnabled;
    playerName = widget.playerName;

    _nameController = TextEditingController(
      text: playerName,
    );
  }

  void updateSettings() {
    widget.onSettingsChanged(
      music,
      sfx,
      playerName,
    );
  }

  void savePlayerName() {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player name cannot be empty.'),
        ),
      );

      return;
    }

    if (newName.length >
        GameConstants.maxPlayerNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Player name is too long.'),
        ),
      );

      return;
    }

    setState(() {
      playerName = newName;
    });

    updateSettings();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Player name updated!'),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: const Color(0xFF276B50),
        foregroundColor: Colors.white,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.settings,
            size: 65,
            color: Color(0xFF276B50),
          ),

          const SizedBox(height: 20),

          // PLAYER NAME SETTINGS

          const Text(
            'Player Settings',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            'Player Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            maxLength: GameConstants.maxPlayerNameLength,
            decoration: const InputDecoration(
              hintText: 'Enter your player name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: savePlayerName,
              child: const Text('SAVE PLAYER NAME'),
            ),
          ),

          const SizedBox(height: 30),

          // AUDIO SETTINGS

          const Text(
            'Audio Settings',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          SwitchListTile(
            secondary: const Icon(Icons.music_note),
            title: const Text('Music'),
            subtitle: const Text(
              'Turn background music on or off.',
            ),
            value: music,
            onChanged: (value) {
              setState(() {
                music = value;
              });

              updateSettings();
            },
          ),

          const Divider(),

          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Sound Effects'),
            subtitle: const Text(
              'Turn sound effects on or off.',
            ),
            value: sfx,
            onChanged: (value) {
              setState(() {
                sfx = value;
              });

              updateSettings();
            },
          ),

          const SizedBox(height: 30),

          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AR Chameleon',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text('Development Version 0.1'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ============================================================
// LOBBY SCREEN
// ============================================================

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You left the server.'),
      ),
    );

    Navigator.popUntil(
      context,
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = serverManager.currentPlayer;

    final bool isHost = server.isHost(currentPlayer.id);

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

                    Text(
                      server.isPublic
                          ? 'Public Server'
                          : 'Private Server',
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isHost
                          ? 'You are the Host'
                          : 'You are a Player',
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
                      await Clipboard.setData(
                        ClipboardData(text: server.code),
                      );

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

                  Text(
                    '${players.length}/'
                    '${GameConstants.maxPlayers}',
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: players.isEmpty
                    ? const Center(
                        child: Text('No players in this server.'),
                      )
                    : ListView.builder(
                        itemCount: players.length,
                        itemBuilder: (context, index) {
                          final player = players[index];

                          final bool playerIsHost =
                              server.isHost(player.id);

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