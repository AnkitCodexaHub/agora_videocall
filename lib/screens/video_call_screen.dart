import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../services/agora_service.dart';
import '../widgets/control_bar.dart';
import '../widgets/video_grid.dart';
import '../widgets/participants_list.dart';

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
  final AgoraService _agoraService = AgoraService();
  
  bool _localUserJoined = false;
  final List<int> _remoteUids = [];
  final Map<int, Map<String, bool>> _remoteMuteStatus = {};
  final Map<int, String> _userNames = {};
  final Map<int, bool> _raisedHands = {};

  bool _isMicMuted = true;
  bool _isCameraOff = true;
  bool _isScreenSharing = false;
  bool _isHandRaised = false;

  int? _activeSpeakerUid;
  StreamSubscription? _userJoinedSubscription;
  StreamSubscription? _userLeftSubscription;
  StreamSubscription? _remoteAudioStateSubscription;
  StreamSubscription? _remoteVideoStateSubscription;
  StreamSubscription? _audioVolumeSubscription;
  StreamSubscription? _dataMessageSubscription;
  StreamSubscription? _joinSuccessSubscription;

  @override
  void initState() {
    super.initState();
    final localUid = _agoraService.localUid;
    if (localUid != null) {
      _userNames[localUid] = widget.userName;
    }
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    try {
      await _agoraService.initialize();
      _setupEventListeners();
      
      await _agoraService.joinChannel(
        channelName: widget.channelName,
        muteAudio: _isMicMuted,
        muteVideo: _isCameraOff,
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to initialize: $e');
      }
    }
  }

  void _setupEventListeners() {
    _joinSuccessSubscription = _agoraService.joinSuccess.listen((_) {
      setState(() {
        _localUserJoined = true;
      });
      _agoraService.sendName(widget.userName);
    });

    _userJoinedSubscription = _agoraService.userJoined.listen((remoteUid) {
      setState(() {
        _remoteUids.add(remoteUid);
        _remoteMuteStatus[remoteUid] = {'audio': false, 'video': false};
        _userNames[remoteUid] = '${AppConstants.defaultParticipantNamePrefix} $remoteUid';
      });
      _refreshParticipantsList();
    });

    _userLeftSubscription = _agoraService.userLeft.listen((remoteUid) {
      setState(() {
        _remoteUids.remove(remoteUid);
        _remoteMuteStatus.remove(remoteUid);
        _userNames.remove(remoteUid);
        _raisedHands.remove(remoteUid);
      });
    });

    _remoteAudioStateSubscription =
        _agoraService.remoteAudioStateChanged.listen((event) {
      setState(() {
        final uid = event['uid'] as int;
        final isMuted = event['isMuted'] as bool;
        _remoteMuteStatus[uid] ??= {'audio': false, 'video': false};
        _remoteMuteStatus[uid]!['audio'] = isMuted;
      });
      _refreshParticipantsList();
    });

    _remoteVideoStateSubscription =
        _agoraService.remoteVideoStateChanged.listen((event) {
      setState(() {
        final uid = event['uid'] as int;
        final isOff = event['isOff'] as bool;
        _remoteMuteStatus[uid] ??= {'audio': false, 'video': false};
        _remoteMuteStatus[uid]!['video'] = isOff;
      });
      _refreshParticipantsList();
    });

    _audioVolumeSubscription = _agoraService.audioVolume.listen((speakingUid) {
      setState(() {
        _activeSpeakerUid = speakingUid;
      });
    });

    _dataMessageSubscription = _agoraService.dataMessage.listen((event) {
      final remoteUid = event['remoteUid'] as int;
      final message = event['message'] as String;

      if (message.startsWith(AppConstants.nameMessagePrefix)) {
        final remoteName = message.substring(AppConstants.nameMessagePrefix.length);
        setState(() {
          _userNames[remoteUid] = remoteName;
        });
        _refreshParticipantsList();
      } else if (message.startsWith(AppConstants.handMessagePrefix)) {
        final status = message.substring(AppConstants.handMessagePrefix.length);
        final isRaised = status == AppConstants.handRaisedStatus;
        setState(() {
          _raisedHands[remoteUid] = isRaised;
          if (!isRaised) {
            _raisedHands.remove(remoteUid);
          }
        });
        _refreshParticipantsList();
      } else if (message == AppConstants.endMeetingMessage) {
        _handleRemoteEndCall();
      }
    });
  }

  void _refreshParticipantsList() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleMic() async {
    setState(() => _isMicMuted = !_isMicMuted);
    await _agoraService.toggleMicrophone(_isMicMuted);
  }

  Future<void> _toggleCamera() async {
    setState(() => _isCameraOff = !_isCameraOff);
    await _agoraService.toggleCamera(_isCameraOff);
  }

  Future<void> _switchCamera() async {
    await _agoraService.switchCamera();
  }

  void _toggleScreenShare() {
    setState(() => _isScreenSharing = !_isScreenSharing);
    // TODO: Implement actual screen sharing functionality
  }

  void _toggleHand() {
    if (!widget.isHost) {
      setState(() => _isHandRaised = !_isHandRaised);

      if (_isHandRaised) {
        final localUid = _agoraService.localUid;
        if (localUid != null) {
          _raisedHands[localUid] = true;
        }
        _agoraService.sendHandStatus(true);
      } else {
        final localUid = _agoraService.localUid;
        if (localUid != null) {
          _raisedHands.remove(localUid);
        }
        _agoraService.sendHandStatus(false);
      }
      _refreshParticipantsList();
    }
  }

  Future<void> _toggleRemoteMic(int uid, bool isMuted) async {
    if (uid == _agoraService.localUid) {
      await _toggleMic();
      return;
    }
    if (widget.isHost) {
      await _agoraService.toggleRemoteMicrophone(uid, isMuted);
      setState(() {
        _remoteMuteStatus[uid]!['audio'] = isMuted;
      });
      _refreshParticipantsList();
    }
  }

  Future<void> _toggleRemoteCamera(int uid, bool isOff) async {
    if (uid == _agoraService.localUid) {
      await _toggleCamera();
      return;
    }
    if (widget.isHost) {
      await _agoraService.toggleRemoteCamera(uid, isOff);
      setState(() {
        _remoteMuteStatus[uid]!['video'] = isOff;
      });
      _refreshParticipantsList();
    }
  }

  void _shareMeetingLink() {
    share_plus.Share.share('Join my live meeting: ${widget.channelName}');
  }

  void _endCall() {
    if (widget.isHost) {
      _showHostEndMeetingDialog();
    } else {
      _agoraService.leaveChannel();
      Navigator.of(context).pop();
    }
  }

  void _handleRemoteEndCall() {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('The host has ended the meeting.'),
        duration: Duration(seconds: 3),
      ),
    );
    _agoraService.leaveChannel();
    Navigator.of(context).pop();
  }

  void _showHostEndMeetingDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('End Meeting?'),
          content: const Text(
            'As the host, you can choose to end the meeting for everyone or just leave yourself.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _agoraService.leaveChannel();
                Navigator.of(this.context).pop();
              },
              child: const Text('Leave Meeting'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                _agoraService.sendEndMeeting();

                setState(() {
                  _remoteUids.clear();
                  _remoteMuteStatus.clear();
                  final localUid = _agoraService.localUid;
                  if (localUid != null) {
                    _userNames.removeWhere((key, value) => key != localUid);
                  }
                  _raisedHands.clear();
                  _activeSpeakerUid = null;
                });

                Navigator.of(context).pop();
                _agoraService.leaveChannel();
                Navigator.of(this.context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Meeting ended for all participants.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('End Meeting for All'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  void dispose() {
    _userJoinedSubscription?.cancel();
    _userLeftSubscription?.cancel();
    _remoteAudioStateSubscription?.cancel();
    _remoteVideoStateSubscription?.cancel();
    _audioVolumeSubscription?.cancel();
    _dataMessageSubscription?.cancel();
    _joinSuccessSubscription?.cancel();
    _agoraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localUid = _agoraService.localUid;
    if (localUid == null || _agoraService.engine == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final allBroadcasters = {
      localUid: ClientRoleType.clientRoleBroadcaster,
      for (var uid in _remoteUids) uid: ClientRoleType.clientRoleBroadcaster,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(widget.channelName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _endCall,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: VideoGrid(
                engine: _agoraService.engine,
                localUid: localUid,
                remoteUids: _remoteUids,
                remoteMuteStatus: _remoteMuteStatus,
                isLocalUserJoined: _localUserJoined,
                isCameraOff: _isCameraOff,
                isMicMuted: _isMicMuted,
                userNames: _userNames,
                raisedHands: _raisedHands,
                activeSpeakerUid: _activeSpeakerUid,
              ),
            ),
          ),
          ControlBar(
            isHost: widget.isHost,
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
                  localUid: localUid,
                  remoteUids: _remoteUids,
                  remoteRoles: allBroadcasters,
                  remoteMuteStatus: _remoteMuteStatus,
                  userNames: _userNames,
                  engine: _agoraService.engine!,
                  isHost: widget.isHost,
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
            onToggleHand: widget.isHost ? null : _toggleHand,
          ),
        ],
      ),
    );
  }
}

