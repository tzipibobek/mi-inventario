import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _returnedCode = false;

  void _onDetect(BarcodeCapture result) {
    if (_returnedCode || !mounted) {
      return;
    }
    for (final barcode in result.barcodes) {
      final code = barcode.rawValue?.trim();
      if (code == null || code.isEmpty) {
        continue;
      }
      // La cámara puede detectar el mismo código en varios fotogramas.
      _returnedCode = true;
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear código')),
      body: MobileScanner(
        onDetect: _onDetect,
        errorBuilder: (context, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Permití el acceso a la cámara desde Ajustes del teléfono. '
                        'También podés volver y escribir el código manualmente.'
                  : 'No se pudo iniciar la cámara. Volvé y probá otra vez.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Apuntá a un código de barras o QR. Se lee automáticamente.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
