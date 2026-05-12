import 'package:flutter/material.dart';

class PlateOverlay extends StatelessWidget {
  const PlateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth * 0.75;
        final h = w * 0.25;
        final left = (constraints.maxWidth - w) / 2;
        final top = (constraints.maxHeight - h) / 2;

        return Stack(
          children: [
            // Dim background
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
            // Clear window
            Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.greenAccent, width: 2.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Corner accents
            ..._corners(left, top, w, h),
            // Label
            Positioned(
              left: left,
              top: top + h + 10,
              width: w,
              child: const Text(
                'ضع اللوحة داخل الإطار',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _corners(double left, double top, double w, double h) {
    const size = 20.0;
    const thick = 3.0;
    const color = Colors.greenAccent;

    return [
      // Top-left
      Positioned(left: left, top: top,
          child: _corner(size, thick, color, top: true, left: true)),
      // Top-right
      Positioned(left: left + w - size, top: top,
          child: _corner(size, thick, color, top: true, left: false)),
      // Bottom-left
      Positioned(left: left, top: top + h - size,
          child: _corner(size, thick, color, top: false, left: true)),
      // Bottom-right
      Positioned(left: left + w - size, top: top + h - size,
          child: _corner(size, thick, color, top: false, left: false)),
    ];
  }

  Widget _corner(double size, double thick, Color color,
      {required bool top, required bool left}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(thick, color, top: top, left: left),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final double thick;
  final Color color;
  final bool top;
  final bool left;

  _CornerPainter(this.thick, this.color, {required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke;

    final x = left ? 0.0 : size.width;
    final y = top ? 0.0 : size.height;
    final dx = left ? size.width : -size.width;
    final dy = top ? size.height : -size.height;

    canvas.drawLine(Offset(x, y), Offset(x + dx, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x, y + dy), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}