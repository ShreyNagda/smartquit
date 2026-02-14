import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/intervention_provider.dart';
import '../../services/haptic_service.dart';

/// Quick Sketch: A blank canvas for 60 seconds of doodling.
class QuickSketchScreen extends ConsumerStatefulWidget {
  const QuickSketchScreen({super.key});

  @override
  ConsumerState<QuickSketchScreen> createState() => _QuickSketchScreenState();
}

class _QuickSketchScreenState extends ConsumerState<QuickSketchScreen> {
  final List<_DrawingStroke> _strokes = [];
  _DrawingStroke? _currentStroke;
  Color _currentColor = AppColors.primary;
  double _strokeWidth = 4.0;
  Timer? _timer;
  int _secondsLeft = 60;
  bool _isDrawing = false;

  static const _colors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.secondary,
    AppColors.primaryDark,
    AppColors.info,
    AppColors.error,
    AppColors.textPrimary,
  ];

  void _startDrawing() {
    setState(() => _isDrawing = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _complete();
      }
    });
  }

  void _complete() {
    _timer?.cancel();
    setState(() => _isDrawing = false);
    ref.read(hapticServiceProvider).heavy();
    ref.read(interventionProvider.notifier).completeIntervention();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🎨 Sketch Done!'),
        content: const Text(
          'Your hands were busy creating instead of craving.\n'
          'Art is a powerful distraction!',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Quick Sketch'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _timer?.cancel();
            ref.read(interventionProvider.notifier).cancelIntervention();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_isDrawing)
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _secondsLeft <= 10
                      ? AppColors.error.withOpacity(0.1)
                      : AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_secondsLeft}s',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    color: _secondsLeft <= 10
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          if (_isDrawing)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () {
                if (_strokes.isNotEmpty) {
                  setState(() => _strokes.removeLast());
                }
              },
            ),
          if (_isDrawing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() => _strokes.clear());
              },
            ),
        ],
      ),
      body: _isDrawing ? _buildCanvas() : _buildStart(),
    );
  }

  Widget _buildStart() {
    return SafeArea(
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎨', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text(
                'Quick Sketch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Montserrat',
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You have 60 seconds to doodle freely.\n\n'
                'Draw anything — shapes, patterns, words.\n'
                'The goal is to occupy your hands.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Montserrat',
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _startDrawing,
                child: const Text('Start Drawing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    return Column(
      children: [
        // Color picker
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Color dots
              ..._colors.map((color) {
                final isSelected = color == _currentColor;
                return GestureDetector(
                  onTap: () => setState(() => _currentColor = color),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 32 : 24,
                    height: isSelected ? 32 : 24,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black26, width: 3)
                          : null,
                    ),
                  ),
                );
              }),
              const Spacer(),
              // Stroke width
              SizedBox(
                width: 80,
                child: Slider(
                  value: _strokeWidth,
                  min: 2,
                  max: 12,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                  activeColor: _currentColor,
                ),
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentStroke = _DrawingStroke(
                  points: [details.localPosition],
                  color: _currentColor,
                  width: _strokeWidth,
                );
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentStroke?.points.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
              if (_currentStroke != null) {
                setState(() {
                  _strokes.add(_currentStroke!);
                  _currentStroke = null;
                });
              }
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _SketchPainter(
                strokes: _strokes,
                currentStroke: _currentStroke,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  _DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

class _SketchPainter extends CustomPainter {
  final List<_DrawingStroke> strokes;
  final _DrawingStroke? currentStroke;

  _SketchPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, _DrawingStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
