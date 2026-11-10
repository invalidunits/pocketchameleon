import 'package:flutter/material.dart';

import '../../models/matchmaking/server_manager.dart';
import '../components/menu_button.dart';
import 'create_server_screen.dart';
import 'join_server_screen.dart';
import 'settings_screen.dart';

class MainMenu extends StatelessWidget {
  final ServerManager serverManager;
  final bool musicEnabled;
  final bool sfxEnabled;
  final Function(bool, bool, String) onSettingsChanged;
  final VoidCallback onSignOut;

  const MainMenu({
    super.key,
    required this.serverManager,
    required this.musicEnabled,
    required this.sfxEnabled,
    required this.onSettingsChanged,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF193B35), Color(0xFF356E52), Color(0xFF829E67)],
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
                      builder: (_) =>
                          CreateServerScreen(serverManager: serverManager),
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
                      builder: (_) =>
                          JoinServerScreen(serverManager: serverManager),
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
              MenuButton(
                text: 'SIGN OUT',
                icon: Icons.logout,
                onPressed: onSignOut,
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
