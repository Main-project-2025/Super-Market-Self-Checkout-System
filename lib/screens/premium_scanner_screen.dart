import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:ui';

class PremiumScannerScreen extends StatefulWidget {
  final double cartTotal;
  final int itemCount;
  final Function(String barcode)? onBarcodeScanned;

  const PremiumScannerScreen({
    super.key,
    this.cartTotal = 0.0,
    this.itemCount = 0,
    this.onBarcodeScanned,
  });

  @override
  State<PremiumScannerScreen> createState() => _PremiumScannerScreenState();
}

class _PremiumScannerScreenState extends State<PremiumScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController cameraController;
  bool _flashOn = false;
  bool _showSuccessNotification = false;
  String? _lastScannedProduct;
  String? _lastScannedPrice;

  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    // Laser scan animation
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(
        parent: _laserController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    _laserController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
    cameraController.toggleTorch();
  }

  void _handleBarcode(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        _showSuccessNotification = true;
        _lastScannedProduct = "Scanned Product";
        _lastScannedPrice = "\$0.00";
      });

      // Call callback
      widget.onBarcodeScanned?.call(barcode);

      // Hide notification after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccessNotification = false;
          });
        }
      });
    }
  }

  void _undoLastScan() {
    setState(() {
      _showSuccessNotification = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Camera Feed Background
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
          ),

          // 2. Dark Overlay with Cutout
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: Container(),
          ),

          // 3. Scanning Frame with Corner Brackets and Laser
          Center(
            child: Container(
              width: 320,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
              ),
              child: Stack(
                children: [
                  // Corner Brackets
                  ..._buildCornerBrackets(),

                  // Animated Laser Line
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        left: 16,
                        right: 16,
                        top: _laserAnimation.value * 200,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.8),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),

                  // Inner ring
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. UI Layer
          SafeArea(
            child: Column(
              children: [
                // Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close Button
                      _buildGlassButton(
                        icon: Icons.close,
                        onTap: () => Navigator.pop(context),
                      ),

                      // Cart Summary Pill
                      _buildCartSummary(),
                    ],
                  ),
                ),

                // Success Notification
                if (_showSuccessNotification)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: _buildSuccessNotification(),
                  ),

                const Spacer(),

                // Helper Text
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: _buildHelperText(),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildBottomControls(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const size = 32.0;
    const thickness = 5.0;
    const primaryColor = Color(0xFF009485);

    return [
      // Top Left
      Positioned(
        top: -1,
        left: -1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: primaryColor, width: thickness),
              top: BorderSide(color: primaryColor, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
            ),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: -1,
        right: -1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: primaryColor, width: thickness),
              top: BorderSide(color: primaryColor, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(32),
            ),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: -1,
        left: -1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: primaryColor, width: thickness),
              bottom: BorderSide(color: primaryColor, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
            ),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: -1,
        right: -1,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: primaryColor, width: thickness),
              bottom: BorderSide(color: primaryColor, width: thickness),
            ),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(32),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildGlassButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Color(0xFF009485),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '\$${widget.cartTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 16,
                color: Colors.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Text(
                '${widget.itemCount} items',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessNotification() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image Placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                ),
              ),
              child: Icon(
                Icons.shopping_bag,
                color: Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _lastScannedProduct ?? 'Product',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF009485).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Added',
                          style: TextStyle(
                            color: Color(0xFF009485),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _lastScannedPrice ?? '\$0.00',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.undo, size: 20),
              color: Colors.grey[400],
              onPressed: _undoLastScan,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.center_focus_strong,
                color: Colors.white.withOpacity(0.9),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Align barcode within frame',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Row(
      children: [
        // Flashlight Toggle
        GestureDetector(
          onTap: _toggleFlash,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _flashOn
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Icon(
                  _flashOn ? Icons.flash_on : Icons.flash_off,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Manual Entry Button
        Expanded(
          child: GestureDetector(
            onTap: () {
              // TODO: Navigate to manual entry screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Manual entry coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard,
                        color: Colors.black87,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Enter barcode manually',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Menu Button
        _buildGlassButton(
          icon: Icons.grid_view,
          onTap: () {
            // TODO: Show menu options
          },
        ),
      ],
    );
  }
}

// Custom painter for the dark overlay with cutout
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Create the full screen path
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Create the cutout path (centered scanning area)
    final cutoutWidth = 320.0;
    final cutoutHeight = 200.0;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2;

    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutWidth, cutoutHeight),
          const Radius.circular(32),
        ),
      );

    // Subtract the cutout from the full screen
    final overlayPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );

    canvas.drawPath(overlayPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
