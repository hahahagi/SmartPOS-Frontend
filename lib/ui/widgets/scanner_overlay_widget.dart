import 'package:flutter/material.dart';

import '../../config/colors.dart';

class ScannerOverlayWidget extends StatelessWidget {
  const ScannerOverlayWidget({
    super.key,
    this.hintText = 'Arahkan barcode ke kotak',
  });

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(color: const Color.fromRGBO(0, 0, 0, 0.45)),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primaryBlue, width: 3),
                color: Colors.transparent,
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CustomPaint(painter: _CornerPainter()),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hintText,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
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

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.15)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.15, 0)
      ..moveTo(size.width * 0.85, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.15)
      ..moveTo(size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.85, size.height)
      ..moveTo(size.width * 0.15, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height * 0.85);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
