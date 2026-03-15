import 'package:flutter/material.dart';

class EQWidget extends StatefulWidget {
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
  State<EQWidget> createState() => _EQWidgetState();
}

class _EQWidgetState extends State<EQWidget> {
  final Map<int, double> _dragGains = {};

  @override
  Widget build(BuildContext context) {
    final currentGains = List<double>.from(widget.gains);
    _dragGains.forEach((index, value) {
      if (index < currentGains.length) {
        currentGains[index] = value;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive band width: fits 10 bands if possible, but keeps a readable minimum
        final double bandWidth = (constraints.maxWidth / 10).clamp(40.0, 64.0);
        const double sliderHeight = 120.0;
        const double topSpace = 24.0;
        const double bottomSpace = 24.0;
        final double totalWidth = bandWidth * 10;
        final double totalHeight = topSpace + sliderHeight + bottomSpace;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. The Curve - perfectly aligned vertically with the slider area
                Positioned(
                  top: topSpace,
                  height: sliderHeight,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: EqCurvePainter(
                        gains: currentGains,
                        enabled: widget.enabled,
                        color: Theme.of(context).colorScheme.primary,
                        bandWidth: bandWidth,
                      ),
                    ),
                  ),
                ),
                // 2. The Interactive Column (Value + Slider + Label)
                Row(
                  children: List.generate(10, (i) {
                    final val = currentGains[i];
                    return SizedBox(
                      width: bandWidth,
                      child: Column(
                        children: [
                          // Value Text Area
                          SizedBox(
                            height: topSpace,
                            child: Center(
                              child: Text(
                                '${val > 0 ? '+' : ''}${val.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.enabled ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          // Slider Area
                          SizedBox(
                            height: sliderHeight,
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7,
                                    elevation: 0,
                                    pressedElevation: 0,
                                  ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14,
                                  ),
                                  // Remove all internal padding from the slider track
                                  trackShape: const _TightTrackShape(),
                                  activeTrackColor: widget.enabled
                                      ? null
                                      : Colors.grey.withAlpha(128),
                                  inactiveTrackColor: widget.enabled
                                      ? null
                                      : Colors.grey.withAlpha(51),
                                  thumbColor: widget.enabled
                                      ? null
                                      : Colors.grey,
                                ),
                                child: Slider(
                                  min: -15,
                                  max: 15,
                                  value: val,
                                  onChanged: widget.enabled
                                      ? (v) => setState(() => _dragGains[i] = v)
                                      : null,
                                  onChangeEnd: widget.enabled
                                      ? (v) async {
                                          widget.onChanged(i, v);
                                          await Future.delayed(
                                            const Duration(milliseconds: 500),
                                          );
                                          if (mounted) {
                                            setState(
                                              () => _dragGains.remove(i),
                                            );
                                          }
                                        }
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          // Label Text Area
                          SizedBox(
                            height: bottomSpace,
                            child: Center(
                              child: Text(
                                EQWidget._labels[i],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: widget.enabled ? null : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TightTrackShape extends RoundedRectSliderTrackShape {
  const _TightTrackShape();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

class EqCurvePainter extends CustomPainter {
  final List<double> gains;
  final bool enabled;
  final Color color;
  final double bandWidth;

  EqCurvePainter({
    required this.gains,
    required this.enabled,
    required this.color,
    required this.bandWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (gains.isEmpty) return;

    final paintLine = Paint()
      ..color = enabled ? color : Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final zeroY = size.height / 2;

    double getGainY(double gain) {
      double normalized = (gain + 15) / 30; // 0.0 to 1.0
      return (1.0 - normalized) * size.height;
    }

    final path = Path();
    final fillPath = Path();

    double getX(int i) => (i * bandWidth) + (bandWidth / 2);

    double firstX = getX(0);
    double firstY = getGainY(enabled ? gains[0] : 0.0);

    path.moveTo(firstX, firstY);
    fillPath.moveTo(firstX, zeroY);
    fillPath.lineTo(firstX, firstY);

    for (int i = 1; i < gains.length; i++) {
      double x = getX(i);
      double y = getGainY(enabled ? gains[i] : 0.0);
      double prevX = getX(i - 1);
      double prevY = getGainY(enabled ? gains[i - 1] : 0.0);

      double dx = (x - prevX) * 0.4;
      path.cubicTo(prevX + dx, prevY, x - dx, y, x, y);
      fillPath.cubicTo(prevX + dx, prevY, x - dx, y, x, y);
    }

    double lastX = getX(gains.length - 1);
    fillPath.lineTo(lastX, zeroY);
    fillPath.close();

    if (enabled) {
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.3),
          color.withValues(alpha: 0.02),
          color.withValues(alpha: 0.3),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);

      canvas.drawPath(fillPath, Paint()..shader = gradient);
    }

    canvas.drawPath(path, paintLine);

    final zeroPaint = Paint()
      ..color = enabled
          ? color.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(firstX, zeroY), Offset(lastX, zeroY), zeroPaint);
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) {
    if (enabled != oldDelegate.enabled || bandWidth != oldDelegate.bandWidth) {
      return true;
    }
    for (int i = 0; i < gains.length; i++) {
      if (gains[i] != oldDelegate.gains[i]) return true;
    }
    return false;
  }
}
