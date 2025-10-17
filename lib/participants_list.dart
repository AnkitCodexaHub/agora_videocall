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
  });

  @override
  Widget build(BuildContext context) {
    final allUids = remoteUids.toList()..insert(0, localUid);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1F1F1F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Participants (${allUids.length})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: allUids.length,
              itemBuilder: (context, index) {
                final uid = allUids[index];
                final isLocal = uid == localUid;

                final isAudioMuted = isLocal
                    ? isLocalMicMuted
                    : remoteMuteStatus[uid]?['audio'] ?? true;
                final isVideoMuted = isLocal
                    ? isLocalCameraOff
                    : remoteMuteStatus[uid]?['video'] ?? true;
                final isHandRaised = raisedHands[uid] ?? false;

                String name = userNames[uid] ?? 'User $uid';
                if (isLocal) name += ' (You)';

                Widget controls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHandRaised && !isLocal)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Text('✋', style: TextStyle(fontSize: 20)),
                      ),
                    Icon(
                      isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: isAudioMuted ? Colors.red : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isVideoMuted ? Icons.videocam_off : Icons.videocam,
                      color: isVideoMuted ? Colors.red : Colors.green,
                      size: 20,
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
