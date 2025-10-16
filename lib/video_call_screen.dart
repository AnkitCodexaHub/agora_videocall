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
  static const String appId = "2264731781464d4e8764ce1c02be1c46";
  static const String token =
      "007eJxTYDApY+Ho1jmRZnu42TE1IzdM5MDKbyHCHhf3aN1nvpvBwavAYGRkZmJubGhuYWhiZpJikmphbmaSnGqYbGCUBCRNzN7t/pDREMjIwMVoycrIAIEgPgtDSWpxCQMDAEXvG/s=";

  final int _localUid = Random().nextInt(10000000);
  RtcEngine? _engine;
  bool _localUserJoined = false;

  final List<int> _remoteUids = [];
  final Map<int, ClientRoleType> _remoteRoles = {};
  final Map<int, Map<String, bool>> _remoteMuteStatus = {};
  final Map<int, String> _userNames = {};
  final Map<int, bool> _raisedHands = {};

  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isScreenSharing = false;

  ClientRoleType get _localRole => widget.isHost
      ? ClientRoleType.clientRoleBroadcaster
      : _remoteRoles[_localUid] ?? ClientRoleType.clientRoleAudience;

  bool get _isLocalBroadcaster =>
      _localRole == ClientRoleType.clientRoleBroadcaster;

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
        onJoinChannelSuccess: (connection, elapsed) =>
            setState(() => _localUserJoined = true),
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
            _remoteRoles[remoteUid] = ClientRoleType.clientRoleAudience;
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
        onClientRoleChanged: (connection, oldRole, newRole, newRoleOptions) {
          setState(() {
            _remoteRoles[_localUid] = newRole;
            final isNowBroadcaster =
                newRole == ClientRoleType.clientRoleBroadcaster;
            _engine!.muteLocalAudioStream(!isNowBroadcaster);
            _engine!.enableLocalVideo(isNowBroadcaster);
            _isMicMuted = !isNowBroadcaster;
            _isCameraOff = !isNowBroadcaster;
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

    _isMicMuted = !widget.isHost;
    _isCameraOff = !widget.isHost;

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: _localUid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: widget.isHost
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
        publishCameraTrack: widget.isHost,
        publishMicrophoneTrack: widget.isHost,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  void _toggleMic() {
    if (!_isLocalBroadcaster) return;
    setState(() => _isMicMuted = !_isMicMuted);
    _engine!.muteLocalAudioStream(_isMicMuted);
  }

  void _toggleCamera() {
    if (!_isLocalBroadcaster) return;
    setState(() => _isCameraOff = !_isCameraOff);
    _engine!.enableLocalVideo(!_isCameraOff);
  }

  void _switchCamera() {
    if (!_isLocalBroadcaster) return;
    _engine!.switchCamera();
  }

  void _toggleScreenShare() {
    if (!_isLocalBroadcaster) return;
    setState(() => _isScreenSharing = !_isScreenSharing);
  }

  void _shareMeetingLink() {
    Share.share('Join my live meeting: ${widget.channelName}');
  }

  void _endCall() => Navigator.of(context).pop();

  void _promoteToSpeaker(int uid, bool promote) async {
    if (!widget.isHost || uid == _localUid) return;
    final newRole = promote
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;
    await _engine!.setClientRole(
      role: newRole,
      options: const ClientRoleOptions(
        audienceLatencyLevel:
            AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
      ),
    );
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
    final isLocalBroadcaster = _isLocalBroadcaster;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          '${widget.channelName} (${isLocalBroadcaster ? 'Live' : 'Watching'})',
        ),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _endCall),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
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
            isLocalBroadcaster: isLocalBroadcaster,
            isMicMuted: _isMicMuted,
            isCameraOff: _isCameraOff,
            isScreenSharing: _isScreenSharing,
            isHandRaised: !isLocalBroadcaster
                ? (_raisedHands[_localUid] ?? false)
                : false,
            onToggleMic: _toggleMic,
            onToggleCamera: _toggleCamera,
            onSwitchCamera: _switchCamera,
            onToggleScreenShare: _toggleScreenShare,
            onShare: _shareMeetingLink,
            onShowParticipants: () {
              setState(() {});
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => ParticipantsList(
                  localUid: _localUid,
                  remoteUids: _remoteUids,
                  remoteRoles: Map.from(_remoteRoles)..[_localUid] = _localRole,
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
            onEndCall: _endCall,
            onToggleHand: !isLocalBroadcaster
                ? () => setState(
                    () => _raisedHands[_localUid] =
                        !(_raisedHands[_localUid] ?? false),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
