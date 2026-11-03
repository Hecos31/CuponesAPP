import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/datasources/sello_remote_data_source.dart';

class ScannerPage extends StatefulWidget {
  // 🔑 Ahora recibe los IDs reales desde la navegación
  final String cuponeraId;
  final String emisorId;

  const ScannerPage({
    super.key,
    required this.cuponeraId,
    required this.emisorId,
  });

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final SelloRemoteDataSource _dataSource = SelloRemoteDataSource();
  bool _isProcessing = false;

  Future<void> _procesarCodigoQR(String token) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _dataSource.otorgarSello(
        tokenCliente: token,
        cuponeraId: widget.cuponeraId, // Usamos el ID real que se pasó a la vista
        emisorId: widget.emisorId,     // Usamos el ID del comercio logueado
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sello otorgado con éxito. Acumulados: ${result['sellos_acumulados']}'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(); // Cierra el escáner tras el éxito
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