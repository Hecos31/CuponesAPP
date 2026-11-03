import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // 🔑 IMPORTANTE PARA EL TIMER
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fidelidad/data/datasources/qr_remote_data_source.dart';

// --- IMPORTS DEL EDITOR ---
import '../../../editor/models/diseno_lienzo.dart';
import '../../../editor/widgets/elemento_vista.dart';

class CuponeraDetailPage extends StatefulWidget {
  final Map<String, dynamic> cuponeraData;

  const CuponeraDetailPage({super.key, required this.cuponeraData});

  @override
  State<CuponeraDetailPage> createState() => _CuponeraDetailPageState();
}

class _CuponeraDetailPageState extends State<CuponeraDetailPage> {
  final QrRemoteDataSource _qrDataSource = QrRemoteDataSource();
  
  bool _estaSuscrito = false;
  bool _isLoading = false; 
  bool _isSubscribing = false; 
  String? _errorMessage;

  DisenoLienzo? _diseno;
  
  // 🔑 VARIABLES DE ESTADO PARA EL TIEMPO REAL
  int _sellosAcumulados = 0;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _sellosAcumulados = widget.cuponeraData['sellos_acumulados'] ?? 0;
    _verificarSuscripcion();
    _procesarDiseno();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Limpiamos el timer al salir de la pantalla
    super.dispose();
  }

  void _verificarSuscripcion() {
    final progresoId = widget.cuponeraData['progreso_id'];
    setState(() {
      _estaSuscrito = progresoId != null && progresoId.toString().isNotEmpty;
    });
  }

  void _procesarDiseno() {
    try {
      final dynamic confUi = widget.cuponeraData['configuracion_ui'];
      if (confUi != null) {
        Map<String, dynamic>? mapToParse;

        if (confUi is Map) {
          if (confUi.containsKey('configuracion_ui') && confUi['configuracion_ui'] is Map) {
            mapToParse = Map<String, dynamic>.from(confUi['configuracion_ui']);
          } else {
            mapToParse = Map<String, dynamic>.from(confUi);
          }
        } else if (confUi is String) {
          final decoded = jsonDecode(confUi);
          if (decoded is Map) {
            mapToParse = Map<String, dynamic>.from(decoded);
          }
        }

        if (mapToParse != null && mapToParse.containsKey('elementos')) {
          setState(() {
            _diseno = DisenoLienzo.fromJson(mapToParse!);
          });
        }
      }
    } catch (e) {
      debugPrint('Error al procesar el diseño JSON: $e');
    }
  }

  Future<void> _unirseCuponera() async {
    setState(() {
      _isSubscribing = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');
      final cuponeraId = widget.cuponeraData['id'];

      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId/unirse?usuario_id=$usuarioId');
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _estaSuscrito = true;
          _isSubscribing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['mensaje'] ?? '¡Te has suscrito exitosamente!'), backgroundColor: Colors.green),
        );
      } else {
        throw Exception(data['detail'] ?? 'Error al suscribirse');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSubscribing = false;
      });
    }
  }

  Future<void> _solicitarYMostrarQr() async {
    if (!_estaSuscrito) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debes unirte a la cuponera.'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      
      // 🔑 Buscamos en 'id' y si no está, buscamos en 'cuponera_id'
      final cuponeraId = (widget.cuponeraData['id'] ?? widget.cuponeraData['cuponera_id'])?.toString();

      // Esto imprimirá en tu consola qué datos están llegando realmente
      debugPrint("🔍 DEBUG QR - Usuario: $usuarioId | Cuponera: $cuponeraId");
      debugPrint("📦 DATOS DEL MAPA: ${widget.cuponeraData}");

      // Separamos los errores para saber exactamente qué falló
      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception("Tu sesión expiró o no se guardó el usuario_id. Vuelve a iniciar sesión.");
      }
      
      if (cuponeraId == null || cuponeraId.isEmpty) {
        throw Exception("No se pudo leer el ID de esta cuponera en la base de datos.");
      }

      final qrToken = await _qrDataSource.generarQrCliente(usuarioId);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _mostrarQrBottomSheet(qrToken, usuarioId, cuponeraId);

    } catch (e) {
      debugPrint("❌ ERROR AL GENERAR QR: $e");
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _mostrarQrBottomSheet(String qrToken, String usuarioId, String cuponeraId) {
    final int sellosIniciales = _sellosAcumulados;

    // 🔑 INICIAMOS EL TIMER (Pregunta al servidor cada 3 segundos)
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final nuevosSellos = await _qrDataSource.consultarProgreso(usuarioId, cuponeraId);
        
        if (nuevosSellos > sellosIniciales) {
          timer.cancel(); // Detenemos la búsqueda
          
          if (mounted) {
            // Actualizamos la interfaz
            setState(() {
              _sellosAcumulados = nuevosSellos;
            });
            
            // Cerramos el QR automáticamente
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            
            // Celebramos con el usuario
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Sello registrado! Tienes $_sellosAcumulados sellos. 🎉'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      } catch (e) {
        // Ignoramos fallos de red silenciosamente
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Muestra este código en caja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Cerraremos esta ventana automáticamente cuando el comercio lo escanee.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: QrImageView(data: qrToken, version: QrVersions.auto, size: 220.0, foregroundColor: Colors.black87),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    ).then((_) {
      // 🔑 Si el usuario desliza o cierra manualmente el modal, apagamos el timer
      _pollingTimer?.cancel();
    });
  }

  Widget _buildHeader(String nombreNegocio, String? logoUrl, String? bannerUrl) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade100,
            image: bannerUrl != null && bannerUrl.isNotEmpty
                ? DecorationImage(image: NetworkImage(bannerUrl), fit: BoxFit.cover)
                : null,
          ),
          child: (bannerUrl == null || bannerUrl.isEmpty)
              ? const Center(child: Icon(Icons.storefront, size: 64, color: Colors.white54))
              : null,
        ),
        Positioned(
          bottom: -40,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: logoUrl != null && logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
              child: (logoUrl == null || logoUrl.isEmpty)
                  ? Text(nombreNegocio[0].toUpperCase(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey))
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreNegocio = widget.cuponeraData['establecimiento_nombre'] ?? 'Negocio';
    final logoUrl = widget.cuponeraData['establecimiento_logo'];
    final bannerUrl = widget.cuponeraData['establecimiento_banner'];
    final int totales = widget.cuponeraData['total_sellos_requeridos'] ?? 6;

    Color backgroundColor = _diseno != null ? _diseno!.fondo : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(nombreNegocio),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent, 
      ),
      extendBodyBehindAppBar: true, 
      body: Column(
        children: [
          _buildHeader(nombreNegocio, logoUrl, bannerUrl),
          
          const SizedBox(height: 50), 
          
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),

          // VISTA SERVER-DRIVEN UI LIMPIA
          Expanded(
            child: _diseno != null
                ? SizedBox(
                    width: double.infinity,
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
                              child: ElementoVista(
                                elemento: elemento,
                                escala: 1.0,
                                onTapQr: _solicitarYMostrarQr,
                                isLoading: _isLoading, 
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  )
                : Padding(
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
                        // 🔑 Usamos la variable de estado dinámica en lugar de la estática
                        final bool completado = index < _sellosAcumulados; 
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
          ),

          // BOTÓN INFERIOR FIJO: SOLO SI NO ESTÁ SUSCRITO
          if (!_estaSuscrito)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubscribing ? null : _unirseCuponera,
                    icon: _isSubscribing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add_card, color: Colors.white),
                    label: Text(_isSubscribing ? 'Suscribiendo...' : 'Quiero esta cuponera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}