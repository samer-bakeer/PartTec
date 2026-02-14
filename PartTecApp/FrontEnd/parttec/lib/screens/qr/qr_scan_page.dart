import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController controller = MobileScannerController();
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مسح QR')),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          if (_scanned) return;

          final String? code = capture.barcodes.first.rawValue;
          if (code == null) return;

          _scanned = true;
          controller.stop();
          Navigator.pop(context, code);
        },
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
