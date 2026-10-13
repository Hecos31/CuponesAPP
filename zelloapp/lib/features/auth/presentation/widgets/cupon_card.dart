import 'package:flutter/material.dart';
// Import corregido (sube 3 niveles hasta features y busca en cuponeras)
import '../../../cuponeras/presentation/pages/cupon.model.dart';

class CuponCard extends StatelessWidget {
  final CuponModel cupon;
  final VoidCallback? onTap;

  const CuponCard({
    super.key,
    required this.cupon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              // Corregido: Uso de withValues en lugar de withOpacity
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          // Corregido: Uso de withValues
          border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Sección Izquierda
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
                cupon.discount,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            
            // Línea divisoria
            Container(
              width: 1,
              height: 100,
              color: Colors.grey[300],
            ),

            // Sección Derecha
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cupon.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cupon.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cupon.terms,
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
      ),
    );
  }
}