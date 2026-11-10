import 'package:flutter/material.dart';

import '../../constants.dart';

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
  State<SettingsScreen> createState() => _SettingsScreenState();
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
    _nameController = TextEditingController(text: playerName);
  }

  void updateSettings() {
    widget.onSettingsChanged(music, sfx, playerName);
  }

  void savePlayerName() {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player name cannot be empty.')),
      );
      return;
    }

    if (newName.length > Constants.maxPlayerNameLength) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Player name is too long.')));
      return;
    }

    setState(() {
      playerName = newName;
    });

    updateSettings();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Player name updated!')));
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
          const Icon(Icons.settings, size: 65, color: Color(0xFF276B50)),
          const SizedBox(height: 20),
          const Text(
            'Player Settings',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          const Text(
            'Player Name',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            maxLength: Constants.maxPlayerNameLength,
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
          const Text(
            'Audio Settings',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          SwitchListTile(
            secondary: const Icon(Icons.music_note),
            title: const Text('Music'),
            subtitle: const Text('Turn background music on or off.'),
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
            subtitle: const Text('Turn sound effects on or off.'),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
