import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreadorCupones extends StatefulWidget {
  const CreadorCupones({super.key});

  @override
  State<CreadorCupones> createState() => _CreadorCuponesState();
}

class _CreadorCuponesState extends State<CreadorCupones> {
  // Controladores para escuchar los cambios en tiempo real
  final _titleController = TextEditingController();
  final _discountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _termsController = TextEditingController();

  // Valores por defecto para la vista previa
  String get _title => _titleController.text.isEmpty ? 'Título del Cupón' : _titleController.text;
  String get _discount => _discountController.text.isEmpty ? '0%' : _discountController.text;
  String get _description => _descriptionController.text.isEmpty ? 'Descripción breve de la promoción...' : _descriptionController.text;
  String get _terms => _termsController.text.isEmpty ? 'Aplican términos y condiciones.' : _termsController.text;

  @override
  void initState() {
    super.initState();
    // Añadimos listeners para que actualicen el estado con cada tecla presionada
    _titleController.addListener(_updatePreview);
    _discountController.addListener(_updatePreview);
    _descriptionController.addListener(_updatePreview);
    _termsController.addListener(_updatePreview);
  }

  void _updatePreview() {
    setState(() {}); // Provoca un repintado de la UI al escribir
  }

  @override
  void dispose() {
    _titleController.dispose();
    _discountController.dispose();
    _descriptionController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Cupón'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // 1. ZONA DE VISTA PREVIA (Arriba, fija)
          Container(
            color: Colors.grey[100],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Vista Previa en Tiempo Real',
                  style: theme.textTheme.labelLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                _buildCouponPreview(theme),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 1),

          // 2. ZONA DEL FORMULARIO (Abajo, deslizable)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Título de la promoción',
                    icon: Icons.title,
                    hint: 'Ej: 2x1 en Hamburguesas',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _discountController,
                    label: 'Descuento (Texto o %)',
                    icon: Icons.local_offer_outlined,
                    hint: 'Ej: 50% OFF o \$100 de descuento',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Descripción',
                    icon: Icons.description_outlined,
                    hint: 'Explica de qué trata la promoción',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _termsController,
                    label: 'Términos y condiciones',
                    icon: Icons.rule,
                    hint: 'Ej: Válido solo de lunes a jueves...',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      // Lógica futura para enviar el cupón al backend
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cupón guardado exitosamente')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Publicar Cupón',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget personalizado para el diseño del cupón (Vista Previa)
  Widget _buildCouponPreview(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Sección Izquierda (Descuento resaltado)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            alignment: Alignment.center,
            width: 110,
            child: Text(
              _discount,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          
          // Línea punteada divisoria (simulación visual)
          Container(
            width: 1,
            height: 100,
            color: Colors.grey[300],
          ),

          // Sección Derecha (Detalles)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _terms,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para construir los TextFields rápidamente
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}