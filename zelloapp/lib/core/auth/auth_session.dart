class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String userId = '4cffbabf-436d-4ce0-b304-964f5eefa63e';
  String email = 'fabs@prueba.com';
  String rol = 'cliente'; // 'cliente', 'propietario', 'admin'
  String? token;

  bool get isAdmin => rol.toLowerCase() == 'admin';
  bool get isPropietario => rol.toLowerCase() == 'propietario' || isAdmin;

  void updateFromLogin(Map<String, dynamic> data) {
    final usuario = data['usuario'] as Map<String, dynamic>?;
    if (usuario != null) {
      userId = (usuario['id'] ?? userId).toString();
      email = (usuario['email'] ?? email).toString();
      rol = (usuario['rol'] ?? 'cliente').toString().toLowerCase();
    }
    token = data['token']?.toString();
  }

  void setRol(String nuevoRol) {
    rol = nuevoRol.toLowerCase();
  }
}
