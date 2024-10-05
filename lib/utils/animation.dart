import 'package:flutter/material.dart';

class AnimatedBlob extends StatefulWidget {
  @override
  _AnimatedBlobState createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withOpacity(0.5),
          ),
          child: ClipOval(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.5),
              ),
              child: Transform.translate(
                offset: Offset(
                  (100 * (_controller.value - 0.5)).clamp(-50, 50),
                  (100 * (_controller.value - 0.5)).clamp(-50, 50),
                ),
                child: Container(
                  color: Colors.blue.withOpacity(0.5),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}