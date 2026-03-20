import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';

/// Manages Agora video call sessions.
/// Each call uses the jobId as the channel name so both parties join the same room.
class VideoCallService {
  RtcEngine? _engine;
  bool _isInitialized = false;

  // Callbacks for UI updates
  void Function(int uid)? onUserJoined;
  void Function(int uid)? onUserOffline;
  void Function()? onJoinSuccess;
  void Function(String error)? onError;

  /// Request camera + mic permissions
  Future<bool> requestPermissions() async {
    final camera = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return camera.isGranted && mic.isGranted;
  }

  /// Initialize the Agora engine
  Future<void> init() async {
    if (_isInitialized) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: AppConfig.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        onJoinSuccess?.call();
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        onUserJoined?.call(remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        onUserOffline?.call(remoteUid);
      },
      onError: (err, msg) {
        onError?.call('Agora error: $err - $msg');
      },
    ));

    await _engine!.enableVideo();
    await _engine!.startPreview();
    _isInitialized = true;
  }

  /// Join a video call channel (uses jobId as channel name)
  Future<void> joinChannel(String channelName, {int uid = 0}) async {
    if (_engine == null) await init();

    await _engine!.joinChannel(
      token: '', // No token needed in testing mode
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  /// Leave the call
  Future<void> leaveChannel() async {
    await _engine?.leaveChannel();
  }

  /// Toggle mic
  Future<void> toggleMic(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
  }

  /// Toggle camera
  Future<void> toggleCamera(bool off) async {
    await _engine?.muteLocalVideoStream(off);
  }

  /// Switch front/back camera
  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  /// Get the engine for rendering video views
  RtcEngine? get engine => _engine;

  /// Dispose
  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
    _isInitialized = false;
  }
}
