import 'package:flutter/material.dart';

class ControlBar extends StatelessWidget {
  final bool isHost;
  final bool isLocalBroadcaster;
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
  final VoidCallback? onToggleHand;

  const ControlBar({
    super.key,
    required this.isHost,
    required this.isLocalBroadcaster,
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

  Widget _buildButton(
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> buttons = [];

    if (isHost) {
      buttons.add(
        _buildButton(
          isMicMuted ? Icons.mic_off : Icons.mic,
          isMicMuted ? Colors.red : Colors.green,
          onToggleMic,
        ),
      );

      buttons.add(
        _buildButton(
          isCameraOff ? Icons.videocam_off : Icons.videocam,
          isCameraOff ? Colors.red : Colors.blue,
          onToggleCamera,
        ),
      );

      if (!isCameraOff) {
        buttons.add(
          _buildButton(
            Icons.flip_camera_ios,
            Colors.white.withValues(alpha: 0.2),
            onSwitchCamera,
          ),
        );
      }

      if (isLocalBroadcaster) {
        buttons.add(
          _buildButton(
            isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            isScreenSharing ? Colors.red : Colors.blue,
            onToggleScreenShare,
          ),
        );
      }

      buttons.add(
        _buildButton(
          Icons.people,
          Colors.white.withValues(alpha: 0.2),
          onShowParticipants,
        ),
      );

      buttons.add(
        _buildButton(Icons.share, Colors.white.withValues(alpha: 0.2), onShare),
      );
    } else {
      if (onToggleHand != null) {
        buttons.add(
          _buildButton(
            Icons.waving_hand,
            isHandRaised
                ? Colors.yellow[700]!
                : Colors.white.withValues(alpha: 0.2),
            onToggleHand!,
            iconColor: isHandRaised ? Colors.black : Colors.white,
          ),
        );
      }
    }

    buttons.add(
      _buildButton(Icons.call_end, const Color(0xFFE4405F), onEndCall),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: buttons
                    .map(
                      (widget) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: widget,
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
