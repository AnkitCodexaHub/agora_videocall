/// Application-wide constants
class AppConstants {
  // Agora Configuration
  // NOTE: In production, these should be fetched from a secure backend
  static const String agoraAppId = '2264731781464d4e8764ce1c02be1c46';
  static const String agoraToken =
      '007eJxTYCh+ZdE7K6Ux7smTakb+Hzu3Vz/W5+G1Wf1ktdDi5JgkbysFBiMjMxNzY0NzC0MTM5MUk1QLczOT5FTDZAOjJCBpYnbJnCWzIZCRwa7Ki5GRAQJBfBaGktTiEgYGAPVCHVc=';

  // Audio/Video Configuration
  static const int audioVolumeThreshold = 5;
  static const int audioVolumeIndicatorInterval = 200;
  static const int audioVolumeSmooth = 3;

  // UI Constants
  static const double defaultBorderRadius = 16.0;
  static const double videoTileBorderRadius = 12.0;
  static const double smallVideoTileSize = 120.0;
  static const double controlBarButtonSize = 50.0;
  static const double controlBarIconSize = 24.0;
  static const int maxRandomUid = 1000000;

  // Data Stream Message Types
  static const String nameMessagePrefix = 'NAME:';
  static const String handMessagePrefix = 'HAND:';
  static const String handRaisedStatus = 'RAISED';
  static const String handLoweredStatus = 'LOWERED';
  static const String endMeetingMessage = 'END_MEETING';

  // Default Values
  static const String defaultUserName = 'User Name';
  static const String defaultChannelName = 'test';
  static const String defaultParticipantNamePrefix = 'Participant';
}

