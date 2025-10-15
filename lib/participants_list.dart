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
  });

  void _forceToggleRemote(int uid, bool muteAudio) async {
    if (!isHost) return;
    final key = muteAudio ? 'audio' : 'video';
    final current = remoteMuteStatus[uid]?[key] ?? false;

    if (muteAudio) {
      // Mute/Unmute audio
      await engine.muteRemoteAudioStream(uid: uid, mute: !current);
    } else {
      // Mute/Unmute video
      await engine.muteRemoteVideoStream(uid: uid, mute: !current);
    }

    // Update local state and trigger UI refresh
    remoteMuteStatus[uid]?[key] = !current;
    notifyParent();
  }

  void _toggleUserRole(int uid) {
    if (!isHost) return;
    final isBroadcaster = remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster;

    // Call the callback function from the parent to change the role
    onRoleChange(uid, !isBroadcaster);
  }

  // Helper to get role of a remote user, or infer local user role
  ClientRoleType _getUserRole(int uid) {
    if (uid == localUid) {
      return isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience;
    }
    return remoteRoles[uid] ?? ClientRoleType.clientRoleAudience;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Combine local and remote UIDs
    final List<int> allUids = [localUid, ...remoteUids];

    // 2. Sort: Broadcasters first, then Audience, with Host always on top of the broadcasters
    allUids.sort((a, b) {
      final aRole = _getUserRole(a);
      final bRole = _getUserRole(b);

      // Host (local user) should always be first
      if (a == localUid && isHost) return -1;
      if (b == localUid && isHost) return 1;

      // Broadcasters before Audience
      if (aRole == ClientRoleType.clientRoleBroadcaster &&
          bRole == ClientRoleType.clientRoleAudience) return -1;
      if (aRole == ClientRoleType.clientRoleAudience &&
          bRole == ClientRoleType.clientRoleBroadcaster) return 1;

      return 0; // Maintain insertion order for same roles
    });

    return FractionallySizedBox(
      heightFactor: 0.8, // Make the bottom sheet cover 80% of the screen
      child: Container(
        padding: const EdgeInsets.only(top: 16, left: 8, right: 8),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E), // Darker background for the sheet
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle (for dragging down)
            Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Participants (${allUids.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allUids.length,
                itemBuilder: (context, index) {
                  final uid = allUids[index];
                  final isLocal = uid == localUid;
                  final displayName = userNames[uid] ?? (isLocal ? 'You (Local)' : 'User $uid');
                  final role = _getUserRole(uid);
                  final isBroadcaster = role == ClientRoleType.clientRoleBroadcaster;

                  // Determine mute status
                  final isAudioMuted = isLocal
                      ? isLocalMicMuted
                      : remoteMuteStatus[uid]?['audio'] ?? false;
                  final isVideoMuted = isLocal
                      ? isLocalCameraOff
                      : remoteMuteStatus[uid]?['video'] ?? false;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBroadcaster ? Colors.redAccent : Colors.blueGrey,
                      child: Text(
                        displayName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isBroadcaster ? 'Speaker' : 'Audience',
                      style: TextStyle(
                        color: isBroadcaster ? Colors.greenAccent : Colors.white70,
                      ),
                    ),
                    trailing: isHost && !isLocal
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Audio Toggle Button (Host can toggle remote users)
                        IconButton(
                          icon: Icon(
                            isAudioMuted ? Icons.mic_off : Icons.mic,
                            color: isAudioMuted ? Colors.red : Colors.green,
                          ),
                          onPressed: () => _forceToggleRemote(uid, true),
                        ),
                        // Video Toggle Button
                        IconButton(
                          icon: Icon(
                            isVideoMuted ? Icons.videocam_off : Icons.videocam,
                            color: isVideoMuted ? Colors.red : Colors.green,
                          ),
                          onPressed: () => _forceToggleRemote(uid, false),
                        ),
                        // Role Button
                        TextButton(
                          onPressed: () => _toggleUserRole(uid),
                          child: Text(
                            isBroadcaster ? 'Demote' : 'Promote',
                            style: TextStyle(
                              color: isBroadcaster
                                  ? Colors.deepOrange
                                  : Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    )
                        : null, // Host controls for remote users.
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
