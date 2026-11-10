import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../models/matchmaking/server_manager.dart';
import 'lobby_screen.dart';

class CreateServerScreen extends StatefulWidget {
  final ServerManager serverManager;

  const CreateServerScreen({super.key, required this.serverManager});

  @override
  State<CreateServerScreen> createState() => _CreateServerScreenState();
}

class _CreateServerScreenState extends State<CreateServerScreen> {
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
        builder: (_) =>
            LobbyScreen(server: server, serverManager: widget.serverManager),
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              const Text(
                'Server Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                maxLength: Constants.maxServerNameLength,
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              RadioListTile<bool>(
                title: const Text('Public'),
                subtitle: const Text('Anyone can find and join this server.'),
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
