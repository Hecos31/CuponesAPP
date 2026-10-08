import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fidelidad/data/datasources/qr_remote_data_source.dart';

class CuponeraDetailPage extends StatefulWidget {
  const CuponeraDetailPage({super.key});

  @override
  State<CuponeraDetailPage> createState() => _CuponeraDetailPageState();
}

class _CuponeraDetailPageState extends State<CuponeraDetailPage> {
  final QrRemoteDataSource _qrDataSource = QrRemoteDataSource();
  
  String? _qrToken;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _solicitarQr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String usuarioSimuladoId = "b9f2c3a0-1d4e-4f5a-8c7b-9a0e1f2c3d4e";
      final token = await _qrDataSource.generarQrCliente(usuarioSimuladoId);
      
      setState(() {
        _qrToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Fallo la conexión con el servidor.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Cuponera'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_qrToken != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10)
                  ],
                ),
                child: QrImageView(
                  data: _qrToken!,
                  version: QrVersions.auto,
                  size: 200.0,
                  foregroundColor: AppTheme.primaryColor,
                ),
              )
            else
              const Icon(Icons.card_giftcard, size: 100, color: Colors.grey),
            
            const SizedBox(height: 24),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),

            const Text(
              'Progreso: 3 / 10 Sellos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 48),
            
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _solicitarQr,
                    icon: const Icon(Icons.qr_code_2, color: Colors.white),
                    label: Text(_qrToken == null ? 'Generar QR para Sello' : 'Actualizar QR'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}