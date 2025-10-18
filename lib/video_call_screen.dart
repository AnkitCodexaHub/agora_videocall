import 'dart:math';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'participants_list.dart';
import 'video_grid.dart';
import 'control_bar.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final bool isHost;
  final String userName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.userName,
    this.isHost = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  static const String appId = "2264731781464d4e8764ce1c02be1c46";
  static const String token =
      "007eJxTYLj8ar9N3JtuMe713pxVp7cb3lH4ae71ckkQc4vFtMBz84MUGIyMzEzMjQ3NLQxNzExSTFItzM1MklMNkw2MkoCkiZlV/OeMhkBGhk+pOUyMDBAI4rMwlKQWlzAwAAAuXx7+";

  final int _localUid = Random().nextInt(1000000);
  RtcEngine? _engine;
  bool _localUserJoined = false;

  final List<int> _remoteUids = [];
  final Map<int, Map<String, bool>> _remoteMuteStatus = {};
  final Map<int, String> _userNames = {};

  bool _isMicMuted = true;
  bool _isCameraOff = true;
  bool _isScreenSharing = false;
  bool _isHandRaised = false;

  int? _activeSpeakerUid;
  final Map<int, bool> _raisedHands = {};

  final ClientRoleType _fixedRole = ClientRoleType.clientRoleBroadcaster;

  @override
  void initState() {
    super.initState();
    _userNames[_localUid] = widget.userName;
    _initAgora();
  }


  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(appId: appId));

    await _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) =>
            setState(() => _localUserJoined = true),
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() {
            _remoteUids.add(remoteUid);
            _remoteMuteStatus[remoteUid] = {'audio': false, 'video': false};
            _userNames[remoteUid] = "Participant $remoteUid";
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          setState(() {
            _remoteUids.remove(remoteUid);
            _remoteMuteStatus.remove(remoteUid);
            _userNames.remove(remoteUid);
            _raisedHands.remove(remoteUid);
          });
        },
        onRemoteAudioStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          setState(() {
            final isMuted =
                state == RemoteAudioState.remoteAudioStateStopped;
            _remoteMuteStatus[remoteUid] ??= {
              'audio': false,
              'video': false,
            };
            _remoteMuteStatus[remoteUid]!['audio'] = isMuted;
          });
        },
        onRemoteVideoStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          setState(() {
            final isOff = state == RemoteVideoState.remoteVideoStateStopped;
            _remoteMuteStatus[remoteUid] ??= {
              'audio': false,
              'video': false,
            };
            _remoteMuteStatus[remoteUid]!['video'] = isOff;
          });
        },
        onAudioVolumeIndication:
            (connection, speakers, totalVolume, deviceVolume) {
          int? speakingUid;

          for (var speaker in speakers) {
            final uid = speaker.uid == 0 ? _localUid : speaker.uid;

            if (speaker.volume! > 5) {
              speakingUid = uid;
              break;
            }
          }

          setState(() {
            if (speakingUid != null && speakingUid != _activeSpeakerUid) {
              _activeSpeakerUid = speakingUid;
            } else if (speakingUid == null &&
                _activeSpeakerUid != null &&
                totalVolume < 5) {
              _activeSpeakerUid = null;
            }
          });
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.setClientRole(role: _fixedRole);

    await _engine!.muteLocalAudioStream(_isMicMuted);
    await _engine!.enableLocalVideo(!_isCameraOff);

    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      uid: _localUid,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: _fixedRole,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  void _toggleMic() async {
    setState(() => _isMicMuted = !_isMicMuted);
    await _engine!.muteLocalAudioStream(_isMicMuted);
  }

  void _toggleCamera() async {
    setState(() => _isCameraOff = !_isCameraOff);
    await _engine!.enableLocalVideo(!_isCameraOff);
  }

  void _switchCamera() {
    _engine!.switchCamera();
  }

  void _toggleScreenShare() {
    setState(() => _isScreenSharing = !_isScreenSharing);
  }

  void _toggleHand() {
    if (!widget.isHost) {
      setState(() => _isHandRaised = !_isHandRaised);
      if (_isHandRaised) {
        _raisedHands[_localUid] = true;
      } else {
        _raisedHands.remove(_localUid);
      }
      _refreshParticipantsList();
    }
  }

  void _toggleRemoteMic(int uid, bool isMuted) async {
    if (uid == _localUid) {
      _toggleMic();
      return;
    }

    await _engine!.muteRemoteAudioStream(uid: uid, mute: isMuted);

    setState(() {
      _remoteMuteStatus[uid]!['audio'] = isMuted;
    });
    _refreshParticipantsList();
  }

  void _toggleRemoteCamera(int uid, bool isOff) async {
    if (uid == _localUid) {
      _toggleCamera();
      return;
    }

    await _engine!.muteRemoteVideoStream(uid: uid, mute: isOff);

    setState(() {
      _remoteMuteStatus[uid]!['video'] = isOff;
    });
    _refreshParticipantsList();
  }

  void _shareMeetingLink() {
    Share.share('Join my live meeting: ${widget.channelName}');
  }

  void _endCall() => Navigator.of(context).pop();

  void _refreshParticipantsList() {
    setState(() {});
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, ClientRoleType> allBroadcasters = {
      _localUid: _fixedRole,
      for (var uid in _remoteUids) uid: _fixedRole,
    };

    final bool isHost = widget.isHost;

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(widget.channelName),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _endCall),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: VideoGrid(
                engine: _engine,
                localUid: _localUid,
                remoteUids: _remoteUids,
                remoteRoles: allBroadcasters,
                remoteMuteStatus: _remoteMuteStatus,
                isLocalUserJoined: _localUserJoined,
                isCameraOff: _isCameraOff,
                isMicMuted: _isMicMuted,
                channelName: widget.channelName,
                userNames: _userNames,
                raisedHands: _raisedHands,
                onRoleChange: null,
                activeSpeakerUid: _activeSpeakerUid,
                isHost: isHost,
              ),
            ),
          ),
          ControlBar(
            isHost: isHost,
            isLocalBroadcaster: true,
            isMicMuted: _isMicMuted,
            isCameraOff: _isCameraOff,
            isScreenSharing: _isScreenSharing,
            isHandRaised: _isHandRaised,
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
                  remoteRoles: allBroadcasters,
                  remoteMuteStatus: _remoteMuteStatus,
                  userNames: _userNames,
                  engine: _engine!,
                  isHost: isHost,
                  notifyParent: _refreshParticipantsList,
                  isLocalMicMuted: _isMicMuted,
                  isLocalCameraOff: _isCameraOff,
                  onRoleChange: (_, __) {},
                  raisedHands: _raisedHands,
                  onToggleRemoteMic: _toggleRemoteMic,
                  onToggleRemoteCamera: _toggleRemoteCamera,
                ),
              );
            },
            onEndCall: _endCall,
            onToggleHand: isHost ? null : _toggleHand,
          ),
        ],
      ),
    );
  }
}