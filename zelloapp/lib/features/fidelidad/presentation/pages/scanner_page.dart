import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../..//data/datasources/sello_remote_data_source.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final SelloRemoteDataSource _dataSource = SelloRemoteDataSource();
  bool _isProcessing = false;

  final String _cuponeraPruebaId = "c9b8a7f6-e5d4-3c2b-1a0f-9e8d7c6b5a4f";
  final String _emisorPruebaId = "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d";

  Future<void> _procesarCodigoQR(String token) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _dataSource.otorgarSello(
        tokenCliente: token,
        cuponeraId: _cuponeraPruebaId,
        emisorId: _emisorPruebaId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sello otorgado con éxito. Acumulados: ${result['sellos_acumulados']}'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear QR del Cliente'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _procesarCodigoQR(barcodes.first.rawValue!);
              }
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}