import 'package:flutter/material.dart';
import 'video_call_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Meeting App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFFE4405F),
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE4405F),
          secondary: Color(0xFF4A90E2),
          surface: Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE4405F), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE4405F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
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
  final TextEditingController _channelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isHost = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = "User Name";
    _channelController.text = "test";
  }

  void onJoin(BuildContext context) async {
    setState(() => _isJoining = true);

    if (_channelController.text.isNotEmpty && _nameController.text.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: _channelController.text,
            isHost: _isHost,
            userName: _nameController.text,
          ),
        ),
      );
    }
    setState(() => _isJoining = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Meeting'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height:
                MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Join Agora Live Meeting',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Your Name',
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _channelController,
                            decoration: const InputDecoration(
                              labelText: 'Channel Name',
                              prefixIcon: Icon(Icons.meeting_room),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _isHost,
                                onChanged: (val) =>
                                    setState(() => _isHost = val ?? false),
                                activeColor: const Color(0xFFE4405F),
                              ),
                              const Text('Join as Host'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: _isJoining
                                  ? Container(
                                      width: 20,
                                      height: 20,
                                      padding: const EdgeInsets.all(2),
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.group, size: 24),
                              label: Text(
                                _isJoining ? "Joining..." : "Join Meeting",
                                style: const TextStyle(fontSize: 16),
                              ),
                              onPressed: _isJoining
                                  ? null
                                  : () => onJoin(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
