import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:zelloapp/core/network/api_config.dart';

class SucursalModel {
  final String id;
  final String propietarioId;
  final String nombre;
  final String slug;
  final String? logoUrl;
  final bool activo;
  final DateTime fechaCreacion;
  final bool requiereAprobacionNombre;
  final String? solicitudId;
  final String? mensaje;

  SucursalModel({
    required this.id,
    required this.propietarioId,
    required this.nombre,
    required this.slug,
    this.logoUrl,
    required this.activo,
    required this.fechaCreacion,
    this.requiereAprobacionNombre = false,
    this.solicitudId,
    this.mensaje,
  });

  factory SucursalModel.fromJson(Map<String, dynamic> json) {
    return SucursalModel(
      id: json['id'] ?? '',
      propietarioId: json['propietario_id'] ?? '',
      nombre: json['nombre'] ?? '',
      slug: json['slug'] ?? '',
      logoUrl: json['logo_url'],
      activo: json['activo'] ?? true,
      fechaCreacion: DateTime.tryParse(json['fecha_creacion'] ?? '') ?? DateTime.now(),
      requiereAprobacionNombre: json['requiere_aprobacion_nombre'] ?? false,
      solicitudId: json['solicitud_id']?.toString(),
      mensaje: json['mensaje']?.toString(),
    );
  }
}

class SolicitudModel {
  final String id;
  final String usuarioId;
  final String nombreNegocio;
  final String? documentosUrl;
  final String estado;
  final DateTime fechaSolicitud;
  final String? usuarioEmail;
  final String? direccion;
  final String? nombreSolicitante;
  final String? comentariosEvaluacion;
  final String? fechaEvaluacion;
  final String tipoSolicitud;
  final String? establecimientoId;
  final String? nombreAnterior;

  SolicitudModel({
    required this.id,
    required this.usuarioId,
    required this.nombreNegocio,
    this.documentosUrl,
    required this.estado,
    required this.fechaSolicitud,
    this.usuarioEmail,
    this.direccion,
    this.nombreSolicitante,
    this.comentariosEvaluacion,
    this.fechaEvaluacion,
    this.tipoSolicitud = 'ALTA_SUCURSAL',
    this.establecimientoId,
    this.nombreAnterior,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    return SolicitudModel(
      id: json['id'] ?? '',
      usuarioId: json['usuario_id'] ?? '',
      nombreNegocio: json['nombre_negocio'] ?? '',
      documentosUrl: json['documentos_url'],
      estado: (json['estado'] ?? 'PENDIENTE').toString().toUpperCase(),
      fechaSolicitud: DateTime.tryParse(json['fecha_solicitud'] ?? '') ?? DateTime.now(),
      usuarioEmail: json['usuario_email']?.toString(),
      direccion: json['direccion']?.toString(),
      nombreSolicitante: json['nombre_solicitante']?.toString(),
      comentariosEvaluacion: json['comentarios_evaluacion']?.toString(),
      fechaEvaluacion: json['fecha_evaluacion']?.toString(),
      tipoSolicitud: (json['tipo_solicitud'] ?? 'ALTA_SUCURSAL').toString().toUpperCase(),
      establecimientoId: json['establecimiento_id']?.toString(),
      nombreAnterior: json['nombre_anterior']?.toString(),
    );
  }

  bool get esCambioNombre => tipoSolicitud == 'CAMBIO_NOMBRE';

  List<String> get listaDocumentos {
    if (documentosUrl == null || documentosUrl!.trim().isEmpty) return [];
    return documentosUrl!
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class SucursalesRemoteDataSource {
  // ---------------------------------------------------------------------------
  // Tarea 1000 (FG): Carga segura de documentos probatorios y logotipos
  // ---------------------------------------------------------------------------
  Future<String> uploadDocumento(
    List<int> bytes,
    String filename, {
    String tipoDocumento = 'INE',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/solicitudes/upload-documento');
    final request = http.MultipartRequest('POST', uri);

    request.fields['tipo_documento'] = tipoDocumento;
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'] as String;
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error al subir archivo');
    }
  }

  // ---------------------------------------------------------------------------
  // Solicitudes de verificación y cambio de nombre
  // ---------------------------------------------------------------------------
  Future<SolicitudModel> crearSolicitud({
    required String usuarioId,
    required String nombreNegocio,
    String? documentosUrl,
    String? direccion,
    String? nombreSolicitante,
    String tipoSolicitud = 'ALTA_SUCURSAL',
    String? establecimientoId,
    String? nombreAnterior,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/solicitudes/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'usuario_id': usuarioId,
        'nombre_negocio': nombreNegocio,
        'documentos_url': documentosUrl,
        'direccion': direccion,
        'nombre_solicitante': nombreSolicitante,
        'tipo_solicitud': tipoSolicitud,
        'establecimiento_id': establecimientoId,
        'nombre_anterior': nombreAnterior,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SolicitudModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error al registrar solicitud');
    }
  }

  Future<List<SolicitudModel>> getSolicitudes({String? usuarioId, String? estado}) async {
    var queryParams = <String, String>{};
    if (usuarioId != null && usuarioId.isNotEmpty) queryParams['usuario_id'] = usuarioId;
    if (estado != null && estado.isNotEmpty) queryParams['estado'] = estado;

    final uri = Uri.parse('${ApiConfig.baseUrl}/solicitudes/').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => SolicitudModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener lista de solicitudes: ${response.statusCode}');
    }
  }

  Future<SolicitudModel> getDetalleSolicitud(String solicitudId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/solicitudes/$solicitudId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return SolicitudModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener detalle de la solicitud: ${response.statusCode}');
    }
  }

  // Tarea 980 (FG): Máquina de estados y evaluación manual con comentarios/correcciones
  Future<SolicitudModel> actualizarEstadoSolicitud(
    String solicitudId,
    String nuevoEstado, {
    String? comentariosEvaluacion,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/solicitudes/$solicitudId/estado');
    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'estado': nuevoEstado,
        'comentarios_evaluacion': comentariosEvaluacion,
      }),
    );

    if (response.statusCode == 200) {
      return SolicitudModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error al cambiar estado de solicitud');
    }
  }

  // ---------------------------------------------------------------------------
  // Sucursales / Establecimientos: Altas, Administración y Configuración
  // ---------------------------------------------------------------------------
  Future<SucursalModel> darDeAltaSucursal({
    required String propietarioId,
    required String nombre,
    String? slug,
    String? logoUrl,
    bool activo = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/establecimientos/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'propietario_id': propietarioId,
        'nombre': nombre,
        'slug': slug,
        'logo_url': logoUrl,
        'activo': activo,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return SucursalModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error al dar de alta la sucursal');
    }
  }

  Future<List<SucursalModel>> getSucursales({String? propietarioId, bool? activo}) async {
    var queryParams = <String, String>{};
    if (propietarioId != null && propietarioId.isNotEmpty) queryParams['propietario_id'] = propietarioId;
    if (activo != null) queryParams['activo'] = activo.toString();

    final uri = Uri.parse('${ApiConfig.baseUrl}/establecimientos/').replace(queryParameters: queryParams);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((e) => SucursalModel.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener lista de sucursales: ${response.statusCode}');
    }
  }

  Future<SucursalModel> getDetalleSucursal(String sucursalId) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/establecimientos/$sucursalId');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return SucursalModel.fromJson(json.decode(response.body));
    } else {
      throw Exception('Error al obtener sucursal: ${response.statusCode}');
    }
  }

  Future<SucursalModel> actualizarConfiguracionSucursal(
    String sucursalId, {
    String? nombre,
    String? logoUrl,
    bool? activo,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/establecimientos/$sucursalId/configuracion');
    final body = <String, dynamic>{};
    if (nombre != null) body['nombre'] = nombre;
    if (logoUrl != null) body['logo_url'] = logoUrl;
    if (activo != null) body['activo'] = activo;

    final response = await http.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return SucursalModel.fromJson(json.decode(response.body));
    } else {
      final error = json.decode(response.body);
      throw Exception(error['detail'] ?? 'Error al actualizar configuración de sucursal');
    }
  }
}
