import 'dart:io';

class ApiConfig {
  // Cambia a `true` antes de compilar el .aab de producción para Play Console,
  // o pasa `--dart-define=API_BASE_URL=https://tu-app.onrender.com/api/v1`
  static const bool isProduction = false;

  static const String _prodUrl = 'https://zelloapp-backend.onrender.com/api/v1';
  static const String _devUrl = 'http://192.168.1.68:8000/api/v1';

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (isProduction) return _prodUrl;
    if (!Platform.isAndroid && !Platform.isIOS) return _devUrl;
    return _devUrl;
  }
}
