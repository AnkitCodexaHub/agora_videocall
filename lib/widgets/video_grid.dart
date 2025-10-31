import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart' as agora;
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';

class VideoGrid extends StatefulWidget {
  final RtcEngine? engine;
  final int localUid;
  final List<int> remoteUids;
  final Map<int, Map<String, bool>> remoteMuteStatus;
  final bool isLocalUserJoined;
  final bool isCameraOff;
  final bool isMicMuted;
  final Map<int, String> userNames;
  final Map<int, bool> raisedHands;
  final int? activeSpeakerUid;

  const VideoGrid({
    super.key,
    required this.engine,
    required this.localUid,
    required this.remoteUids,
    required this.remoteMuteStatus,
    required this.isLocalUserJoined,
    required this.isCameraOff,
    required this.isMicMuted,
    required this.userNames,
    required this.raisedHands,
    required this.activeSpeakerUid,
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

  Widget _buildVideoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = AppConstants.videoTileBorderRadius,
  }) {
    final isVideoMuted = isLocal
        ? widget.isCameraOff
        : widget.remoteMuteStatus[uid]?['video'] ?? false;
    final isAudioMuted = isLocal
        ? widget.isMicMuted
        : widget.remoteMuteStatus[uid]?['audio'] ?? false;
    final name = widget.userNames[uid] ??
        '${AppConstants.defaultParticipantNamePrefix} $uid';
    final isSpeaking = uid == widget.activeSpeakerUid;
    final isHandRaised = widget.raisedHands[uid] ?? false;

    return GestureDetector(
      onTap: () => _togglePin(uid),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: isSpeaking
              ? Border.all(color: AppColors.speaking, width: 3.0)
              : Border.all(color: Colors.transparent, width: 0),
          color: AppColors.surface,
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
                    const Icon(
                      Icons.person,
                      size: 50,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // User Info Overlay (Bottom Left)
            Positioned(
              left: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.overlayDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: isAudioMuted ? AppColors.muted : AppColors.textPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Raised Hand Indicator (Top Right)
            if (isHandRaised)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.waving_hand,
                  color: AppColors.handRaised,
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

    final allUids = [widget.localUid, ...widget.remoteUids];
    final pinnedUid = _pinnedUid;
    final smallUids = allUids.where((uid) => uid != pinnedUid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _buildVideoTile(
            uid: pinnedUid,
            isLocal: pinnedUid == widget.localUid,
            borderRadius: 0,
          ),
        ),
        if (smallUids.isNotEmpty) const SizedBox(height: 8),
        if (smallUids.isNotEmpty)
          SizedBox(
            height: AppConstants.smallVideoTileSize,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: smallUids.length,
              itemBuilder: (context, index) {
                final uid = smallUids[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SizedBox(
                    width: AppConstants.smallVideoTileSize,
                    height: AppConstants.smallVideoTileSize,
                    child: _buildVideoTile(
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

