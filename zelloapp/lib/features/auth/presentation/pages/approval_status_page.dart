import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ApprovalStatusPage extends StatefulWidget {
  const ApprovalStatusPage({super.key});

  @override
  State<ApprovalStatusPage> createState() => _ApprovalStatusPageState();
}

class _ApprovalStatusPageState extends State<ApprovalStatusPage> {
  bool _isChecking = false;

  // Función para simular la recarga del estado
  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    
    // Simula una petición de red de 2 segundos
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      setState(() => _isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta sigue en revisión por los administradores.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icono ilustrativo principal
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    size: 80,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Título
                Text(
                  'Revisión en curso',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Descripción detallada
                Text(
                  'Hemos recibido la solicitud de tu establecimiento. Nuestro equipo está validando tu información para garantizar la seguridad de la comunidad.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                
                // Tarjeta de Estado
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_filled, color: Colors.orange),
                      const SizedBox(width: 12),
                      Text(
                        'Estado: Pendiente de aprobación',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.orange[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                
                // Botón para recargar/verificar estado
                ElevatedButton(
                  onPressed: _isChecking ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Verificar Estado',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),
                
                // Botón secundario para volver o cerrar sesión
                TextButton(
                  onPressed: () {
                    // Cierra sesión localmente y redirige al login
                    context.go('/login');
                  },
                  child: Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}