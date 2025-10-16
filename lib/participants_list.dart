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
    // Safely retrieve current status, defaulting to OFF (false) if missing
    final current = remoteMuteStatus[uid]?[key] ?? false;
    final value = !current;

    if (muteAudio) {
      // Mute/Unmute audio
      await engine.muteRemoteAudioStream(uid: uid, mute: value);
    } else {
      // Mute/Unmute video
      await engine.muteRemoteVideoStream(uid: uid, mute: value);
    }

    notifyParent();
  }

  void _toggleUserRole(int uid) {
    if (!isHost) return;
    final isBroadcaster = remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster;

    // Promote/Demote logic
    onRoleChange(uid, !isBroadcaster);
    notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    // Combine local user and remote users into a single list
    final List<int> allUids = [localUid, ...remoteUids];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Participants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: allUids.length,
                itemBuilder: (context, index) {
                  final uid = allUids[index];
                  final isLocal = uid == localUid;
                  final displayName = userNames[uid] ?? (isLocal ? 'Me (You)' : 'User $uid');

                  // Determine status for the current user
                  final isAudioMuted = isLocal ? isLocalMicMuted : (remoteMuteStatus[uid]?['audio'] ?? false);
                  final isVideoMuted = isLocal ? isLocalCameraOff : (remoteMuteStatus[uid]?['video'] ?? false);
                  final isBroadcaster = isLocal ? isHost : (remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBroadcaster ? Colors.redAccent : Colors.blueGrey,
                      child: Text(
                        displayName.substring(0, 1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      isBroadcaster ? 'Broadcaster' : 'Audience',
                      style: TextStyle(
                        color: isBroadcaster ? Colors.redAccent : Colors.white70,
                      ),
                    ),
                    // Host-only controls for remote users
                    trailing: isHost && !isLocal
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Audio Toggle Button
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
                        : isLocal
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Local user only shows status
                        Icon(Icons.person, color: Colors.white70),
                      ],
                    )
                        : null,
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