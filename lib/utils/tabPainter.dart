import 'dart:ui';

import 'package:flutter/painting.dart';

class CircularTabIndicator extends Decoration {
  final Color color;
  final double radius;

  CircularTabIndicator({required this.color, required this.radius});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _CircularPainter(color: color, radius: radius);
  }
}

class _CircularPainter extends BoxPainter {
  final Color color;
  final double radius;

  _CircularPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Offset circleOffset = offset +
        Offset(configuration.size!.width / 2, configuration.size!.height - radius);

    final Paint paint = Paint()..color = color;

    canvas.drawCircle(circleOffset, radius, paint);
  }
}
