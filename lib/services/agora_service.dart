import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_constants.dart';

/// Service class to handle all Agora SDK operations
class AgoraService {
  RtcEngine? _engine;
  int? _localUid;
  int? _dataStreamId;
  bool _isInitialized = false;

  // Stream controllers for events
  final _userJoinedController = StreamController<int>.broadcast();
  final _userLeftController = StreamController<int>.broadcast();
  final _remoteAudioStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _remoteVideoStateController = StreamController<Map<String, dynamic>>.broadcast();
  final _audioVolumeController = StreamController<int?>.broadcast();
  final _dataMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _joinSuccessController = StreamController<void>.broadcast();

  // Getters
  RtcEngine? get engine => _engine;
  int? get localUid => _localUid;
  int? get dataStreamId => _dataStreamId;
  bool get isInitialized => _isInitialized;

  // Streams
  Stream<int> get userJoined => _userJoinedController.stream;
  Stream<int> get userLeft => _userLeftController.stream;
  Stream<Map<String, dynamic>> get remoteAudioStateChanged => _remoteAudioStateController.stream;
  Stream<Map<String, dynamic>> get remoteVideoStateChanged => _remoteVideoStateController.stream;
  Stream<int?> get audioVolume => _audioVolumeController.stream;
  Stream<Map<String, dynamic>> get dataMessage => _dataMessageController.stream;
  Stream<void> get joinSuccess => _joinSuccessController.stream;

  /// Initialize Agora engine with permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Generate local UID
    _localUid = Random().nextInt(AppConstants.maxRandomUid);

    // Create and initialize engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(
      const RtcEngineContext(appId: AppConstants.agoraAppId),
    );

    // Enable audio and video
    await _engine!.enableAudio();
    await _engine!.enableVideo();

    // Set client role as broadcaster
    await _engine!.setClientRole(
      role: ClientRoleType.clientRoleBroadcaster,
    );

    // Enable audio volume indication
    try {
      await _engine!.enableAudioVolumeIndication(
        interval: AppConstants.audioVolumeIndicatorInterval,
        smooth: AppConstants.audioVolumeSmooth,
        reportVad: true,
      );
    } catch (e) {
      debugPrint('Audio volume indication failed: $e');
    }

    // Create data stream
    try {
      final streamConfig = DataStreamConfig(
        syncWithAudio: false,
        ordered: true,
      );
      _dataStreamId = await _engine!.createDataStream(streamConfig);
      debugPrint('Data stream created: $_dataStreamId');
    } catch (e) {
      debugPrint('Data stream creation failed: $e');
    }

    // Register event handlers
    _registerEventHandlers();

    _isInitialized = true;
  }

  /// Register Agora event handlers
  void _registerEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          _joinSuccessController.add(null);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          _userJoinedController.add(remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          _userLeftController.add(remoteUid);
        },
        onRemoteAudioStateChanged: (connection, remoteUid, state, reason, elapsed) {
          final isMuted = state == RemoteAudioState.remoteAudioStateStopped;
          _remoteAudioStateController.add({
            'uid': remoteUid,
            'isMuted': isMuted,
          });
        },
        onRemoteVideoStateChanged: (connection, remoteUid, state, reason, elapsed) {
          final isOff = state == RemoteVideoState.remoteVideoStateStopped;
          _remoteVideoStateController.add({
            'uid': remoteUid,
            'isOff': isOff,
          });
        },
        onAudioVolumeIndication: (connection, speakers, totalVolume, deviceVolume) {
          int? speakingUid;
          for (var speaker in speakers) {
            final uid = speaker.uid == 0 ? _localUid : speaker.uid;
            if (speaker.volume! > AppConstants.audioVolumeThreshold) {
              speakingUid = uid;
              break;
            }
          }
          if (speakingUid == null && totalVolume < AppConstants.audioVolumeThreshold) {
            speakingUid = null;
          }
          _audioVolumeController.add(speakingUid);
        },
        onStreamMessage: (connection, remoteUid, streamId, data, length, sentTs) {
          if (streamId == _dataStreamId) {
            final message = String.fromCharCodes(data);
            _dataMessageController.add({
              'remoteUid': remoteUid,
              'message': message,
            });
          }
        },
      ),
    );
  }

  /// Join a channel
  Future<void> joinChannel({
    required String channelName,
    bool muteAudio = true,
    bool muteVideo = true,
  }) async {
    if (_engine == null || !_isInitialized) {
      throw Exception('Agora service not initialized');
    }

    await _engine!.muteLocalAudioStream(muteAudio);
    await _engine!.enableLocalVideo(!muteVideo);

    await _engine!.joinChannel(
      token: AppConstants.agoraToken,
      channelId: channelName,
      uid: _localUid!,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
      ),
    );
  }

  /// Leave the current channel
  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }

  /// Toggle local microphone
  Future<void> toggleMicrophone(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
  }

  /// Toggle local camera
  Future<void> toggleCamera(bool disable) async {
    await _engine?.enableLocalVideo(!disable);
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Toggle remote user's microphone (host only)
  Future<void> toggleRemoteMicrophone(int uid, bool mute) async {
    await _engine?.muteRemoteAudioStream(uid: uid, mute: mute);
  }

  /// Toggle remote user's camera (host only)
  Future<void> toggleRemoteCamera(int uid, bool mute) async {
    await _engine?.muteRemoteVideoStream(uid: uid, mute: mute);
  }

  /// Send name via data stream
  void sendName(String name) {
    if (_engine != null && _dataStreamId != null) {
      final message = '${AppConstants.nameMessagePrefix}$name';
      final data = Uint8List.fromList(message.codeUnits);
      _engine!.sendStreamMessage(
        streamId: _dataStreamId!,
        data: data,
        length: data.length,
      );
    }
  }

  /// Send hand status via data stream
  void sendHandStatus(bool isRaised) {
    if (_engine != null && _dataStreamId != null) {
      final status = isRaised
          ? AppConstants.handRaisedStatus
          : AppConstants.handLoweredStatus;
      final message = '${AppConstants.handMessagePrefix}$status';
      final data = Uint8List.fromList(message.codeUnits);
      _engine!.sendStreamMessage(
        streamId: _dataStreamId!,
        data: data,
        length: data.length,
      );
    }
  }

  /// Send end meeting message
  void sendEndMeeting() {
    if (_engine != null && _dataStreamId != null) {
      final data = Uint8List.fromList(
        AppConstants.endMeetingMessage.codeUnits,
      );
      _engine!.sendStreamMessage(
        streamId: _dataStreamId!,
        data: data,
        length: data.length,
      );
    }
  }

  /// Dispose and cleanup resources
  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
    _localUid = null;
    _dataStreamId = null;

    // Close stream controllers
    await _userJoinedController.close();
    await _userLeftController.close();
    await _remoteAudioStateController.close();
    await _remoteVideoStateController.close();
    await _audioVolumeController.close();
    await _dataMessageController.close();
    await _joinSuccessController.close();
  }
}

