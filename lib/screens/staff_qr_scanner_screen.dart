import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'verification_details_screen.dart';

class StaffQrScannerScreen extends StatefulWidget {
  const StaffQrScannerScreen({super.key});

  @override
  State<StaffQrScannerScreen> createState() => _StaffQrScannerScreenState();
}

class _StaffQrScannerScreenState extends State<StaffQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _cameraController;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  bool _hasScanned = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _laserController.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_hasScanned) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    try {
      final Map<String, dynamic> qrData = json.decode(rawValue);
      // Validate it's a checkout QR (must have transaction_id)
      if (qrData['transaction_id'] == null) {
        _showError('Invalid QR code. Not a valid checkout receipt.');
        return;
      }
      setState(() => _hasScanned = true);
      _cameraController.stop();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => VerificationDetailsScreen(qrData: qrData),
          ),
        );
      }
    } catch (e) {
      _showError('Could not read QR code. Please ensure it is a checkout receipt.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _cameraController,
            onDetect: _handleBarcode,
          ),

          // Dark overlay with cutout
          CustomPaint(
            painter: _QrOverlayPainter(),
            child: Container(),
          ),

          // Scanning frame + laser
          Center(
            child: SizedBox(
              width: 270,
              height: 270,
              child: Stack(
                children: [
                  // Corner brackets
                  ..._buildCornerBrackets(),
                  // Laser
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left: 16,
                        right: 16,
                        top: _laserAnimation.value * 270,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF009485).withValues(alpha: 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF009485).withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GlassButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                      _GlassPill(label: 'Scan Customer QR'),
                      _GlassButton(
                        icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                        onTap: () {
                          setState(() => _flashOn = !_flashOn);
                          _cameraController.toggleTorch();
                        },
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Instruction
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_2, color: Colors.white.withValues(alpha: 0.9), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Align customer QR code in frame',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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

  List<Widget> _buildCornerBrackets() {
    const size = 30.0;
    const thickness = 4.0;
    const color = Color(0xFF009485);
    return [
      Positioned(
        top: 0, left: 0,
        child: _corner(top: true, left: true, size: size, thickness: thickness, color: color),
      ),
      Positioned(
        top: 0, right: 0,
        child: _corner(top: true, left: false, size: size, thickness: thickness, color: color),
      ),
      Positioned(
        bottom: 0, left: 0,
        child: _corner(top: false, left: true, size: size, thickness: thickness, color: color),
      ),
      Positioned(
        bottom: 0, right: 0,
        child: _corner(top: false, left: false, size: size, thickness: thickness, color: color),
      ),
    ];
  }

  Widget _corner({
    required bool top,
    required bool left,
    required double size,
    required double thickness,
    required Color color,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !top ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: left ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !left ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: (top && left) ? const Radius.circular(8) : Radius.zero,
          topRight: (top && !left) ? const Radius.circular(8) : Radius.zero,
          bottomLeft: (!top && left) ? const Radius.circular(8) : Radius.zero,
          bottomRight: (!top && !left) ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;

    const cutoutSize = 270.0;
    final cutoutLeft = (size.width - cutoutSize) / 2;
    final cutoutTop = (size.height - cutoutSize) / 2;

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutSize, cutoutSize),
        const Radius.circular(16),
      ));
    final overlayPath = Path.combine(PathOperation.difference, fullPath, cutoutPath);
    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String label;
  const _GlassPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
