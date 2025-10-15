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
  int _pinnedUid = 0; // The UID of the user in the large slot

  @override
  void initState() {
    super.initState();
    // Initialize pinned UID
    _updatePinnedUid(widget.remoteUids, widget.localUid, widget.isHost, widget.remoteRoles);
  }

  @override
  void didUpdateWidget(VideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update pinned UID whenever remote UIDs or role changes happen
    if (widget.remoteUids != oldWidget.remoteUids ||
        widget.isHost != oldWidget.isHost ||
        widget.remoteRoles != oldWidget.remoteRoles) {
      _updatePinnedUid(widget.remoteUids, widget.localUid, widget.isHost, widget.remoteRoles);
    }
  }

  void _updatePinnedUid(List<int> remoteUids, int localUid, bool isHost, Map<int, ClientRoleType> remoteRoles) {
    int newPinnedUid = 0;

    // 1. Find the first Broadcaster (Host/Speaker) among remote users
    final remoteBroadcasters = remoteUids.where(
            (uid) => remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster);

    if (remoteBroadcasters.isNotEmpty) {
      newPinnedUid = remoteBroadcasters.first;
    } else if (isHost) {
      // 2. Fallback: If no remote broadcasters, and the local user is the Host/Broadcaster, pin them.
      newPinnedUid = localUid;
    }

    // This logic ensures the largest stream is always the primary broadcaster (Host or promoted speaker).
    // If the local user is the primary broadcaster and no one else is, they are pinned.
    // If a remote user is a broadcaster, they are pinned, achieving the swap effect
    // where the local host or participant is in the smaller grid/list watching the main speaker.

    if (newPinnedUid != _pinnedUid) {
      setState(() {
        _pinnedUid = newPinnedUid;
      });
    }
  }

  Widget _videoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = 12,
  }) {
    // Determine the mute state
    final isTileAudioMuted = isLocal
        ? widget.isMicMuted
        : widget.remoteMuteStatus[uid]?['audio'] ?? true;
    final isTileVideoOff = isLocal
        ? widget.isCameraOff
        : widget.remoteMuteStatus[uid]?['video'] ?? true;
    final isBroadcaster = isLocal
        ? widget.isHost // Local user role is determined by isHost in this app's context
        : widget.remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster;
    final displayName = widget.userNames[uid] ?? 'User $uid';
    final hasRaisedHand = widget.raisedHands[uid] ?? false;

    // Determine the video rendering widget
    Widget videoWidget;
    if (widget.engine == null || isTileVideoOff) {
      // Placeholder: Display name on a colored background if video is off
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
      // Actual Video View
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
        if (_pinnedUid == uid) return; // Already pinned, do nothing

        setState(() {
          int previousPinned = _pinnedUid; // Save old pinned UID
          _pinnedUid = uid;                // New pinned UID
          // No need to modify small list, small list rebuilds automatically
          // because we exclude _pinnedUid in build()
        });
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
                  color: isTileAudioMuted ? Colors.red.withOpacity(0.8) : Colors.black54,
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
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasRaisedHand)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.pan_tool_alt, color: Colors.yellow, size: 18),
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

    final int largeUid = _pinnedUid;

    List<int> smallListUids = [widget.localUid, ...widget.remoteUids];
    smallListUids.removeWhere((uid) => uid == largeUid);

    final bool isLocalPinned = largeUid == widget.localUid;
    final int pinnedUidToRender = largeUid == 0 ? widget.localUid : largeUid;

    // Check if the local user is a Broadcaster, even if not the Host
    final bool isLocalBroadcaster = widget.isHost || widget.remoteRoles[widget.localUid] == ClientRoleType.clientRoleBroadcaster;


    return Column(
      children: [
        Expanded(
          flex: 5,
          child: pinnedUidToRender == 0
              ? Center(
            child: Text(
              isLocalBroadcaster ? 'You are Live!' : 'Waiting for the Broadcaster...',
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          )
              : _videoTile(
            uid: pinnedUidToRender,
            isLocal: pinnedUidToRender == widget.localUid,
            borderRadius: 0,
          ),
        ),

        const SizedBox(height: 8),

        if (smallListUids.isNotEmpty)
          Container(
            height: 120,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: smallListUids.length,
              itemBuilder: (context, index) {
                final uid = smallListUids[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
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
        const SizedBox(height: 8),
      ],
    );
  }
}
