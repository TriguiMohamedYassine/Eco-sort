import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _capture() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted || file == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(imagePath: file.path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Stack(
        children: [
          // Fake camera preview
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0FBC7C), Color(0xFF27AEF7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 300,
              height: 420,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        return CustomPaint(
                          painter: _ScanPainter(progress: _controller.value),
                        );
                      },
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.search, color: Colors.white24, size: 72),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _capture,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(18),
                backgroundColor: Colors.white,
              ),
              child: const Icon(Icons.circle, color: Colors.green, size: 44),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  final double progress;
  _ScanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    final stripeHeight = 12.0;
    final offsetY = (progress * (size.height + stripeHeight)) - stripeHeight;
    for (double y = offsetY; y < size.height; y += stripeHeight * 4) {
      canvas.drawRect(
        Rect.fromLTWH(0, y - stripeHeight, size.width, stripeHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => old.progress != progress;
}
