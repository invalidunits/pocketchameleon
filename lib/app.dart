import 'package:flutter/material.dart';

import 'auth/cognito_auth_service.dart';
import 'models/matchmaking/server_manager.dart';
import 'ui/menus/main_menu.dart';
import 'ui/menus/sign_in_screen.dart';

class MyApp extends StatefulWidget {
  final CognitoAuthService authService;
  final String? configurationError;

  const MyApp({
    super.key,
    required this.authService,
    required this.configurationError,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ServerManager serverManager = ServerManager();

  bool? _isSignedIn;
  String? _authError;

  bool musicEnabled = true;
  bool sfxEnabled = true;

  @override
  void initState() {
    super.initState();
    _authError = widget.configurationError;
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (!widget.authService.isConfigured) {
      setState(() {
        _isSignedIn = false;
      });
      return;
    }

    try {
      final isSignedIn = await widget.authService.isSignedIn();
      if (mounted) {
        setState(() {
          _isSignedIn = isSignedIn;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _authError = error.toString();
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.authService.signOut();
      if (mounted) {
        setState(() {
          _isSignedIn = false;
        });
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not sign out: $error')),
        );
      }
    }
  }

  void updateSettings(bool music, bool sfx, String playerName) {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF276B50)),
        scaffoldBackgroundColor: const Color(0xFFF3F5EF),
      ),
      home: _isSignedIn == null
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _isSignedIn!
          ? MainMenu(
              serverManager: serverManager,
              musicEnabled: musicEnabled,
              sfxEnabled: sfxEnabled,
              onSettingsChanged: updateSettings,
              onSignOut: () => _signOut(),
            )
          : SignInScreen(
              authService: widget.authService,
              configurationError: _authError,
              onSignedIn: () {
                setState(() {
                  _isSignedIn = true;
                  _authError = null;
                });
              },
            ),
    );
  }
}
