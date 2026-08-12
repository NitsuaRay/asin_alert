import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class PanicButton extends StatefulWidget {
  final Future<void> Function() onTrigger;
  final Duration holdDuration;

  const PanicButton({
    super.key,
    required this.onTrigger,
    this.holdDuration = const Duration(seconds: 2), // 2-second hold requirement
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
      // Vibrational feedback during press
      if (_controller.isAnimating && _hasVibrator) {
        if ((_controller.value * 100).toInt() % 15 == 0) {
          Vibration.vibrate(duration: 40, amplitude: (_controller.value * 255).toInt());
        }
      }
    });

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && !_isTriggering) {
        setState(() => _isTriggering = true);
        
        // Heavy vibration pulse on trigger complete
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
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.red.shade100,
                  color: Colors.red.shade800,
                ),
              ),
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: progress > 0 ? Colors.red.shade800 : Colors.red.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.4),
                      blurRadius: progress > 0 ? 30 : 15,
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
                              Icons.warning_rounded,
                              size: 55,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              progress > 0
                                  ? 'HOLD... ${( (1 - progress) * 2 ).toStringAsFixed(1)}s'
                                  : 'HOLD 2 SEC\nFOR POLICE',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}