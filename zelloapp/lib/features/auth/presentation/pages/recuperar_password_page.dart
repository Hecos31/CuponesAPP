import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class RecuperarPasswordPage extends StatefulWidget {
  const RecuperarPasswordPage({super.key});

  @override
  State<RecuperarPasswordPage> createState() =>
      _RecuperarPasswordPageState();
}

class _RecuperarPasswordPageState
    extends State<RecuperarPasswordPage> {

  final TextEditingController emailController =
      TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void continuar() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ingresa tu correo electrónico',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitud enviada correctamente',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recuperar contraseña',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 35),

              Center(
                child: Icon(
                  Icons.lock_reset_outlined,
                  size: 72,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Ingresa el correo electrónico asociado '
                'a tu cuenta para recuperar el acceso.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 32),

              AuthTextField(
                label: 'Correo electrónico',
                hintText: 'Ingresa tu correo',
                icon: Icons.email_outlined,
                keyboardType:
                    TextInputType.emailAddress,
                controller: emailController,
              ),

              const SizedBox(height: 28),

              AuthButton(
                text: 'Continuar',
                onPressed: continuar,
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text(
                    'Regresar al inicio de sesión',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}