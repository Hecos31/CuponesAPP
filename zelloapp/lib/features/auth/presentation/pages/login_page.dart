import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zelloapp/core/network/api_config.dart';
import 'package:zelloapp/core/network/sesion_usuario.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';

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
      final baseUrl = ApiConfig.baseUrl;
      final url = Uri.parse('$baseUrl/auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // 1. Guardamos el token de autenticación
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        // 2. Extraemos los datos del usuario de forma segura
        final usuarioData = data['usuario'];
        final usuarioId =
            usuarioData != null ? usuarioData['id'] : (data['id'] ?? '');
        final rol = (usuarioData != null ? usuarioData['rol'] : 'cliente')
            .toString()
            .toLowerCase();

        // 3. Guardamos el ID y el rol en SharedPreferences
        if (usuarioId.isNotEmpty) {
          await prefs.setString('usuario_id', usuarioId);
        }
        await prefs.setString('rol_usuario', rol);

        // 4. Actualizamos la sesión global en memoria
        SesionUsuario().usuarioId = usuarioId;
        SesionUsuario().rol = rol;

        // 5. Validamos flujos según el rol del usuario
        if (rol == 'admin') {
          await prefs.setBool('is_establecimiento', false);
          if (mounted) {
            context.go('/admin/solicitudes');
          }
          return;
        }

        if (rol == 'propietario') {
          await prefs.setBool('is_establecimiento', true);
          await prefs.setString('status_local', 'aprobado');
        } else {
          await prefs.setBool('is_establecimiento', false);
        }

        if (mounted) {
          context.go('/descubrir');
        }
      } else {
        final message = data['detail'] ?? 'Credenciales incorrectas';
        throw Exception(message);
      }
    } catch (e) {
      if (mounted) {
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanError),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo decorativo superior con gradiente Zello y círculos luminosos
          Container(
            height: MediaQuery.of(context).size.height * 0.46,
            decoration: const BoxDecoration(
              gradient: AppTheme.darkHeaderGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(42),
                bottomRight: Radius.circular(42),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            top: 90,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo vectorial SVG oficial de Zello
                    const ZelloLogo(
                      size: 88,
                      showWordmark: true,
                      lightText: true,
                      subtitle: 'Tus cuponeras digitales en un solo lugar',
                    ),
                    const SizedBox(height: 28),

                    // Tarjeta flotante de inicio de sesión
                    Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryDeep.withValues(alpha: 0.14),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              '¡Hola de nuevo!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.darkInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Ingresa tus credenciales para continuar',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.mutedSlate,
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Correo electrónico',
                                hintText: 'ejemplo@correo.com',
                                prefixIcon: Icon(Icons.alternate_email_rounded),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu correo electrónico';
                                }
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'Ingresa un correo electrónico válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                            const SizedBox(height: 26),
                            Container(
                              decoration: BoxDecoration(
                                gradient: AppTheme.brandGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Iniciar Sesión',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 18,
                                            color: AppTheme.accentColor,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Aún no tienes cuenta?',
                          style: TextStyle(
                            color: AppTheme.mutedSlate,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text(
                            'Crear cuenta gratis',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
