import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final bool isHost;
  final bool isMicMuted;
  final bool isCameraOff;
  final bool isScreenSharing;
  final bool isHandRaised;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCamera;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onShare;
  final VoidCallback onShowParticipants;
  final VoidCallback onEndCall;
  final VoidCallback? onToggleHand; // Nullable for participants only

  const ControlBar({
    super.key,
    required this.isHost,
    required this.isMicMuted,
    required this.isCameraOff,
    required this.isScreenSharing,
    required this.isHandRaised,
    required this.onToggleMic,
    required this.onToggleCamera,
    required this.onSwitchCamera,
    required this.onToggleScreenShare,
    required this.onShare,
    required this.onShowParticipants,
    required this.onEndCall,
    this.onToggleHand,
  });

  Widget _buildButton(IconData icon, Color color, VoidCallback onPressed,
      {Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if (isHost) {
      buttons.add(_buildButton(
        isMicMuted ? Icons.mic_off : Icons.mic,
        isMicMuted ? Colors.red : Colors.green,
        onToggleMic,
      ));
      buttons.add(_buildButton(
        isCameraOff ? Icons.videocam_off : Icons.videocam,
        isCameraOff ? Colors.red : Colors.green,
        onToggleCamera,
      ));
      if (!isCameraOff) {
        buttons.add(_buildButton(
          Icons.switch_camera,
          Colors.white.withOpacity(0.2),
          onSwitchCamera,
        ));
      }
      buttons.add(_buildButton(
        isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
        isScreenSharing ? Colors.red : Colors.blue,
        onToggleScreenShare,
      ));
    }

    if (onToggleHand != null) {
      buttons.add(_buildButton(
        isHandRaised ? Icons.pan_tool_alt : Icons.waving_hand,
        isHandRaised ? Colors.yellow[700]! : const Color(0xFFE4405F),
        onToggleHand!,
      ));
    }

    buttons.add(_buildButton(
      Icons.share,
      const Color(0xFFE4405F),
      onShare,
    ));
    buttons.add(_buildButton(
      Icons.people,
      Colors.white.withOpacity(0.2),
      onShowParticipants,
    ));
    buttons.add(_buildButton(
      Icons.call_end,
      Colors.red,
      onEndCall,
    ));

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: Colors.black38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: buttons,
        ),
      ),
    );
  }
}
