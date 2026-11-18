import 'package:flutter/material.dart';

class LanguageButton extends StatelessWidget {
  final bool en;
  final VoidCallback onChanged;
  const LanguageButton({super.key, required this.en, required this.onChanged});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onChanged,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: en
              ? 'Mudar para português do Brasil'
              : 'Switch to British English',
          child: Semantics(
            label: en
                ? 'Mudar para português do Brasil'
                : 'Switch to British English',
            child: SizedBox(
              width: 32,
              height: 32,
              child: ClipOval(
                child: CustomPaint(painter: _FlagPainter(uk: !en)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(en ? 'PT' : 'EN'),
      ],
    ),
  );
}

class _FlagPainter extends CustomPainter {
  final bool uk;
  _FlagPainter({required this.uk});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint();
    canvas.drawRect(
      Offset.zero & size,
      paint..color = uk ? const Color(0xff15356a) : const Color(0xff178343),
    );
    if (uk) {
      for (final points in [
        [Offset.zero, Offset(w, h)],
        [Offset(w, 0), Offset(0, h)],
      ]) {
        canvas.drawLine(
          points[0],
          points[1],
          paint
            ..color = Colors.white
            ..strokeWidth = 7,
        );
        canvas.drawLine(
          points[0],
          points[1],
          paint
            ..color = const Color(0xffc52335)
            ..strokeWidth = 3,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(w * .35, 0, w * .3, h),
        paint..color = Colors.white,
      );
      canvas.drawRect(Rect.fromLTWH(0, h * .35, w, h * .3), paint);
      canvas.drawRect(
        Rect.fromLTWH(w * .42, 0, w * .16, h),
        paint..color = const Color(0xffc52335),
      );
      canvas.drawRect(Rect.fromLTWH(0, h * .42, w, h * .16), paint);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(w * .5, h * .12)
          ..lineTo(w * .94, h * .5)
          ..lineTo(w * .5, h * .88)
          ..lineTo(w * .06, h * .5)
          ..close(),
        paint..color = const Color(0xffffdc40),
      );
      canvas.drawCircle(
        Offset(w / 2, h / 2),
        w * .23,
        paint..color = const Color(0xff214ba1),
      );
      canvas.drawLine(
        Offset(w * .29, h * .46),
        Offset(w * .7, h * .56),
        paint
          ..color = Colors.white
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) =>
      oldDelegate.uk != uk;
}
