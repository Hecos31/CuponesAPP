import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../fidelidad/data/datasources/qr_remote_data_source.dart';

// --- IMPORTS DEL EDITOR (SERVER-DRIVEN UI) ---
import '../../../editor/models/diseno_lienzo.dart';
import '../../../editor/widgets/elemento_vista.dart';

class CuponeraDetailPage extends StatefulWidget {
  final Map<String, dynamic> cuponeraData;

  const CuponeraDetailPage({super.key, required this.cuponeraData});

  @override
  State<CuponeraDetailPage> createState() => _CuponeraDetailPageState();
}

class _CuponeraDetailPageState extends State<CuponeraDetailPage> {
  // Corrección: QrRemoteDataSource con 'r' minúscula
  final QrRemoteDataSource _qrDataSource = QrRemoteDataSource();
  
  bool _estaSuscrito = false;
  String? _qrToken;
  bool _isLoading = false;
  String? _errorMessage;

  // Variable para guardar el diseño JSON procesado
  DisenoLienzo? _diseno;

  @override
  void initState() {
    super.initState();
    _verificarSuscripcion();
    _procesarDiseno();
  }

  // Verificamos si el usuario ya está suscrito (si tiene progreso_id o viene de Mis Cuponeras)
  void _verificarSuscripcion() {
    final progresoId = widget.cuponeraData['progreso_id'];
    setState(() {
      _estaSuscrito = progresoId != null && progresoId.toString().isNotEmpty;
    });
  }

// MÉTODO PARA PROCESAR EL JSON DEL EDITOR DESDE LA BD
  void _procesarDiseno() {
    try {
      final dynamic confUi = widget.cuponeraData['configuracion_ui'];
      if (confUi != null) {
        Map<String, dynamic>? mapToParse;

        if (confUi is Map) {
          // Verificamos si viene anidado o plano
          if (confUi.containsKey('configuracion_ui') && confUi['configuracion_ui'] is Map) {
            mapToParse = Map<String, dynamic>.from(confUi['configuracion_ui']);
          } else {
            mapToParse = Map<String, dynamic>.from(confUi);
          }
        } else if (confUi is String) {
          // Por si acaso viene como String codificado en JSON
          final decoded = jsonDecode(confUi);
          if (decoded is Map) {
            mapToParse = Map<String, dynamic>.from(decoded);
          }
        }

        if (mapToParse != null && mapToParse.containsKey('elementos')) {
          setState(() {
            // Usamos el operador '!' porque ya validamos que mapToParse no es null
            _diseno = DisenoLienzo.fromJson(mapToParse!);
          });
          debugPrint('Diseño Server-Driven UI cargado exitosamente: ${_diseno!.elementos.length} elementos');
        } else {
          debugPrint('El JSON no contiene la clave "elementos" requerida por DisenoLienzo');
        }
      }
    } catch (e) {
      debugPrint('Error al procesar el diseño JSON: $e');
    }
  }

  // 🎟️ Función para suscribirse desde el detalle
  Future<void> _unirseCuponera() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getString('usuario_id');
      final token = prefs.getString('token');
      final cuponeraId = widget.cuponeraData['id'];

      if (usuarioId == null || cuponeraId == null) {
        throw Exception("No hay sesión activa o ID de cuponera inválido.");
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/cuponeras/$cuponeraId/unirse?usuario_id=$usuarioId');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _estaSuscrito = true;
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['mensaje'] ?? '¡Te has suscrito exitosamente!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception(data['detail'] ?? 'Error al suscribirse');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

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
    final titulo = widget.cuponeraData['titulo_cuponera'] ??
        widget.cuponeraData['titulo'] ??
        'Cuponera';
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
            // VISTA SERVER-DRIVEN UI (Dinámica desde la BD)
            // -----------------------------------------------------------
            if (_diseno != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
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
                          child: IgnorePointer(
                            child: ElementoVista(
                              elemento: elemento,
                              escala: 1.0,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              )
            else
              // Fallback estático en caso de que aún no tenga un diseño guardado
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
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
                        border: Border.all(
                          color: completado ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                        color: completado
                            ? Colors.green.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: completado
                            ? const Icon(
                                Icons.star,
                                color: Colors.green,
                                size: 32,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 20,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 32),

            // Mensajes de error
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // -----------------------------------------------------------
            // CONTROL DE ACCIÓN SEGÚN SUSCRIPCIÓN
            // -----------------------------------------------------------
            if (!_estaSuscrito)
              // 1. Si NO está suscrito, mostramos el botón para unirse
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _unirseCuponera,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add_card, color: Colors.white),
                  label: Text(_isLoading ? 'Suscribiendo...' : 'Quiero esta cuponera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (_qrToken != null)
              // 2. Si ya está suscrito y generó el QR, lo mostramos
              Column(
                children: [
                  const Text(
                    'Muestra este código en caja',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 2,
                      ),
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
              // 3. Si ya está suscrito pero aún no genera el QR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _solicitarQr,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.qr_code_2, color: Colors.white),
                  label: Text(
                    _isLoading
                        ? 'Generando...'
                        : 'Generar QR para Sellar/Canjear',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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