import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/sesion_usuario.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      debugPrint('Paso 1: Iniciando petición de login');
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/auth/login');

     debugPrint('Paso 2: Enviando datos a $url');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 10)); // <--- ¡AGREGA ESTO AQUÍ!

      debugPrint('Paso 3: Respuesta del servidor -> StatusCode: ${response.statusCode}');

      // Corregido: Solo decodificamos si la respuesta es exitosa (200) para evitar colapsos por HTML/Texto plano
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        
        // 1. Guardamos el token de autenticación
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        // 2. Extraemos los datos del usuario de forma segura
        final usuarioData = data['usuario'];
        final usuarioId = usuarioData != null ? usuarioData['id'] : (data['id'] ?? '');
        final rol = usuarioData != null ? usuarioData['rol'] : 'cliente';

        // 3. Guardamos el ID en SharedPreferences
        if (usuarioId.toString().isNotEmpty) {
          await prefs.setString('usuario_id', usuarioId.toString());
        }

        // 4. Actualizamos la sesión global en memoria
        SesionUsuario().usuarioId = usuarioId.toString();
        SesionUsuario().rol = rol;

        // 5. Validamos flujos según el rol del usuario
        if (rol == 'propietario') {
          await prefs.setBool('is_establecimiento', true);
          await prefs.setString('status_local', 'aprobado');
        } else {
          await prefs.setBool('is_establecimiento', false);
        }

        if (mounted) {
          debugPrint('Paso 4: Login exitoso, redirigiendo...');
          context.go('/descubrir'); 
        }
      } else {
        // Manejo seguro de errores del backend (401, 404, 422, etc.)
        String errorMessage = 'Error al iniciar sesión';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['detail'] ?? 'Credenciales incorrectas';
        } catch (_) {
          errorMessage = 'Error de conexión o servidor inalcanzable (Código: ${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Paso ERROR: Hubo una falla -> $e');
      if (mounted) {
        // Limpiamos el texto de la excepción para que el usuario vea un mensaje limpio
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanError),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('Paso Final: Apagando estado de carga');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.local_offer_rounded,
                    size: 72,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Bienvenido!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Inicia sesión para gestionar tus cupones',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu correo electrónico';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Ingresa un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No tienes cuenta?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      TextButton(
                        onPressed: () => context.push('/register'),
                        child: const Text(
                          'Regístrate',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}