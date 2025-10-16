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
      ),
      home: const JoinScreen(),
    );
  }
}

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final TextEditingController _channelController = TextEditingController(
    text: "test",
  );
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void onJoin(BuildContext context, bool isHost) {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoCallScreen(
            channelName: _channelController.text,
            isHost: isHost,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Meeting'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Enter Channel Name",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _channelController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "e.g., Meeting123",
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a valid channel name'
                      : null,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: const Icon(Icons.videocam),
                  label: const Text("Start Meeting (Host)"),
                  onPressed: () => onJoin(context, true),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  icon: const Icon(Icons.group),
                  label: const Text("Join Meeting (Participant)"),
                  onPressed: () => onJoin(context, false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
