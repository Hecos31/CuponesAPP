import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zelloapp/core/theme/app_theme.dart';

class ZelloLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  final bool lightText;
  final String? subtitle;

  const ZelloLogo({
    super.key,
    this.size = 76,
    this.showWordmark = false,
    this.lightText = false,
    this.subtitle,
  });

  static const String svgString = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500" width="500" height="500">
  <defs>
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#4B1484"/>
      <stop offset="100%" stop-color="#3B0D6F"/>
    </linearGradient>
    <linearGradient id="zGrad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#FFA81E"/>
      <stop offset="60%" stop-color="#FF9312"/>
      <stop offset="100%" stop-color="#FF7A00"/>
    </linearGradient>
  </defs>
  <rect width="500" height="500" rx="110" fill="url(#bgGrad)"/>
  <g fill="#FF9E1B">
    <path d="M 82 170 C 85 160 115 185 130 205 C 122 212 105 210 82 170 Z"/>
    <path d="M 70 230 C 70 220 115 222 125 228 C 125 238 75 250 70 230 Z"/>
    <path d="M 425 170 C 430 175 380 205 370 210 C 368 200 410 168 425 170 Z"/>
    <path d="M 425 230 C 428 245 385 240 375 232 C 380 225 420 220 425 230 Z"/>
  </g>
  <g id="Z-Logo">
    <path d="M 145 145 C 185 120 300 82 342 92 C 370 98 375 126 350 150 L 182 342 C 225 310 305 270 342 270 C 370 270 372 305 348 312 C 290 328 180 378 132 378 C 102 378 95 332 125 296 L 268 138 C 228 154 165 178 142 178 C 122 178 122 156 145 145 Z" 
          fill="#210543" stroke="#210543" stroke-width="26" stroke-linejoin="round" stroke-linecap="round"/>
    <path d="M 145 145 C 185 120 300 82 342 92 C 370 98 375 126 350 150 L 182 342 C 225 310 305 270 342 270 C 370 270 372 305 348 312 C 290 328 180 378 132 378 C 102 378 95 332 125 296 L 268 138 C 228 154 165 178 142 178 C 122 178 122 156 145 145 Z" 
          fill="url(#zGrad)"/>
    <path d="M 132 378 C 180 378 290 328 348 312 C 372 305 365 280 340 282 C 280 298 175 345 130 358 C 112 363 118 378 132 378 Z" 
          fill="#D94B00" opacity="0.85"/>
    <path d="M 182 342 L 350 150 C 362 138 358 122 342 125 C 310 135 220 230 182 342 Z" 
          fill="#D94B00" opacity="0.4"/>
    <path d="M 142 178 C 165 178 228 154 268 138 C 255 148 200 172 142 178 Z" 
          fill="#D94B00" opacity="0.5"/>
  </g>
  <g transform="translate(345, 362) rotate(18)">
    <path d="M -42 -30 L 42 -30 A 8 8 0 0 1 50 -22 L 50 -10 A 12 12 0 0 0 50 10 L 50 22 A 8 8 0 0 1 42 30 L -42 30 A 8 8 0 0 1 -50 22 L -50 10 A 12 12 0 0 0 -50 -10 L -50 -22 A 8 8 0 0 1 -42 -30 Z" 
          fill="#210543" stroke="#210543" stroke-width="22" stroke-linejoin="round" stroke-linecap="round"/>
    <path d="M -42 -30 L 42 -30 A 8 8 0 0 1 50 -22 L 50 -10 A 12 12 0 0 0 50 10 L 50 22 A 8 8 0 0 1 42 30 L -42 30 A 8 8 0 0 1 -50 22 L -50 10 A 12 12 0 0 0 -50 -10 L -50 -22 A 8 8 0 0 1 -42 -30 Z" 
          fill="#FF9E1B"/>
    <line x1="-18" y1="-22" x2="-18" y2="22" 
          stroke="#210543" stroke-width="5" stroke-dasharray="6 5" stroke-linecap="round"/>
  </g>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final logoMark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: 0.35),
            blurRadius: size * 0.26,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: SvgPicture.string(
        svgString,
        width: size,
        height: size,
      ),
    );

    if (!showWordmark) return logoMark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoMark,
        const SizedBox(height: 12),
        Text(
          'ZELLO',
          style: TextStyle(
            fontSize: size * 0.34,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.2,
            color: lightText ? Colors.white : AppTheme.darkInk,
          ),
        ),
        if (subtitle != null && subtitle!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: lightText
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppTheme.mutedSlate,
            ),
          ),
        ],
      ],
    );
  }
}

/// Fondo ambiental moderno con destellos suaves en morado y naranja Zello
class ZelloAmbientBackground extends StatelessWidget {
  final Widget child;

  const ZelloAmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.pageBackgroundGradient,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 140,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.12),
                      AppTheme.primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 110,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.11),
                      AppTheme.accentColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Encabezado superior curvo y moderno con el logo oficial de Zello,
/// destellos decorativos y barra inferior ambar.
class ZelloHeaderBanner extends StatelessWidget {
  final String title;
  final String eyebrow;
  final Widget? trailing;
  final Widget? bottomChild;
  final Widget? leading;

  const ZelloHeaderBanner({
    super.key,
    required this.title,
    this.eyebrow = 'ZELLO',
    this.trailing,
    this.bottomChild,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.darkHeaderGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeep.withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Stack(
          children: [
            // Orbe luminoso naranja en la esquina superior derecha
            Positioned(
              top: -45,
              right: -35,
              child: Container(
                width: 175,
                height: 175,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentBright.withValues(alpha: 0.26),
                      AppTheme.accentBright.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Orbe violeta suave a la izquierda
            Positioned(
              bottom: -55,
              left: -35,
              child: Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Marca de agua de boleto inclinada estilo Zello
            Positioned(
              right: 16,
              bottom: bottomChild != null ? 58 : -10,
              child: Transform.rotate(
                angle: 0.25,
                child: Icon(
                  Icons.confirmation_num_rounded,
                  size: 86,
                  color: Colors.white.withValues(alpha: 0.045),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (leading != null) ...[
                          leading!,
                          const SizedBox(width: 10),
                        ],
                        const ZelloLogo(size: 46),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppTheme.accentBright.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  eyebrow,
                                  style: const TextStyle(
                                    color: AppTheme.accentBright,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ?trailing,
                      ],
                    ),
                    if (bottomChild != null) ...[
                      const SizedBox(height: 18),
                      bottomChild!,
                    ],
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
