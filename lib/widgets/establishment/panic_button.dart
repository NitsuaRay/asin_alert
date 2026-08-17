import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class PanicButton extends StatefulWidget {
  final Future<void> Function() onTrigger;
  final Duration holdDuration;
  final Color baseColor;

  const PanicButton({
    super.key,
    required this.onTrigger,
    this.holdDuration = const Duration(seconds: 2),
    this.baseColor = const Color(0xFFDC2626), // Default Red
  });

  @override
  State<PanicButton> createState() => _PanicButtonState();
}

class _PanicButtonState extends State<PanicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isTriggering = false;
  bool _hasVibrator = false;

  @override
  void initState() {
    super.initState();
    _checkVibration();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _controller.addListener(() {
      if (_controller.isAnimating && _hasVibrator) {
        if ((_controller.value * 100).toInt() % 15 == 0) {
          Vibration.vibrate(
            duration: 35,
            amplitude: (_controller.value * 255).toInt(),
          );
        }
      }
    });

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && !_isTriggering) {
        setState(() => _isTriggering = true);

        if (_hasVibrator) {
          Vibration.vibrate(pattern: [0, 100, 50, 200]);
        }

        try {
          await widget.onTrigger();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to trigger alert: $e'),
                backgroundColor: Colors.black,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isTriggering = false);
            _controller.reset();
          }
        }
      }
    });
  }

  Future<void> _checkVibration() async {
    _hasVibrator = (await Vibration.hasVibrator());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isTriggering) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reset();
    }
  }

  void _onTapCancel() {
    if (_controller.status != AnimationStatus.completed) {
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          final scale = 1.0 - (progress * 0.05); // Subtle press scale effect

          return Transform.scale(
            scale: scale,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Progress Circle
                SizedBox(
                  width: 230,
                  height: 230,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: widget.baseColor.withValues(alpha: 0.15),
                    color: widget.baseColor,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Inner Panic Button Core
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.baseColor,
                        HSLColor.fromColor(widget.baseColor)
                            .withLightness(0.35)
                            .toColor(),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.baseColor.withValues(alpha: progress > 0 ? 0.5 : 0.25),
                        blurRadius: progress > 0 ? 30 : 16,
                        spreadRadius: progress > 0 ? 8 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isTriggering
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 56,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                progress > 0
                                    ? 'HOLD... ${((1 - progress) * widget.holdDuration.inSeconds).toStringAsFixed(1)}s'
                                    : 'HOLD 2 SEC\nFOR HELP',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  height: 1.2,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}