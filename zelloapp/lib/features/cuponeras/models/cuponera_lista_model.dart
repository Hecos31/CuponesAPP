class CuponeraListaModel {
  final String id;
  final String titulo;
  final String descripcionPremio;
  final int totalSellosRequeridos;
  final String establecimientoNombre;
  final Map<String, dynamic>? diseno;

  CuponeraListaModel({
    required this.id,
    required this.titulo,
    required this.descripcionPremio,
    required this.totalSellosRequeridos,
    required this.establecimientoNombre,
    this.diseno,
  });

  factory CuponeraListaModel.fromJson(Map<String, dynamic> json) {
    return CuponeraListaModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? 'Sin título',
      descripcionPremio: json['descripcion_premio'] ?? '',
      totalSellosRequeridos: json['total_sellos_requeridos'] ?? 6,
      establecimientoNombre: json['establecimiento_nombre'] ?? 'Establecimiento',
      diseno: json['diseno']?['configuracion_ui'],
    );
  }
}