import 'package:flutter/material.dart';

class AIAnalyzingOverlay extends StatelessWidget {
  const AIAnalyzingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.65),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI-themed animated loader
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 78,
                    height: 78,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
                      backgroundColor: Color(0xFFE0E7FF),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent,
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 28,
                      color: Colors.blueAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              const Text(
                "Analyzing Invoice",
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                "AI is analyzing invoice data and finding matching purchase orders",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 24),

              // Subtle progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _AnimatedDot(index: index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated pulsing dots
class _AnimatedDot extends StatefulWidget {
  final int index;
  const _AnimatedDot({required this.index});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200 + (widget.index * 150)),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity:
              0.3 +
              0.7 *
                  (0.5 +
                      0.5 *
                          (1 -
                              ((_controller.value + widget.index * 0.33) % 1))),
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
