import 'package:flutter/material.dart';

/// Cores centralizadas do aplicativo DNS Manager
/// 
/// Use estas constantes em vez de valores hexadecimais hardcoded
/// para manter consistência visual em todo o app.
/// 
/// Cores do gradiente do logo:
/// - Ciano claro: #5de0e6
/// - Azul escuro: #004aad
class AppColors {
  // Prevenir instanciação
  AppColors._();

  // ============================================
  // CORES PRIMÁRIAS E DE DESTAQUE (baseadas no logo)
  // ============================================
  
  /// Cor primária do app (Azul escuro do logo)
  static const Color primary = Color(0xFF004aad);
  
  /// Cor secundária/destaque (Ciano claro do logo)
  static const Color secondary = Color(0xFF5de0e6);
  
  /// Variante da cor primária (mais claro para tema claro)
  static const Color primaryLight = Color(0xFF3366BB);
  
  /// Variante do secundário (mais escuro para contraste)
  static const Color secondaryDark = Color(0xFF00B4B4);
  
  /// Cor de erro
  static const Color error = Color(0xFFCF6679);
  
  /// Cor de sucesso
  static const Color success = Color(0xFF4CAF50);
  
  /// Cor de alerta/warning
  static const Color warning = Color(0xFFFFA726);

  // ============================================
  // CORES DO TEMA ESCURO
  // ============================================
  
  /// Fundo principal (tema escuro)
  static const Color darkBackground = Color(0xFF121212);
  
  /// Superfície/container (tema escuro)
  static const Color darkSurface = Color(0xFF1E1E1E);
  
  /// Cards e elementos elevados (tema escuro)
  static const Color darkCard = Color(0xFF2D2D2D);
  
  /// Texto primário (tema escuro)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  
  /// Texto secundário (tema escuro)
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  
  /// Divisores (tema escuro)
  static const Color darkDivider = Color(0xFF3D3D3D);

  // ============================================
  // CORES DO TEMA CLARO
  // ============================================
  
  /// Fundo principal (tema claro)
  static const Color lightBackground = Color(0xFFF5F5F5);
  
  /// Superfície/container (tema claro)
  static const Color lightSurface = Color(0xFFFFFFFF);
  
  /// Cards e elementos elevados (tema claro)
  static const Color lightCard = Color(0xFFFFFFFF);
  
  /// Texto primário (tema claro)
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  
  /// Texto secundário (tema claro)
  static const Color lightTextSecondary = Color(0xFF666666);
  
  /// Divisores (tema claro)
  static const Color lightDivider = Color(0xFFE0E0E0);

  // ============================================
  // CORES DE STATUS DO DNS
  // ============================================
  
  /// DNS ativo (ciano do logo)
  static const Color dnsActive = Color(0xFF5de0e6);
  
  /// DNS inativo (cinza)
  static const Color dnsInactive = Color(0xFF9E9E9E);

  // ============================================
  // CORES DOS PROVEDORES DNS
  // ============================================
  
  /// Cloudflare
  static const Color providerCloudflare = Color(0xFFF38020);
  
  /// Google
  static const Color providerGoogle = Color(0xFF4285F4);
  
  /// Quad9
  static const Color providerQuad9 = Color(0xFFED1944);
  
  /// AdGuard
  static const Color providerAdguard = Color(0xFF68BC71);
  
  /// Servidor customizado (cor padrão - azul do logo)
  static const Color providerCustom = Color(0xFF004aad);

  // ============================================
  // GRADIENTES
  // ============================================
  
  /// Gradiente primário do app (circular do logo)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF5de0e6), // Ciano claro
      Color(0xFF004aad), // Azul escuro
    ],
  );
  
  /// Gradiente do ícone do app (igual ao logo)
  static const LinearGradient iconGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF5de0e6), // Ciano claro
      Color(0xFF004aad), // Azul escuro
    ],
  );
  
  /// Gradiente radial para fundos especiais
  static const RadialGradient radialGradient = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [
      Color(0xFF5de0e6), // Ciano claro
      Color(0xFF004aad), // Azul escuro
    ],
  );

  // ============================================
  // CORES DE LATÊNCIA
  // ============================================
  
  /// Latência excelente (< 50ms)
  static const Color latencyExcellent = Color(0xFF4CAF50);
  
  /// Latência boa (50-100ms)
  static const Color latencyGood = Color(0xFF8BC34A);
  
  /// Latência média (100-200ms)
  static const Color latencyMedium = Color(0xFFFFA726);
  
  /// Latência ruim (> 200ms)
  static const Color latencyPoor = Color(0xFFEF5350);
  
  /// Latência desconhecida/erro
  static const Color latencyUnknown = Color(0xFF9E9E9E);

  // ============================================
  // MÉTODOS UTILITÁRIOS
  // ============================================
  
  /// Retorna a cor de latência baseada no valor em ms
  static Color getLatencyColor(int? latencyMs) {
    if (latencyMs == null) return latencyUnknown;
    if (latencyMs < 50) return latencyExcellent;
    if (latencyMs < 100) return latencyGood;
    if (latencyMs < 200) return latencyMedium;
    return latencyPoor;
  }
  
  /// Retorna a cor do provedor DNS pelo nome
  static Color getProviderColor(String providerName) {
    final name = providerName.toLowerCase();
    if (name.contains('cloudflare')) return providerCloudflare;
    if (name.contains('google')) return providerGoogle;
    if (name.contains('quad9')) return providerQuad9;
    if (name.contains('adguard')) return providerAdguard;
    return providerCustom;
  }
  
  /// Retorna cor com opacidade para fundos
  static Color withSurfaceOpacity(Color color, {double opacity = 0.1}) {
    return color.withOpacity(opacity);
  }
}
