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
  int _pinnedUid = 0;

  @override
  void initState() {
    super.initState();
    _pinnedUid = widget.localUid;
    _updatePinnedUid();
  }

  @override
  void didUpdateWidget(VideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remoteUids != oldWidget.remoteUids ||
        widget.activeSpeakerUid != oldWidget.activeSpeakerUid ||
        widget.isCameraOff != oldWidget.isCameraOff) {
      _updatePinnedUid();
    }
  }

  void _updatePinnedUid() {
    final List<int> allUids = [widget.localUid, ...widget.remoteUids];
    int? newPinnedCandidate;

    bool isVideoOff(int uid) {
      if (uid == widget.localUid) {
        return widget.isCameraOff;
      }
      return widget.remoteMuteStatus[uid]?['video'] ?? true;
    }

    if (widget.activeSpeakerUid != null &&
        allUids.contains(widget.activeSpeakerUid) &&
        !isVideoOff(widget.activeSpeakerUid!)) {
      newPinnedCandidate = widget.activeSpeakerUid!;
    }

    if (newPinnedCandidate == null &&
        allUids.contains(_pinnedUid) &&
        !isVideoOff(_pinnedUid)) {
      newPinnedCandidate = _pinnedUid;
    }

    if (newPinnedCandidate == null && !widget.isCameraOff) {
      newPinnedCandidate = widget.localUid;
    }

    if (newPinnedCandidate == null) {
      for (final uid in widget.remoteUids) {
        if (!isVideoOff(uid)) {
          newPinnedCandidate = uid;
          break;
        }
      }
    }

    if (newPinnedCandidate == null || newPinnedCandidate == 0) {
      newPinnedCandidate = widget.localUid;
    }

    if (newPinnedCandidate != _pinnedUid) {
      setState(() => _pinnedUid = newPinnedCandidate!);
    }
  }

  Widget _videoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = 12,
  }) {
    final isTileAudioMuted = isLocal
        ? widget.isMicMuted
        : widget.remoteMuteStatus[uid]?['audio'] ?? true;
    final isTileVideoOff = isLocal
        ? widget.isCameraOff
        : widget.remoteMuteStatus[uid]?['video'] ?? true;

    String displayName = widget.userNames[uid] ?? 'User $uid';
    if (isLocal) {
      displayName += ' (You)';
    }

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
              const Icon(
                Icons.videocam_off_rounded,
                size: 30,
                color: Colors.white,
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

    Color? borderColor;
    if (_pinnedUid == uid) {
      if (widget.activeSpeakerUid == uid && !isTileVideoOff) {
        borderColor = Colors.redAccent;
      } else {
        borderColor = Colors.blue;
      }
    }

    return GestureDetector(
      onTap: () {
        if (_pinnedUid != uid) setState(() => _pinnedUid = uid);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderColor != null
              ? Border.all(color: borderColor, width: 3)
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