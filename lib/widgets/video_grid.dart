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
  final Function(int uid, bool isMuted)? onToggleRemoteMic;
  final Function(int uid, bool isOff)? onToggleRemoteCamera;
  final bool isHost;

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
    this.onToggleRemoteMic,
    this.onToggleRemoteCamera,
    required this.isHost,
  });

  @override
  State<VideoGrid> createState() => _VideoGridState();
}

class _VideoGridState extends State<VideoGrid> {
  late int _pinnedUid;
  // Cache video controllers to avoid duplicate keys
  final Map<int, agora.VideoViewController> _videoControllers = {};

  @override
  void initState() {
    super.initState();
    _pinnedUid = widget.localUid;
    _initializeVideoControllers();
  }

  void _initializeVideoControllers() {
    if (widget.engine == null) return;

    // Initialize controller for local user
    final localController = agora.VideoViewController(
      rtcEngine: widget.engine!,
      canvas: agora.VideoCanvas(uid: 0),
    );
    _videoControllers[widget.localUid] = localController;

    // Initialize controllers for remote users
    for (final uid in widget.remoteUids) {
      if (!_videoControllers.containsKey(uid)) {
        final controller = agora.VideoViewController(
          rtcEngine: widget.engine!,
          canvas: agora.VideoCanvas(uid: uid),
        );
        _videoControllers[uid] = controller;
      }
    }
  }

  @override
  void didUpdateWidget(VideoGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.engine != oldWidget.engine ||
        widget.remoteUids != oldWidget.remoteUids) {
      // Update controllers when remote users change
      _updateVideoControllers();
    }
  }

  void _updateVideoControllers() {
    if (widget.engine == null) return;

    // Remove controllers for users who left
    final currentUids = {widget.localUid, ...widget.remoteUids};
    _videoControllers.removeWhere((uid, _) => !currentUids.contains(uid));

    // Add controllers for new users
    for (final uid in widget.remoteUids) {
      if (!_videoControllers.containsKey(uid)) {
        final controller = agora.VideoViewController(
          rtcEngine: widget.engine!,
          canvas: agora.VideoCanvas(uid: uid),
        );
        _videoControllers[uid] = controller;
      }
    }
  }

  @override
  void dispose() {
    // Dispose all video controllers
    for (final controller in _videoControllers.values) {
      controller.dispose();
    }
    _videoControllers.clear();
    super.dispose();
  }

  void _togglePin(int uid) {
    setState(() {
      _pinnedUid = (_pinnedUid == uid) ? widget.localUid : uid;
    });
  }

  agora.VideoViewController _getVideoController(int uid, bool isLocal) {
    if (_videoControllers.containsKey(uid)) {
      return _videoControllers[uid]!;
    }

    // Create new controller if it doesn't exist
    if (widget.engine != null) {
      final controller = agora.VideoViewController(
        rtcEngine: widget.engine!,
        canvas: agora.VideoCanvas(uid: isLocal ? 0 : uid),
      );
      _videoControllers[uid] = controller;
      return controller;
    }

    throw Exception('Cannot create video controller: engine is null');
  }

  Widget _buildVideoTile({
    required int uid,
    required bool isLocal,
    double borderRadius = AppConstants.videoTileBorderRadius,
    bool showControls = false,
  }) {
    final isVideoMuted = isLocal
        ? widget.isCameraOff
        : widget.remoteMuteStatus[uid]?['video'] ?? false;
    final isAudioMuted = isLocal
        ? widget.isMicMuted
        : widget.remoteMuteStatus[uid]?['audio'] ?? false;
    final name =
        widget.userNames[uid] ??
        '${AppConstants.defaultParticipantNamePrefix} $uid';
    final isSpeaking = uid == widget.activeSpeakerUid;
    final isHandRaised = widget.raisedHands[uid] ?? false;
    // Controls enabled if: local user controlling themselves OR host controlling anyone
    final canControl = isLocal || widget.isHost;

    return GestureDetector(
      key: ValueKey('video_tile_$uid'),
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
            if (!isVideoMuted && widget.engine != null)
              agora.AgoraVideoView(
                key: ValueKey('video_view_$uid'),
                controller: _getVideoController(uid, isLocal),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        name,
                        style: const TextStyle(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

            // User Info Overlay (Top Left)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.overlayDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: isAudioMuted
                          ? AppColors.muted
                          : AppColors.textPrimary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Video/Audio Controls (Bottom) - Show for all participants in grid
            if (showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlayDark.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(borderRadius),
                      bottomRight: Radius.circular(borderRadius),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Audio Toggle - Always visible, enabled only if can control
                      IconButton(
                        icon: Icon(
                          isAudioMuted ? Icons.mic_off : Icons.mic,
                          color: canControl
                              ? (isAudioMuted
                                    ? AppColors.muted
                                    : AppColors.active)
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        onPressed:
                            canControl && widget.onToggleRemoteMic != null
                            ? () {
                                widget.onToggleRemoteMic!(uid, !isAudioMuted);
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: canControl
                            ? (isAudioMuted ? 'Unmute audio' : 'Mute audio')
                            : (isAudioMuted ? 'Audio muted' : 'Audio unmuted'),
                      ),
                      const SizedBox(width: 8),
                      // Video Toggle - Always visible, enabled only if can control
                      IconButton(
                        icon: Icon(
                          isVideoMuted ? Icons.videocam_off : Icons.videocam,
                          color: canControl
                              ? (isVideoMuted
                                    ? AppColors.muted
                                    : AppColors.cameraActive)
                              : AppColors.textSecondary,
                          size: 18,
                        ),
                        onPressed:
                            canControl && widget.onToggleRemoteCamera != null
                            ? () {
                                widget.onToggleRemoteCamera!(
                                  uid,
                                  !isVideoMuted,
                                );
                              }
                            : null,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: canControl
                            ? (isVideoMuted
                                  ? 'Turn on video'
                                  : 'Turn off video')
                            : (isVideoMuted ? 'Video off' : 'Video on'),
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
    final participantsUids = allUids.where((uid) => uid != pinnedUid).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main video area - 70% of screen
        Expanded(
          flex: 7,
          child: _buildVideoTile(
            uid: pinnedUid,
            isLocal: pinnedUid == widget.localUid,
            borderRadius: 0,
            showControls: false,
          ),
        ),

        // Participants grid - 30% of screen
        if (participantsUids.isNotEmpty)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.overlayLight, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: GridView.builder(
                  shrinkWrap: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: participantsUids.length <= 3
                        ? participantsUids.length == 0
                              ? 1
                              : participantsUids.length
                        : 3,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: participantsUids.length,
                  itemBuilder: (context, index) {
                    final uid = participantsUids[index];
                    return _buildVideoTile(
                      uid: uid,
                      isLocal: uid == widget.localUid,
                      showControls: true,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}
