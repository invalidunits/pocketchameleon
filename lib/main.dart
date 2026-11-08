import 'package:flutter/material.dart';
import 'package:pocketchameleon/little_guy.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Grafitti',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}



class _HomeState extends State<Home> {
  GlobalKey mainScreen = GlobalKey();
  _HomeState()
  {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      littleGuyOverlay = OverlayEntry(builder: (context) =>Positioned(
        bottom: -30,
        left: 0,
        right: 0,
        child: Center(
          child: Semantics(
            button: true,
            label: 'Talk to Little Guy',
            child: GestureDetector(
              onTap: _showTalkDialog,
              child: LittleGuy(key: littleGuy),
            ),
          ),
        ),
      ));

      Overlay.of(context).insert(littleGuyOverlay!);
    });
  }

  
  OverlayEntry? littleGuyOverlay;


  @override
  void dispose() {
    littleGuyOverlay?.remove();
    super.dispose();
  }
  




  final GlobalKey littleGuy = GlobalKey();
  Future<void> _showTalkDialog() async {
    if (littleGuy.currentState is LittleGuyState && mainScreen.currentContext != null && (ModalRoute.of(mainScreen.currentContext!)?.isCurrent ?? false))
    {
      var dialog = await (littleGuy.currentState as LittleGuyState).openTalkDialog("Hello! My name is Little guy!", close: false);
      await (littleGuy.currentState as LittleGuyState).openTalkDialog("Could you help me with something?", dialogKey: dialog);
    }

    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Little Guy')),
      body: Stack(
        key: mainScreen,
        
        children: [
          // OverlayPortal(controller: controller, overlayChildBuilder: overlayChildBuilder)
          
        ],
      ),
    );
  }
}
