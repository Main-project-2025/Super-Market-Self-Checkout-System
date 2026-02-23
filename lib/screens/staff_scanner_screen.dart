import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'verification_result_screen.dart';

class StaffScannerScreen extends StatefulWidget {
  const StaffScannerScreen({super.key});

  @override
  State<StaffScannerScreen> createState() => _StaffScannerScreenState();
}

class _StaffScannerScreenState extends State<StaffScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => isScanning = false);
        _handleVerification(code);
      }
    }
  }

  Future<void> _handleVerification(String qrData) async {
    try {
      final result = await ApiService.verifyQrCode(qrData);

      if (mounted) {
        if (result['success'] == true) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  VerificationResultScreen(billData: result['data']),
            ),
          );
          if (mounted) {
            setState(() => isScanning = true);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Verification failed'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isScanning = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() => isScanning = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Purchase'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),
          // Scanning Overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  _buildCorner(
                    leftPos: 0,
                    topPos: 0,
                    isTop: true,
                    isLeft: true,
                  ),
                  _buildCorner(
                    rightPos: 0,
                    topPos: 0,
                    isTop: true,
                    isRight: true,
                  ),
                  _buildCorner(
                    leftPos: 0,
                    bottomPos: 0,
                    isBottom: true,
                    isLeft: true,
                  ),
                  _buildCorner(
                    rightPos: 0,
                    bottomPos: 0,
                    isBottom: true,
                    isRight: true,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  'Scan the customer\'s bill QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({
    double? leftPos,
    double? topPos,
    double? rightPos,
    double? bottomPos,
    bool isTop = false,
    bool isLeft = false,
    bool isRight = false,
    bool isBottom = false,
  }) {
    return Positioned(
      top: topPos,
      bottom: bottomPos,
      left: leftPos,
      right: rightPos,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Colors.teal, width: 5)
                : BorderSide.none,
            bottom: isBottom
                ? const BorderSide(color: Colors.teal, width: 5)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Colors.teal, width: 5)
                : BorderSide.none,
            right: isRight
                ? const BorderSide(color: Colors.teal, width: 5)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
