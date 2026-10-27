import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fidelidad/data/datasources/qr_remote_data_source.dart';

// ----------------------------------------------------------------------
// NOTA IMPORTANTE SOBRE EL SERVER-DRIVEN UI (DISEÑO DESDE BD):
// ----------------------------------------------------------------------
// Como en esta rama aún no tienes los modelos del Editor 
// (DisenoLienzo, ElementoDiseno, ElementoVista), la UI dinámica está
// comentada temporalmente.
// Cuando hagas el merge de la rama del editor, solo debes descomentar
// la sección indicada más abajo para que la tarjeta adopte la apariencia
// exacta que el dueño del negocio dibujó.
// ----------------------------------------------------------------------

class CuponeraDetailPage extends StatefulWidget {
  final Map<String, dynamic> cuponeraData;

  const CuponeraDetailPage({super.key, required this.cuponeraData});

  @override
  State<CuponeraDetailPage> createState() => _CuponeraDetailPageState();
}

class _CuponeraDetailPageState extends State<CuponeraDetailPage> {
  final QrRemoteDataSource _qrDataSource = QrRemoteDataSource();
  
  String? _qrToken;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Variable futura para guardar el diseño JSON cuando tengas el modelo:
  // DisenoLienzo? _diseno;

  @override
  void initState() {
    super.initState();
    // _procesarDiseno(); // Lo descomentarás luego
  }

  /*
  // FUTURO MÉTODO PARA PROCESAR EL JSON DEL EDITOR
  void _procesarDiseno() {
    try {
      final dynamic confUi = widget.cuponeraData['configuracion_ui'];
      if (confUi != null && confUi is Map) {
        final Map<String, dynamic> mapToParse = confUi.containsKey('configuracion_ui')
            ? confUi['configuracion_ui'] as Map<String, dynamic>
            : confUi as Map<String, dynamic>;
            
        setState(() {
          _diseno = DisenoLienzo.fromJson(mapToParse);
        });
      }
    } catch (e) {
      debugPrint('Error al procesar el diseño JSON: $e');
    }
  }
  */

  Future<void> _solicitarQr() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      
      if (usuarioId == null) {
        throw Exception("No hay sesión de usuario activa.");
      }

      final token = await _qrDataSource.generarQrCliente(usuarioId);
      
      setState(() {
        _qrToken = token;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Fallo la conexión al solicitar el código QR.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombreNegocio = widget.cuponeraData['establecimiento_nombre'] ?? 'Negocio';
    final titulo = widget.cuponeraData['titulo_cuponera'] ?? 'Cuponera';
    final int acumulados = widget.cuponeraData['sellos_acumulados'] ?? 0;
    final int totales = widget.cuponeraData['total_sellos_requeridos'] ?? 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(nombreNegocio),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cabecera descriptiva
            Text(
              titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Has acumulado $acumulados de $totales sellos',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),

            // -----------------------------------------------------------
            // VISTA TEMPORAL DE LA CUPONERA (ESTÁTICA)
            // -----------------------------------------------------------
            // Mientras integras el editor, mostraremos una cuadrícula genérica.
            // Si el cliente tiene 3 sellos, se pintarán los 3 primeros.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: totales,
                itemBuilder: (context, index) {
                  final bool completado = index < acumulados;
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: completado ? Colors.green : Colors.grey, width: 2),
                      color: completado ? Colors.green.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: Center(
                      child: completado 
                        ? const Icon(Icons.star, color: Colors.green, size: 32)
                        : Text('${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 20)),
                    ),
                  );
                },
              ),
            ),

            /*
            // -----------------------------------------------------------
            // FUTURA VISTA SERVER-DRIVEN UI (Dinámica desde BD)
            // -----------------------------------------------------------
            // Cuando traigas los archivos del editor, borra el Container de 
            // arriba (GridView estático) y descomenta este bloque.
            
            if (_diseno != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(8),
                // Usamos FittedBox para que el diseño escale perfectamente sin importar el tamaño del teléfono
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: DisenoLienzo.ancho,
                    height: DisenoLienzo.alto,
                    child: Stack(
                      children: _diseno!.elementos.map((elemento) {
                        return Positioned(
                          left: elemento.x,
                          top: elemento.y,
                          // Desactivamos interacciones táctiles en la vista del cliente
                          child: IgnorePointer(
                            child: ElementoVista(elemento: elemento, escala: 1.0),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: const Center(
                  child: Text('Diseño no disponible', style: TextStyle(color: Colors.grey)),
                ),
              ),
            */

            const SizedBox(height: 32),

            // Control del QR
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            if (_qrToken != null)
              Column(
                children: [
                  const Text('Muestra este código en caja', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                    ),
                    child: QrImageView(
                      data: _qrToken!,
                      version: QrVersions.auto,
                      size: 200.0,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _solicitarQr,
                  icon: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.qr_code_2, color: Colors.white),
                  label: Text(_isLoading ? 'Generando...' : 'Generar QR para Sellar/Canjear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}