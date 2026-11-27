import 'package:flutter/material.dart';

/// Retrato escalable para las fichas y el selector de especie.
class PetMascot extends StatelessWidget {
  const PetMascot({super.key, required this.species, required this.size});
  final String species;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
        widthFactor: 1,
        heightFactor: 1,
        child: CustomPaint(
            size: Size.square(size), painter: _Portrait(species == 'cat')),
      );
}

class _Portrait extends CustomPainter {
  const _Portrait(this.cat);
  final bool cat;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160, size.height / 160);
    const ivory = Color(0xfffffcf0),
        caramel = Color(0xffffdfaf),
        blush = Color(0xffffb8c5),
        ink = Color(0xff342927);
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    void shape(Path path, Color fill) {
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, pen);
    }

    void oval(double x, double y, double w, double h, Color color) =>
        canvas.drawOval(
            Rect.fromCenter(center: Offset(x, y), width: w, height: h),
            Paint()..color = color);

    // Patitas cortas y cuerpo de peluche.
    shape(
        Path()
          ..moveTo(49, 86)
          ..quadraticBezierTo(40, 109, 42, 139)
          ..quadraticBezierTo(44, 151, 62, 147)
          ..quadraticBezierTo(70, 146, 73, 138)
          ..quadraticBezierTo(80, 135, 86, 139)
          ..quadraticBezierTo(90, 151, 110, 147)
          ..quadraticBezierTo(126, 146, 119, 123)
          ..lineTo(111, 89)
          ..close(),
        ivory);
    final head = Path()..moveTo(38, 62);
    if (cat) {
      head
        ..lineTo(34, 22)
        ..quadraticBezierTo(34, 14, 41, 18)
        ..lineTo(63, 34)
        ..quadraticBezierTo(80, 29, 97, 34)
        ..lineTo(121, 18)
        ..quadraticBezierTo(128, 15, 126, 26)
        ..lineTo(123, 62);
    } else {
      head
        ..quadraticBezierTo(44, 27, 73, 26)
        ..quadraticBezierTo(81, 22, 88, 27)
        ..quadraticBezierTo(119, 27, 125, 62);
    }
    head
      ..cubicTo(144, 98, 112, 104, 80, 104)
      ..cubicTo(48, 104, 17, 97, 38, 62)
      ..close();
    shape(head, caramel);
    canvas.save();
    canvas.clipPath(head);
    canvas.drawPath(
        Path()
          ..moveTo(73, 24)
          ..cubicTo(86, 42, 64, 72, 57, 76)
          ..quadraticBezierTo(39, 75, 35, 102)
          ..lineTo(126, 111)
          ..quadraticBezierTo(119, 79, 100, 77)
          ..cubicTo(85, 71, 77, 38, 86, 24)
          ..close(),
        Paint()..color = ivory);
    canvas.restore();
    for (final mirror in [false, true]) {
      canvas.save();
      if (mirror) {
        canvas.translate(160, 0);
        canvas.scale(-1, 1);
      }
      if (cat) {
        canvas.drawPath(
            Path()
              ..moveTo(40, 27)
              ..lineTo(56, 38)
              ..lineTo(42, 45)
              ..close(),
            Paint()..color = blush);
        canvas.drawLine(const Offset(38, 81), const Offset(24, 77), pen);
        canvas.drawLine(const Offset(37, 87), const Offset(24, 89), pen);
      } else {
        shape(
            Path()
              ..moveTo(52, 32)
              ..cubicTo(39, 32, 29, 43, 21, 58)
              ..cubicTo(8, 77, 20, 90, 35, 85)
              ..quadraticBezierTo(48, 81, 50, 69),
            caramel);
      }
      oval(53, 85, 14, 9, blush);
      oval(65, 77, 7, 8, ink);
      canvas.restore();
    }
    shape(
        Path()
          ..moveTo(77, 83)
          ..quadraticBezierTo(80, 81, 83, 83)
          ..lineTo(80, 86)
          ..close(),
        ink);
    // Estrella de bolsillo, compartida por ambas versiones.
    shape(
        Path()
          ..moveTo(80, 99)
          ..lineTo(87, 109)
          ..lineTo(99, 111)
          ..lineTo(92, 121)
          ..lineTo(93, 133)
          ..lineTo(81, 129)
          ..lineTo(70, 134)
          ..lineTo(69, 121)
          ..lineTo(60, 113)
          ..lineTo(73, 109)
          ..close(),
        const Color(0xffffdf81));
    for (final x in [59.0, 101.0]) {
      final paw = Path()
        ..addOval(
            Rect.fromCenter(center: Offset(x, 113), width: 19, height: 16));
      shape(paw, ivory);
    }
  }

  @override
  bool shouldRepaint(_Portrait oldDelegate) => cat != oldDelegate.cat;
}
