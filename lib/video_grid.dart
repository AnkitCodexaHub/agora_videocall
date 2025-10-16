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

    // FIX: If the local user is the Host, they should always be pinned in the large view.
    if (isHost) {
      newPinnedUid = localUid;
    } else {
      // If not the Host (i.e., a Participant), pin the first available remote Broadcaster.
      final remoteBroadcasters = remoteUids.where(
              (uid) => remoteRoles[uid] == ClientRoleType.clientRoleBroadcaster);

      if (remoteBroadcasters.isNotEmpty) {
        newPinnedUid = remoteBroadcasters.first;
      }
    }

    // Fallback: If no other suitable candidate is found, pin the local user.
    if (newPinnedUid == 0) {
      newPinnedUid = localUid;
    }

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
    // FIX: Default to unmuted (false) if status is missing, which is common for broadcasters
        : widget.remoteMuteStatus[uid]?['audio'] ?? false;
    final isTileVideoOff = isLocal
        ? widget.isCameraOff
    // FIX: Default to video on (false) if status is missing, which is common for broadcasters
        : widget.remoteMuteStatus[uid]?['video'] ?? false;

    final isBroadcaster = isLocal
        ? widget.isHost
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

        // Host cannot pin others over themselves (as per the new requirement)
        if (widget.isHost) return;

        setState(() {
          _pinnedUid = uid; // New pinned UID
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

    // The pinnedUidToRender will be the calculated pinned UID
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