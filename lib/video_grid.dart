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
  final bool isHost;
  final Map<int, String> userNames;
  final Map<int, bool> raisedHands;
  final Function(int uid, bool promote)? onRoleChange;

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
    required this.isHost,
    required this.userNames,
    required this.raisedHands,
    this.onRoleChange,
  });

  @override
  State<VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends State<VideoGrid> {
  int _pinnedUid = 0;

  @override
  void initState() {
    super.initState();
    _updatePinnedUid();
  }

  @override
  void didUpdateWidget(VideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remoteUids != oldWidget.remoteUids ||
        widget.remoteRoles != oldWidget.remoteRoles ||
        widget.isHost != oldWidget.isHost) {
      _updatePinnedUid();
    }
  }

  void _updatePinnedUid() {
    int newPinned = 0;
    final remoteBroadcasters = widget.remoteUids.where(
      (uid) => widget.remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster,
    );
    if (remoteBroadcasters.isNotEmpty) {
      newPinned = remoteBroadcasters.first;
    } else {
      newPinned = widget.localUid;
    }
    if (newPinned != _pinnedUid) {
      setState(() => _pinnedUid = newPinned);
    }
  }

  Widget _videoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = 12,
  }) {
    final isTileAudioMuted = isLocal
        ? widget.isMicMuted
        : widget.remoteMuteStatus[uid]?['audio'] ?? false;
    final isTileVideoOff = isLocal
        ? widget.isCameraOff
        : widget.remoteMuteStatus[uid]?['video'] ?? false;

    final isBroadcaster =
        widget.remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster;
    final displayName = widget.userNames[uid] ?? 'User $uid';
    final hasRaisedHand = widget.raisedHands[uid] ?? false;

    Widget videoWidget;
    if (widget.engine == null || isTileVideoOff) {
      videoWidget = Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBroadcaster ? Icons.videocam_off_rounded : Icons.person_off,
                size: 30,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else {
      videoWidget = isLocal
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
                connection: agora.RtcConnection(channelId: widget.channelName),
              ),
            );
    }

    return GestureDetector(
      onTap: () {
        if (_pinnedUid != uid) setState(() => _pinnedUid = uid);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
          border: _pinnedUid == uid
              ? Border.all(color: Colors.redAccent, width: 3)
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Positioned.fill(child: videoWidget),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isTileAudioMuted
                      ? Colors.red.withValues(alpha: 0.8)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isTileAudioMuted ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasRaisedHand)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.pan_tool,
                          color: Colors.yellow,
                          size: 18,
                        ),
                      ),
                  ],
                ),
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

    // For host: show grid of all participants
    if (widget.isHost) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          itemCount: allUids.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final uid = allUids[index];
            return _videoTile(uid: uid, isLocal: uid == widget.localUid);
          },
        ),
      );
    }

    // For participants: pinned + horizontal scroll of others
    final int pinnedUid = _pinnedUid;
    List<int> smallUids = allUids.where((uid) => uid != pinnedUid).toList();

    return Column(
      children: [
        Expanded(
          flex: 5,
          child: _videoTile(
            uid: pinnedUid,
            isLocal: pinnedUid == widget.localUid,
            borderRadius: 0,
          ),
        ),
        const SizedBox(height: 8),
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
                    width: 100,
                    height: 100,
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
