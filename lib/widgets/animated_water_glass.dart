import 'package:flutter/material.dart';

class AnimatedWaterGlass extends StatefulWidget {
  final double progress; // 0.0 a 1.0
  final double height;
  final double width;

  const AnimatedWaterGlass({
    super.key,
    required this.progress,
    this.height = 200,
    this.width = 120,
  });

  @override
  State<AnimatedWaterGlass> createState() => _AnimatedWaterGlassState();
}

class _AnimatedWaterGlassState extends State<AnimatedWaterGlass>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedWaterGlass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: oldWidget.progress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: CustomPaint(
        painter: _WaterGlassPainter(
          animation: _animation,
          color: const Color.fromARGB(255, 64, 187, 224),
        ),
      ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  _WaterGlassPainter({
    required this.animation,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Constantes ajustadas para o copo
    final topY = size.height * 0.1;
    final bottomY = size.height * 0.95;
    final topWidth = size.width * 0.6; // Topo mais estreito
    final bottomWidth = size.width * 0.5; // Base mais estreita

    final leftTopX = (size.width - topWidth) / 2;
    final rightTopX = leftTopX + topWidth;
    final leftBottomX = (size.width - bottomWidth) / 2;
    final rightBottomX = leftBottomX + bottomWidth;

    // Desenha o copo (contorno) - simplificado
    final glassPath = Path()
      ..moveTo(leftTopX, topY)
      ..lineTo(leftBottomX, bottomY)
      ..lineTo(rightBottomX, bottomY)
      ..lineTo(rightTopX, topY)
      ..close();

    canvas.drawPath(glassPath, paint);

    // Calcula a altura da água
    final maxWaterHeight = size.height * 0.85;
    final waterHeight =
        (maxWaterHeight * animation.value).clamp(0.0, maxWaterHeight);
    final waterBottom = bottomY;
    final waterTop = waterBottom - waterHeight;

    // Calcula a largura da água proporcionalmente
    final progress = (waterTop - topY) / (bottomY - topY);
    final waterWidth = bottomWidth + (topWidth - bottomWidth) * (1 - progress);
    final waterLeftX = (size.width - waterWidth) / 2;

    final waterPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Desenha a água - mantendo dentro dos limites do copo
    final waterPath = Path();
    waterPath.moveTo(leftBottomX, waterBottom);
    waterPath.lineTo(waterLeftX, waterTop);
    waterPath.lineTo(waterLeftX + waterWidth, waterTop);
    waterPath.lineTo(rightBottomX, waterBottom);
    waterPath.close();

    // Garante que a água não ultrapasse os limites do copo
    final clipPath = Path()
      ..moveTo(leftTopX, topY)
      ..lineTo(leftBottomX, bottomY)
      ..lineTo(rightBottomX, bottomY)
      ..lineTo(rightTopX, topY)
      ..close();

    canvas.clipPath(clipPath); // Aplica o clipping
    canvas.drawPath(waterPath, waterPaint);

    // Reflexo simplificado
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final highlightPath = Path()
      ..moveTo(leftTopX + (topWidth * 0.1), size.height * 0.2)
      ..lineTo(leftTopX + (topWidth * 0.2), size.height * 0.2)
      ..lineTo(leftBottomX + (bottomWidth * 0.2), size.height * 0.8)
      ..lineTo(leftBottomX + (bottomWidth * 0.1), size.height * 0.8)
      ..close();

    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
