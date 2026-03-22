import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/socket_service.dart';
import 'video_call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String callerId;
  final String channelName;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.callerId,
    required this.channelName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    SocketService().onCallEnded = (_) {
      if (mounted) Navigator.pop(context);
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SocketService().onCallEnded = null;
    super.dispose();
  }

  void _accept() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(
          channelName: widget.channelName,
          remoteName: widget.callerName,
        ),
      ),
    );
  }

  void _decline() {
    SocketService().declineCall(targetUserId: widget.callerId);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Pulsing avatar
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.08);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.primary.withValues(alpha: 0.3),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.surfaceVariant,
                  child: Text(
                    widget.callerName.isNotEmpty
                        ? widget.callerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Incoming video call...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
            const Spacer(flex: 3),
            // Accept / Decline buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _decline,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call_end_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Decline',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                    ],
                  ),
                  // Accept
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _accept,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.videocam_rounded,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Accept',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
