import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/dns_server.dart';
import '../theme/app_colors.dart';

/// Dialog de informações detalhadas sobre um servidor DNS
/// 
/// Exibe:
/// - Logo e nome do servidor
/// - Hostname
/// - Descrição detalhada
/// - Lista de benefícios
/// - Botão para visitar o site oficial
class ServerInfoDialog extends StatelessWidget {
  final DnsServer server;

  const ServerInfoDialog({super.key, required this.server});

  /// Exibe o dialog como BottomSheet
  static void show({
    required BuildContext context,
    required DnsServer server,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ServerInfoDialog(server: server),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final serverColor = server.color ?? AppColors.primary;
    final bgColor = isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Conteúdo scrollável
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com logo e nome
                    _buildHeader(serverColor, textColor, subtitleColor, isDarkMode),
                    
                    const SizedBox(height: 24),
                    
                    // Descrição
                    if (server.description != null) ...[
                      _buildSectionTitle('Sobre', Icons.info_outline_rounded, textColor),
                      const SizedBox(height: 8),
                      Text(
                        server.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Benefícios
                    if (server.benefits != null && server.benefits!.isNotEmpty) ...[
                      _buildSectionTitle('Benefícios', Icons.check_circle_outline_rounded, textColor),
                      const SizedBox(height: 12),
                      ...server.benefits!.map((benefit) => _buildBenefitItem(
                        benefit, 
                        serverColor,
                        subtitleColor,
                      )),
                      const SizedBox(height: 24),
                    ],
                    
                    // Botão visitar site
                    if (server.websiteUrl != null)
                      _buildVisitButton(serverColor),
                    
                    // Espaço extra para safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color serverColor, Color textColor, Color? subtitleColor, bool isDarkMode) {
    return Row(
      children: [
        // Logo
        _buildLogo(serverColor, isDarkMode),
        const SizedBox(width: 16),
        
        // Nome e hostname
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                server.name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: serverColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  server.hostname,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: serverColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(Color serverColor, bool isDarkMode) {
    const double size = 56;
    
    // Logo customizado
    if (server.customLogoPath != null) {
      final file = File(server.customLogoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    
    // Logo SVG dos assets
    if (server.logoAsset != null) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: serverColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SvgPicture.asset(
          server.logoAsset!,
          colorFilter: ColorFilter.mode(serverColor, BlendMode.srcIn),
        ),
      );
    }
    
    // Fallback
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: serverColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          server.name.isNotEmpty ? server.name[0].toUpperCase() : 'D',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: serverColor,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 20, color: textColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String benefit, Color serverColor, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: serverColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 14,
              color: serverColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              benefit,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitButton(Color serverColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _launchUrl,
        style: ElevatedButton.styleFrom(
          backgroundColor: serverColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.open_in_new_rounded, size: 20),
        label: const Text(
          'Visitar site oficial',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl() async {
    if (server.websiteUrl == null) return;
    
    final uri = Uri.parse(server.websiteUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
