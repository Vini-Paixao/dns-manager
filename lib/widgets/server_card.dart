import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/dns_server.dart';

/// Card reutilizável para exibir um servidor DNS
/// 
/// Suporta:
/// - Logo SVG dos assets ou PNG customizado
/// - Cor de destaque personalizada
/// - Estados: normal, selecionado, ativo
/// - Badge de favorito
/// - Ações de toque e long press
class ServerCard extends StatelessWidget {
  final DnsServer server;
  final bool isSelected;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onHideToggle; // Callback para ocultar/mostrar servidor
  final bool showFavoriteButton;
  final bool showHideButton; // Mostrar botão de ocultar (modo reordenação)
  final bool isDragging;
  final bool isCompact; // Modo compacto para reordenação

  const ServerCard({
    super.key,
    required this.server,
    this.isSelected = false,
    this.isActive = false,
    this.onTap,
    this.onLongPress,
    this.onFavoriteToggle,
    this.onHideToggle,
    this.showFavoriteButton = true,
    this.showHideButton = false,
    this.isDragging = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final serverColor = server.color ?? const Color(0xFF7C4DFF);
    
    // Modo compacto para reordenação (layout horizontal)
    if (isCompact) {
      return _buildCompactCard(serverColor);
    }
    
    return _buildFullCard(serverColor);
  }

  /// Card compacto horizontal para modo de reordenação
  Widget _buildCompactCard(Color serverColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDragging 
            ? serverColor.withOpacity(0.3)
            : isActive 
                ? serverColor.withOpacity(0.15) 
                : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
              ? serverColor 
              : isSelected 
                  ? const Color(0xFF00BFA5) 
                  : Colors.transparent,
          width: isActive || isSelected ? 2 : 1,
        ),
        boxShadow: isDragging ? [
          BoxShadow(
            color: serverColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Ícone de drag
              Icon(
                Icons.drag_handle_rounded,
                color: Colors.grey[600],
                size: 24,
              ),
              const SizedBox(width: 12),
              
              // Logo pequeno
              _buildLogo(serverColor, size: 32),
              const SizedBox(width: 12),
              
              // Nome e hostname
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      server.hostname,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Badges
              if (server.isFavorite)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
              if (isActive)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: serverColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ATIVO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              
              // Botão de ocultar/mostrar (modo reordenação)
              if (showHideButton)
                GestureDetector(
                  onTap: onHideToggle,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: server.isHidden 
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      server.isHidden 
                          ? Icons.visibility_off_rounded 
                          : Icons.visibility_rounded,
                      color: server.isHidden 
                          ? Colors.orange 
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card completo vertical (modo normal)
  Widget _buildFullCard(Color serverColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isDragging 
            ? serverColor.withOpacity(0.3)
            : isActive 
                ? serverColor.withOpacity(0.15) 
                : const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive 
              ? serverColor 
              : isSelected 
                  ? const Color(0xFF00BFA5) 
                  : Colors.transparent,
          width: isActive || isSelected ? 2 : 1,
        ),
        boxShadow: isDragging ? [
          BoxShadow(
            color: serverColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha superior: Logo + Favorito
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo do servidor
                    _buildLogo(serverColor),
                    
                    // Badges e ações
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge de ativo
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: serverColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ATIVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        
                        // Botão favorito
                        if (showFavoriteButton && onFavoriteToggle != null)
                          IconButton(
                            onPressed: onFavoriteToggle,
                            icon: Icon(
                              server.isFavorite 
                                  ? Icons.star_rounded 
                                  : Icons.star_outline_rounded,
                              color: server.isFavorite 
                                  ? Colors.amber 
                                  : Colors.grey[600],
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Nome do servidor
                Text(
                  server.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Hostname
                Text(
                  server.hostname,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Badge de servidor customizado
                if (server.isCustom) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'PERSONALIZADO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o widget do logo do servidor
  Widget _buildLogo(Color fallbackColor, {double size = 40}) {
    final double logoSize = size;
    final double borderRadius = size > 35 ? 10.0 : 8.0;
    final double padding = size > 35 ? 8.0 : 6.0;
    
    // Se tem logo customizado (arquivo local)
    if (server.customLogoPath != null) {
      final file = File(server.customLogoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.file(
            file,
            width: logoSize,
            height: logoSize,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildFallbackLogo(fallbackColor, size: size),
          ),
        );
      }
    }
    
    // Se tem logo nos assets (SVG)
    if (server.logoAsset != null) {
      return Container(
        width: logoSize,
        height: logoSize,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: fallbackColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: SvgPicture.asset(
          server.logoAsset!,
          width: logoSize - (padding * 2),
          height: logoSize - (padding * 2),
          colorFilter: ColorFilter.mode(
            fallbackColor,
            BlendMode.srcIn,
          ),
          placeholderBuilder: (_) => _buildFallbackIcon(fallbackColor, size: size),
        ),
      );
    }
    
    // Fallback: ícone baseado no ID ou genérico
    return _buildFallbackLogo(fallbackColor, size: size);
  }

  /// Logo fallback com inicial do nome
  Widget _buildFallbackLogo(Color color, {double size = 40}) {
    final double borderRadius = size > 35 ? 10.0 : 8.0;
    final double fontSize = size > 35 ? 18.0 : 14.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Text(
          server.name.isNotEmpty ? server.name[0].toUpperCase() : 'D',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  /// Ícone fallback para quando SVG não carrega
  Widget _buildFallbackIcon(Color color, {double size = 40}) {
    return Icon(
      Icons.dns_rounded,
      color: color,
      size: size > 35 ? 24 : 18,
    );
  }
}

/// Card de placeholder para adicionar novo servidor
class AddServerCard extends StatelessWidget {
  final VoidCallback? onTap;

  const AddServerCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[700]!,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C4DFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Adicionar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
              Text(
                'servidor',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
