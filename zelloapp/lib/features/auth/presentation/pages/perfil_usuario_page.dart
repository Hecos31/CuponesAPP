import 'package:flutter/material.dart';

import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({super.key});

  @override
  State<PerfilUsuarioPage> createState() =>
      _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState
    extends State<PerfilUsuarioPage> {

  final TextEditingController emailController =
      TextEditingController(
    text: 'usuario@ejemplo.com',
  );

  bool modoEdicion = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  void guardarCambios() {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El correo electrónico es obligatorio',
          ),
        ),
      );
      return;
    }

    setState(() {
      modoEdicion = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Cambios guardados correctamente',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,

        actions: [
          IconButton(
            icon: Icon(
              modoEdicion
                  ? Icons.close
                  : Icons.edit_outlined,
            ),
            onPressed: () {
              setState(() {
                modoEdicion = !modoEdicion;
              });
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            children: [
              const SizedBox(height: 20),

              CircleAvatar(
                radius: 48,
                backgroundColor:
                    Theme.of(context)
                        .colorScheme
                        .primaryContainer,

                child: Icon(
                  Icons.person_outline,
                  size: 52,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Perfil de usuario',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Administra la información de tu cuenta',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 35),

              AuthTextField(
                label: 'Correo electrónico',
                hintText: 'Correo electrónico',
                icon: Icons.email_outlined,
                keyboardType:
                    TextInputType.emailAddress,
                controller: emailController,
                enabled: modoEdicion,
              ),

              const SizedBox(height: 20),

              _InfoField(
                label: 'Tipo de usuario',
                value: 'Cliente',
                icon: Icons.badge_outlined,
              ),

              const SizedBox(height: 20),

              _InfoField(
                label: 'Fecha de registro',
                value: 'Pendiente de cargar',
                icon: Icons.calendar_today_outlined,
              ),

              if (modoEdicion) ...[
                const SizedBox(height: 30),

                AuthButton(
                  text: 'Guardar cambios',
                  onPressed: guardarCambios,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoField({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,

          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),

          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
            ),

            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.grey.shade600,
              ),

              const SizedBox(width: 12),

              Text(
                value,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}