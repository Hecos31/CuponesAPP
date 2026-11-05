import 'package:flutter/material.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';

import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class PerfilUsuarioPage extends StatefulWidget {
  const PerfilUsuarioPage({super.key});

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  final TextEditingController emailController = TextEditingController(
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
          content: Text('El correo electrónico es obligatorio'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() {
      modoEdicion = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cambios guardados correctamente'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: ZelloAmbientBackground(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ZelloHeaderBanner(
                eyebrow: 'ZELLO',
                title: 'Mi Perfil',
                leading: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                trailing: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: IconButton(
                    icon: Icon(
                      modoEdicion ? Icons.close_rounded : Icons.edit_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        modoEdicion = !modoEdicion;
                      });
                    },
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryDeep.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppTheme.brandGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 44,
                          backgroundColor: AppTheme.primarySoft,
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Perfil de Usuario',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkInk,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Administra la información de tu cuenta Zello',
                        style: TextStyle(
                          color: AppTheme.mutedSlate,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthTextField(
                        label: 'Correo electrónico',
                        hintText: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        enabled: modoEdicion,
                      ),
                      const SizedBox(height: 18),
                      const _InfoField(
                        label: 'Tipo de usuario',
                        value: 'Cliente Zello',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 18),
                      const _InfoField(
                        label: 'Estado de cuenta',
                        value: 'Activa',
                        icon: Icons.verified_user_outlined,
                      ),
                      if (modoEdicion) ...[
                        const SizedBox(height: 26),
                        AuthButton(
                          text: 'Guardar cambios',
                          onPressed: guardarCambios,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.darkInk,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.14),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.darkInk,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
