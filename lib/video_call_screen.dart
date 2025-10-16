import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'participants_list.dart';
import 'video_grid.dart';
import 'control_bar.dart';

class VideoCallScreen extends StatefulWidget {
  final bool isHost;
  final String channelName;

  const VideoCallScreen({
    super.key,
    required this.isHost,
    required this.channelName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // NOTE: Replace these with your actual App ID and Token
  static const String appId = "2264731781464d4e8764ce1c02be1c46";
  static const String token =
      "007eJxTYLCb4yLbpXqHb9bUBTunH5fXXuqW5TPZR1j38KW/d16/VrRXYDAyMjMxNzY0tzA0MTNJMUm1MDczSU41TDYwSgKSJmZLyj5kNAQyMlx7w8nKyACBID4LQ0lqcQkDAwARcR9X";

  final int _localUid = Random().nextInt(10000000);
  RtcEngine? _engine;
  bool _localUserJoined = false;

  final List<int> _remoteUids = [];
  final Map<int, ClientRoleType> _remoteRoles = {};

  // FIX: Initialize remote mute status to assume Broadcasters are NOT muted by default
  final Map<int, Map<String, bool>> _remoteMuteStatus = {};
  final Map<int, String> _userNames = {};
  final Map<int, bool> _raisedHands = {};

  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    _userNames[_localUid] = widget.isHost
        ? "Host: ${widget.channelName}"
        : "Participant $_localUid";
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
            // Default new user to Audience, their role will be updated by remote role change event
            _remoteRoles[remoteUid] = ClientRoleType.clientRoleAudience;
            // FIX: Initialize remote mute status optimistically for all new users (unmuted)
            _remoteMuteStatus[remoteUid] = {'audio': false, 'video': false};
            _userNames[remoteUid] = "Participant $remoteUid";
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
            _remoteRoles.remove(remoteUid);
            _remoteMuteStatus.remove(remoteUid);
            _userNames.remove(remoteUid);
            _raisedHands.remove(remoteUid);
          });
        },
      ),
    );

    await _engine!.enableVideo();

    await _engine!.setClientRole(
      role: widget.isHost
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: _localUid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: widget.isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        // Host publishes by default, Participants do not
        publishCameraTrack: widget.isHost,
        publishMicrophoneTrack: widget.isHost,
      ),
    );
  }

  void _onToggleMic() {
    setState(() => _isMicMuted = !_isMicMuted);
    _engine!.muteLocalAudioStream(_isMicMuted);
  }

  void _onToggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _engine!.enableLocalVideo(!_isCameraOff);
  }

  void _switchCamera() => _engine!.switchCamera();

  void _toggleScreenShare() {
    setState(() => _isScreenSharing = !_isScreenSharing);
    // TODO: Implement actual Agora screen sharing logic here
  }

  void _shareMeetingLink() {
    Share.share('Join my live stream on channel: ${widget.channelName}');
  }

  void _onEndCall() => Navigator.of(context).pop();

  void _promoteToSpeaker(int uid, bool promote) {
    if (!widget.isHost) return;
    final newRole = promote
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    setState(() {
      _remoteRoles[uid] = newRole;
      if (promote) _raisedHands.remove(uid);
    });
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(widget.channelName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onEndCall,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: VideoGrid(
              engine: _engine,
              localUid: _localUid,
              remoteUids: _remoteUids,
              remoteRoles: _remoteRoles,
              remoteMuteStatus: _remoteMuteStatus,
              isLocalUserJoined: _localUserJoined,
              isCameraOff: _isCameraOff,
              isMicMuted: _isMicMuted,
              isHost: widget.isHost,
              channelName: widget.channelName,
              userNames: _userNames,
              raisedHands: _raisedHands,
              onRoleChange: _promoteToSpeaker,
            ),
          ),
          ControlBar(
            isHost: widget.isHost,
            isMicMuted: _isMicMuted,
            isCameraOff: _isCameraOff,
            isScreenSharing: _isScreenSharing,
            isHandRaised: !widget.isHost
                ? (_raisedHands[_localUid] ?? false)
                : false,
            onToggleMic: _onToggleMic,
            onToggleCamera: _onToggleCamera,
            onSwitchCamera: _switchCamera,
            onToggleScreenShare: _toggleScreenShare,
            onShare: _shareMeetingLink,
            onShowParticipants: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ParticipantsList(
                  localUid: _localUid,
                  remoteUids: _remoteUids,
                  remoteRoles: _remoteRoles,
                  remoteMuteStatus: _remoteMuteStatus,
                  userNames: _userNames,
                  engine: _engine!,
                  isHost: widget.isHost,
                  notifyParent: () => setState(() {}),
                  isLocalMicMuted: _isMicMuted,
                  isLocalCameraOff: _isCameraOff,
                  onRoleChange: _promoteToSpeaker,
                ),
              );
            },
            onEndCall: _onEndCall,
            onToggleHand: !widget.isHost
                ? () {
              setState(() {
                _raisedHands[_localUid] =
                !(_raisedHands[_localUid] ?? false);
              });
            }
                : null,
          ),
        ],
      ),
    );
  }
}