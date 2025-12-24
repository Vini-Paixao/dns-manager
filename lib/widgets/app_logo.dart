import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Widget do logo do aplicativo DNS Manager
/// 
/// Pode ser usado em diferentes tamanhos e com diferentes efeitos visuais.
/// O logo é a imagem PNG do app com gradiente de fundo opcional.
class AppLogo extends StatelessWidget {
  /// Tamanho do container do logo
  final double size;
  
  /// Raio das bordas arredondadas
  final double borderRadius;
  
  /// Se deve mostrar o container com gradiente de fundo
  final bool showBackground;
  
  /// Se deve adicionar sombra ao container
  final bool showShadow;
  
  /// Opacidade da sombra (0.0 a 1.0)
  final double shadowOpacity;
  
  /// Se deve usar apenas o foreground (ícone sem fundo)
  final bool foregroundOnly;

  const AppLogo({
    super.key,
    this.size = 80,
    this.borderRadius = 20,
    this.showBackground = true,
    this.showShadow = true,
    this.shadowOpacity = 0.3,
    this.foregroundOnly = false,
  });

  /// Logo pequeno para uso em listas e ícones
  const AppLogo.small({
    super.key,
    this.showBackground = true,
    this.showShadow = false,
  })  : size = 40,
        borderRadius = 10,
        shadowOpacity = 0.2,
        foregroundOnly = false;

  /// Logo médio para uso em dialogs e cards
  const AppLogo.medium({
    super.key,
    this.showBackground = true,
    this.showShadow = true,
  })  : size = 60,
        borderRadius = 14,
        shadowOpacity = 0.3,
        foregroundOnly = false;

  /// Logo grande para telas de splash e about
  const AppLogo.large({
    super.key,
    this.showBackground = true,
    this.showShadow = true,
  })  : size = 100,
        borderRadius = 24,
        shadowOpacity = 0.4,
        foregroundOnly = false;

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          foregroundOnly 
              ? 'assets/icon/app_icon_foreground.png'
              : 'assets/icon/app_icon.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: shadowOpacity),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Image.asset(
            'assets/icon/app_icon_foreground.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/// Widget simples do logo sem container (apenas a imagem)
class AppLogoImage extends StatelessWidget {
  final double size;
  
  const AppLogoImage({
    super.key,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icon/app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
