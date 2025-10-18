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
      return Icon(
        icon,
        color: isMuted ? Colors.red : Colors.green,
        size: 20,
      );
    }

    return IconButton(
      icon: Icon(
        icon,
        color: isMuted ? Colors.red : Colors.green,
        size: 20,
      ),
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
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
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
          Expanded(
            child: ListView.builder(
              itemCount: allUids.length,
              itemBuilder: (context, index) {
                final uid = allUids[index];
                final isLocal = uid == localUid;

                final isAudioMuted = isLocal
                    ? isLocalMicMuted
                    : remoteMuteStatus[uid]?['audio'] ?? false;
                final isVideoMuted = isLocal
                    ? isLocalCameraOff
                    : remoteMuteStatus[uid]?['video'] ?? false;
                final isHandRaised = raisedHands[uid] ?? false;

                String name = userNames[uid] ?? 'User $uid';
                if (isLocal) name += ' (You)';

                const bool canToggle = true;

                Widget controls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    if (isHandRaised)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text('✋', style: TextStyle(fontSize: 20)),
                      ),

                    _buildMuteButton(
                      icon: isAudioMuted ? Icons.mic_off : Icons.mic,
                      isMuted: isAudioMuted,
                      isClickable: canToggle,
                      onPressed: () {
                        onToggleRemoteMic(uid, !isAudioMuted);
                      },
                    ),
                    const SizedBox(width: 8),

                    _buildMuteButton(
                      icon: isVideoMuted ? Icons.videocam_off : Icons.videocam,
                      isMuted: isVideoMuted,
                      isClickable: canToggle,
                      onPressed: () {
                        onToggleRemoteCamera(uid, !isVideoMuted);
                      },
                    ),
                  ],
                );

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isHost && isLocal
                        ? Colors.blue
                        : Colors.grey,
                    child: Text(name.substring(0, 1)),
                  ),
                  title: Text(name, overflow: TextOverflow.ellipsis),
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