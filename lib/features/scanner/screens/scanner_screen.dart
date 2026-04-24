import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/scanner_service.dart';
import '../services/api_service.dart';
import '../models/food_model.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  final _scannerService = ScannerService();
  final _apiService = ApiService();

  bool _isInitialized = false;
  bool _isScanning = false;
  bool _torchOn = false;
  FoodModel? _food;
  String? _errorMsg;

  late AnimationController _scanLineCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _scanLineAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _scanLineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _scanLineAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanLineCtrl, curve: Curves.easeInOut),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanLineCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    // Request camera permission first
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        setState(() => _errorMsg =
            'Camera permission denied. Please enable it in Settings.');
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _errorMsg = 'No camera found on this device.');
        return;
      }
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _errorMsg = 'Camera error: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_isInitialized) return;
    try {
      _torchOn = !_torchOn;
      await _controller!.setFlashMode(
        _torchOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (_) {}
  }

  Future<void> _captureAndScan() async {
    if (_isScanning || _controller == null) return;
    setState(() {
      _isScanning = true;
      _food = null;
      _errorMsg = null;
    });

    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final text = await _scannerService.scanText(inputImage);

      if (text.isEmpty) {
        setState(() {
          _isScanning = false;
          _errorMsg = 'No text detected. Try again.';
        });
        return;
      }

      final result = await _apiService.fetchFood(text);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _food = result;
          _isScanning = false;
        });
        _showResultSheet(result);
      } else {
        setState(() {
          _isScanning = false;
          _errorMsg = 'Could not identify food. Try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _errorMsg = 'Scan failed. Please try again.';
        });
      }
    }
  }

  void _showResultSheet(FoodModel food) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ResultSheet(food: food),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // ── Camera preview ────────────────────────────────────
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: CameraPreview(_controller!),
              )
            else
              Container(color: const Color(0xFF0D0D1A)),

            // ── Dark overlay outside viewfinder ───────────────────
            if (_isInitialized)
              Positioned.fill(
                child: _ViewfinderOverlay(),
              ),

            // ── Scanning line inside viewfinder ───────────────────
            if (_isInitialized)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _scanLineAnim,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _ScanLinePainter(
                        progress: _scanLineAnim.value,
                        isScanning: _isScanning,
                      ),
                    );
                  },
                ),
              ),

            // ── Top bar ───────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    _IconBtn(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),

                    // Title
                    const Text(
                      'Food Scanner',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),

                    // Torch
                    _IconBtn(
                      icon: _torchOn
                          ? Icons.flashlight_on_rounded
                          : Icons.flashlight_off_rounded,
                      onTap: _toggleTorch,
                      active: _torchOn,
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  28,
                  24,
                  28,
                  MediaQuery.of(context).padding.bottom + 32,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                      Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    // Helper text
                    Text(
                      _isScanning
                          ? 'Scanning...'
                          : _errorMsg ??
                              'Point at food label or barcode',
                      style: TextStyle(
                        fontSize: 14,
                        color: _errorMsg != null
                            ? const Color(0xFFFF6B6B)
                            : Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Scan button
                    GestureDetector(
                      onTap: _isScanning ? null : _captureAndScan,
                      child: AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (context, child) {
                          return Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(
                                    _isScanning
                                        ? _pulseAnim.value * 0.5
                                        : 0.25,
                                  ),
                                  blurRadius: _isScanning ? 30 : 16,
                                  spreadRadius: _isScanning ? 8 : 2,
                                ),
                              ],
                            ),
                            child: _isScanning
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(
                                    Icons.document_scanner_rounded,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Error if no camera ────────────────────────────────
            if (!_isInitialized && _errorMsg != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography_rounded,
                          color: Colors.white38, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        _errorMsg!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            else if (!_isInitialized)
              const Center(
                child: CircularProgressIndicator(color: Colors.white54),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Viewfinder overlay ──────────────────────────────────────────────────────
class _ViewfinderOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ViewfinderPainter());
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    const boxW = 260.0;
    const boxH = 200.0;
    final left = cx - boxW / 2;
    final top = cy - boxH / 2;
    final rect = Rect.fromLTWH(left, top, boxW, boxH);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));

    // Dark overlay with cut-out
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final boxPath = Path()..addRRect(rrect);
    final overlay = Path.combine(PathOperation.difference, fullPath, boxPath);
    canvas.drawPath(overlay, paint);

    // Corner brackets
    const cornerLen = 24.0;
    const cornerRadius = 6.0;
    final bracketPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void drawCorner(double x, double y, double dx, double dy) {
      final path = Path();
      path.moveTo(x + dx * cornerLen, y);
      path.lineTo(x, y);
      path.lineTo(x, y + dy * cornerLen);
      canvas.drawPath(path, bracketPaint);
    }

    drawCorner(left + cornerRadius, top + cornerRadius, 1, 1);
    drawCorner(left + boxW - cornerRadius, top + cornerRadius, -1, 1);
    drawCorner(left + cornerRadius, top + boxH - cornerRadius, 1, -1);
    drawCorner(left + boxW - cornerRadius, top + boxH - cornerRadius, -1, -1);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => false;
}

// ── Animated scan line ──────────────────────────────────────────────────────
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final bool isScanning;
  const _ScanLinePainter({required this.progress, required this.isScanning});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    const boxW = 260.0;
    const boxH = 200.0;
    final left = cx - boxW / 2;
    final top = cy - boxH / 2;

    final y = top + (boxH * progress);

    // Line gradient
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          (isScanning ? Colors.white : const Color(0xFF6BCB77))
              .withOpacity(0.9),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(left, y - 1, boxW, 2));
    linePaint.strokeWidth = 2;
    linePaint.style = PaintingStyle.stroke;

    canvas.drawLine(Offset(left + 8, y), Offset(left + boxW - 8, y), linePaint);
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) =>
      old.progress != progress || old.isScanning != isScanning;
}

// ── Result bottom sheet ─────────────────────────────────────────────────────
class _ResultSheet extends StatelessWidget {
  final FoodModel food;
  const _ResultSheet({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.20),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6BCB77).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Color(0xFF6BCB77), size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Food Detected',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6BCB77),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Food name
                Text(
                  food.name.isNotEmpty ? food.name : 'Unknown Food',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Calorie card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A1A1A), Color(0xFF16213E)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: const Color(0xFFFF6B6B).withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Icon(Icons.local_fire_department_rounded,
                              color: Color(0xFFFF6B6B), size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${food.calories}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                              height: 1,
                            ),
                          ),
                          const Text(
                            'kcal per serving',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Log button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6BCB77), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6BCB77).withOpacity(0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.black, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Add to Today\'s Log',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Frosted icon button ─────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _IconBtn({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withOpacity(0.20)
              : Colors.black.withOpacity(0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Colors.white.withOpacity(0.40)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.white70,
          size: 20,
        ),
      ),
    );
  }
}
