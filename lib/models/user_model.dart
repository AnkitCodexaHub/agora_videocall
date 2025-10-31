class UserModel {
  final int uid;
  final String name;
  final bool isHost;
  final bool isLocal;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isHandRaised;
  final bool isSpeaking;

  const UserModel({
    required this.uid,
    required this.name,
    this.isHost = false,
    this.isLocal = false,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isHandRaised = false,
    this.isSpeaking = false,
  });

  UserModel copyWith({
    int? uid,
    String? name,
    bool? isHost,
    bool? isLocal,
    bool? isAudioMuted,
    bool? isVideoMuted,
    bool? isHandRaised,
    bool? isSpeaking,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isLocal: isLocal ?? this.isLocal,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isSpeaking: isSpeaking ?? this.isSpeaking,
    );
  }
}

