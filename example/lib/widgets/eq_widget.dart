import 'package:flutter/material.dart';

class EQWidget extends StatelessWidget {
  final List<double> gains;
  final bool enabled;
  final void Function(int index, double value) onChanged;

  static const _labels = [
    '31',
    '63',
    '125',
    '250',
    '500',
    '1k',
    '2k',
    '4k',
    '8k',
    '16k',
  ];

  const EQWidget({
    super.key,
    required this.gains,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grafico in background
          Positioned.fill(
            top: 25,
            bottom: 25,
            child: IgnorePointer(
              child: CustomPaint(
                painter: EqCurvePainter(
                  gains: gains,
                  enabled: enabled,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          // Silder in foreground
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(10, (i) {
              final val = gains[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Column(
                  children: [
                    Text(
                      '${val > 0 ? '+' : ''}${val.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: enabled ? null : Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 120,
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 14,
                            ),
                            activeTrackColor: enabled
                                ? null
                                : Colors.grey.withValues(alpha: 0.5),
                            inactiveTrackColor: enabled
                                ? null
                                : Colors.grey.withValues(alpha: 0.2),
                            thumbColor: enabled ? null : Colors.grey,
                          ),
                          child: Slider(
                            min: -15,
                            max: 15,
                            value: val,
                            onChanged: enabled ? (v) => onChanged(i, v) : null,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: enabled ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class EqCurvePainter extends CustomPainter {
  final List<double> gains;
  final bool enabled;
  final Color color;

  EqCurvePainter({
    required this.gains,
    required this.enabled,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.isEmpty) return;

    final paintLine = Paint()
      ..color = enabled ? color.withValues(alpha: 0.6) : Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final paintFill = Paint()
      ..color = enabled ? color.withValues(alpha: 0.15) : Colors.transparent
      ..style = PaintingStyle.fill;

    // Zero-line (il centro in altitudine)
    final zeroY = size.height / 2;

    // La slider va in altezza per 120 pixel, min=-15 max=+15
    // un punto Y su Size.height relativo al gain:
    // gain_factor = (gain - min) / (max - min) ?
    // In reltà +15Gain si traduce in Y vicino a 0.
    // -15Gain si traduce in Y vicino a size.height.
    double getGainY(double gain) {
      double normalized = (gain + 15) / 30; // 0.0 to 1.0 (bottom to top)
      return size.height - (normalized * size.height);
    }

    final path = Path();
    final fillPath = Path();

    // Lo spazio fra colonna e colonna è basato sulle larghezze di Padding
    // In Slider() ci sono 10 children. Dobbiamo indovinare il deltaX
    final stepX = size.width / (gains.length > 1 ? gains.length - 1 : 1);

    // Mappo l'inizio del path
    double firstY = getGainY(enabled ? gains[0] : 0.0);
    path.moveTo(0, firstY);
    fillPath.moveTo(0, zeroY);
    fillPath.lineTo(0, firstY);

    for (int i = 1; i < gains.length; i++) {
      double x = i * stepX;
      double y = getGainY(enabled ? gains[i] : 0.0);

      // Calcolo i punti per curvare
      double prevX = (i - 1) * stepX;
      double prevY = getGainY(enabled ? gains[i - 1] : 0.0);
      double cx = (prevX + x) / 2;

      path.quadraticBezierTo(cx, prevY, cx, (prevY + y) / 2);
      path.quadraticBezierTo(cx, y, x, y);

      fillPath.quadraticBezierTo(cx, prevY, cx, (prevY + y) / 2);
      fillPath.quadraticBezierTo(cx, y, x, y);
    }

    fillPath.lineTo(size.width, zeroY);
    fillPath.close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // Disegno la riga dello 0
    final zeroPaint = Paint()
      ..color = enabled ? Colors.white24 : Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroPaint);
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) {
    if (enabled != oldDelegate.enabled) return true;
    for (int i = 0; i < gains.length; i++) {
      if (gains[i] != oldDelegate.gains[i]) return true;
    }
    return false;
  }
}
