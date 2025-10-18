// video_call_screen.dart

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
  final String userName; // <-- The user's entered name

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.userName,
    this.isHost = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> with WidgetsBindingObserver {
  // NOTE: Replace these with your actual Agora App ID and Token
  static const String appId = "2264731781464d4e8764ce1c02be1c46";
  static const String token =
      "007eJxTYLjCwTjjUlHgIanJi4+l7F2VcZ1ZeeKR+2uOWdWJ5xj3bhRRYDAyMjMxNzY0tzA0MTNJMUm1MDczSU41TDYwSgKSJma1tp8zGgIZGdi50xgZGSAQxGdhKEktLmFgAA";

  RtcEngine? _engine;
  bool isJoined = false;

  // Initialized to 0. Agora will assign the actual UID on join.
  int _localUid = 0;

  List<int> _remoteUids = [];
  Map<int, Map<String, bool>> _remoteMuteStatus = {};
  Map<int, ClientRoleType> _remoteRoles = {};
  Map<int, String> _userNames = {};
  Map<int, bool> _raisedHands = {};

  // Active Speaker State
  int? _activeSpeakerUid;

  // Local Media State
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isScreenSharing = false;
  bool _isHandRaised = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // REMOVED: Manual random UID generation.
    // The name will be associated after joining the channel.

    _initAgora();
  }

  @override
  void dispose() {
    _dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
  }

  Future<bool> _checkPermissions() async {
    if (await Permission.camera.request().isDenied ||
        await Permission.microphone.request().isDenied) {
      return false;
    }
    return true;
  }

  Future<void> _initAgora() async {
    if (!await _checkPermissions()) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
    ));

    ClientRoleType clientRole =
    widget.isHost ? ClientRoleType.clientRoleBroadcaster : ClientRoleType.clientRoleAudience;

    await _engine!.setClientRole(role: clientRole);

    _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    _addAgoraEventHandlers();

    await _engine!.enableVideo();
    await _engine!.startPreview();

    ChannelMediaOptions options = ChannelMediaOptions(
      clientRoleType: clientRole,
      channelProfile: ChannelProfileType.channelProfileCommunication,
      publishMicrophoneTrack: !_isMicMuted,
      publishCameraTrack: !_isCameraOff,
    );

    // Pass _localUid (which is 0) to tell Agora to assign a unique UID.
    await _engine!.joinChannel(
      token: token,
      channelId: widget.channelName,
      options: options,
      uid: _localUid,
    );
  }

  RtcEngineEventHandler _addAgoraEventHandlers() {
    return RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        debugPrint("onJoinChannelSuccess: ${connection.localUid}");
        setState(() {
          isJoined = true;

          // 1. Get the actual UID assigned by Agora
          _localUid = connection.localUid!;

          // 2. Associate the entered username with this UID
          _userNames[_localUid] = widget.userName;

          _remoteMuteStatus[_localUid] = {'audio': _isMicMuted, 'video': _isCameraOff};
          _activeSpeakerUid = _localUid;
        });
      },

      onUserJoined: (connection, remoteUid, elapsed) {
        debugPrint("onUserJoined: $remoteUid");
        setState(() {
          _remoteUids.add(remoteUid);
          _remoteMuteStatus[remoteUid] = {'audio': false, 'video': false};
          // Placeholder for remote user name
          _userNames[remoteUid] = "Participant $remoteUid";
        });
      },

      onUserOffline: (connection, remoteUid, reason) {
        debugPrint("onUserOffline: $remoteUid reason: $reason");
        setState(() {
          _remoteUids.remove(remoteUid);
          _remoteMuteStatus.remove(remoteUid);
          _remoteRoles.remove(remoteUid);
          _userNames.remove(remoteUid);
          _raisedHands.remove(remoteUid);
          if (_activeSpeakerUid == remoteUid) {
            _activeSpeakerUid = _localUid;
          }
        });
      },

      onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int totalVolume, int deviceVolume) {
        if (speakers.isNotEmpty) {
          var loudestSpeaker = speakers.reduce(
                (a, b) => (a.volume ?? 0) > (b.volume ?? 0) ? a : b,
          );

          int? speakerUid = loudestSpeaker.uid == 0 ? _localUid : loudestSpeaker.uid;

          if ((loudestSpeaker.volume ?? 0) > 10 && speakerUid != _activeSpeakerUid) {
            setState(() {
              _activeSpeakerUid = speakerUid;
            });
          } else if (totalVolume < 5 && _activeSpeakerUid != _localUid) {
            setState(() {
              _activeSpeakerUid = _localUid;
            });
          }
        }
      },


      onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
        setState(() {
          _remoteMuteStatus[remoteUid]?['audio'] = (state == 0 || state == 1);
        });
      },

      onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
        setState(() {
          _remoteMuteStatus[remoteUid]?['video'] = (state == 0);
        });
      },
    );
  }

  void _toggleMic() {
    setState(() => _isMicMuted = !_isMicMuted);
    _engine!.muteLocalAudioStream(_isMicMuted);
    _remoteMuteStatus[_localUid]?['audio'] = _isMicMuted;
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _engine!.muteLocalVideoStream(_isCameraOff);
    _remoteMuteStatus[_localUid]?['video'] = _isCameraOff;
  }

  void _switchCamera() {
    _engine!.switchCamera();
  }

  void _toggleScreenShare() {
    setState(() {
      _isScreenSharing = !_isScreenSharing;
    });
  }

  void _shareMeetingLink() {
    Share.share(
        'Join my meeting in channel ${widget.channelName}. Link/Details here...');
  }

  void _endCall() {
    Navigator.of(context).pop();
  }

  void _refreshParticipantsList() {
    setState(() {});
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

  void _toggleRemoteMic(int uid, bool isMuted) {
    if (uid == _localUid) {
      _toggleMic();
    } else if (widget.isHost) {
      setState(() {
        _remoteMuteStatus[uid]?['audio'] = isMuted;
      });
    }
    _refreshParticipantsList();
  }

  void _toggleRemoteCamera(int uid, bool isOff) {
    if (uid == _localUid) {
      _toggleCamera();
    } else if (widget.isHost) {
      setState(() {
        _remoteMuteStatus[uid]?['video'] = isOff;
      });
    }
    _refreshParticipantsList();
  }

  @override
  Widget build(BuildContext context) {
    bool isHost = widget.isHost;
    List<int> allBroadcasters = [
      ..._remoteUids,
      _localUid,
    ];

    if (!isJoined) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channelName),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main Video Grid
          Positioned.fill(
            child: VideoGrid(
              engine: _engine,
              localUid: _localUid,
              channelName: widget.channelName,
              remoteUids: _remoteUids,
              remoteRoles: _remoteRoles,
              remoteMuteStatus: _remoteMuteStatus,
              isLocalUserJoined: isJoined,
              isCameraOff: _isCameraOff,
              isMicMuted: _isMicMuted,
              userNames: _userNames,
              raisedHands: _raisedHands,
              isHost: isHost,
              activeSpeakerUid: _activeSpeakerUid,
            ),
          ),

          // Control Bar
          Align(
            alignment: Alignment.bottomCenter,
            child: ControlBar(
              isHost: isHost,
              isLocalBroadcaster: isHost,
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
                    remoteRoles: _remoteRoles,
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
          ),
        ],
      ),
    );
  }
}