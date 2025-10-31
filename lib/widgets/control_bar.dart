import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

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

  Widget _buildButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    Color iconColor = AppColors.textPrimary,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: AppConstants.controlBarButtonSize,
        height: AppConstants.controlBarButtonSize,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: AppConstants.controlBarIconSize,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> buttons = [];

    if (isHost) {
      // Mic button
      buttons.add(
        _buildButton(
          icon: isMicMuted ? Icons.mic_off : Icons.mic,
          color: isMicMuted ? AppColors.muted : AppColors.active,
          onPressed: onToggleMic,
        ),
      );

      // Camera button
      buttons.add(
        _buildButton(
          icon: isCameraOff ? Icons.videocam_off : Icons.videocam,
          color: isCameraOff ? AppColors.muted : AppColors.cameraActive,
          onPressed: onToggleCamera,
        ),
      );

      // Switch camera button (only when camera is on)
      if (!isCameraOff) {
        buttons.add(
          _buildButton(
            icon: Icons.flip_camera_ios,
            color: AppColors.overlayLight,
            onPressed: onSwitchCamera,
          ),
        );
      }

      // Screen share button (only for broadcasters)
      if (isLocalBroadcaster) {
        buttons.add(
          _buildButton(
            icon: isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            color: isScreenSharing ? AppColors.muted : AppColors.cameraActive,
            onPressed: onToggleScreenShare,
          ),
        );
      }

      // Participants list button
      buttons.add(
        _buildButton(
          icon: Icons.people,
          color: AppColors.overlayLight,
          onPressed: onShowParticipants,
        ),
      );

      // Share button
      buttons.add(
        _buildButton(
          icon: Icons.share,
          color: AppColors.overlayLight,
          onPressed: onShare,
        ),
      );
    } else {
      // Hand raise button (only for non-hosts)
      if (onToggleHand != null) {
        buttons.add(
          _buildButton(
            icon: Icons.waving_hand,
            color: isHandRaised ? AppColors.handRaisedDark : AppColors.overlayLight,
            onPressed: onToggleHand!,
            iconColor: isHandRaised ? Colors.black : AppColors.textPrimary,
          ),
        );
      }
    }

    // End call button (always visible)
    buttons.add(
      _buildButton(
        icon: Icons.call_end,
        color: AppColors.primary,
        onPressed: onEndCall,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24.0,
        left: 16,
        right: 16,
      ),
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

