import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'video_call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _channelController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isHost = false;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = AppConstants.defaultUserName;
    _channelController.text = AppConstants.defaultChannelName;
  }

  @override
  void dispose() {
    _channelController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onJoin(BuildContext context) async {
    if (_channelController.text.isEmpty || _nameController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all fields');
      return;
    }

    setState(() => _isJoining = true);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: _channelController.text.trim(),
            isHost: _isHost,
            userName: _nameController.text.trim(),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
            height: MediaQuery.of(context).size.height -
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
                                activeColor: Theme.of(context).primaryColor,
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
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.group, size: 24),
                              label: Text(
                                _isJoining ? 'Joining...' : 'Join Meeting',
                                style: const TextStyle(fontSize: 16),
                              ),
                              onPressed: _isJoining
                                  ? null
                                  : () => _onJoin(context),
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

