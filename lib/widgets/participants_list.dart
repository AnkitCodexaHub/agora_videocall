import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class ParticipantsList extends StatelessWidget {
  final int localUid;
  final List<int> remoteUids;
  final Map<int, ClientRoleType> remoteRoles;
  final Map<int, Map<String, bool>> remoteMuteStatus;
  final Map<int, String> userNames;
  final RtcEngine engine;
  final bool isHost;
  final VoidCallback notifyParent;
  final bool isLocalMicMuted;
  final bool isLocalCameraOff;
  final Function(int uid, bool promote) onRoleChange;
  final Map<int, bool> raisedHands;
  final Function(int uid, bool isMuted) onToggleRemoteMic;
  final Function(int uid, bool isOff) onToggleRemoteCamera;

  const ParticipantsList({
    super.key,
    required this.localUid,
    required this.remoteUids,
    required this.remoteRoles,
    required this.remoteMuteStatus,
    required this.userNames,
    required this.engine,
    required this.isHost,
    required this.notifyParent,
    required this.isLocalMicMuted,
    required this.isLocalCameraOff,
    required this.onRoleChange,
    required this.raisedHands,
    required this.onToggleRemoteMic,
    required this.onToggleRemoteCamera,
  });

  Widget _buildMuteButton({
    required IconData icon,
    required bool isMuted,
    required VoidCallback onPressed,
    required bool isClickable,
  }) {
    final color = isMuted ? AppColors.muted : AppColors.active;
    
    if (!isClickable) {
      return Icon(icon, color: color, size: 20);
    }

    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final allUids = remoteUids.toList()..insert(0, localUid);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Participants (${allUids.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Participants List
          Expanded(
            child: ListView.builder(
              itemCount: allUids.length,
              itemBuilder: (context, index) {
                final uid = allUids[index];
                final isLocal = uid == localUid;
                final name = userNames[uid] ??
                    '${AppConstants.defaultParticipantNamePrefix} $uid';

                final isAudioMuted = isLocal
                    ? isLocalMicMuted
                    : remoteMuteStatus[uid]?['audio'] ?? false;
                final isVideoMuted = isLocal
                    ? isLocalCameraOff
                    : remoteMuteStatus[uid]?['video'] ?? false;

                final isHandRaised = raisedHands[uid] ?? false;
                final canToggle = isHost && !isLocal;

                final controls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Raised Hand Icon
                    if (isHandRaised)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text('✋', style: TextStyle(fontSize: 20)),
                      ),

                    // Mic Mute Button
                    _buildMuteButton(
                      icon: isAudioMuted ? Icons.mic_off : Icons.mic,
                      isMuted: isAudioMuted,
                      isClickable: canToggle || isLocal,
                      onPressed: () {
                        onToggleRemoteMic(uid, !isAudioMuted);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Camera Mute Button
                    _buildMuteButton(
                      icon: isVideoMuted ? Icons.videocam_off : Icons.videocam,
                      isMuted: isVideoMuted,
                      isClickable: canToggle || isLocal,
                      onPressed: () {
                        onToggleRemoteCamera(uid, !isVideoMuted);
                      },
                    ),
                  ],
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isHost && isLocal
                        ? AppColors.avatarHost
                        : AppColors.avatarDefault,
                    child: Text(
                      name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  title: Text(
                    name + (isLocal ? ' (You)' : ''),
                    style: const TextStyle(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: controls,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

