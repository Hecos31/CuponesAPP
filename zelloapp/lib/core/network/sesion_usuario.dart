class SesionUsuario {
  static final SesionUsuario _instance = SesionUsuario._internal();
  factory SesionUsuario() => _instance;
  SesionUsuario._internal();

  String? usuarioId;
  String? rol; // 'cliente' o 'propietario'

  bool get esPropietario => rol == 'propietario';
  bool get tieneSesion => usuarioId != null && usuarioId!.isNotEmpty;
  
  void limpiar() {
    usuarioId = null;
    rol = null;
  }
}