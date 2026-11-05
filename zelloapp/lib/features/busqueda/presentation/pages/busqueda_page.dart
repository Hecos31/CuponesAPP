import 'package:flutter/material.dart';
import 'package:zelloapp/core/theme/app_theme.dart';
import 'package:zelloapp/core/widgets/zello_logo.dart';

class BusquedaPage extends StatelessWidget {
  const BusquedaPage({super.key});

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
                title: 'Buscar Comercios',
                bottomChild: TextField(
                  decoration: InputDecoration(
                    hintText: 'Busca cafeterías, restaurantes, tiendas...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          color: AppTheme.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.travel_explore_rounded,
                          size: 52,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Encuentra tus locales favoritos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Escribe el nombre del negocio o explora las sugerencias cercanas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedSlate, fontSize: 13),
                      ),
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
