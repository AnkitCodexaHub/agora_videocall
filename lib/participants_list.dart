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

  void _toggleRemoteAudioVideo(int uid, bool muteAudio) async {
    if (!isHost) return;
    final key = muteAudio ? 'audio' : 'video';
    final current = remoteMuteStatus[uid]?[key] ?? false;
    final newValue = !current;

    if (muteAudio) {
      await engine.muteRemoteAudioStream(uid: uid, mute: newValue);
    } else {
      await engine.muteRemoteVideoStream(uid: uid, mute: newValue);
    }

    remoteMuteStatus.putIfAbsent(uid, () => {'audio': false, 'video': false});
    remoteMuteStatus[uid]![key] = newValue;
    notifyParent();
  }

  void _toggleUserRole(int uid) {
    if (!isHost) return;
    final isBroadcaster =
        remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster;
    onRoleChange(uid, !isBroadcaster);
    notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final allUids = [localUid, ...remoteUids];

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) =>
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Participants (${allUids.length})',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Divider(color: Colors.grey, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: allUids.length,
                    itemBuilder: (context, index) {
                      final uid = allUids[index];
                      final isLocal = uid == localUid;
                      final displayName =
                          userNames[uid] ?? (isLocal ? 'Me' : 'User $uid');
                      final role =
                          remoteRoles[uid] ?? ClientRoleType.clientRoleAudience;
                      final isBroadcaster =
                          role == ClientRoleType.clientRoleBroadcaster;

                      final isAudioMuted = isLocal
                          ? isLocalMicMuted
                          : (remoteMuteStatus[uid]?['audio'] ?? false);
                      final isVideoMuted = isLocal
                          ? isLocalCameraOff
                          : (remoteMuteStatus[uid]?['video'] ?? false);

                      String roleLabel = isBroadcaster
                          ? 'Broadcaster'
                          : 'Audience';
                      if (uid == localUid && isHost) {
                        roleLabel = 'Host';
                      } else if (uid == localUid)
                        roleLabel = 'You ($roleLabel)';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isBroadcaster
                              ? Colors.redAccent
                              : Colors.blueGrey,
                          child: Text(
                            displayName[0],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          roleLabel,
                          style: TextStyle(
                            color: isBroadcaster
                                ? Colors.redAccent
                                : Colors.white70,
                          ),
                        ),
                        trailing: isHost && !isLocal
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isAudioMuted ? Icons.mic_off : Icons.mic,
                                      color: isAudioMuted
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    onPressed: () =>
                                        _toggleRemoteAudioVideo(uid, true),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isVideoMuted
                                          ? Icons.videocam_off
                                          : Icons.videocam,
                                      color: isVideoMuted
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    onPressed: () =>
                                        _toggleRemoteAudioVideo(uid, false),
                                  ),
                                  TextButton(
                                    onPressed: () => _toggleUserRole(uid),
                                    child: Text(
                                      isBroadcaster ? 'Demote' : 'Promote',
                                      style: TextStyle(
                                        color: isBroadcaster
                                            ? Colors.deepOrange
                                            : Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isAudioMuted ? Icons.mic_off : Icons.mic,
                                    color: isAudioMuted
                                        ? Colors.red
                                        : Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isVideoMuted
                                        ? Icons.videocam_off
                                        : Icons.videocam,
                                    color: isVideoMuted
                                        ? Colors.red
                                        : Colors.green,
                                    size: 20,
                                  ),
                                ],
                              ),
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