import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as agora;

class VideoGrid extends StatefulWidget {
  final RtcEngine? engine;
  final int localUid;
  final String channelName;
  final List<int> remoteUids;
  final Map<int, ClientRoleType> remoteRoles;
  final Map<int, Map<String, bool>> remoteMuteStatus;
  final bool isLocalUserJoined;
  final bool isCameraOff;
  final bool isMicMuted;
  final Map<int, String> userNames;
  final Map<int, bool> raisedHands;
  final Function(int uid, bool promote)? onRoleChange;
  final bool isHost;
  final int? activeSpeakerUid;

  const VideoGrid({
    super.key,
    required this.engine,
    required this.localUid,
    required this.channelName,
    required this.remoteUids,
    required this.remoteRoles,
    required this.remoteMuteStatus,
    required this.isLocalUserJoined,
    required this.isCameraOff,
    required this.isMicMuted,
    required this.userNames,
    required this.raisedHands,
    required this.isHost,
    required this.activeSpeakerUid,
    this.onRoleChange,
  });

  @override
  State<VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends State<VideoGrid> {
  late int _pinnedUid;

  @override
  void initState() {
    super.initState();
    _pinnedUid = widget.localUid;
  }

  void _togglePin(int uid) {
    setState(() {
      _pinnedUid = (_pinnedUid == uid) ? widget.localUid : uid;
    });
  }

  Widget _videoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = 12.0,
  }) {
    final bool isVideoMuted = isLocal
        ? widget.isCameraOff
        : widget.remoteMuteStatus[uid]?['video'] ?? false;
    final bool isAudioMuted = isLocal
        ? widget.isMicMuted
        : widget.remoteMuteStatus[uid]?['audio'] ?? false;
    final String name = widget.userNames[uid] ?? 'User $uid';
    final bool isSpeaking = uid == widget.activeSpeakerUid;
    final bool isHandRaised = widget.raisedHands[uid] ?? false; // Check hand status

    return GestureDetector(
      onTap: () => _togglePin(uid),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: isSpeaking
              ? Border.all(color: Colors.blueAccent, width: 3.0)
              : Border.all(color: Colors.transparent, width: 0),
          color: const Color(0xFF1E1E1E),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Video Surface
            if (!isVideoMuted)
              agora.AgoraVideoView(
                controller: agora.VideoViewController(
                  rtcEngine: widget.engine!,
                  canvas: agora.VideoCanvas(uid: isLocal ? 0 : uid),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, size: 50, color: Colors.white70),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // User Info and Mute Status Overlay (Bottom Left)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Mute Icon
                    Icon(
                      isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: isAudioMuted ? Colors.red : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // NEW: Raised Hand Indicator (Top Right)
            if (isHandRaised)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.waving_hand,
                  color: Colors.yellow,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLocalUserJoined || widget.engine == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<int> allUids = [widget.localUid, ...widget.remoteUids];
    final int pinnedUid = _pinnedUid;
    List<int> smallUids = allUids.where((uid) => uid != pinnedUid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _videoTile(
            uid: pinnedUid,
            isLocal: pinnedUid == widget.localUid,
            borderRadius: 0,
          ),
        ),
        if (smallUids.isNotEmpty) const SizedBox(height: 8),

        if (smallUids.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: smallUids.length,
              itemBuilder: (context, index) {
                final uid = smallUids[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _videoTile(
                      uid: uid,
                      isLocal: uid == widget.localUid,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}