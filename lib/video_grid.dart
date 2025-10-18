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

  void _onTapVideo(int uid) {
    setState(() {
      _pinnedUid = uid;
    });
  }

  Widget _videoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = 12,
  }) {
    final String userName = widget.userNames[uid] ?? 'User $uid';
    final String displayName = isLocal ? '$userName (You)' : userName;

    final bool isMuted = isLocal
        ? widget.isMicMuted
        : (widget.remoteMuteStatus[uid]?['audio'] ?? false);
    final bool isCameraOff = isLocal
        ? widget.isCameraOff
        : (widget.remoteMuteStatus[uid]?['video'] ?? false);
    final bool isHandRaised = widget.raisedHands[uid] ?? false;

    final bool isBroadcaster = isLocal ||
        (widget.remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster);
    final bool isActiveSpeaker = widget.activeSpeakerUid == uid;

    final Color borderColor = isActiveSpeaker
        ? const Color(0xFF4A90E2)
        : Colors.transparent;

    return GestureDetector(
      onTap: () => _onTapVideo(uid),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor,
            width: 3.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Video View
              if (isBroadcaster && !isCameraOff && widget.engine != null)
                isLocal
                    ? agora.AgoraVideoView(
                  controller: agora.VideoViewController(
                    rtcEngine: widget.engine!,
                    canvas: const agora.VideoCanvas(uid: 0),
                  ),
                )
                    : agora.AgoraVideoView(
                  controller: agora.VideoViewController.remote(
                    rtcEngine: widget.engine!,
                    canvas: agora.VideoCanvas(uid: uid),
                    connection: agora.RtcConnection(
                        channelId: widget.channelName),
                  ),
                )
              else
              // 2. Camera Off Placeholder (Display Name is here)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_off,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        // Display the user's name
                        Text(
                          displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Name and Status Overlay (Always visible)
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mute Icon
                      Icon(
                        isMuted ? Icons.mic_off : Icons.mic,
                        color: isMuted ? Colors.red : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),

                      // Hand Raised Icon
                      if (isHandRaised)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Text('✋', style: TextStyle(fontSize: 20)),
                        ),

                      // User Name
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            displayName, // Display the user's name
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Host Badge Overlay
              if (widget.isHost && isLocal)
                const Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  // --- END OF MODIFIED METHOD ---

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
        // Main/Pinned Video
        Expanded(
          flex: 5,
          child: _videoTile(
            uid: pinnedUid,
            isLocal: pinnedUid == widget.localUid,
            borderRadius: 0,
          ),
        ),
        if (smallUids.isNotEmpty) const SizedBox(height: 8),

        // Small Video Grid (Horizontal Scroll)
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