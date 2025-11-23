import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../widgets/scanner_overlay_widget.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  static const String routeName = 'scanner';
  static const String routePath = '/scanner';

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: true,
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  String? _lastBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null || barcode.isEmpty || barcode == _lastBarcode) {
      return;
    }
    _lastBarcode = barcode;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          const ScannerOverlayWidget(),
        ],
      ),
    );
  }
}
