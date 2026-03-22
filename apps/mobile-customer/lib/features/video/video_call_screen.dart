import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../core/services/video_call_service.dart';
import '../../core/services/api_service.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';

/// Full-screen video call UI.
class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String remoteName;
  final String? targetUserId;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.remoteName,
    this.targetUserId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _callService = VideoCallService();
  bool _isMuted = false;
  bool _isCameraOff = false;
  int? _remoteUid;
  bool _isJoined = false;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _startCall();
  }

  Future<void> _startCall() async {
    final hasPermission = await _callService.requestPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera and microphone permission required')),
        );
        Navigator.pop(context);
      }
      return;
    }

    _callService.onJoinSuccess = () {
      if (mounted) setState(() { _isJoined = true; _isConnecting = false; });
    };

    _callService.onUserJoined = (uid) {
      if (mounted) setState(() => _remoteUid = uid);
    };

    _callService.onUserOffline = (uid) {
      if (mounted) setState(() => _remoteUid = null);
    };

    _callService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    };

    await _callService.init();

    // Fetch Agora token from backend
    String token = '';
    try {
      final data = await ApiService().getAgoraToken(widget.channelName);
      token = data['token'] ?? '';
    } catch (_) {
      // If token fetch fails, try without token (works if App Certificate is not enabled)
    }

    await _callService.joinChannel(widget.channelName, token: token);

    // Notify the other user about the incoming call
    if (widget.targetUserId != null) {
      final callerName = AuthService().currentUser?.displayName ?? 'Someone';
      SocketService().callUser(
        targetUserId: widget.targetUserId!,
        channelName: widget.channelName,
        callerName: callerName,
      );
    }
  }

  Future<void> _endCall() async {
    if (widget.targetUserId != null) {
      SocketService().endCall(targetUserId: widget.targetUserId!);
    }
    await _callService.leaveChannel();
    await _callService.dispose();
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          _remoteUid != null
              ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _callService.engine!,
                    canvas: VideoCanvas(uid: _remoteUid),
                    connection: RtcConnection(channelId: widget.channelName),
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.surfaceVariant,
                        child: Text(
                          widget.remoteName.isNotEmpty ? widget.remoteName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 36, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.remoteName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        _isConnecting ? 'Connecting...' : 'Waiting for ${widget.remoteName} to join...',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                      ),
                      if (_isConnecting) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: Colors.white),
                      ],
                    ],
                  ),
                ),

          // Local video (small overlay, top right)
          if (_isJoined && !_isCameraOff)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _callService.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Top bar — name + duration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: _endCall,
                  ),
                  const Spacer(),
                  if (_remoteUid != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('Connected', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Toggle mic
                  _ControlButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    label: _isMuted ? 'Unmute' : 'Mute',
                    isActive: !_isMuted,
                    onTap: () {
                      setState(() => _isMuted = !_isMuted);
                      _callService.toggleMic(_isMuted);
                    },
                  ),
                  // End call
                  _ControlButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    isActive: true,
                    isDestructive: true,
                    onTap: _endCall,
                  ),
                  // Toggle camera
                  _ControlButton(
                    icon: _isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                    label: _isCameraOff ? 'Camera On' : 'Camera Off',
                    isActive: !_isCameraOff,
                    onTap: () {
                      setState(() => _isCameraOff = !_isCameraOff);
                      _callService.toggleCamera(_isCameraOff);
                    },
                  ),
                  // Switch camera
                  _ControlButton(
                    icon: Icons.cameraswitch_rounded,
                    label: 'Flip',
                    isActive: true,
                    onTap: () => _callService.switchCamera(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red
                  : isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}
