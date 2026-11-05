import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/zello_logo.dart';
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
    _pollingTimer?.cancel();
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
      final cuponeraId = widget.cuponeraData['id'] ?? widget.cuponeraData['cuponera_id'];

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
          SnackBar(
            content: Text(data['mensaje'] ?? '¡Te has suscrito exitosamente!'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
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
        const SnackBar(
          content: Text('Primero debes unirte a la cuponera.'),
          backgroundColor: AppTheme.accentColor,
          behavior: SnackBarBehavior.floating,
        ),
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

      final cuponeraId = (widget.cuponeraData['id'] ?? widget.cuponeraData['cuponera_id'])?.toString();

      if (usuarioId == null || usuarioId.isEmpty) {
        throw Exception('Tu sesión expiró o no se guardó el usuario_id. Vuelve a iniciar sesión.');
      }

      if (cuponeraId == null || cuponeraId.isEmpty) {
        throw Exception('No se pudo leer el ID de esta cuponera en la base de datos.');
      }

      final qrToken = await _qrDataSource.generarQrCliente(usuarioId);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _mostrarQrBottomSheet(qrToken, usuarioId, cuponeraId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _mostrarQrBottomSheet(String qrToken, String usuarioId, String cuponeraId) {
    final int sellosIniciales = _sellosAcumulados;

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final nuevosSellos = await _qrDataSource.consultarProgreso(usuarioId, cuponeraId);

        if (nuevosSellos > sellosIniciales) {
          timer.cancel();

          if (mounted) {
            setState(() {
              _sellosAcumulados = nuevosSellos;
            });

            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('¡Sello registrado! Tienes $_sellosAcumulados sellos. 🎉'),
                backgroundColor: AppTheme.successColor,
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
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const ZelloLogo(size: 32),
                  const SizedBox(width: 10),
                  const Text(
                    'Muestra tu QR en caja',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.darkInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Cerraremos esta ventana automáticamente en cuanto el comercio registre tu sello.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDeep.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrToken,
                  version: QrVersions.auto,
                  size: 220.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppTheme.primaryDeep,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppTheme.darkInk,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Listo / Cerrar',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _pollingTimer?.cancel();
    });
  }

  Widget _buildHeader(
    String nombreNegocio,
    String tituloCuponera,
    String? logoUrl,
    String? bannerUrl,
    int totales,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 56),
          decoration: BoxDecoration(
            gradient: AppTheme.darkHeaderGradient,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
            image: bannerUrl != null && bannerUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(bannerUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      AppTheme.primaryDeep.withValues(alpha: 0.65),
                      BlendMode.darken,
                    ),
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryDeep.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ZELLO CUPONERA',
                          style: TextStyle(
                            color: AppTheme.accentBright,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nombreNegocio,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.accentBright.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, color: AppTheme.accentBright, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          '$_sellosAcumulados / $totales',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (tituloCuponera.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  tituloCuponera,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        Positioned(
          bottom: -36,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDeep.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: AppTheme.primarySoft,
              backgroundImage: logoUrl != null && logoUrl.isNotEmpty ? NetworkImage(logoUrl) : null,
              child: (logoUrl == null || logoUrl.isEmpty)
                  ? Text(
                      nombreNegocio.isNotEmpty ? nombreNegocio[0].toUpperCase() : 'Z',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String nombreNegocio = widget.cuponeraData['establecimiento_nombre'] ?? 'Negocio';
    final String tituloCuponera = widget.cuponeraData['titulo_cuponera'] ?? '';
    final String? logoUrl = widget.cuponeraData['establecimiento_logo'];
    final String? bannerUrl = widget.cuponeraData['establecimiento_banner'];
    final int totales = widget.cuponeraData['total_sellos_requeridos'] ?? 6;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ZelloAmbientBackground(
        child: Column(
          children: [
            _buildHeader(nombreNegocio, tituloCuponera, logoUrl, bannerUrl, totales),
            const SizedBox(height: 44),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            // Lienzo o cuadrícula de la cuponera dentro de una tarjeta moderna Zello
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _diseno != null ? _diseno!.fondo : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDeep.withValues(alpha: 0.10),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _diseno != null
                      ? FittedBox(
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
                        )
                      : Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Progreso de tu Cuponera',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.darkInk,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Acumula $totales sellos para canjear tu beneficio',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppTheme.mutedSlate,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                  ),
                                  itemCount: totales,
                                  itemBuilder: (context, index) {
                                    final bool completado = index < _sellosAcumulados;
                                    return Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: completado ? AppTheme.accentGradient : null,
                                        color: completado ? null : AppTheme.primarySoft.withValues(alpha: 0.5),
                                        border: Border.all(
                                          color: completado
                                              ? AppTheme.accentBright
                                              : AppTheme.primaryColor.withValues(alpha: 0.25),
                                          width: 2,
                                        ),
                                        boxShadow: completado
                                            ? [
                                                BoxShadow(
                                                  color: AppTheme.accentColor.withValues(alpha: 0.35),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: completado
                                            ? const Icon(Icons.star_rounded, color: Colors.white, size: 36)
                                            : Text(
                                                '${index + 1}',
                                                style: const TextStyle(
                                                  color: AppTheme.primaryColor,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),

            // BARRA INFERIOR DE ACCIÓN: SOLO SI NO ESTÁ SUSCRITO ("Quiero esta cuponera")
            if (!_estaSuscrito)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _isSubscribing ? null : _unirseCuponera,
                      icon: _isSubscribing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(
                              Icons.add_card_rounded,
                              color: AppTheme.accentBright,
                              size: 22,
                            ),
                      label: Text(
                        _isSubscribing ? 'Suscribiendo...' : 'Quiero esta cuponera',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ),
              )
            else
              const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}
