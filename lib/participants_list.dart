import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

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
    if (!isClickable) {
      return Icon(icon, color: isMuted ? Colors.red : Colors.green, size: 20);
    }

    return IconButton(
      icon: Icon(icon, color: isMuted ? Colors.red : Colors.green, size: 20),
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      splashRadius: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Combine local and remote UIDs
    final allUids = remoteUids.toList()..insert(0, localUid);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
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
                  "Participants (${allUids.length})",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
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
                final isBroadcaster = remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster;
                final name = userNames[uid] ?? 'Participant $uid';

                final isAudioMuted = isLocal
                    ? isLocalMicMuted
                    : remoteMuteStatus[uid]?['audio'] ?? false;
                final isVideoMuted = isLocal
                    ? isLocalCameraOff
                    : remoteMuteStatus[uid]?['video'] ?? false;

                final isHandRaised = raisedHands[uid] ?? false; // Check for raised hand status

                // Only the host can toggle remote status
                final bool canToggle = isHost && !isLocal;

                Widget controls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Raised Hand Icon (✋)
                    if (isHandRaised)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text('✋', style: TextStyle(fontSize: 20)),
                      ),

                    // Mic Mute Button
                    _buildMuteButton(
                      icon: isAudioMuted ? Icons.mic_off : Icons.mic,
                      isMuted: isAudioMuted,
                      isClickable: canToggle || isLocal, // Local user can toggle their own mic
                      onPressed: () {
                        // Pass local or remote status to the handler
                        if (isLocal) {
                          onToggleRemoteMic(uid, !isAudioMuted);
                        } else if (canToggle) {
                          onToggleRemoteMic(uid, !isAudioMuted);
                        }
                      },
                    ),
                    const SizedBox(width: 8),

                    // Camera Mute Button
                    _buildMuteButton(
                      icon: isVideoMuted ? Icons.videocam_off : Icons.videocam,
                      isMuted: isVideoMuted,
                      isClickable: canToggle || isLocal, // Local user can toggle their own camera
                      onPressed: () {
                        // Pass local or remote status to the handler
                        if (isLocal) {
                          onToggleRemoteCamera(uid, !isVideoMuted);
                        } else if (canToggle) {
                          onToggleRemoteCamera(uid, !isVideoMuted);
                        }
                      },
                    ),
                  ],
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isHost && isLocal
                        ? Colors.blue // Host's own avatar color
                        : Colors.grey,
                    child: Text(name.substring(0, 1), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(
                    name + (isLocal ? ' (You)' : ''),
                    style: const TextStyle(color: Colors.white),
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